import 'dart:io';

class InvoiceItem {
  String description;
  int quantity;
  double price;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }
}

class Invoice {
  String invoiceNumber;
  DateTime date;
  DateTime dueDate;
  String from;
  String to;
  List<InvoiceItem> items;
  double taxRate;
  File? qrCodeImage;

  Invoice({
    required this.invoiceNumber,
    required this.date,
    required this.dueDate,
    required this.from,
    required this.to,
    required this.items,
    this.taxRate = 0.0,
    this.qrCodeImage,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * taxRate / 100;
  double get total => subtotal + taxAmount;

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'from': from,
      'to': to,
      'items': items.map((item) => item.toMap()).toList(),
      'taxRate': taxRate,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'total': total,
      'hasQRCode': qrCodeImage != null,
    };
  }
}