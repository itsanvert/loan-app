import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loanapp/model/loan_calculate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

    // Load logo from asset
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/image.png')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            // Centered Logo
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Image(logoImage, height: 60),
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Loan Amount: \$${double.tryParse(principalController.text)?.toStringAsFixed(2) ?? "0.00"}',
                  ),
                  pw.Text('Interest Rate: ${interestController.text}% / month'),
                  pw.Text('Term: ${monthsController.text} months'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              headers: [
                'Month',
                'Principal (\$)',
                'Interest (\$)',
                'Payment (\$)',
                'Balance (\$)',
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
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.center,
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
            ),

            pw.SizedBox(height: 20),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey, width: 1),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Paid: \$${loanSchedule.fold(0.0, (sum, p) => sum + p.totalPayment).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Text(
                    'Total Interest: \$${loanSchedule.fold(0.0, (sum, p) => sum + p.interestPayment).toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
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
    Sheet sheet = excel['Loan Schedule'];

    final headers = [
      'Month',
      'Principal (\$)',
      'Interest (\$)',
      'Payment (\$)',
      'Balance (\$)',
    ];

    // Add header row
    sheet.appendRow(headers);

    // Add data rows (formatted to 2 decimal places)
    for (var payment in loanSchedule) {
      sheet.appendRow([
        payment.month,
        payment.principalPayment.toStringAsFixed(2),
        payment.interestPayment.toStringAsFixed(2),
        payment.totalPayment.toStringAsFixed(2),
        payment.remainingBalance.toStringAsFixed(2),
      ]);
    }

    // Save file
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await FileSaver.instance.saveFile(
        name: 'Loan_Schedule',
        bytes: Uint8List.fromList(fileBytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel file exported successfully!')),
        );
      }
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
