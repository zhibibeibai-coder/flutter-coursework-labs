import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'question.dart';

void main() {
  runApp(const MiniQuizApp());
}

class MiniQuizApp extends StatelessWidget {
  const MiniQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiniQuiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const QuizPage(),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final Set<int> _answeredIndexes = <int>{};
  final Set<int> _hintedIndexes = <int>{};
  final Map<int, bool> _answerResults = <int, bool>{};
  final List<Question> _questions = <Question>[];
  int _currentIndex = 0;
  bool _loading = true;
  String? _error;

  int get _correctCount => _answerResults.values.where((bool ok) => ok).length;

  int get _countedAnswerCount => _answerResults.length;

  Question? get _currentQuestion {
    if (_questions.isEmpty) {
      return null;
    }
    return _questions[_currentIndex];
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final String jsonText = await rootBundle.loadString(
        'assets/json/questions.json',
      );
      final List<dynamic> list = json.decode(jsonText) as List<dynamic>;
      setState(() {
        _questions
          ..clear()
          ..addAll(
            list.map(
              (dynamic item) => Question.fromJson(item as Map<String, dynamic>),
            ),
          );
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = '题库加载失败：$error';
        _loading = false;
      });
    }
  }

  Future<void> _openHint() async {
    final Question? question = _currentQuestion;
    if (question == null) {
      return;
    }
    final bool usedHint =
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (BuildContext context) => HintPage(question: question),
          ),
        ) ??
        false;

    if (usedHint) {
      setState(() {
        _hintedIndexes.add(_currentIndex);
      });
      if (_isFinished()) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showResultPage());
      }
    }
  }

  void _answerQuestion(bool answer) {
    final Question? question = _currentQuestion;
    if (question == null ||
        _answeredIndexes.contains(_currentIndex) ||
        _hintedIndexes.contains(_currentIndex)) {
      return;
    }

    setState(() {
      _answeredIndexes.add(_currentIndex);
      _answerResults[_currentIndex] = question.answer == answer;
    });

    if (_isFinished()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResultPage());
    }
  }

  bool _isFinished() {
    if (_questions.isEmpty) {
      return false;
    }
    for (int i = 0; i < _questions.length; i += 1) {
      if (!_answeredIndexes.contains(i) && !_hintedIndexes.contains(i)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _showResultPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ResultPage(
          total: _questions.length,
          counted: _countedAnswerCount,
          correct: _correctCount,
          hinted: _hintedIndexes.length,
        ),
      ),
    );
  }

  void _moveQuestion(int offset) {
    if (_questions.isEmpty) {
      return;
    }
    setState(() {
      _currentIndex = (_currentIndex + offset).clamp(0, _questions.length - 1);
    });
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _answeredIndexes.clear();
      _hintedIndexes.clear();
      _answerResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Question? question = _currentQuestion;
    final bool answered = _answeredIndexes.contains(_currentIndex);
    final bool hinted = _hintedIndexes.contains(_currentIndex);
    final bool inputLocked = answered || hinted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniQuiz'),
        actions: <Widget>[
          IconButton(
            tooltip: '重新开始',
            onPressed: _restart,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildBody(question, answered, hinted, inputLocked),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    Question? question,
    bool answered,
    bool hinted,
    bool inputLocked,
  ) {
    if (_loading) {
      return const CircularProgressIndicator();
    }
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.red));
    }
    if (question == null) {
      return const Text('题库为空');
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '第 ${_currentIndex + 1} / ${_questions.length} 题',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        Text(
          question.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton(
              onPressed: inputLocked ? null : () => _answerQuestion(true),
              child: const Text('True'),
            ),
            const SizedBox(width: 16),
            FilledButton.tonal(
              onPressed: inputLocked ? null : () => _answerQuestion(false),
              child: const Text('False'),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: inputLocked ? null : _openHint,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('提示'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          hinted
              ? '本题已查看提示，不计入正确率。'
              : answered
              ? (_answerResults[_currentIndex] == true ? '回答正确。' : '回答错误。')
              : '请选择 True 或 False，也可以先查看提示。',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: _currentIndex == 0 ? null : () => _moveQuestion(-1),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Prev'),
            ),
            Text(
              '正确 $_correctCount / 已答 $_countedAnswerCount / 提示 ${_hintedIndexes.length}',
              textAlign: TextAlign.center,
            ),
            OutlinedButton.icon(
              onPressed: _currentIndex == _questions.length - 1
                  ? null
                  : () => _moveQuestion(1),
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}

class HintPage extends StatefulWidget {
  const HintPage({super.key, required this.question});

  final Question question;

  @override
  State<HintPage> createState() => _HintPageState();
}

class _HintPageState extends State<HintPage> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('题目提示'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(_showAnswer),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  widget.question.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                if (_showAnswer)
                  Text(
                    widget.question.answer ? '答案提示：True' : '答案提示：False',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAnswer = true;
                    });
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Show Answer'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_showAnswer),
                  child: const Text('返回答题页'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  const ResultPage({
    super.key,
    required this.total,
    required this.counted,
    required this.correct,
    required this.hinted,
  });

  final int total;
  final int counted;
  final int correct;
  final int hinted;

  @override
  Widget build(BuildContext context) {
    final double accuracy = counted == 0 ? 0 : correct / counted * 100;
    return Scaffold(
      appBar: AppBar(title: const Text('答题结果')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.emoji_events_outlined, size: 72),
                const SizedBox(height: 20),
                Text(
                  '完成 $total 道题',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text('计分题目：$counted 题'),
                Text('正确题目：$correct 题'),
                Text('使用提示：$hinted 次'),
                Text('正确率：${accuracy.toStringAsFixed(1)}%'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('查看答题记录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
