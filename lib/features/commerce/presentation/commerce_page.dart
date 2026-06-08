import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/commerce_order.dart';
import 'package:offlimu/domain/entities/commerce_product.dart';

enum _CommerceSection { browse, listings, orders }

class CommercePage extends ConsumerStatefulWidget {
  const CommercePage({super.key});

  @override
  ConsumerState<CommercePage> createState() => _CommercePageState();
}

class _CommercePageState extends ConsumerState<CommercePage> {
  _CommerceSection _section = _CommerceSection.browse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commerce'),
        actions: <Widget>[
          if (_section == _CommerceSection.listings)
            IconButton(
              tooltip: 'Add product',
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add_business_rounded),
            ),
        ],
      ),
      floatingActionButton: _section == _CommerceSection.listings
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SegmentedButton<_CommerceSection>(
              selected: <_CommerceSection>{_section},
              onSelectionChanged: (value) {
                setState(() => _section = value.single);
              },
              segments: const <ButtonSegment<_CommerceSection>>[
                ButtonSegment<_CommerceSection>(
                  value: _CommerceSection.browse,
                  icon: Icon(Icons.storefront_rounded),
                  label: Text('Browse'),
                ),
                ButtonSegment<_CommerceSection>(
                  value: _CommerceSection.listings,
                  icon: Icon(Icons.inventory_2_rounded),
                  label: Text('My Listings'),
                ),
                ButtonSegment<_CommerceSection>(
                  value: _CommerceSection.orders,
                  icon: Icon(Icons.receipt_long_rounded),
                  label: Text('Orders'),
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (_section) {
              _CommerceSection.browse => const _BrowseProductsView(),
              _CommerceSection.listings => _MyListingsView(
                onAddProduct: _showAddProductDialog,
              ),
              _CommerceSection.orders => const _OrdersView(),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddProductDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _AddProductDialog(),
    );
  }
}

class CommerceProductDetailPage extends ConsumerStatefulWidget {
  const CommerceProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<CommerceProductDetailPage> createState() =>
      _CommerceProductDetailPageState();
}

class _CommerceProductDetailPageState
    extends ConsumerState<CommerceProductDetailPage> {
  final TextEditingController _detailsController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(commerceProductProvider(widget.productId));
    final localNodeId = ref.watch(localNodeIdentityProvider).nodeId;

    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found.'));
          }
          final isOwnProduct = product.vendorNodeId == localNodeId;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _ProductImage(product: product),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                product.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(product.description),
              const SizedBox(height: 16),
              _InfoRow(label: 'Vendor', value: product.vendorNodeId),
              _InfoRow(label: 'Price', value: product.priceLabel),
              _InfoRow(
                label: 'Status',
                value: product.isAvailable ? 'Available' : 'Out of stock',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _detailsController,
                enabled: product.isAvailable && !isOwnProduct && !_submitting,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Delivery address and notes',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: product.isAvailable && !isOwnProduct && !_submitting
                    ? () => _submitOrder(product)
                    : null,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shopping_bag_rounded),
                label: Text(
                  isOwnProduct
                      ? 'This is your listing'
                      : product.isAvailable
                      ? 'Buy for ${product.priceLabel}'
                      : 'Out of stock',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitOrder(CommerceProduct product) async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(submitCommerceOrderUseCaseProvider)
          .submit(
            localNodeId: ref.read(localNodeIdentityProvider).nodeId,
            productId: product.productId,
            details: _detailsController.text,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order and payment queued.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Order failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _BrowseProductsView extends ConsumerWidget {
  const _BrowseProductsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(commerceAvailableProductsProvider);
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
      data: (products) {
        if (products.isEmpty) {
          return const _EmptyState(
            icon: Icons.storefront_rounded,
            title: 'No products yet',
            body: 'Products broadcast by nearby nodes will appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(commerceAvailableProductsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) => _ProductCard(
              product: products[index],
              onTap: () => context.push(
                '/commerce/product/${Uri.encodeComponent(products[index].productId)}',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MyListingsView extends ConsumerWidget {
  const _MyListingsView({required this.onAddProduct});

  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(commerceMyListingsProvider);
    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
      data: (products) {
        if (products.isEmpty) {
          return _EmptyState(
            icon: Icons.inventory_2_rounded,
            title: 'No listings yet',
            body: 'Add a product to broadcast it across the mesh.',
            action: FilledButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          itemBuilder: (context, index) => _ProductCard(
            product: products[index],
            trailing: products[index].isAvailable
                ? IconButton(
                    tooltip: 'Mark out of stock',
                    onPressed: () =>
                        _markOutOfStock(context, ref, products[index]),
                    icon: const Icon(Icons.block_rounded),
                  )
                : const Chip(label: Text('Out')),
          ),
        );
      },
    );
  }

  Future<void> _markOutOfStock(
    BuildContext context,
    WidgetRef ref,
    CommerceProduct product,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark out of stock?'),
        content: const Text(
          'Any unresolved incoming orders for this product will be rejected and refunded.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(markProductOutOfStockUseCaseProvider)
          .markOutOfStock(
            localNodeId: ref.read(localNodeIdentityProvider).nodeId,
            product: product,
            rejectOpenOrders: true,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Out-of-stock broadcast queued.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update listing: $error')),
      );
    }
  }
}

class _OrdersView extends ConsumerWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAsync = ref.watch(commerceIncomingOrdersProvider);
    final outgoingAsync = ref.watch(commerceOutgoingOrdersProvider);
    if (incomingAsync.isLoading || outgoingAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = incomingAsync.error ?? outgoingAsync.error;
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }
    final incoming = incomingAsync.value ?? const <CommerceOrder>[];
    final outgoing = outgoingAsync.value ?? const <CommerceOrder>[];
    if (incoming.isEmpty && outgoing.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No orders yet',
        body: 'Orders you send or receive will be tracked here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        if (incoming.isNotEmpty) ...<Widget>[
          Text('Incoming', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...incoming.map(
            (order) => _OrderTile(
              order: order,
              role: _OrderRole.vendor,
              onReceive: () => _receive(context, ref, order),
              onReject: () => _reject(context, ref, order),
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (outgoing.isNotEmpty) ...<Widget>[
          Text('Outgoing', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...outgoing.map(
            (order) => _OrderTile(order: order, role: _OrderRole.buyer),
          ),
        ],
      ],
    );
  }

  Future<void> _receive(
    BuildContext context,
    WidgetRef ref,
    CommerceOrder order,
  ) async {
    try {
      await ref
          .read(markOrderReceivedUseCaseProvider)
          .markReceived(
            localNodeId: ref.read(localNodeIdentityProvider).nodeId,
            order: order,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order received bundle queued.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not receive order: $error')),
      );
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    CommerceOrder order,
  ) async {
    final controller = TextEditingController(text: 'Product unavailable');
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject order'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(rejectCommerceOrderUseCaseProvider)
          .reject(
            localNodeId: ref.read(localNodeIdentityProvider).nodeId,
            order: order,
            reason: reason,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order rejected and refund queued.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not reject order: $error')));
    }
  }
}

class _AddProductDialog extends ConsumerStatefulWidget {
  const _AddProductDialog();

  @override
  ConsumerState<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<_AddProductDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _price = TextEditingController();
  PlatformFile? _image;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              decoration: const InputDecoration(labelText: 'Price in DTN'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickImage,
              icon: const Icon(Icons.image_rounded),
              label: Text(_image == null ? 'Choose image' : _image!.name),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Publish'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() => _image = result.files.first);
  }

  Future<void> _submit() async {
    final image = _image;
    final bytes = image?.bytes;
    final priceMinorUnits = _parseMinorUnits(_price.text);
    if (image == null || bytes == null || bytes.isEmpty) {
      _show('Choose an image first.');
      return;
    }
    if (priceMinorUnits == null || priceMinorUnits <= 0) {
      _show('Enter a valid price.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(publishProductUseCaseProvider)
          .publish(
            localNodeId: ref.read(localNodeIdentityProvider).nodeId,
            title: _title.text,
            description: _description.text,
            priceMinorUnits: priceMinorUnits,
            imageFileName: image.name,
            imageBytes: Uint8List.fromList(bytes),
            imageMimeType: _mimeFor(image.name),
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product broadcast queued.')),
      );
    } catch (error) {
      _show('Could not publish: $error');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  int? _parseMinorUnits(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return null;
    }
    return (parsed * 100).round();
  }

  String _mimeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, this.onTap, this.trailing});

  final CommerceProduct product;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 86,
                  height: 74,
                  child: _ProductImage(product: product),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(product.priceLabel),
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            product.isAvailable ? 'Available' : 'Out of stock',
                          ),
                        ),
                      ],
                    ),
                    Text(
                      product.vendorNodeId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends ConsumerWidget {
  const _ProductImage({required this.product});

  final CommerceProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!product.hasImage && product.imageReceivedChunkCount <= 0) {
      return const ColoredBox(
        color: Color(0xFFE5EEE1),
        child: Center(child: Icon(Icons.image_not_supported_rounded)),
      );
    }
    return FutureBuilder<Uint8List?>(
      future: ref
          .read(contentStoreProvider)
          .read(contentHash: product.imageContentHash),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return ColoredBox(
            color: const Color(0xFFE5EEE1),
            child: Center(
              child: Text(
                product.imageExpectedChunkCount <= 0
                    ? 'Image pending'
                    : '${product.imageReceivedChunkCount}/${product.imageExpectedChunkCount} chunks',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return Image.memory(bytes, fit: BoxFit.cover);
      },
    );
  }
}

enum _OrderRole { buyer, vendor }

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    required this.role,
    this.onReceive,
    this.onReject,
  });

  final CommerceOrder order;
  final _OrderRole role;
  final VoidCallback? onReceive;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final isVendorOpen = role == _OrderRole.vendor && order.isOpen;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    order.productTitle ?? order.productId,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(label: Text(_statusLabel(order.status))),
              ],
            ),
            const SizedBox(height: 4),
            Text(order.priceLabel),
            Text(
              role == _OrderRole.vendor
                  ? 'Buyer ${order.buyerNodeId}'
                  : 'Vendor ${order.vendorNodeId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (order.details.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(order.details),
            ],
            if (order.rejectionReason != null) ...<Widget>[
              const SizedBox(height: 8),
              Text('Reason: ${order.rejectionReason}'),
            ],
            if (isVendorOpen) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onReceive,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Receive'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(CommerceOrderStatus status) {
    return switch (status) {
      CommerceOrderStatus.pendingPayment => 'Pending payment',
      CommerceOrderStatus.pendingVendor => 'Pending vendor',
      CommerceOrderStatus.received => 'Received',
      CommerceOrderStatus.rejected => 'Rejected',
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center),
            if (action != null) ...<Widget>[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
