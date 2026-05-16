import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/session_model.dart';
import '../../features/analytics/analytics_provider.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<void> generate({
    required List<WorkoutSessionModel> sessions,
    required List<LiftData> liftData,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'FitTrack — Progress Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 24),
          pw.Header(level: 1, child: pw.Text('Top Lifts')),
          pw.TableHelper.fromTextArray(
            headers: ['Exercise', 'Max Weight (kg)', 'Trend'],
            data: liftData.map((d) {
              final trend = d.trend > 0 ? '+${d.trend.toStringAsFixed(1)} kg' : d.trend < 0 ? '${d.trend.toStringAsFixed(1)} kg' : 'Same';
              return [d.exerciseName, d.currentMax > 0 ? '${d.currentMax.toStringAsFixed(1)}' : 'N/A', trend];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(8),
          ),
          pw.SizedBox(height: 24),
          pw.Header(level: 1, child: pw.Text('Recent Sessions (Last 30 Days)')),
          ...sessions.take(30).map((session) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${session.dayName} — ${DateFormat('MMM d, yyyy').format(session.startTime)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                  ),
                  pw.Text('Duration: ${session.durationMinutes} minutes'),
                  ...session.exercises.map((ex) {
                    final setsStr = ex.sets.map((s) => '${s.weight}kg×${s.reps}').join(', ');
                    return pw.Text('  • ${ex.exerciseName}: $setsStr', style: const pw.TextStyle(fontSize: 11));
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'fittrack_progress_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
    );
  }
}
