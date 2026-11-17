import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_room_page.dart';

/// หน้า Shop: สินค้านักเรียน กรองตามหมวด / ติดต่อผู้ขาย / ทักแชท
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String filter = 'ทั้งหมด';

  void _add() {
    final s = context.read<AppState>();
    final title = TextEditingController();
    final price = TextEditingController();
    final cond = TextEditingController();
    final contact = TextEditingController();
    final cat = ValueNotifier<String>(kShopCategories.first);
    final image = ValueNotifier<Uint8List?>(null);
    showFormSheet(
      context,
      title: 'ลงขายสินค้า',
      fields: [
        ImagePickerBox(bytes: image, aspect: 1.5),
        textField('ชื่อสินค้า *', title, maxLength: 80),
        textField('ราคา (บาท) *', price, type: const TextInputType.numberWithOptions(decimal: true)),
        DropField(label: 'หมวดหมู่', items: kShopCategories, value: cat),
        textField('สภาพสินค้า', cond, hint: 'เช่น มือสอง 90%', maxLength: 60),
        textField('ช่องทางติดต่อ *', contact, hint: 'เบอร์โทร / LINE ID', maxLength: 60),
      ],
      onSubmit: () async {
        final pr = double.tryParse(price.text.trim());
        if (title.text.trim().isEmpty || contact.text.trim().isEmpty) throw 'กรอกข้อมูลที่จำเป็นให้ครบ';
        if (pr == null || pr < 0) throw 'ราคาไม่ถูกต้อง';
        await s.addProduct(
          title: title.text.trim(), price: pr, category: cat.value,
          condition: cond.text.trim(), contact: contact.text.trim(), image: image.value,
        );
      },
    ).whenComplete(() {
      title.dispose();
      price.dispose();
      cond.dispose();
      contact.dispose();
      cat.dispose();
      image.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = s.products.where((m) => filter == 'ทั้งหมด' || m.category == filter).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        ChipBar(items: ['ทั้งหมด', ...kShopCategories], selected: filter, onSelected: (v) => setState(() => filter = v)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => s.reload(['products']),
            child: items.isEmpty
                ? ListView(children: const [SizedBox(height: 80), EmptyState('ยังไม่มีสินค้า กด + เพื่อลงขาย')])
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: .66,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _ProductCard(product: items[i]),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final m = product;
    final own = m.sellerId == s.me!.id;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: m.imageUrl != null
              ? NetImage(m.imageUrl!, width: double.infinity)
              : Container(color: kAccent.withOpacity(.12), child: const Center(child: Icon(Icons.shopping_bag, size: 40))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('฿${m.price % 1 == 0 ? m.price.toInt() : m.price}',
                style: const TextStyle(color: kAccent, fontWeight: FontWeight.w800)),
            Text('${m.category} · ${m.condition}\n@${s.pf(m.sellerId).username}',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
          ]),
        ),
        Row(children: [
          Expanded(
            child: TextButton(
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => contactSeller(context, m.contact),
              child: Text(
                'ติดต่อ ${m.contact}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          if (!own)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              onPressed: () async {
                final nav = Navigator.of(context);
                try {
                  final id = await s.startChat(m.sellerId);
                  await s.sendProductToChat(id, m);
                  nav.push(MaterialPageRoute(builder: (_) => ChatRoomPage(chatId: id)));
                } catch (e) {
                  if (context.mounted) snack(context, errText(e));
                }
              },
            ),
          if (own || s.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                if (await confirmDelete(context) && context.mounted) {
                  await guard(context, () => s.deleteProduct(m.id));
                }
              },
            ),
        ]),
      ]),
    );
  }
}
