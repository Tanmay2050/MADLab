import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'invoice_model.dart';
import 'pdf_service.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  DateTime _date = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  double _taxRate = 0.0;

  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  final List<InvoiceItem> _items = [
    InvoiceItem(description: '', quantity: 1, price: 0.0),
  ];

  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _priceControllers = [];

  File? _selectedQRCode;
  final ImagePicker _picker = ImagePicker();
  bool _showQRCodeInPDF = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var item in _items) {
      _descriptionControllers.add(TextEditingController(text: item.description));
      _quantityControllers.add(TextEditingController(text: item.quantity.toString()));
      _priceControllers.add(TextEditingController(text: item.price.toStringAsFixed(2)));
    }
  }

  Future<void> _pickQRCodeFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedQRCode = File(image.path);
          _showQRCodeInPDF = true;
        });
        _showSnackBar('QR Code selected from gallery!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Failed to pick QR Code: $e', Colors.red);
    }
  }

  Future<void> _captureQRCodeFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedQRCode = File(image.path);
          _showQRCodeInPDF = true;
        });
        _showSnackBar('QR Code captured from camera!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Failed to capture QR Code: $e', Colors.red);
    }
  }

  void _removeQRCode() {
    setState(() {
      _selectedQRCode = null;
      _showQRCodeInPDF = false;
    });
    _showSnackBar('QR Code removed', Colors.orange);
  }

  void _showQRCodeOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickQRCodeFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Capture from Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _captureQRCodeFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem(description: '', quantity: 1, price: 0.0));
      _descriptionControllers.add(TextEditingController());
      _quantityControllers.add(TextEditingController(text: '1'));
      _priceControllers.add(TextEditingController(text: '0.00'));
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
        _descriptionControllers.removeAt(index);
        _quantityControllers.removeAt(index);
        _priceControllers.removeAt(index);
      });
      _showSnackBar('Item removed', Colors.orange);
    } else {
      _showSnackBar('At least one item is required', Colors.red);
    }
  }

  void _updateItem(int index) {
    final description = _descriptionControllers[index].text;
    final quantity = int.tryParse(_quantityControllers[index].text) ?? 1;
    final price = double.tryParse(_priceControllers[index].text) ?? 0.0;

    setState(() {
      _items[index] = InvoiceItem(
        description: description,
        quantity: quantity,
        price: price,
      );
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _generateInvoice() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final String fromText = _fromController.text;
      final String toText = _toController.text;

      bool hasValidItems = _items.any((item) =>
      item.description.isNotEmpty && item.price > 0);

      if (!hasValidItems) {
        _showSnackBar('Please add at least one item with description and price', Colors.red);
        return;
      }

      if (fromText.isEmpty || toText.isEmpty) {
        _showSnackBar('Please fill company and client details', Colors.red);
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Row(
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700)),
                const SizedBox(width: 20),
                const Text("Creating Professional Invoice...", style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      );

      try {
        final invoice = Invoice(
          invoiceNumber: _invoiceNumber,
          date: _date,
          dueDate: _dueDate,
          from: fromText,
          to: toText,
          items: _items.where((item) => item.description.isNotEmpty).toList(),
          taxRate: _taxRate,
          qrCodeImage: _showQRCodeInPDF ? _selectedQRCode : null,
        );

        await PdfService.generateInvoice(invoice);
        _showSnackBar('Invoice generated successfully!', Colors.green);
      } catch (e) {
        _showSnackBar('Error generating PDF: $e', Colors.red);
      } finally {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _date = DateTime.now();
      _dueDate = DateTime.now().add(const Duration(days: 30));
      _taxRate = 0.0;

      _fromController.clear();
      _toController.clear();

      _items.clear();
      _descriptionControllers.clear();
      _quantityControllers.clear();
      _priceControllers.clear();

      _items.add(InvoiceItem(description: '', quantity: 1, price: 0.0));
      _descriptionControllers.add(TextEditingController());
      _quantityControllers.add(TextEditingController(text: '1'));
      _priceControllers.add(TextEditingController(text: '0.00'));

      _selectedQRCode = null;
      _showQRCodeInPDF = false;
    });
    _showSnackBar('Form reset successfully', Colors.blue);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    for (var controller in _descriptionControllers) {
      controller.dispose();
    }
    for (var controller in _quantityControllers) {
      controller.dispose();
    }
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Generator',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Logged in as: ${_currentUser?.email ?? 'User'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withAlpha(200),
                height: 1.2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.blue.shade100,
        toolbarHeight: 80,
        actions: [
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ),
          Tooltip(
            message: 'Reset Form',
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetForm,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildInvoiceInfo(),
              const SizedBox(height: 20),
              _buildPartiesInfo(),
              const SizedBox(height: 20),
              _buildItemsList(),
              const SizedBox(height: 20),
              _buildTaxInfo(),
              const SizedBox(height: 20),
              _buildQRCodeSection(),
              const SizedBox(height: 20),
              _buildTotalSection(),
              const SizedBox(height: 30),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceInfo() {
    return _buildSection(
      title: 'Invoice Details',
      icon: Icons.description,
      backgroundColor: Colors.blue.shade50,
      child: Column(
        children: [
          _buildInputField(
            label: 'Invoice Number',
            icon: Icons.numbers,
            initialValue: _invoiceNumber,
            onSaved: (value) => _invoiceNumber = value!,
            validator: (value) => value!.isEmpty ? 'Invoice number is required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Invoice Date',
                  date: _date,
                  onTap: () => _selectDate(context, isDueDate: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'Due Date',
                  date: _dueDate,
                  onTap: () => _selectDate(context, isDueDate: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartiesInfo() {
    return _buildSection(
      title: 'Company & Client Details',
      icon: Icons.business_center,
      backgroundColor: Colors.blue.shade50,
      child: Column(
        children: [
          _buildRichTextField(
            controller: _fromController,
            label: 'Your Company Details',
            hint: 'Company Name\nStreet Address\nCity, State, ZIP Code\nEmail • Phone',
            icon: Icons.business,
          ),
          const SizedBox(height: 16),
          _buildRichTextField(
            controller: _toController,
            label: 'Client Details',
            hint: 'Client Company Name\nBilling Address\nCity, State, ZIP Code\nEmail • Phone',
            icon: Icons.person,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return _buildSection(
      title: 'Items & Services',
      icon: Icons.shopping_cart,
      backgroundColor: Colors.blue.shade50,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add products or services',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              FloatingActionButton.small(
                onPressed: _addItem,
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
                tooltip: 'Add New Item',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            return _buildItemCard(index);
          }),
          if (_items.isEmpty) _buildEmptyItemsState(),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory_2, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item ${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildItemInputField(
                        controller: _descriptionControllers[index],
                        label: 'Product/Service Description',
                        hint: 'e.g., Website Development, Product Name, Consulting Hours',
                        onChanged: (value) => _updateItem(index),
                      ),
                    ],
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    onPressed: () => _removeItem(index),
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                    tooltip: 'Remove Item',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildItemInputField(
                    controller: _quantityControllers[index],
                    label: 'Quantity',
                    hint: 'Qty',
                    isNumber: true,
                    onChanged: (value) => _updateItem(index),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildItemInputField(
                    controller: _priceControllers[index],
                    label: 'Unit Price',
                    hint: '0.00',
                    isNumber: true,
                    isPrice: true,
                    onChanged: (value) => _updateItem(index),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${_items[index].total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.blue.shade400),
          const SizedBox(height: 12),
          Text(
            'No items added',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the + button to add your first item',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxInfo() {
    return _buildSection(
      title: 'Tax & Discounts',
      icon: Icons.percent,
      backgroundColor: Colors.blue.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.savings, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tax Rate',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_taxRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _taxRate,
            min: 0,
            max: 30,
            divisions: 30,
            label: '${_taxRate.toStringAsFixed(1)}%',
            activeColor: Colors.blue.shade700,
            inactiveColor: Colors.blue.shade300,
            onChanged: (value) {
              setState(() {
                _taxRate = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('0%', style: TextStyle(color: Colors.blue.shade600)),
              const Spacer(),
              Text('30%', style: TextStyle(color: Colors.blue.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return _buildSection(
      title: 'QR Code',
      icon: Icons.qr_code,
      backgroundColor: Colors.blue.shade50,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Add QR Code',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Switch(
                value: _showQRCodeInPDF,
                activeColor: Colors.blue.shade700,
                onChanged: (value) {
                  setState(() {
                    _showQRCodeInPDF = value;
                    if (!value) {
                      _selectedQRCode = null;
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showQRCodeInPDF)
            Column(
              children: [
                if (_selectedQRCode != null)
                  Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.file(_selectedQRCode!, fit: BoxFit.cover),
                  )
                else
                  Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'No QR Code',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showQRCodeOptions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add QR Code'),
                      ),
                    ),
                    if (_selectedQRCode != null) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _removeQRCode,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                        ),
                        icon: Icon(Icons.delete, color: Colors.red.shade700),
                        tooltip: 'Remove QR Code',
                      ),
                    ],
                  ],
                ),
              ],
            )
          else
            Text(
              'Toggle on to add QR code for online payments',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    final invoice = Invoice(
      invoiceNumber: _invoiceNumber,
      date: _date,
      dueDate: _dueDate,
      from: _fromController.text,
      to: _toController.text,
      items: _items,
      taxRate: _taxRate,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Invoice Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTotalRow('Subtotal Amount', invoice.subtotal),
            _buildTotalRow('Tax (${_taxRate.toStringAsFixed(1)}%)', invoice.taxAmount),
            Divider(height: 24, thickness: 1, color: Colors.blue.shade300),
            _buildTotalRow('Grand Total', invoice.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green.shade700 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _generateInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              shadowColor: Colors.blue.shade200,
            ),
            icon: const Icon(Icons.picture_as_pdf, size: 24),
            label: const Text('Generate Professional Invoice'),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _resetForm,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.blue.shade300),
          ),
          icon: Icon(Icons.refresh, size: 20, color: Colors.blue.shade700),
          label: const Text('Clear All Fields'),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child, Color? backgroundColor}) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String initialValue,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      onSaved: onSaved,
      validator: validator,
    );
  }

  Widget _buildDateField({required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Text(_formatDate(date), style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildRichTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        alignLabelWithHint: true,
      ),
      validator: (value) => value!.isEmpty ? 'This field is required' : null,
    );
  }

  Widget _buildItemInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumber = false,
    bool isPrice = false,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: isPrice ? '₹ ' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isDueDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? _dueDate : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue.shade700,
            colorScheme: ColorScheme.light(primary: Colors.blue.shade700),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}