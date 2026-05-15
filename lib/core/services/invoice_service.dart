import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'repository.dart';

class InvoiceService {
  InvoiceService(this.repo);
  final Repository repo;

  double _d(dynamic v) => repo.numToDouble(v);

  Future<pw.Document> _buildDocument({
    required String title,
    required Map<String, dynamic> header,
    required List<Map<String, dynamic>> items,
  }) async {
    final business = await repo.business() ?? {'name': 'Invygen', 'currency': 'USD'};
    final currency = business['currency']?.toString() ?? 'USD';
    final doc = pw.Document();
    final dateText = header['sale_date']?.toString() ?? header['order_date']?.toString() ?? DateTime.now().toIso8601String();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(business['name']?.toString() ?? 'Invygen', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                if ((business['address'] ?? '').toString().isNotEmpty) pw.Text(business['address'].toString()),
                if ((business['phone'] ?? '').toString().isNotEmpty) pw.Text('Phone: ${business['phone']}'),
                if ((business['email'] ?? '').toString().isNotEmpty) pw.Text('Email: ${business['email']}'),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('No: ${header['invoice_no'] ?? header['order_no'] ?? header['purchase_no'] ?? header['id']}'),
                pw.Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(dateText) ?? DateTime.now())),
              ]),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Customer: ${header['customer_name'] ?? 'Walk-in Customer'}'),
              pw.Text('Status: ${header['status'] ?? ''}'),
            ]),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headers: const ['Item', 'Qty', 'Rate', 'Amount'],
            data: items.map((i) => [
              i['product_name']?.toString() ?? '',
              _d(i['quantity']).toStringAsFixed(2),
              '$currency ${_d(i['price']).toStringAsFixed(2)}',
              '$currency ${_d(i['total']).toStringAsFixed(2)}',
            ]).toList(),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 240,
              child: pw.Column(children: [
                _totalRow('Subtotal', _d(header['subtotal']), currency),
                _totalRow('Discount', _d(header['discount']), currency),
                pw.Divider(),
                _totalRow('Total', _d(header['total']), currency, bold: true),
                _totalRow('Received', _d(header['received']), currency),
                _totalRow('Pending', _d(header['pending']), currency, bold: true),
              ]),
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.Text((business['receipt_footer'] ?? 'Thank you for your business.').toString(), textAlign: pw.TextAlign.center),
          pw.Text('Powered by UMERON Technologies - Invygen', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
    return doc;
  }

  pw.Widget _totalRow(String label, double amount, String currency, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
        pw.Text('$currency ${amount.toStringAsFixed(2)}', style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
      ]),
    );
  }

  Future<void> printSale(int saleId) async {
    final sale = await repo.find('sales', saleId);
    if (sale == null) return;
    final items = await repo.saleItems(saleId);
    final doc = await _buildDocument(title: 'Invoice / Receipt', header: sale, items: items);
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<void> shareSale(int saleId) async {
    final sale = await repo.find('sales', saleId);
    if (sale == null) return;
    final items = await repo.saleItems(saleId);
    final doc = await _buildDocument(title: 'Invoice / Receipt', header: sale, items: items);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${sale['invoice_no']}.pdf');
    await file.writeAsBytes(await doc.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Invoice ${sale['invoice_no']}');
  }

  Future<void> printOrder(int orderId) async {
    final order = await repo.find('orders', orderId);
    if (order == null) return;
    final items = await repo.orderItems(orderId);
    final doc = await _buildDocument(title: 'Order', header: order, items: items);
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<void> shareOrder(int orderId) async {
    final order = await repo.find('orders', orderId);
    if (order == null) return;
    final items = await repo.orderItems(orderId);
    final doc = await _buildDocument(title: 'Order', header: order, items: items);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${order['order_no']}.pdf');
    await file.writeAsBytes(await doc.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Order ${order['order_no']}');
  }
}
