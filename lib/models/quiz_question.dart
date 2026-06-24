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

  factory QuizSet.fromJson(dynamic json) {
    if (json is List) {
      return QuizSet(
        questions: json
            .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }

    final map = json as Map<String, dynamic>;
    if (map['questions'] is List) {
      return QuizSet(
        questions: (map['questions'] as List)
            .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    }

    return QuizSet(questions: [QuizQuestion.fromJson(map)]);
  }
}
