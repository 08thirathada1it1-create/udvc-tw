-- ============================================================
-- UDVC Vibe : โครงสร้างฐานข้อมูล Supabase
-- วิธีใช้: Supabase Dashboard > SQL Editor > New query > วางทั้งไฟล์ > Run
-- ============================================================
create extension if not exists pgcrypto;

-- ---------- ผู้ใช้ ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,20}$'),
  name text not null,
  level text,
  major text,
  bio text not null default '',
  avatar_url text,
  role text not null default 'student' check (role in ('student','admin')),
  created_at timestamptz not null default now()   -- เวลาลงทะเบียน
);

create or replace function public.is_admin() returns boolean
language sql security definer set search_path = public stable as $$
  select exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
$$;

-- สร้างโปรไฟล์อัตโนมัติเมื่อสมัครสมาชิก
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, name, level, major)
  values (new.id,
          lower(new.raw_user_meta_data->>'username'),
          coalesce(nullif(new.raw_user_meta_data->>'name',''), 'ผู้ใช้'),
          new.raw_user_meta_data->>'level',
          new.raw_user_meta_data->>'major');
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- กันผู้ใช้แก้ชื่อผู้ใช้ / เวลาลงทะเบียน / สิทธิ์ admin ของตัวเอง
create or replace function public.protect_profile() returns trigger
language plpgsql as $$
begin
  new.username := old.username;
  new.created_at := old.created_at;
  if new.role is distinct from old.role and auth.uid() is not null and not public.is_admin() then
    new.role := old.role;
  end if;
  return new;
end $$;
create trigger protect_profile before update on public.profiles
  for each row execute function public.protect_profile();

create or replace function public.username_available(u text) returns boolean
language sql security definer set search_path = public stable as $$
  select not exists (select 1 from public.profiles where username = lower(u))
$$;

-- ---------- โพสต์ / สตอรี่ ----------
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  caption text not null default '',
  image_url text,
  is_story boolean not null default false,
  created_at timestamptz not null default now()
);
create index on public.posts (created_at desc);

create table public.post_likes (
  post_id uuid references public.posts(id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  primary key (post_id, user_id)
);

create table public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  parent_id uuid references public.comments(id) on delete cascade,
  author_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  body text not null check (length(body) between 1 and 300),
  created_at timestamptz not null default now()
);
create table public.comment_likes (
  comment_id uuid references public.comments(id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  primary key (comment_id, user_id)
);

-- ---------- สินค้า (Shop) ----------
create table public.products (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  title text not null,
  price numeric not null check (price >= 0),
  category text,
  condition text,
  contact text not null,
  image_url text,
  created_at timestamptz not null default now()
);

-- ---------- การ์ดหาเพื่อน (Friends) ----------
create table public.buddies (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  bio text not null default '',
  image_url text,
  created_at timestamptz not null default now()
);

-- ---------- แชท ----------
create table public.chats (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (user_a < user_b),
  unique (user_a, user_b)
);
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  body text not null default '',
  image_url text,
  post_id uuid references public.posts(id) on delete set null,
  liked boolean not null default false,
  created_at timestamptz not null default now()
);
create index on public.messages (chat_id, created_at);

-- เริ่มแชท (สร้างห้องระหว่างสองคน ถ้ามีอยู่แล้วจะคืนห้องเดิม)
create or replace function public.start_chat(other uuid) returns uuid
language plpgsql security definer set search_path = public as $$
declare a uuid; b uuid; cid uuid;
begin
  if auth.uid() is null or other is null or other = auth.uid() then raise exception 'invalid'; end if;
  a := least(auth.uid(), other); b := greatest(auth.uid(), other);
  select id into cid from chats where user_a = a and user_b = b;
  if cid is null then insert into chats (user_a, user_b) values (a, b) returning id into cid; end if;
  return cid;
end $$;

-- กดหัวใจข้อความ (สมาชิกในห้องเท่านั้น)
create or replace function public.toggle_message_like(msg uuid) returns void
language sql security definer set search_path = public as $$
  update messages m set liked = not liked
  where m.id = msg and exists (select 1 from chats c where c.id = m.chat_id and auth.uid() in (c.user_a, c.user_b))
$$;

-- ---------- กิจกรรม / แจ้งปัญหา ----------
create table public.events (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  title text not null,
  event_date date not null,
  event_time time,
  place text,
  note text,
  image_url text,
  created_at timestamptz not null default now()
);
create table public.event_rsvps (
  event_id uuid references public.events(id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  primary key (event_id, user_id)
);
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  title text not null,
  location text not null,
  detail text,
  image_url text,
  status smallint not null default 0 check (status between 0 and 2),  -- 0 รอตรวจสอบ 1 กำลังแก้ไข 2 แก้ไขแล้ว
  created_at timestamptz not null default now()
);

