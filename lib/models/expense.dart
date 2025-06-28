class Expense {
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String? imagePath;

  Expense({
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.imagePath,
  });
} 