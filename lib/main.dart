import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const QuizApp());
}

/// The root widget of the application, configuring the app's theme and routes.
class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/quiz': (context) => const QuizPage(),
        '/inquiries': (context) => const InquiriesPage(),
      },
    );
  }
}

/// The home page featuring a video tutorial and navigation to other pages.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isControllerInitialized = false;
  String _selectedDifficulty = 'Easy'; // Default difficulty

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideoController();
  }

  void _initializeVideoController() {
    _controller = VideoPlayerController.asset('assets/videos/game_explanation.mp4.mp4')
      ..initialize().then((_) {
        print('Video initialized successfully');
        setState(() {
          _isControllerInitialized = true;
        });
      }).catchError((error) {
        print('Video initialization error: $error');
        setState(() {
          _isControllerInitialized = false;
        });
      });

    _controller.addListener(() {
      if (_controller.value.isPlaying != _isPlaying) {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      if (_controller.value.isPlaying) {
        _controller.pause();
        setState(() {
          _isPlaying = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isControllerInitialized) {
        _initializeVideoController();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _showVideoDialog() {
    if (!_isControllerInitialized || !_controller.value.isInitialized) {
      print('Video not initialized');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فيديو الشرح غير متاح حالياً')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('شرح اللعبة', textAlign: TextAlign.center),
          content: SizedBox(
            width: 300,
            height: 250,
            child: _controller.value.isInitialized
                ? Column(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.teal,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_isPlaying) {
                                  _controller.pause();
                                } else {
                                  _controller.play();
                                }
                                _isPlaying = !_isPlaying;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _controller.pause();
                setState(() {
                  _isPlaying = false;
                });
                Navigator.of(context).pop();
              },
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    ).then((_) {
      _controller.seekTo(Duration.zero);
      _controller.pause();
      setState(() {
        _isPlaying = false;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.value.isInitialized && !_controller.value.isPlaying) {
        _controller.play().then((_) {
          print('Video is playing');
          setState(() {
            _isPlaying = true;
          });
        }).catchError((error) {
          print('Error playing video: $error');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              height: 30,
              width: 30,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                return const Icon(Icons.error);
              },
            ),
            const SizedBox(width: 10),
            const Text('التطبيق'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'تعريف اللعبة',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'هذه اللعبة هي اختبار تفاعلي يحتوي على مجموعة من الأسئلة المتنوعة. اختر مستوى الصعوبة وابدأ!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: _selectedDifficulty,
                  items: <String>['Easy', 'Medium', 'Hard']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDifficulty = newValue!;
                    });
                  },
                  dropdownColor: Colors.teal,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/quiz', arguments: _selectedDifficulty);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    'إبدأ',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/inquiries');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    'الاستفسارات',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showVideoDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    'شرح اللعبة',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The quiz page with interactive questions and scoring.
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final Map<String, List<List<String>>> _questionSets = {
    'Easy': [
      ["ما هو المقصود بالتنمية المستدامة؟", "استخدام الموارد بشكل غير محدود", "تلبية احتياجات الحاضر دون المساس بقدرة الأجيال القادمة", "التوسع الصناعي السريع"],
      ["ما هي الطاقة المتجددة؟", "طاقة ناتجة عن الوقود الأحفوري", "طاقة من الشمس، الرياح، والمياه", "طاقة يتم إنتاجها من خلال المواد الكيميائية"],
      ["ما هو الهدف الرئيسي من الحفاظ على التنوع البيولوجي؟", "زيادة الإنتاج الزراعي", "الحفاظ على الأنواع النباتية والحيوانية", "تقليل استهلاك الطاقة"],
      ["ما هو التلوث البيئي؟", "زيادة مستويات التعليم", "تلوث الهواء والماء والتربة", "نقص الموارد الطبيعية"],
      ["أي من هذه الخيارات يعدّ مثالاً على طاقة نظيفة؟", "الفحم", "النفط", "الطاقة الشمسية"],
      ["ما هي إحدى طرق تقليل التلوث في البيئة؟", "زيادة استخدام البلاستيك", "استخدام السيارات التي تستهلك الوقود الأحفوري", "إعادة تدوير المواد"],
      ["ما هي الزراعة المستدامة؟", "الزراعة التي تستهلك كميات كبيرة من المياه", "الزراعة التي تحافظ على صحة التربة وتقلل من التلوث", "الزراعة التي تعتمد على المبيدات الحشرية فقط"],
      ["ما هو دور الغابات في التنمية المستدامة؟", "توفير الأخشاب فقط", "المحافظة على التنوع البيولوجي وتنقية الهواء", "زيادة التلوث الجوي"],
      ["كيف يمكن تقليل استهلاك المياه في الزراعة؟", "استخدام طرق ري مكلفة", "استخدام الري بالتنقيط", "ري المحاصيل في أوقات الذروة"],
      ["أي من هذه المواد يمكن إعادة تدويرها؟", "الزجاج", "الزيت", "المواد البلاستيكية السامة"],
    ],
    'Medium': [
      ["ما هو الفرق بين التنمية المستدامة والتنمية التقليدية؟", "التنمية المستدامة تهتم بالنمو الاقتصادي فقط", "التنمية التقليدية تهتم بحماية البيئة فقط", "التنمية المستدامة توازن بين الاقتصاد والبيئة والمجتمع"],
      ["أي من هذه الموارد يُعتبر مصدرًا غير متجدد للطاقة؟", "الطاقة الشمسية", "الرياح", "الفحم"],
      ["ما هو أحد تأثيرات تغير المناخ على البيئة؟", "زيادة المساحات الخضراء في الأرض", "ارتفاع مستويات البحار والمحيطات", "انخفاض درجات الحرارة في جميع أنحاء العالم"],
      ["أي من هذه المبادرات يمكن أن يُساهم في تحقيق التنمية المستدامة في المدن؟", "بناء المزيد من الطرق السريعة", "تشجيع النقل العام وتقليل استخدام السيارات الخاصة", "استخدام المزيد من المواد البلاستيكية في البناء"],
      ["ما هو الهدف من اتفاقية باريس للمناخ التي تم توقيعها في 2015؟", "زيادة انبعاثات الغازات الدفيئة", "تقليل الاحتباس الحراري إلى أقل من درجتين مئويتين", "منع استخدام الطاقات المتجددة"],
      ["أي من هذه الأنشطة يعتبر مثالاً على التصرف البيئي المستدام؟", "استخدام الأسمدة الكيميائية بشكل مفرط", "قطع الأشجار بشكل غير مسؤول", "زراعة محاصيل مقاومة للجفاف في الأراضي الصحراوية"],
      ["ما هو أحد أضرار التلوث البلاستيكي على البيئة؟", "يحسن جودة التربة", "يزيد من التنوع البيولوجي", "يؤدي إلى اختناق الحيوانات البحرية"],
      ["كيف تساهم الزراعة المستدامة في الحفاظ على الموارد الطبيعية؟", "باستخدام المبيدات الحشرية بكثرة", "من خلال تقنيات الري الذكية والمستدامة", "بتوسيع استخدام الأراضي الزراعية بشكل مفرط"],
      ["ما هو مفهوم 'البصمة البيئية'؟", "كمية النفايات التي تُنتجها دولة ما", "التأثير الكلي لأنشطة الإنسان على البيئة من خلال استهلاك الموارد وإنتاج النفايات", "استهلاك الكهرباء في المنازل"],
      ["أي من هذه المبادرات يمكن أن يساعد في الحد من ظاهرة الاحتباس الحراري؟", "زيادة استخدام الوقود الأحفوري", "تقليل انبعاثات الغازات الدفيئة من خلال الطاقة المتجددة", "إزالة الغابات بشكل واسع"],
    ],
    'Hard': [
      ["ما هي 'الحدود البيئية' (Planetary Boundaries) وكيف تؤثر على التنمية المستدامة؟", "الحدود البيئية تمثل مستويات الاستخدام المستدام للموارد الطبيعية", "هي الحدود الجغرافية التي تحدد مناطق الزراعة المستدامة", "الحدود البيئية تشير إلى التأثيرات الاجتماعية الناتجة عن النمو السكاني"],
      ["ما هو الفرق بين 'الاقتصاد الدائري' و 'الاقتصاد الخطي'؟", "الاقتصاد الدائري يعتمد على استهلاك الموارد بشكل غير محدود", "الاقتصاد الخطي يعتمد على إعادة استخدام الموارد بشكل مستدام", "الاقتصاد الدائري يركز على تقليل الفاقد وإعادة تدوير المواد"],
      ["كيف يؤثر تدهور الأراضي على تحقيق أهداف التنمية المستدامة؟", "تدهور الأراضي يساهم في زيادة الإنتاج الزراعي بشكل مستدام", "يؤدي إلى فقدان التنوع البيولوجي وتدهور البيئة الطبيعية", "يحسن من جودة المياه في الأنهار"],
      ["أي من هذه التقنيات يمكن أن يُساعد في إزالة غازات الدفيئة من الغلاف الجوي؟", "التقاط وتخزين الكربون (CCS)", "تحسين استخدام الوقود الأحفوري", "تعزيز التلوث الصناعي"],
      ["ما هو مفهوم 'العدالة البيئية' وكيف يرتبط بالتنمية المستدامة؟", "التأكد من توزيع الموارد البيئية بشكل متساوٍ بين الأفراد والمجتمعات", "منح أولوية التنوع البيولوجي على حساب التنمية الاقتصادية", "إلغاء الفقر على حساب حماية البيئة"],
      ["ما هي العلاقة بين الفقر وتدهور البيئة في السياق العالمي؟", "الفقر لا يؤثر على تدهور البيئة لأن الفقراء يستخدمون الموارد بشكل مستدام", "الفقر يؤدي إلى استنزاف الموارد الطبيعية بسبب قلة الفرص الاقتصادية", "تدهور البيئة يؤدي إلى زيادة الفقر بشكل طفيف"],
      ["كيف يمكن لزيادة التنوع البيولوجي أن تُساهم في تقليل آثار تغير المناخ؟", "زيادة التنوع البيولوجي يساهم في تقليل انبعاثات الغازات الدفيئة بشكل كبير", "التنوع البيولوجي يساعد في مقاومة الظروف المناخية المتغيرة ويعزز استدامة النظم البيئية", "التنوع البيولوجي لا يؤثر بشكل كبير على تغير المناخ"],
      ["أي من هذه الدول حققت أكبر تقدم في تنفيذ أهداف التنمية المستدامة لعام 2030؟", "الولايات المتحدة", "السويد", "الهند"],
      ["ما هو مفهوم 'الاقتصاد الأخضر' وكيف يختلف عن التنمية المستدامة التقليدية؟", "الاقتصاد الأخضر يركز على حماية البيئة وتخفيض الفقر من خلال الأنشطة الاقتصادية المستدامة", "يركز الاقتصاد الأخضر على زيادة الاستهلاك والانتاج في الصناعات الكبيرة", "الاقتصاد الأخضر لا يهتم بالنمو الاقتصادي بل بالبيئة فقط"],
      ["ما هو التأثير طويل الأمد لاستهلاك المياه في الزراعة على البيئة؟", "زيادة استهلاك المياه يؤدي إلى تدمير الأنظمة البيئية البحرية", "استهلاك المياه في الزراعة لا يؤثر على البيئة إذا تم بشكل مستدام", "يؤدي الاستهلاك غير المستدام للمياه إلى انخفاض مستوى المياه الجوفية وتدهور التربة"],
    ],
  };

  int _currentQuestionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  late List<List<String>> _currentQuestions;

  // Initialize the audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _currentQuestions = _questionSets['Easy']!;
    _audioPlayer.setSource(AssetSource('sounds/clap.mp3'));
    _audioPlayer.setSource(AssetSource('sounds/error.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound(bool isCorrect) async {
    try {
      if (isCorrect) {
        await _audioPlayer.play(AssetSource('sounds/clap.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/error.mp3'));
      }
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void _loadQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length) {
      setState(() {
        _selectedAnswer = null;
      });
    } else {
      _showResult();
    }
  }

  void _checkAnswer() {
    bool isCorrect = _selectedAnswer == _currentQuestions[_currentQuestionIndex][3];
    if (isCorrect) {
      _score++;
      _playSound(true);
    } else {
      _playSound(false);
    }
    setState(() {
      _currentQuestionIndex++;
    });
    _loadQuestion();
  }

  void _showResult() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'انتهى الاختبار! درجاتك: $_score من ${_currentQuestions.length}',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? difficulty = ModalRoute.of(context)?.settings.arguments as String?;
    if (difficulty != null && _currentQuestions != _questionSets[difficulty]) {
      setState(() {
        _currentQuestions = _questionSets[difficulty]!;
        _currentQuestionIndex = 0;
        _score = 0;
        _selectedAnswer = null;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              height: 30,
              width: 30,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error);
              },
            ),
            const SizedBox(width: 10),
            const Text('التطبيق'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _currentQuestionIndex < _currentQuestions.length
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentQuestions[_currentQuestionIndex][0],
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    RadioListTile<String>(
                      title: Text(
                        _currentQuestions[_currentQuestionIndex][1],
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: _currentQuestions[_currentQuestionIndex][1],
                      groupValue: _selectedAnswer,
                      onChanged: (value) {
                        setState(() {
                          _selectedAnswer = value;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(
                        _currentQuestions[_currentQuestionIndex][2],
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: _currentQuestions[_currentQuestionIndex][2],
                      groupValue: _selectedAnswer,
                      onChanged: (value) {
                        setState(() {
                          _selectedAnswer = value;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text(
                        _currentQuestions[_currentQuestionIndex][3],
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: _currentQuestions[_currentQuestionIndex][3],
                      groupValue: _selectedAnswer,
                      onChanged: (value) {
                        setState(() {
                          _selectedAnswer = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _selectedAnswer == null
                          ? null
                          : () {
                              _checkAnswer();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        'التالي',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'انتهى الاختبار! درجاتك: $_score من ${_currentQuestions.length}',
                        style: const TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text(
                          'العودة',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// The inquiries page with contact information.
class InquiriesPage extends StatelessWidget {
  const InquiriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              height: 30,
              width: 30,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error);
              },
            ),
            const SizedBox(width: 10),
            const Text('التطبيق'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'الاستفسارات',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'إذا كانت لديك أي استفسارات، يرجى التواصل مع الدعم الفني. سنكون سعداء بمساعدتك!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'العودة',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}