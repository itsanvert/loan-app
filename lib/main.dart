import 'package:flutter/material.dart';
import 'package:loanapp/screen/loan_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';

// Note: Make sure to add these dependencies in pubspec.yaml:
// dependencies:
//   flutter:
//     sdk: flutter
//   pdf: ^3.10.4
//   printing: ^5.11.0
//   excel: ^4.0.2
//   file_saver: ^0.2.8

void main() {
  runApp(const LoanCalculatorApp());
}

