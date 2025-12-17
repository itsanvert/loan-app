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
