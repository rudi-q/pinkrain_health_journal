import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'core/util/helpers.dart';

class ShareableWidget extends StatefulWidget {
  const ShareableWidget({super.key});

  @override
  _ShareableWidgetState createState() => _ShareableWidgetState();
}

class _ShareableWidgetState extends State<ShareableWidget> {
  // Create a GlobalKey to identify the widget we want to capture
  final GlobalKey _widgetKey = GlobalKey();

  // Function to capture widget as image, convert to PDF and share
  Future<void> _captureAndShareAsPdf() async {
    try {
      // Step 1: Capture widget as image
      RenderRepaintBoundary boundary = _widgetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Step 2: Create PDF from image
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage),
            );
          },
        ),
      );

      // Step 3: Save PDF to temporary directory
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/widget_screenshot.pdf');
      await file.writeAsBytes(await pdf.save());

      // Step 4: Share the PDF file
      await Share.shareFiles([file.path], text: 'Check out this widget!');
    } catch (e) {
      print('Error during capture and share: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shareable Widget'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Wrap the widget you want to capture in RepaintBoundary
            RepaintBoundary(
              key: _widgetKey,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                    ),
                  ],
                ),
                // Replace this with your actual widget content
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flutter_dash, size: 64, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'My Amazing Widget',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('This is the content of my shareable widget'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 32),
            IconButton(
              icon: Icon(Icons.share),
              //label: Text('Share as PDF'),
              onPressed: _captureAndShareAsPdf,
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ShareableWidget(),
  ));
}

Future<void> captureAndShareAsPdfWidget(GlobalKey widgetKey, String fileName) async {
  try {
    // Get the render object
    final RenderRepaintBoundary boundary =
    widgetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    // Get the size of the widget
    final Size size = boundary.size;

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

    await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Pillow Wellness Report: $fileName.PDF',
        subject: 'Pillow Wellness Report'
    );
  } catch (e) {
    devPrint('Error during capture and share: $e');
  }
}