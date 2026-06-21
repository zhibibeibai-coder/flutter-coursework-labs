class Question {
  const Question({required this.title, required this.answer});

  final String title;
  final bool answer;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      title: json['title'] as String,
      answer: json['answer'] as bool,
    );
  }
}
