import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';

class ParserService {
  static Future<String> extractText(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    
    if (extension == 'pdf') {
      return _extractFromPdf(file);
    } else if (extension == 'docx') {
      return _extractFromDocx(file);
    } else {
      throw Exception('Unsupported file format: $extension');
    }
  }

  static bool isLikelyResume(String text) {
    if (text.length < 100) return false; // Too short for a resume
    
    final lowerText = text.toLowerCase();
    final keywords = [
      'experience', 'education', 'skills', 'projects', 'summary', 
      'contact', 'employment', 'certificates', 'work', 'university',
      'college', 'email', 'phone', 'objective'
    ];
    
    int matchCount = 0;
    for (var keyword in keywords) {
      if (lowerText.contains(keyword)) matchCount++;
    }
    
    // Require at least 3 keyword matches to be considered a resume
    return matchCount >= 3;
  }

  static Future<String> _extractFromPdf(File file) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: await file.readAsBytes());
      if (document.pages.count == 0) {
        document.dispose();
        throw Exception('The PDF is empty');
      }
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      if (e.toString().contains("password")) {
        throw Exception('This PDF is password protected');
      }
      throw Exception('Could not read PDF: $e');
    }
  }

  static Future<String> _extractFromDocx(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return docxToText(bytes);
    } catch (e) {
      throw Exception('Error extracting text from DOCX: $e');
    }
  }
}
