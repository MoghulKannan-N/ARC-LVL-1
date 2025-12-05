  class Quiz {
    final String id;
    final String title;
    final String description;
    final int duration; // in minutes
    final List<Question> questions;

    Quiz({
      required this.id,
      required this.title,
      required this.description,
      required this.duration,
      required this.questions,
    });
  }

  class Question {
    final String questionText;
    final List<String> options;
    final int correctAnswerIndex;

    Question({
      required this.questionText,
      required this.options,
      required this.correctAnswerIndex,
    });
  }