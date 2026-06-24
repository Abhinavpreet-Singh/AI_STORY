class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });

  final String question;
  final List<String> options;
  final String answer;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      answer: json['answer'] as String,
    );
  }

  bool isCorrect(String selected) => selected == answer;
}

class QuizSet {
  const QuizSet({required this.questions});

  final List<QuizQuestion> questions;

  factory QuizSet.fromJson(Map<String, dynamic> json) {
    final questions = json['questions'];
    if (questions is! List) {
      throw const FormatException(
        'Each story entry in quiz.json must contain a "questions" array',
      );
    }

    return QuizSet(
      questions: questions
          .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
