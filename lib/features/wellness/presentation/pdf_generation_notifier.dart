import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../services/pdf_service.dart';

final pdfGenerationProvider = StateNotifierProvider<PdfGenerationNotifier, AsyncValue<void>>((ref) {
  return PdfGenerationNotifier();
});

class PdfGenerationNotifier extends StateNotifier<AsyncValue<void>> {
  PdfGenerationNotifier() : super(const AsyncValue.data(null));

  Future<void> generateAndShare(DateTime date, String timeRange) async {
    state = const AsyncValue.loading();
    
    try {
      // Generate the PDF
      final pdfFile = await PdfService.generateWellnessReport(date, timeRange);
      
      // Share the file
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(pdfFile.path)],
          subject: 'Wellness Report',
          text: 'Here\'s my wellness report from PinkRain',
        ),
      );
      
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
