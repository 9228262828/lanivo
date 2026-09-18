import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LanivoApp());
}

enum LaneGameMode { endless, rush60, perfectRun }

String modeLabel(LaneGameMode mode) {
  switch (mode) {
    case LaneGameMode.endless:
      return 'Endless';
    case LaneGameMode.rush60:
      return '60 Sec Rush';
    case LaneGameMode.perfectRun:
      return 'Perfect Run';
  }
}

String modeSubtitle(LaneGameMode mode) {
  switch (mode) {
    case LaneGameMode.endless:
      return 'Dodge as long as you can.';
    case LaneGameMode.rush60:
      return 'Score as much as possible in 60 seconds.';
    case LaneGameMode.perfectRun:
      return 'Pass 30 obstacles without crashing.';
  }
}

const lanivoNavy = Color(0xFF08111F);
const lanivoBlue = Color(0xFF2563EB);
const lanivoCyan = Color(0xFF06B6D4);
const lanivoPurple = Color(0xFF7C3AED);
const lanivoGreen = Color(0xFF10B981);
const lanivoAmber = Color(0xFFF59E0B);
const lanivoRed = Color(0xFFEF4444);

Color modeColor(LaneGameMode mode) {
  switch (mode) {
    case LaneGameMode.endless:
      return lanivoPurple;
    case LaneGameMode.rush60:
      return lanivoCyan;
    case LaneGameMode.perfectRun:
      return lanivoGreen;
  }
}

IconData modeIcon(LaneGameMode mode) {
  switch (mode) {
    case LaneGameMode.endless:
      return Icons.all_inclusive_rounded;
    case LaneGameMode.rush60:
      return Icons.timer_rounded;
    case LaneGameMode.perfectRun:
      return Icons.workspace_premium_rounded;
  }
}

ThemeData lanivoTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: lanivoBlue,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF060A12)
        : const Color(0xFFF4F7FB),
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  );
}

class LanivoStore extends ChangeNotifier {
  static const _bestEndlessKey = 'lanivo_best_endless_v1';
  static const _bestRushKey = 'lanivo_best_rush_v1';
  static const _bestPerfectKey = 'lanivo_best_perfect_v1';
  static const _coinsKey = 'lanivo_coins_v1';
  static const _gamesKey = 'lanivo_games_v1';
  static const _bestComboKey = 'lanivo_best_combo_v1';
  static const _distanceKey = 'lanivo_distance_v1';
  static const _darkKey = 'lanivo_dark_v1';
  static const _hapticKey = 'lanivo_haptic_v1';

  bool ready = false;
  bool darkMode = false;
  bool haptics = true;

  int bestEndless = 0;
  int bestRush = 0;
  int bestPerfect = 0;
  int totalCoins = 0;
  int gamesPlayed = 0;
  int bestCombo = 0;
  int totalDistance = 0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    bestEndless = prefs.getInt(_bestEndlessKey) ?? 0;
    bestRush = prefs.getInt(_bestRushKey) ?? 0;
    bestPerfect = prefs.getInt(_bestPerfectKey) ?? 0;
    totalCoins = prefs.getInt(_coinsKey) ?? 0;
    gamesPlayed = prefs.getInt(_gamesKey) ?? 0;
    bestCombo = prefs.getInt(_bestComboKey) ?? 0;
    totalDistance = prefs.getInt(_distanceKey) ?? 0;
    darkMode = prefs.getBool(_darkKey) ?? false;
    haptics = prefs.getBool(_hapticKey) ?? true;
    ready = true;
    notifyListeners();
  }

  int bestFor(LaneGameMode mode) {
    switch (mode) {
      case LaneGameMode.endless:
        return bestEndless;
      case LaneGameMode.rush60:
        return bestRush;
      case LaneGameMode.perfectRun:
        return bestPerfect;
    }
  }

  Future<void> registerRun({
    required LaneGameMode mode,
    required int score,
    required int coins,
    required int combo,
    required int distance,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    gamesPlayed += 1;
    totalCoins += coins;
    totalDistance += distance;
    if (combo > bestCombo) bestCombo = combo;

    switch (mode) {
      case LaneGameMode.endless:
        if (score > bestEndless) bestEndless = score;
        break;
      case LaneGameMode.rush60:
        if (score > bestRush) bestRush = score;
        break;
      case LaneGameMode.perfectRun:
        if (score > bestPerfect) bestPerfect = score;
        break;
    }

    await prefs.setInt(_bestEndlessKey, bestEndless);
    await prefs.setInt(_bestRushKey, bestRush);
    await prefs.setInt(_bestPerfectKey, bestPerfect);
    await prefs.setInt(_coinsKey, totalCoins);
    await prefs.setInt(_gamesKey, gamesPlayed);
    await prefs.setInt(_bestComboKey, bestCombo);
    await prefs.setInt(_distanceKey, totalDistance);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, value);
    notifyListeners();
  }

  Future<void> setHaptics(bool value) async {
    haptics = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticKey, value);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    bestEndless = 0;
    bestRush = 0;
    bestPerfect = 0;
    totalCoins = 0;
    gamesPlayed = 0;
    bestCombo = 0;
    totalDistance = 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bestEndlessKey);
    await prefs.remove(_bestRushKey);
    await prefs.remove(_bestPerfectKey);
    await prefs.remove(_coinsKey);
    await prefs.remove(_gamesKey);
    await prefs.remove(_bestComboKey);
    await prefs.remove(_distanceKey);
    notifyListeners();
  }
}

