class SessionResult {
  final String date;
  final int score;
  final bool educationBelow12Years;

  const SessionResult({
    required this.date,
    required this.score,
    this.educationBelow12Years = false,
  });
}
