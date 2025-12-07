import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

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

class LoanCalculatorApp extends StatelessWidget {
  const LoanCalculatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loan Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF001F54),
      ),
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF001F54), Color(0xFF003087)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calculate, size: 100, color: Colors.white),
                const SizedBox(height: 30),
                const Text(
                  'កម្មវិធីគណនាប្រាក់កម្ចី',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Loan Calculator',
                  style: TextStyle(fontSize: 24, color: Colors.white70),
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoanCalculatorPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF001F54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'ចាប់ផ្តើម / Start',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoanCalculatorPage extends StatefulWidget {
  const LoanCalculatorPage({Key? key}) : super(key: key);

  @override
  State<LoanCalculatorPage> createState() => _LoanCalculatorPageState();
}

class _LoanCalculatorPageState extends State<LoanCalculatorPage> {
  final TextEditingController principalController = TextEditingController();
  final TextEditingController interestController = TextEditingController();
  final TextEditingController monthsController = TextEditingController();

  List<LoanPayment> loanSchedule = [];
  bool hasCalculated = false;

  void calculateLoan() {
    final double principal = double.tryParse(principalController.text) ?? 0;
    final double monthlyInterestRate =
        (double.tryParse(interestController.text) ?? 0) / 100;
    final int months = int.tryParse(monthsController.text) ?? 0;

    if (principal <= 0 || monthlyInterestRate <= 0 || months <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('សូមបំពេញព័ត៌មានឱ្យបានត្រឹមត្រូវ')),
      );
      return;
    }

    List<LoanPayment> schedule = [];
    double remainingBalance = principal;

    for (int i = 1; i <= months; i++) {
      double interestPayment = remainingBalance * monthlyInterestRate;
      double principalPayment = principal / months;
      double totalPayment = principalPayment + interestPayment;
      remainingBalance -= principalPayment;

      schedule.add(
        LoanPayment(
          month: i,
          totalPayment: totalPayment,
          interestPayment: interestPayment,
          principalPayment: principalPayment,
          remainingBalance: remainingBalance > 0 ? remainingBalance : 0,
        ),
      );
    }

    setState(() {
      loanSchedule = schedule;
      hasCalculated = true;
    });
  }

  Future<void> exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'SAMDECH PREAH MAHSANGHARAJA BOUR KRY UNIVERSITY',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'LOAN SCHEDULE',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),
            pw.Table.fromTextArray(
              headers: [
                'ខែទី',
                'ប្រាក់ដើម',
                'អត្រាការប្រាក់',
                'ប្រាក់ត្រូវបង់',
                'ប្រាក់នៅសល់',
              ],
              data: loanSchedule.map((payment) {
                return [
                  payment.month.toString(),
                  payment.principalPayment.toStringAsFixed(2),
                  payment.interestPayment.toStringAsFixed(2),
                  payment.totalPayment.toStringAsFixed(2),
                  payment.remainingBalance.toStringAsFixed(2),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.center,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Loan Schedule'];

    // Add headers
    sheetObject.appendRow([
      'ខែទី',
      'ប្រាក់ដើម',
      'អត្រាការប្រាក់',
      'ប្រាក់ត្រូវបង់',
      'ប្រាក់នៅសល់',
    ]);

    // Add data
    for (var payment in loanSchedule) {
      sheetObject.appendRow([
        payment.month,
        payment.principalPayment,
        payment.interestPayment,
        payment.totalPayment,
        payment.remainingBalance,
      ]);
    }

    // Save file
    var fileBytes = excel.save();
    if (fileBytes != null) {
      await FileSaver.instance.saveFile(
        name: 'loan_schedule',
        bytes: Uint8List.fromList(fileBytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel file exported successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('កម្មវិធីគណនាប្រាក់កម្ចី'),
        backgroundColor: const Color(0xFF001F54),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF001F54), Color(0xFF003087)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: principalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ចំនួនប្រាក់កម្ចីសរុប',
                          hintText: '50000',
                          prefixIcon: Icon(Icons.money),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: interestController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'អត្រាការប្រាក់ប្រចាំខែ(%)',
                          hintText: '8',
                          prefixIcon: Icon(Icons.percent),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: monthsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'រយៈពេលបង់ប្រាក់(ខែ)',
                          hintText: '24',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: calculateLoan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001F54),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'គណនា',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasCalculated) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: exportToPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Export PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: exportToExcel,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Export Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 5,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ខែទី')),
                        DataColumn(label: Text('ប្រាក់ដើម')),
                        DataColumn(label: Text('អត្រាការប្រាក់')),
                        DataColumn(label: Text('ប្រាក់ត្រូវបង់')),
                        DataColumn(label: Text('ប្រាក់នៅសល់')),
                      ],
                      rows: loanSchedule.map((payment) {
                        return DataRow(
                          cells: [
                            DataCell(Text(payment.month.toString())),
                            DataCell(
                              Text(payment.principalPayment.toStringAsFixed(2)),
                            ),
                            DataCell(
                              Text(payment.interestPayment.toStringAsFixed(2)),
                            ),
                            DataCell(
                              Text(payment.totalPayment.toStringAsFixed(2)),
                            ),
                            DataCell(
                              Text(payment.remainingBalance.toStringAsFixed(2)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LoanPayment {
  final int month;
  final double totalPayment;
  final double interestPayment;
  final double principalPayment;
  final double remainingBalance;

  LoanPayment({
    required this.month,
    required this.totalPayment,
    required this.interestPayment,
    required this.principalPayment,
    required this.remainingBalance,
  });
}
