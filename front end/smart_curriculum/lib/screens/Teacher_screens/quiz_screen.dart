import 'package:flutter/material.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/models/Teacher_model/quiz_model.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isQuizActive = false;
  int _quizTimeRemaining = 600;
  final List<Quiz> _quizzes = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quizNameController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctAnswerIndex = 0;
  bool _showCreateForm = false;
  Quiz? _currentQuiz;

  @override
  void initState() {
    super.initState();
    _loadDummyQuizzes();
  }

  void _loadDummyQuizzes() {
    _quizzes.addAll([
      Quiz(
        id: '1',
        title: 'Python Basics Quiz',
        description: 'Test your knowledge of Python fundamentals',
        duration: 10,
        questions: [
          Question(
            questionText: 'Which keyword is used to define a function in Python?',
            options: ['def', 'function', 'define', 'func'],
            correctAnswerIndex: 0,
          ),
          Question(
            questionText: 'Which data type is immutable in Python?',
            options: ['List', 'Dictionary', 'Tuple', 'Set'],
            correctAnswerIndex: 2,
          ),
        ],
      ),
      Quiz(
        id: '2',
        title: 'Web Development Quiz',
        description: 'HTML, CSS, and JavaScript fundamentals',
        duration: 15,
        questions: [
          Question(
            questionText: 'Which tag is used for creating a hyperlink?',
            options: ['<a>', '<link>', '<href>', '<url>'],
            correctAnswerIndex: 0,
          ),
        ],
      ),
    ]);
  }

  void _addQuiz() {
    if (_formKey.currentState!.validate()) {
      final newQuiz = Quiz(
        id: '${_quizzes.length + 1}',
        title: _quizNameController.text,
        description: 'Custom created quiz',
        duration: 10,
        questions: [
          Question(
            questionText: _questionController.text,
            options: _optionControllers.map((c) => c.text).toList(),
            correctAnswerIndex: _correctAnswerIndex,
          ),
        ],
      );

      setState(() {
        _quizzes.add(newQuiz);
        _resetForm();
        _showCreateForm = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz added successfully!')),
      );
    }
  }

  void _resetForm() {
    _quizNameController.clear();
    _questionController.clear();
    for (var controller in _optionControllers) {
      controller.clear();
    }
    _correctAnswerIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quiz Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 20),

            // Quiz Timer Section (shown when quiz is active)
            if (_isQuizActive) ...[
              Card(
                color: AppColors.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '${_currentQuiz?.title} - In Progress',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Time remaining: ${_formatTime(_quizTimeRemaining)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _stopQuiz,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Stop Quiz',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Create Quiz Button (hidden when quiz is active)
            if (!_isQuizActive) ...[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showCreateForm = !_showCreateForm;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _showCreateForm ? 'Cancel Create Quiz' : 'Create New Quiz',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Create Quiz Form (only shown when _showCreateForm is true)
            if (_showCreateForm && !_isQuizActive) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Create New Quiz',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _quizNameController,
                              decoration: const InputDecoration(
                                labelText: 'Quiz Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter quiz name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _questionController,
                              decoration: const InputDecoration(
                                labelText: 'Question',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter question';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'Options:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ..._optionControllers.asMap().entries.map((entry) {
                              final index = entry.key;
                              final controller = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Radio<int>(
                                      value: index,
                                      groupValue: _correctAnswerIndex,
                                      onChanged: (value) {
                                        setState(() {
                                          _correctAnswerIndex = value!;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          labelText: 'Option ${index + 1}',
                                          border: const OutlineInputBorder(),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter option';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: _addQuiz,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: const Text(
                                'Add Quiz',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Available quizzes
            if (!_isQuizActive && !_showCreateForm) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Available Quizzes:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.quiz,
                            color: AppColors.primaryColor),
                        title: Text(quiz.title),
                        subtitle: Text(
                            '${quiz.duration} min • ${quiz.questions.length} Qs'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            _startSpecificQuiz(quiz);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                          ),
                          child: const Text(
                            'Start',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startSpecificQuiz(Quiz quiz) {
    setState(() {
      _isQuizActive = true;
      _currentQuiz = quiz;
      _quizTimeRemaining = quiz.duration * 60;
      _showCreateForm = false;
    });

    _startQuizTimer();
  }

  void _startQuizTimer() {
    if (_isQuizActive && _quizTimeRemaining > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isQuizActive && mounted) {
          setState(() {
            _quizTimeRemaining--;
          });
          _startQuizTimer();
        }
      });
    } else if (_quizTimeRemaining == 0) {
      _stopQuiz();
    }
  }

  void _stopQuiz() {
    setState(() {
      _isQuizActive = false;
      _currentQuiz = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz completed successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _quizNameController.dispose();
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