class LaneObject {
  final int id;
  final int lane;
  double y;
  final bool coin;
  bool handled;

  LaneObject({
    required this.id,
    required this.lane,
    required this.y,
    required this.coin,
    this.handled = false,
  });
}

class LaneGameController extends ChangeNotifier {
  static const int tickMs = 50;
  static const double playerY = 0.82;

  final LanivoStore store;
  final LaneGameMode mode;
  final Random _random = Random();

  Timer? _timer;
  bool _registered = false;
  int _idSeed = 1;
  int _spawnElapsedMs = 0;
  int _spawnEveryMs = 950;

  int playerLane = 1;
  int score = 0;
  int combo = 0;
  int runBestCombo = 0;
  int runCoins = 0;
  int passedObstacles = 0;
  int distance = 0;
  int remainingMs = 60000;

  bool paused = false;
  bool gameOver = false;
  bool victory = false;
  double speed = 0.24;

  final List<LaneObject> objects = [];

  LaneGameController({
    required this.store,
    required this.mode,
  });

  int get secondsLeft =>
      (remainingMs / 1000).ceil().clamp(0, 60).toInt();

  double get rushProgress =>
      (remainingMs / 60000).clamp(0.0, 1.0).toDouble();

  double get perfectProgress =>
      (passedObstacles / 30).clamp(0.0, 1.0).toDouble();

  void start() {
    _timer?.cancel();

    playerLane = 1;
    score = 0;
    combo = 0;
    runBestCombo = 0;
    runCoins = 0;
    passedObstacles = 0;
    distance = 0;
    remainingMs = 60000;
    paused = false;
    gameOver = false;
    victory = false;
    speed = 0.24;
    _spawnElapsedMs = 0;
    _spawnEveryMs = 950;
    _idSeed = 1;
    _registered = false;
    objects.clear();

    _spawnObstacle();

    _timer = Timer.periodic(
      const Duration(milliseconds: tickMs),
      (_) => _tick(),
    );

    notifyListeners();
  }

  void moveLeft() {
    if (paused || gameOver || playerLane <= 0) return;
    playerLane -= 1;
    notifyListeners();
  }

  void moveRight() {
    if (paused || gameOver || playerLane >= 2) return;
    playerLane += 1;
    notifyListeners();
  }

  void togglePause() {
    if (gameOver) return;
    paused = !paused;
    notifyListeners();
  }

  void _tick() {
    if (paused || gameOver) return;

    if (mode == LaneGameMode.rush60) {
      remainingMs -= tickMs;
      if (remainingMs <= 0) {
        remainingMs = 0;
        _finish(victoryValue: false);
        return;
      }
    }

    _spawnElapsedMs += tickMs;
    distance += 1;

    final deltaSeconds = tickMs / 1000.0;
    for (final object in objects) {
      object.y += speed * deltaSeconds;
    }

    _handleObjects();
    if (gameOver) return;

    objects.removeWhere((object) => object.y > 1.10);

    if (_spawnElapsedMs >= _spawnEveryMs) {
      _spawnElapsedMs = 0;
      if (_random.nextDouble() < 0.22) {
        _spawnCoin();
      } else {
        _spawnObstacle();
      }
    }

    _updateDifficulty();
    notifyListeners();
  }

