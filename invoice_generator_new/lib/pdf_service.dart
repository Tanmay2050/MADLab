import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'invoice_model.dart';

class PdfService {
  static Future<void> generateInvoice(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(invoice),
              pw.SizedBox(height: 25),

              _buildParties(invoice),
              pw.SizedBox(height: 25),

              _buildItemsTable(invoice),
              pw.SizedBox(height: 20),

              _buildTotals(invoice),
              pw.SizedBox(height: 30),

              _buildFooter(),

              if (invoice.qrCodeImage != null) ...[
                pw.Spacer(),
                _buildQRCodeSection(invoice.qrCodeImage!),
                pw.SizedBox(height: 20),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '#${invoice.invoiceNumber}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Date: ${_formatDate(invoice.date)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Due Date: ${_formatDate(invoice.dueDate)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildParties(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FROM:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.from.isEmpty ? 'Your Company Details' : invoice.from,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 30),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TO:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                invoice.to.isEmpty ? 'Client Details' : invoice.to,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(10.0),
              child: pw.Text(
                'Description',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10.0),
              child: pw.Text(
                'Qty',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10.0),
              child: pw.Text(
                'Price',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10.0),
              child: pw.Text(
                'Total',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        for (var item in invoice.items)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(10.0),
                child: pw.Text(
                  item.description.isEmpty ? 'Item Description' : item.description,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10.0),
                child: pw.Text(
                  item.quantity.toString(),
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10.0),
                child: pw.Text(
                  'Rs. ${item.price.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10.0),
                child: pw.Text(
                  'Rs. ${item.total.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildTotals(Invoice invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Subtotal:',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Tax (${invoice.taxRate.toStringAsFixed(1)}%):',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'TOTAL:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          pw.SizedBox(width: 25),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Rs. ${invoice.subtotal.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Rs. ${invoice.taxAmount.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Rs. ${invoice.total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Please make payment within 30 days',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildQRCodeSection(File qrCodeImage) {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: double.infinity,
            height: 1,
            color: PdfColors.grey300,
            margin: const pw.EdgeInsets.only(bottom: 20),
          ),

          pw.Text(
            'SCAN QR CODE FOR ONLINE PAYMENT',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Text(
            'Use any UPI app to scan and pay instantly',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 15),

          pw.Container(
            width: 150,
            height: 150,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue400, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Image(
              pw.MemoryImage(qrCodeImage.readAsBytesSync()),
              fit: pw.BoxFit.cover,
            ),
          ),
          pw.SizedBox(height: 12),

          pw.Text(
            'Fast • Secure • Convenient',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey500,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.SizedBox(height: 6),

          pw.Text(
            'Payment confirmation will be sent automatically',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static Future<void> savePdfToDevice(pw.Document pdf, Invoice invoice) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/invoice_${invoice.invoiceNumber}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      // Handle error silently
    }
  }
}