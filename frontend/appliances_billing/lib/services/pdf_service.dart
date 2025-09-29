import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../config/app_config.dart';

class PdfService {
  static Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            children: [
              // Header
              _buildHeader(),
              pw.SizedBox(height: 20),
              
              // Invoice Details and Customer Info
              _buildInvoiceDetails(invoice),
              pw.SizedBox(height: 20),
              
              // Items Table
              _buildItemsTable(invoice),
              pw.SizedBox(height: 20),
              
              // Tax Summary
              _buildTaxSummary(invoice),
              pw.SizedBox(height: 30),
              
              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: const pw.BoxDecoration(
              color: PdfColors.black,
            ),
            child: pw.Center(
              child: pw.Text(
                'TAX INVOICE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              children: [
                pw.Text(
                  AppConfig.companyName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  AppConfig.companyAddress,
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'GSTIN No. : ${AppConfig.companyGstin}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Mobile No: ${AppConfig.companyPhone}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceDetails(Invoice invoice) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bill to',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(invoice.customer.name),
                  pw.Text(invoice.customer.address),
                  if (invoice.customer.gstin.isNotEmpty)
                    pw.Text('GSTIN No. : ${invoice.customer.gstin}'),
                ],
              ),
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Place of Supply',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('TAMILNADU'),
                ],
              ),
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Invoice No',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(invoice.invoiceNumber),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Dated',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(invoice.formattedDate),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Description of Services', 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('HSN CODE/SAC CODE', 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Amount', 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        // Items
        ...invoice.items.map((item) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item.description),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item.hsnCode),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('${(item.quantity * item.price).toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right),
              ),
            ],
          );
        }).toList(),
        // Total row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('Total', 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(''),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(invoice.subtotal.toStringAsFixed(2),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTaxSummary(Invoice invoice) {
    final cgst = invoice.totalGST / 2;
    final sgst = invoice.totalGST / 2;
    
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(
        children: [
          _buildTaxRow('Taxable Value', invoice.subtotal),
          _buildTaxRow('ADD CGST 9%', cgst, showPercentage: '9%'),
          _buildTaxRow('ADD SGST 9%', sgst, showPercentage: '9%'),
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(width: 2)),
            ),
            child: _buildTaxRow('Total', invoice.total, isBold: true),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTaxRow(String label, double amount, {String? showPercentage, bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          if (showPercentage != null)
            pw.Text(
              showPercentage,
              style: pw.TextStyle(
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          pw.Text(
            amount.toStringAsFixed(2),
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Note: Please make cheques in favor of "${AppConfig.companyName}"',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'For ${AppConfig.companyName}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Proprietor',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> printInvoice(Invoice invoice) async {
    final pdf = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf,
    );
  }

  static Future<void> shareInvoice(Invoice invoice) async {
    final pdf = await generateInvoicePdf(invoice);
    await Printing.sharePdf(
      bytes: pdf,
      filename: 'invoice_${invoice.invoiceNumber}.pdf',
    );
  }
}