-- ============================================================
-- สิทธิ์การเข้าถึง (Row Level Security) — ต้องเปิดทุกตาราง
-- ============================================================
alter table public.profiles       enable row level security;
alter table public.posts          enable row level security;
alter table public.post_likes     enable row level security;
alter table public.comments       enable row level security;
alter table public.comment_likes  enable row level security;
alter table public.products       enable row level security;
alter table public.buddies        enable row level security;
alter table public.chats          enable row level security;
alter table public.messages       enable row level security;
alter table public.events         enable row level security;
alter table public.event_rsvps    enable row level security;
alter table public.reports        enable row level security;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on all functions in schema public to authenticated;
grant execute on function public.username_available(text) to anon;

-- profiles
create policy "profiles read"   on public.profiles for select to authenticated using (true);
create policy "profiles update" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
-- posts
create policy "posts read"   on public.posts for select to authenticated using (true);
create policy "posts insert" on public.posts for insert to authenticated with check (author_id = auth.uid());
create policy "posts delete" on public.posts for delete to authenticated using (author_id = auth.uid() or public.is_admin());
-- likes
create policy "plikes read"   on public.post_likes for select to authenticated using (true);
create policy "plikes insert" on public.post_likes for insert to authenticated with check (user_id = auth.uid());
create policy "plikes delete" on public.post_likes for delete to authenticated using (user_id = auth.uid());
-- comments
create policy "comments read"   on public.comments for select to authenticated using (true);
create policy "comments insert" on public.comments for insert to authenticated with check (author_id = auth.uid());
create policy "comments delete" on public.comments for delete to authenticated using (author_id = auth.uid() or public.is_admin());
create policy "clikes read"   on public.comment_likes for select to authenticated using (true);
create policy "clikes insert" on public.comment_likes for insert to authenticated with check (user_id = auth.uid());
create policy "clikes delete" on public.comment_likes for delete to authenticated using (user_id = auth.uid());
-- products
create policy "products read"   on public.products for select to authenticated using (true);
create policy "products insert" on public.products for insert to authenticated with check (seller_id = auth.uid());
create policy "products update" on public.products for update to authenticated using (seller_id = auth.uid()) with check (seller_id = auth.uid());
create policy "products delete" on public.products for delete to authenticated using (seller_id = auth.uid() or public.is_admin());
-- buddies
create policy "buddies read"   on public.buddies for select to authenticated using (true);
create policy "buddies insert" on public.buddies for insert to authenticated with check (owner_id = auth.uid());
create policy "buddies delete" on public.buddies for delete to authenticated using (owner_id = auth.uid() or public.is_admin());
-- chats / messages (เห็นเฉพาะสมาชิกในห้อง)
create policy "chats read" on public.chats for select to authenticated using (auth.uid() in (user_a, user_b));
create policy "messages read" on public.messages for select to authenticated
  using (exists (select 1 from public.chats c where c.id = chat_id and auth.uid() in (c.user_a, c.user_b)));
create policy "messages insert" on public.messages for insert to authenticated
  with check (sender_id = auth.uid() and exists (select 1 from public.chats c where c.id = chat_id and auth.uid() in (c.user_a, c.user_b)));
create policy "messages delete" on public.messages for delete to authenticated using (sender_id = auth.uid());
-- events
create policy "events read"   on public.events for select to authenticated using (true);
create policy "events insert" on public.events for insert to authenticated with check (creator_id = auth.uid());
create policy "events delete" on public.events for delete to authenticated using (creator_id = auth.uid() or public.is_admin());
create policy "rsvp read"   on public.event_rsvps for select to authenticated using (true);
create policy "rsvp insert" on public.event_rsvps for insert to authenticated with check (user_id = auth.uid());
create policy "rsvp delete" on public.event_rsvps for delete to authenticated using (user_id = auth.uid());
-- reports (เจ้าของเรื่องกับ admin เท่านั้นที่เห็น, admin เป็นคนเปลี่ยนสถานะ)
create policy "reports read"   on public.reports for select to authenticated using (reporter_id = auth.uid() or public.is_admin());
create policy "reports insert" on public.reports for insert to authenticated with check (reporter_id = auth.uid());
create policy "reports update" on public.reports for update to authenticated using (public.is_admin());
create policy "reports delete" on public.reports for delete to authenticated using (reporter_id = auth.uid() or public.is_admin());

-- ============================================================
-- ที่เก็บรูปภาพ (Storage)
-- ============================================================
insert into storage.buckets (id, name, public) values ('images', 'images', true) on conflict (id) do nothing;
create policy "images read"   on storage.objects for select using (bucket_id = 'images');
create policy "images upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'images' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "images delete" on storage.objects for delete to authenticated
  using (bucket_id = 'images' and (storage.foldername(name))[1] = auth.uid()::text);

-- ============================================================
-- Realtime (ให้แชทและฟีดอัปเดตทันที)
-- ============================================================
alter publication supabase_realtime add table
  public.profiles, public.posts, public.post_likes, public.comments, public.comment_likes,
  public.products, public.buddies, public.chats, public.messages, public.events, public.event_rsvps, public.reports;

-- ============================================================
-- ตั้งตัวเองเป็น admin (แก้ชื่อผู้ใช้ แล้วรันหลังสมัครสมาชิกในแอปแล้ว)
--   update public.profiles set role = 'admin' where username = 'ชื่อผู้ใช้ของคุณ';
-- ============================================================
