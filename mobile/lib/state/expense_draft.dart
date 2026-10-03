import 'package:flutter/foundation.dart';

class ExpenseDraft extends ChangeNotifier {
  String amount = '';
  String description = '';
  String categoryId = 'general';
  DateTime date = DateTime.now().toUtc();
  String? receiptPhotoPath;
  double? latitude;
  double? longitude;
  Map<String, String> serverErrors = {};
  String? operationId;

  static String? validateAmount(String? value) {
    final text = (value ?? '').trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
      return 'Monto: ingrese un número positivo con hasta dos decimales.';
    }
    final amount = double.tryParse(text);
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        amount > 9999999999.99) {
      return 'Monto: debe ser mayor que cero y no superar 9.999.999.999,99.';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Descripción: indique en qué consistió el gasto.';
    if (text.length > 255) return 'Descripción: use hasta 255 caracteres.';
    return null;
  }

  Map<String, String> validate() {
    final errors = <String, String>{};
    final amountError = validateAmount(amount);
    final descriptionError = validateDescription(description);
    if (amountError != null) errors['amount'] = amountError;
    if (descriptionError != null) errors['description'] = descriptionError;
    if (categoryId.trim().isEmpty || categoryId.length > 100) {
      errors['category_id'] = 'Categoría: use entre 1 y 100 caracteres.';
    }
    return errors;
  }

  void edit(String field, String value) {
    if (field == 'amount') amount = value;
    if (field == 'description') description = value;
    serverErrors = Map<String, String>.of(serverErrors)..remove(field);
    notifyListeners();
  }

  void clear() {
    amount = '';
    description = '';
    categoryId = 'general';
    date = DateTime.now().toUtc();
    receiptPhotoPath = null;
    latitude = null;
    longitude = null;
    serverErrors = {};
    operationId = null;
    notifyListeners();
  }
}
