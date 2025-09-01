import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/util/helpers.dart';


Future<void> captureAndShareAsPdfWidget(GlobalKey widgetKey, String fileName) async {
  try {
    // Get the render object
    final RenderRepaintBoundary boundary =
    widgetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;


    // Capture the widget with appropriate pixel ratio
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Create a PDF with page size matching the widget's aspect ratio
    final pdf = pw.Document();

    // Convert the image for PDF use
    final pdfImage = pw.MemoryImage(pngBytes);

    // Use a standard page format but adjust the image
    // Default A4 page size is 8.27 x 11.69 inches (595.28 x 841.89 points)
    const double pdfPageHeight = 5500;
    const double pdfPageWidth = 595.28;

    // Create a page with proper dimensions
    pdf.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(pdfPageWidth, pdfPageHeight),
        build: (pw.Context context) {
          return [
            pw.Container(
              alignment: pw.Alignment.center,
              width: pdfPageWidth,
              padding: const pw.EdgeInsets.all(20),
              child: pw.Image(
                pdfImage,
                width: pdfPageWidth - 40,
              ),
            ),
          ];
        },
      )
    );

    // Save and share the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'My PinkRain Wellness Report: $fileName.PDF',
        subject: 'PinkRain Wellness Report'
    ));
  } catch (e) {
    devPrint('Error during capture and share: $e');
  }
}