  void _handleObjects() {
    for (final object in objects) {
      if (object.handled) continue;

      final nearPlayer = object.y >= 0.75 && object.y <= 0.89;

      if (nearPlayer && object.lane == playerLane) {
        object.handled = true;

        if (object.coin) {
          runCoins += 1;
          score += 2;
          combo += 1;
          if (combo > runBestCombo) runBestCombo = combo;
        } else {
          _hitObstacle();
          if (gameOver) return;
        }
        continue;
      }

      if (!object.coin && object.y > 0.90) {
        object.handled = true;
        passedObstacles += 1;
        score += 1;
        combo += 1;
        if (combo > runBestCombo) runBestCombo = combo;

        if (mode == LaneGameMode.perfectRun &&
            passedObstacles >= 30) {
          _finish(victoryValue: true);
          return;
        }
      }

      if (object.coin && object.y > 0.92) {
        object.handled = true;
      }
    }
  }

  void _hitObstacle() {
    combo = 0;

    switch (mode) {
      case LaneGameMode.endless:
        _finish(victoryValue: false);
        break;
      case LaneGameMode.rush60:
        score = max(0, score - 2);
        break;
      case LaneGameMode.perfectRun:
        _finish(victoryValue: false);
        break;
    }
  }

  void _spawnObstacle() {
    objects.add(
      LaneObject(
        id: _idSeed++,
        lane: _random.nextInt(3),
        y: -0.12,
        coin: false,
      ),
    );
  }

  void _spawnCoin() {
    objects.add(
      LaneObject(
        id: _idSeed++,
        lane: _random.nextInt(3),
        y: -0.12,
        coin: true,
      ),
    );
  }

  void _updateDifficulty() {
    final progress = passedObstacles + (distance ~/ 130);

    speed = (0.24 + (progress * 0.004))
        .clamp(0.24, 0.52)
        .toDouble();

    _spawnEveryMs = (950 - (progress * 8))
        .clamp(560, 950)
        .toInt();
  }

  Future<void> _finish({
    required bool victoryValue,
  }) async {
    if (gameOver) return;

    gameOver = true;
    paused = false;
    victory = victoryValue;
    _timer?.cancel();

    if (!_registered) {
      _registered = true;
      await store.registerRun(
        mode: mode,
        score: score,
        coins: runCoins,
        combo: runBestCombo,
        distance: distance,
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class LanivoApp extends StatefulWidget {
  const LanivoApp({super.key});

  @override
  State<LanivoApp> createState() => _LanivoAppState();
}

class _LanivoAppState extends State<LanivoApp> {
  final LanivoStore store = LanivoStore();

  @override
  void initState() {
    super.initState();
    store.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LANIVO',
          themeMode: store.darkMode ? ThemeMode.dark : ThemeMode.light,
          theme: lanivoTheme(Brightness.light),
          darkTheme: lanivoTheme(Brightness.dark),
          home: SplashScreen(store: store),
        );
      },
    );
  }
}

class LanivoLogo extends StatelessWidget {
  final double size;

  const LanivoLogo({
    super.key,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lanivoPurple, lanivoBlue, lanivoCyan],
        ),
        boxShadow: [
          BoxShadow(
            color: lanivoBlue.withOpacity(.25),
            blurRadius: size * .35,
            offset: Offset(0, size * .14),
          ),
        ],
      ),
      child: Icon(
        Icons.alt_route_rounded,
        color: Colors.white,
        size: size * .52,
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        border: Border.all(color: color.withOpacity(.18)),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 11),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final LanivoStore store;

