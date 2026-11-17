import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../pages/chat_room_page.dart';
import '../services/app_state.dart';
import 'common.dart';
import 'post_card.dart';

/// ดูโพสต์หรือสินค้าแบบเต็ม (แตะจากตารางในโปรไฟล์)
Future<void> showItemViewer(BuildContext context, {Post? post, Product? product}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final s = ctx.watch<AppState>();
      if (post != null) {
        final currentPost = s.postById(post.id) ?? post;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: PostCard(post: currentPost),
            ),
          ),
        );
      }
      final url = product?.imageUrl;
      final own = product!.sellerId == s.me!.id;
      final text = '${product.title} · ฿${product.price % 1 == 0 ? product.price.toInt() : product.price}';
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (url != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: NetImage(url, width: double.infinity, fit: BoxFit.contain)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Text('${product.category} · ${product.condition}'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                FilledButton(
                  onPressed: () => contactSeller(ctx, product.contact),
                  child: Text('ติดต่อ ${product.contact}'),
                ),
                if (!own)
                  OutlinedButton(
                    onPressed: () async {
                      final nav = Navigator.of(ctx);
                      try {
                        final id = await s.startChat(product.sellerId);
                        await s.sendProductToChat(id, product);
                        nav.pop();
                        nav.push(MaterialPageRoute(builder: (_) => ChatRoomPage(chatId: id)));
                      } catch (e) {
                        if (ctx.mounted) snack(ctx, errText(e));
                      }
                    },
                    child: const Text('💬 ทักแชทผู้ขาย'),
                  ),
                if (own || s.isAdmin)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('ลบ'),
                    onPressed: () async {
                      if (await confirmDelete(ctx) && ctx.mounted) {
                        final nav = Navigator.of(ctx);
                        final ok = await guard(ctx, () => s.deleteProduct(product.id));
                        if (ok) nav.pop();
                      }
                    },
                  ),
              ]),
            ]),
          ),
        ),
      );
    },
  );
}
