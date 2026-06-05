import 'package:flutter/foundation.dart';
import '../../scanner/models/receipt_item.dart';

class CalculatorProvider with ChangeNotifier {
  List<ReceiptItem> _items = [
    ReceiptItem(id: '1', name: 'Item 1', price: 10.0),
    ReceiptItem(id: '2', name: 'Item 2', price: 15.5),
    ReceiptItem(id: '3', name: 'Item 3', price: 8.0),
  ]; // Dummy data for now
  double _taxRate = 0.0;
  double _serviceFeeRate = 0.0;

  List<ReceiptItem> get items => _items;
  double get taxRate => _taxRate;
  double get serviceFeeRate => _serviceFeeRate;

  void setItems(List<ReceiptItem> items) {
    _items = items;
    notifyListeners();
  }

  void toggleItemSelection(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].isSelected = !_items[index].isSelected;
      notifyListeners();
    }
  }

  void setTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
  }

  void setServiceFeeRate(double rate) {
    _serviceFeeRate = rate;
    notifyListeners();
  }

  double get subtotal => _items.where((item) => item.isSelected).fold(0.0, (sum, item) => sum + item.price);
  double get taxAmount => subtotal * (_taxRate / 100);
  double get serviceFeeAmount => subtotal * (_serviceFeeRate / 100);
  double get total => subtotal + taxAmount + serviceFeeAmount;
}
