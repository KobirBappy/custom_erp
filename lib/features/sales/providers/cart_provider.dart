import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/models/product.dart';
import '../models/sale.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.qty,
    this.discount = 0.0,
    this.transportPerUnit = 0.0,
  });

  final Product product;
  final double qty;
  final double discount;
  final double transportPerUnit;

  double get unitPrice => product.sellingPrice;
  double get taxAmount => (unitPrice * qty) * product.taxPercent / 100;
  double get lineTotal => (unitPrice * qty) + taxAmount - discount;
  double get lineTransportTotal => transportPerUnit * qty;

  CartItem copyWith({double? qty, double? discount, double? transportPerUnit}) {
    return CartItem(
      product: product,
      qty: qty ?? this.qty,
      discount: discount ?? this.discount,
      transportPerUnit: transportPerUnit ?? this.transportPerUnit,
    );
  }
}

class CartState {
  const CartState({
    this.items = const [],
    this.customerId = '',
    this.customerName = 'Walk-In Customer',
    this.globalDiscount = 0.0,
    this.manualTransportCost = 0.0,
    this.paymentMethod = 'cash',
    this.notes = '',
  });

  final List<CartItem> items;
  final String customerId;
  final String customerName;
  final double globalDiscount;
  final double manualTransportCost;
  final String paymentMethod;
  final String notes;

  double get subTotal => items.fold(0.0, (sum, i) => sum + i.unitPrice * i.qty);
  double get totalTax => items.fold(0.0, (sum, i) => sum + i.taxAmount);
  double get totalLineDiscount => items.fold(0.0, (sum, i) => sum + i.discount);
  double get lineTransportCost =>
      items.fold(0.0, (sum, i) => sum + i.lineTransportTotal);
  double get transportCost => lineTransportCost + manualTransportCost;
  double get grandTotal =>
      subTotal + totalTax - totalLineDiscount - globalDiscount;
  int get totalQty => items.fold(0, (sum, i) => sum + i.qty.toInt());
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    String? customerId,
    String? customerName,
    double? globalDiscount,
    double? manualTransportCost,
    String? paymentMethod,
    String? notes,
  }) {
    return CartState(
      items: items ?? this.items,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      globalDiscount: globalDiscount ?? this.globalDiscount,
      manualTransportCost: manualTransportCost ?? this.manualTransportCost,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }

  List<SaleLine> toSaleLines() {
    return items
        .map((i) => SaleLine(
              productId: i.product.id,
              productName: i.product.name,
              sku: i.product.sku,
              qty: i.qty,
              unitPrice: i.unitPrice,
              taxPercent: i.product.taxPercent,
              discount: i.discount,
            ))
        .toList();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addProduct(Product product) {
    final existing = state.items.indexWhere((i) => i.product.id == product.id);
    if (existing >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[existing] =
          updated[existing].copyWith(qty: updated[existing].qty + 1);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(product: product, qty: 1)],
      );
    }
  }

  void removeProduct(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.id != productId).toList(),
    );
  }

  void updateQty(String productId, double qty) {
    if (qty <= 0) {
      removeProduct(productId);
      return;
    }
    state = state.copyWith(
      items: [
        for (final i in state.items)
          if (i.product.id == productId) i.copyWith(qty: qty) else i,
      ],
    );
  }

  void updateLineDiscount(String productId, double discount) {
    state = state.copyWith(
      items: [
        for (final i in state.items)
          if (i.product.id == productId) i.copyWith(discount: discount) else i,
      ],
    );
  }

  void updateProductTransport(String productId, double transportPerUnit) {
    state = state.copyWith(
      items: [
        for (final i in state.items)
          if (i.product.id == productId)
            i.copyWith(
                transportPerUnit: transportPerUnit < 0 ? 0 : transportPerUnit)
          else
            i,
      ],
    );
  }

  void setCustomer({required String id, required String name}) {
    state = state.copyWith(customerId: id, customerName: name);
  }

  void setGlobalDiscount(double discount) {
    state = state.copyWith(globalDiscount: discount);
  }

  void setTransportCost(double cost) {
    state = state.copyWith(manualTransportCost: cost < 0 ? 0 : cost);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void clear() {
    state = const CartState();
  }
}