  const SplashScreen({
    super.key,
    required this.store,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    while (!widget.store.ready) {
      await Future.delayed(
        const Duration(milliseconds: 40),
      );
    }

    await Future.delayed(
      const Duration(milliseconds: 650),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(store: widget.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LanivoLogo(size: 98),
            SizedBox(height: 22),
            Text(
              'LANIVO',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 5,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'SWITCH FAST • STAY ALIVE',
              style: TextStyle(
                color: lanivoBlue,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final LanivoStore store;

  const HomeScreen({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
              children: [
                Row(
                  children: [
                    const LanivoLogo(size: 58),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LANIVO',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                          Text(
                            'LANE SWITCH',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Statistics',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StatsScreen(store: store),
                        ),
                      ),
                      icon: const Icon(Icons.bar_chart_rounded),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(store: store),
                        ),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'Pick a lane challenge',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Move left or right, dodge obstacles, collect coins.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ...LaneGameMode.values.map(
                  (mode) => Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: _ModeCard(
                      mode: mode,
                      best: store.bestFor(mode),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameScreen(
                            store: store,
                            mode: mode,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        lanivoNavy,
                        lanivoPurple,
                        lanivoBlue,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          store.gamesPlayed == 0
                              ? 'Your lane history starts with the first run.'
                              : '${store.gamesPlayed} games • ${store.totalCoins} coins • Best combo ${store.bestCombo}',
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  final LaneGameMode mode;
  final int best;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.best,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = modeColor(mode);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  modeIcon(mode),
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modeLabel(mode),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      modeSubtitle(mode),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BEST  $best',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final LanivoStore store;
  final LaneGameMode mode;

  const GameScreen({
    super.key,
    required this.store,
    required this.mode,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final LaneGameController controller;
  bool navigatedToResult = false;

  @override
  void initState() {
    super.initState();

    controller = LaneGameController(
      store: widget.store,
      mode: widget.mode,
    );

    controller.addListener(_watchResult);
    controller.start();
  }

  void _watchResult() {
    if (!mounted ||
        !controller.gameOver ||
        navigatedToResult) {
      return;
    }

    navigatedToResult = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            store: widget.store,
            mode: widget.mode,
            score: controller.score,
            coins: controller.runCoins,
            combo: controller.runBestCombo,
            distance: controller.distance,
            victory: controller.victory,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    controller.removeListener(_watchResult);
    controller.dispose();
    super.dispose();
  }

  void _moveLeft() {
    if (widget.store.haptics) {
      HapticFeedback.selectionClick();
    }
    controller.moveLeft();
  }

  void _moveRight() {
    if (widget.store.haptics) {
      HapticFeedback.selectionClick();
    }
    controller.moveRight();
  }

  @override
  Widget build(BuildContext context) {
    final color = modeColor(widget.mode);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(modeLabel(widget.mode).toUpperCase()),
            actions: [
              IconButton(
                tooltip: controller.paused ? 'Resume' : 'Pause',
                onPressed: controller.togglePause,
                icon: Icon(
                  controller.paused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      child: _topStats(color),
                    ),
                    if (widget.mode == LaneGameMode.rush60)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(99),
                          value: controller.rushProgress,
                          color: lanivoCyan,
                        ),
                      ),
                    if (widget.mode == LaneGameMode.perfectRun)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(99),
                          value: controller.perfectProgress,
                          color: lanivoGreen,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: _playField(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _moveLeft,
                              icon: const Icon(Icons.arrow_left_rounded),
                              label: const Padding(
                                padding: EdgeInsets.all(14),
                                child: Text('LEFT'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _moveRight,
                              icon: const Icon(Icons.arrow_right_rounded),
                              label: const Padding(
                                padding: EdgeInsets.all(14),
                                child: Text('RIGHT'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.paused) _pauseOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _topStats(Color color) {
    final thirdLabel = widget.mode == LaneGameMode.rush60
        ? 'TIME'
        : widget.mode == LaneGameMode.perfectRun
            ? 'PASSED'
            : 'COINS';

    final thirdValue = widget.mode == LaneGameMode.rush60
        ? '${controller.secondsLeft}s'
        : widget.mode == LaneGameMode.perfectRun
            ? '${controller.passedObstacles}/30'
            : '${controller.runCoins}';

    return Row(
      children: [
        Expanded(
          child: StatTile(
            value: '${controller.score}',
            label: 'SCORE',
            color: color,
            icon: Icons.bolt_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            value: '${controller.combo}',
            label: 'COMBO',
            color: lanivoAmber,
            icon: Icons.local_fire_department_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            value: thirdValue,
            label: thirdLabel,
            color: widget.mode == LaneGameMode.rush60
                ? lanivoCyan
                : widget.mode == LaneGameMode.perfectRun
                    ? lanivoGreen
                    : lanivoAmber,
            icon: widget.mode == LaneGameMode.rush60
                ? Icons.timer_rounded
                : widget.mode == LaneGameMode.perfectRun
                    ? Icons.flag_rounded
                    : Icons.monetization_on_rounded,
          ),
        ),
      ],
    );
  }

  Widget _playField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final laneWidth = width / 3;
        final playerSize =
            min(laneWidth * .48, 58.0).toDouble();
        final objectSize =
            min(laneWidth * .40, 52.0).toDouble();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            if (details.localPosition.dx < width / 2) {
              _moveLeft();
            } else {
              _moveRight();
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: Theme.of(context).brightness ==
                                Brightness.dark
                            ? const [
                                Color(0xFF08111F),
                                Color(0xFF101B2E),
                              ]
                            : const [
                                Color(0xFFEFF6FF),
                                Color(0xFFDDEBFF),
                              ],
                      ),
                    ),
                  ),
                ),
                for (int i = 1; i <= 2; i++)
                  Positioned(
                    left: laneWidth * i - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(.16),
                    ),
                  ),
                ...controller.objects.map(
                  (object) {
                    final left = (laneWidth * object.lane) +
                        ((laneWidth - objectSize) / 2);

                    final top = (object.y * height)
                        .clamp(-objectSize, height + objectSize)
                        .toDouble();

                    return AnimatedPositioned(
                      key: ValueKey(object.id),
                      duration: const Duration(milliseconds: 50),
                      curve: Curves.linear,
                      left: left,
                      top: top,
                      width: objectSize,
                      height: objectSize,
                      child: _laneObjectWidget(object),
                    );
                  },
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  left: (laneWidth * controller.playerLane) +
                      ((laneWidth - playerSize) / 2),
                  top: (height * LaneGameController.playerY) -
                      (playerSize / 2),
                  width: playerSize,
                  height: playerSize,
                  child: _playerWidget(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _laneObjectWidget(LaneObject object) {
    if (object.coin) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [lanivoAmber, Color(0xFFFFD95A)],
          ),
          boxShadow: [
            BoxShadow(
              color: lanivoAmber.withOpacity(.35),
              blurRadius: 16,
            ),
          ],
        ),
        child: const Icon(
          Icons.star_rounded,
          color: Colors.white,
          size: 26,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lanivoRed, Color(0xFFF97316)],
        ),
        boxShadow: [
          BoxShadow(
            color: lanivoRed.withOpacity(.28),
            blurRadius: 14,
          ),
        ],
      ),
      child: const Icon(
        Icons.close_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  Widget _playerWidget() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lanivoBlue, lanivoCyan],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(.75),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: lanivoCyan.withOpacity(.36),
            blurRadius: 18,
          ),
        ],
      ),
      child: const Icon(
        Icons.navigation_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _pauseOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withOpacity(.95),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pause_circle_filled_rounded,
                  size: 74,
                  color: lanivoBlue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: 220,
                  child: FilledButton.icon(
                    onPressed: controller.togglePause,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('RESUME'),
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: 220,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('BACK HOME'),
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

class ResultScreen extends StatelessWidget {
  final LanivoStore store;
  final LaneGameMode mode;
  final int score;
  final int coins;
  final int combo;
  final int distance;
  final bool victory;

  const ResultScreen({
    super.key,
    required this.store,
    required this.mode,
    required this.score,
    required this.coins,
    required this.combo,
    required this.distance,
    required this.victory,
  });

  @override
  Widget build(BuildContext context) {
    final color = modeColor(mode);
    final title =
        mode == LaneGameMode.perfectRun && victory
            ? 'PERFECT RUN!'
            : 'RUN COMPLETE';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 42, 22, 30),
          children: [
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(.12),
                ),
                child: Icon(
                  victory
                      ? Icons.workspace_premium_rounded
                      : Icons.flag_rounded,
                  color: color,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              modeLabel(mode),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: '$score',
                    label: 'SCORE',
                    color: color,
                    icon: Icons.bolt_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    value: '$coins',
                    label: 'COINS',
                    color: lanivoAmber,
                    icon: Icons.monetization_on_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: '$combo',
                    label: 'BEST COMBO',
                    color: lanivoPurple,
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    value: '${store.bestFor(mode)}',
                    label: 'BEST SCORE',
                    color: lanivoGreen,
                    icon: Icons.emoji_events_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GameScreen(
                    store: store,
                    mode: mode,
                  ),
                ),
              ),
              icon: const Icon(Icons.replay_rounded),
              label: const Padding(
                padding: EdgeInsets.all(14),
                child: Text('PLAY AGAIN'),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home_outlined),
              label: const Padding(
                padding: EdgeInsets.all(14),
                child: Text('BACK HOME'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  final LanivoStore store;

  const StatsScreen({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('STATISTICS')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Lane record',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your runs, coins, combos, and best scores.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '${store.gamesPlayed}',
                      label: 'GAMES',
                      color: lanivoBlue,
                      icon: Icons.sports_esports_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      value: '${store.totalCoins}',
                      label: 'COINS',
                      color: lanivoAmber,
                      icon: Icons.monetization_on_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '${store.bestCombo}',
                      label: 'BEST COMBO',
                      color: lanivoPurple,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      value: '${store.totalDistance}',
                      label: 'DISTANCE',
                      color: lanivoCyan,
                      icon: Icons.route_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...LaneGameMode.values.map(
                (mode) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor:
                            modeColor(mode).withOpacity(.12),
                        child: Icon(
                          modeIcon(mode),
                          color: modeColor(mode),
                        ),
                      ),
                      title: Text(
                        modeLabel(mode),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Text(modeSubtitle(mode)),
                      trailing: Text(
                        '${store.bestFor(mode)}',
                        style: TextStyle(
                          color: modeColor(mode),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final LanivoStore store;

  const SettingsScreen({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('SETTINGS')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: store.darkMode,
                      onChanged: store.setDarkMode,
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark mode'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: store.haptics,
                      onChanged: store.setHaptics,
                      secondary: const Icon(Icons.vibration_rounded),
                      title: const Text('Haptic feedback'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LegalScreen(
                            title: 'Privacy Policy',
                            body: privacyText,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms & Conditions'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LegalScreen(
                            title: 'Terms & Conditions',
                            body: termsText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  textColor: lanivoRed,
                  iconColor: lanivoRed,
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Reset progress'),
                  subtitle: const Text('Delete scores and statistics.'),
                  onTap: () => _reset(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all progress?'),
        content: const Text(
          'Best scores and statistics will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('RESET'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await store.resetProgress();
    }
  }
}

const privacyText = '''LANIVO PRIVACY POLICY

LANIVO is an offline-first casual lane-switch game. The current core version does not require an account, login, Firebase, backend services, advertising, cloud sync, or behavioral analytics.

The game stores limited gameplay information locally on your device, including best scores for each game mode, games played, collected coins, best combo, total distance, dark-mode preference, and haptic-feedback preference.

This information is used only to provide local game progress, statistics, preferences, and best-score features.

The current core version does not require access to your location, camera, microphone, contacts, phone, SMS, calendar, photos, files, or payment information.

LANIVO does not intentionally sell or rent your locally stored gameplay information and does not use your gameplay data for personalized advertising.

You can reset gameplay progress from the Settings screen. Clearing application storage or uninstalling the app may also remove locally stored information, subject to operating-system backup and restore behavior.

If future versions add accounts, cloud sync, analytics, crash reporting, advertising, online multiplayer, payments, leaderboards, or additional permissions, this policy should be reviewed and updated before release.

For privacy questions, contact the app publisher through the support email shown on the store listing.''';

const termsText = '''LANIVO TERMS & CONDITIONS

LANIVO is a casual lane-switch game intended for entertainment.

Scores, coins, combos, timers, distance, obstacle progression, and statistics are calculated from gameplay and are provided for entertainment and personal progress tracking.

The current core version stores progress locally. We do not guarantee recovery of scores or settings after uninstalling the app, clearing app data, device loss, storage failure, or operating-system changes.

LANIVO is provided on an "as available" basis to the extent permitted by applicable law. Features may be improved, changed, added, or removed in future versions.

You are responsible for using the game in a safe and appropriate environment. Do not use the game when doing so could distract you from driving, operating machinery, walking in unsafe surroundings, or performing another activity that requires attention.

Use of LANIVO is also subject to applicable laws and the terms of the app-distribution platform through which you obtained it.''';

class LegalScreen extends StatelessWidget {
  final String title;
  final String body;

  const LegalScreen({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SelectableText(
            body,
            style: const TextStyle(height: 1.7),
          ),
        ],
      ),
    );
  }
}
