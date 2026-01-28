import 'package:flutter/material.dart';
import 'package:loanapp/main.dart';
import 'package:loanapp/screen/welcome_screen.dart';

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
