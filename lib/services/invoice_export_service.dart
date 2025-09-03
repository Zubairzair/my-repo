import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as xl;
import 'package:screenshot/screenshot.dart';

class InvoiceExportService {
  static final ScreenshotController _screenshotController = ScreenshotController();

  // Show export options dialog
  static Future<void> showExportDialog(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Share Invoice',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose format to share:'),
              const SizedBox(height: 16),
              _buildExportOption(
                context,
                icon: Icons.picture_as_pdf,
                title: 'PDF Format',
                subtitle: 'Professional document format',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _exportToPDF(context, invoiceData, customerData, items, pricing);
                },
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.table_chart,
                title: 'Excel Format',
                subtitle: 'Spreadsheet format',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _exportToExcel(context, invoiceData, customerData, items, pricing);
                },
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.image,
                title: 'Image Format',
                subtitle: 'Screenshot format',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _exportToImage(context, invoiceData, customerData, items, pricing);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // Export as PDF
  static Future<void> _exportToPDF(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating PDF...'),
            ],
          ),
        ),
      );

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Al Badar Traders Header
                pw.Center(
                  child: pw.Text(
                    'Al Badar Traders',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Shop and Invoice Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Shop: ${customerData['name'] ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Address: ${customerData['address'] ?? 'N/A'}'),
                        if (customerData['phone'] != null) pw.Text('Phone: ${customerData['phone']}'),
                        if (customerData['email'] != null) pw.Text('Email: ${customerData['email']}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date: ${invoiceData['date'] ?? DateTime.now().toString().substring(0, 10)}'),
                        pw.Text('Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                
                // Items Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2), // Barcode
                    1: const pw.FlexColumnWidth(1), // Serial Number
                    2: const pw.FlexColumnWidth(2), // SKU
                    3: const pw.FlexColumnWidth(1), // Quantity
                    4: const pw.FlexColumnWidth(1), // Unit
                    5: const pw.FlexColumnWidth(2), // TP
                    6: const pw.FlexColumnWidth(2), // Total
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Barcode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('S#', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('SKU', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('TP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Table Rows
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final tp = (item['tp'] ?? 0.0) as double;
                      final quantity = (item['quantity'] ?? 1) as int;
                      final total = tp * quantity;
                      
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item['barcode']?.toString() ?? 'N/A'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${index + 1}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item['sku']?.toString() ?? ''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('$quantity'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item['unit']?.toString() ?? 'Pcs'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Rs ${tp.toStringAsFixed(2)}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Rs ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 30),
                
                // Pricing Summary
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rs ${(pricing['subtotal'] as double).toStringAsFixed(2)}'),
                          ],
                        ),
                        if ((pricing['discount'] as double) > 0) ...[
                          pw.SizedBox(height: 8),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount:'),
                              pw.Text('-Rs ${(pricing['discount'] as double).toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        if ((pricing['extraDiscount'] as double) > 0) ...[
                          pw.SizedBox(height: 8),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Extra Discount:'),
                              pw.Text('-Rs ${(pricing['extraDiscount'] as double).toStringAsFixed(2)}'),
                            ],
                          ),
                        ],
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Final Total:', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rs ${(pricing['total'] as double).toStringAsFixed(2)}', 
                                   style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to temporary directory
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      Navigator.pop(context);

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice PDF');

    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Export as Excel
  static Future<void> _exportToExcel(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating Excel...'),
            ],
          ),
        ),
      );

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Invoice'];
      
      // Al Badar Traders Header
      sheetObject.cell(CellIndex.indexByString("A1")).value = const TextCellValue('Al Badar Traders');
      sheetObject.cell(CellIndex.indexByString("A1")).cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );
      sheetObject.merge(CellIndex.indexByString("A1"), CellIndex.indexByString("G1"));
      
      // Shop and Invoice Details
      sheetObject.cell(CellIndex.indexByString("A3")).value = TextCellValue('Shop: ${customerData['name'] ?? 'N/A'}');
      sheetObject.cell(CellIndex.indexByString("A4")).value = TextCellValue('Address: ${customerData['address'] ?? 'N/A'}');
      if (customerData['phone'] != null) {
        sheetObject.cell(CellIndex.indexByString("A5")).value = TextCellValue('Phone: ${customerData['phone']}');
      }
      if (customerData['email'] != null) {
        sheetObject.cell(CellIndex.indexByString("A6")).value = TextCellValue('Email: ${customerData['email']}');
      }
      
      sheetObject.cell(CellIndex.indexByString("E3")).value = TextCellValue('Date: ${invoiceData['date'] ?? DateTime.now().toString().substring(0, 10)}');
      sheetObject.cell(CellIndex.indexByString("E4")).value = TextCellValue('Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}');
      
      // Table Headers (starting from row 8)
      int headerRow = 8;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: headerRow)).value = const TextCellValue('Barcode');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: headerRow)).value = const TextCellValue('S#');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: headerRow)).value = const TextCellValue('SKU');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: headerRow)).value = const TextCellValue('Quantity');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: headerRow)).value = const TextCellValue('Unit');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: headerRow)).value = const TextCellValue('TP');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: headerRow)).value = const TextCellValue('Total');
      
      // Style headers
      for (int col = 0; col <= 6; col++) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRow)).cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.grey25,
        );
      }
      
      // Add items data
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final rowIndex = headerRow + 1 + i;
        final tp = (item['tp'] ?? 0.0) as double;
        final quantity = (item['quantity'] ?? 1) as int;
        final total = tp * quantity;
        
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(item['barcode']?.toString() ?? 'N/A');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = IntCellValue(i + 1);
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(item['sku']?.toString() ?? '');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = IntCellValue(quantity);
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(item['unit']?.toString() ?? 'Pcs');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = DoubleCellValue(tp);
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = DoubleCellValue(total);
      }
      
      // Pricing Summary (starting after items)
      int summaryStartRow = headerRow + items.length + 3;
      
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryStartRow)).value = const TextCellValue('Subtotal:');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryStartRow)).value = DoubleCellValue(pricing['subtotal'] as double);
      
      if ((pricing['discount'] as double) > 0) {
        summaryStartRow++;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryStartRow)).value = const TextCellValue('Discount:');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryStartRow)).value = DoubleCellValue(-(pricing['discount'] as double));
      }
      
      if ((pricing['extraDiscount'] as double) > 0) {
        summaryStartRow++;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryStartRow)).value = const TextCellValue('Extra Discount:');
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryStartRow)).value = DoubleCellValue(-(pricing['extraDiscount'] as double));
      }
      
      summaryStartRow++;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryStartRow)).value = const TextCellValue('Final Total:');
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryStartRow)).value = DoubleCellValue(pricing['total'] as double);
      
      // Style final total
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: summaryStartRow)).cellStyle = CellStyle(bold: true);
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: summaryStartRow)).cellStyle = CellStyle(bold: true);

      // Save Excel file
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(excel.save()!);

      // Close loading dialog
      Navigator.pop(context);

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice Excel');

    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating Excel: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Export as Image (Screenshot)
  static Future<void> _exportToImage(
    BuildContext context,
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating Image...'),
            ],
          ),
        ),
      );

      // Create invoice widget for screenshot
      final invoiceWidget = RepaintBoundary(
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(32),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Al Badar Traders Header
              Center(
                child: Text(
                  'Al Badar Traders',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Shop and Invoice Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shop: ${customerData['name'] ?? 'N/A'}', 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Address: ${customerData['address'] ?? 'N/A'}', 
                           style: const TextStyle(fontSize: 14)),
                      if (customerData['phone'] != null)
                        Text('Phone: ${customerData['phone']}', 
                             style: const TextStyle(fontSize: 14)),
                      if (customerData['email'] != null)
                        Text('Email: ${customerData['email']}', 
                             style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Date: ${invoiceData['date'] ?? DateTime.now().toString().substring(0, 10)}', 
                           style: const TextStyle(fontSize: 14)),
                      Text('Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}', 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Items Table
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 1, child: Text('S#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 1, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('TP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ),
                    // Table Rows
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final tp = (item['tp'] ?? 0.0) as double;
                      final quantity = (item['quantity'] ?? 1) as int;
                      final total = tp * quantity;
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(item['barcode']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 1, child: Text('${index + 1}', style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 2, child: Text(item['sku']?.toString() ?? '', style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 1, child: Text('$quantity', style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 1, child: Text(item['unit']?.toString() ?? 'Pcs', style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 2, child: Text('Rs ${tp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 2, child: Text('Rs ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Pricing Summary
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('Rs ${(pricing['subtotal'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      if ((pricing['discount'] as double) > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount:', style: TextStyle(color: Colors.red, fontSize: 14)),
                            Text('-Rs ${(pricing['discount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontSize: 14)),
                          ],
                        ),
                      ],
                      if ((pricing['extraDiscount'] as double) > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Extra Discount:', style: TextStyle(color: Colors.red, fontSize: 14)),
                            Text('-Rs ${(pricing['extraDiscount'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontSize: 14)),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Final Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Rs ${(pricing['total'] as double).toStringAsFixed(2)}', 
                               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Create screenshot controller
      ScreenshotController screenshotController = ScreenshotController();
      
      // Capture screenshot
      final imageBytes = await screenshotController.captureFromWidget(
        invoiceWidget,
        pixelRatio: 2.0,
      );

      // Save image to temporary directory
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${invoiceData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      // Close loading dialog
      Navigator.pop(context);

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice Image');

    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Widget _buildInvoiceWidget(
    Map<String, dynamic> invoiceData,
    Map<String, dynamic> customerData,
    List<Map<String, dynamic>> items,
    Map<String, dynamic> pricing,
  ) {
    return Container(
      width: 600,
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Al Badar Traders
          const Center(
            child: Text(
              'Al Badar Traders',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Shop Information
          if (customerData['shopName'] != null) ...[
            Center(
              child: Text(
                'Shop: ${customerData['shopName']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
          if (customerData['shopAddress'] != null) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Address: ${customerData['shopAddress']}',
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          // Date and Invoice Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date: ${invoiceData['date'] ?? DateTime.now().toString().substring(0, 10)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
              ),
              Text(
                'Invoice #: ${invoiceData['invoiceNumber'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Items Table with new structure
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  color: Colors.grey.shade200,
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 1, child: Text('S#', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 2, child: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 1, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 2, child: Text('TP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                      Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                    ],
                  ),
                ),
                // Items
                ...items.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('${item['barcode'] ?? 'N/A'}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 1, child: Text('${index + 1}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 2, child: Text('${item['sku'] ?? 'N/A'}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 1, child: Text('${item['quantity'] ?? 0}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 1, child: Text('${item['unit'] ?? 'Pcs'}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 2, child: Text('Rs ${((item['price'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black))),
                        Expanded(flex: 2, child: Text('Rs ${(((item['quantity'] ?? 1) as int) * ((item['price'] ?? 0.0) as double)).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black))),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Pricing Summary
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:', style: TextStyle(color: Colors.black)),
                      Text('Rs ${((pricing['subtotal'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                  if ((pricing['discount'] ?? 0.0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:', style: TextStyle(color: Colors.black)),
                        Text('-Rs ${((pricing['discount'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ],
                  if ((pricing['extraDiscount'] ?? 0.0) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Extra Discount:', style: TextStyle(color: Colors.black)),
                        Text('-Rs ${((pricing['extraDiscount'] ?? 0.0) as double).toStringAsFixed(2)}', style: const TextStyle(color: Colors.purple)),
                      ],
                    ),
                  ],
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Final Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      Text('Rs ${((pricing['total'] ?? 0.0) as double).toStringAsFixed(2)}', 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
