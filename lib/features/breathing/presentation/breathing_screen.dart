import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinkrain/core/theme/tokens.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';

final breathingExerciseProvider = StateNotifierProvider<BreathingExerciseNotifier, BreathingState>(
      (ref) => BreathingExerciseNotifier(),
);

class BreathingState {
  final BreathingStage stage;
  final int secondsRemaining;
  final int totalCycles;
  final int currentCycle;
  final String exerciseType;

  BreathingState({
    required this.stage,
    required this.secondsRemaining,
    required this.totalCycles,
    required this.currentCycle,
    required this.exerciseType,
  });

  BreathingState copyWith({
    BreathingStage? stage,
    int? secondsRemaining,
    int? totalCycles,
    int? currentCycle,
    String? exerciseType,
  }) {
    return BreathingState(
      stage: stage ?? this.stage,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      totalCycles: totalCycles ?? this.totalCycles,
      currentCycle: currentCycle ?? this.currentCycle,
      exerciseType: exerciseType ?? this.exerciseType,
    );
  }
}

enum BreathingStage { inhale, hold, exhale, rest, initial, completed }

class BreathingExerciseNotifier extends StateNotifier<BreathingState> {
  Timer? _timer;

  BreathingExerciseNotifier() : super(BreathingState(
    stage: BreathingStage.initial,
    secondsRemaining: 0,
    totalCycles: 4,
    currentCycle: 0,
    exerciseType: 'box',
  ));

  void startExercise(String type, int cycles) {
    // Reset state
    state = BreathingState(
      stage: BreathingStage.inhale,
      secondsRemaining: _getDuration(type, BreathingStage.inhale),
      totalCycles: cycles,
      currentCycle: 1,
      exerciseType: type,
    );

    _startTimer();
  }

  void pauseExercise() {
    _timer?.cancel();
  }

  void resumeExercise() {
    if (state.stage != BreathingStage.initial &&
        state.stage != BreathingStage.completed) {
      _startTimer();
    }
  }

  void stopExercise() {
    _timer?.cancel();
    state = BreathingState(
      stage: BreathingStage.initial,
      secondsRemaining: 0,
      totalCycles: 4,
      currentCycle: 0,
      exerciseType: 'box',
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsRemaining > 1) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        _moveToNextStage();
      }
    });
  }

  void _moveToNextStage() {
    BreathingStage nextStage;

    switch (state.stage) {
      case BreathingStage.inhale:
        nextStage = state.exerciseType == 'box' ? BreathingStage.hold : BreathingStage.exhale;
        break;
      case BreathingStage.hold:
        nextStage = state.exerciseType == 'box'
            ? (state.stage == BreathingStage.inhale ? BreathingStage.exhale : BreathingStage.rest)
            : BreathingStage.exhale;
        break;
      case BreathingStage.exhale:
        nextStage = state.exerciseType == 'box' ? BreathingStage.hold : BreathingStage.rest;
        break;
      case BreathingStage.rest:
      // Check if we need to move to the next cycle or complete the exercise
        if (state.currentCycle < state.totalCycles) {
          nextStage = BreathingStage.inhale;
          state = state.copyWith(
            stage: nextStage,
            secondsRemaining: _getDuration(state.exerciseType, nextStage),
            currentCycle: state.currentCycle + 1,
          );
          return;
        } else {
          nextStage = BreathingStage.completed;
          _timer?.cancel();
          state = state.copyWith(
            stage: nextStage,
            secondsRemaining: 0,
          );
          return;
        }
      default:
        nextStage = BreathingStage.inhale;
    }

    state = state.copyWith(
      stage: nextStage,
      secondsRemaining: _getDuration(state.exerciseType, nextStage),
    );
  }

  int _getDuration(String exerciseType, BreathingStage stage) {
    switch (exerciseType) {
      case 'box':
        return 4; // All stages are 4 seconds in box breathing
      case '4-7-8':
        switch (stage) {
          case BreathingStage.inhale:
            return 4;
          case BreathingStage.hold:
            return 7;
          case BreathingStage.exhale:
            return 8;
          case BreathingStage.rest:
            return 2;
          default:
            return 4;
        }
      case 'calm':
        switch (stage) {
          case BreathingStage.inhale:
            return 5;
          case BreathingStage.exhale:
            return 5;
          case BreathingStage.rest:
            return 2;
          default:
            return 5;
        }
      default:
        return 4;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Particle model for CustomPainter
class _BreathingParticle {
  final double baseAngle;
  final double orbitRadius;
  final double size;
  final double speedFactor;
  final Color color;
  _BreathingParticle({
    required this.baseAngle,
    required this.orbitRadius,
    required this.size,
    required this.speedFactor,
    required this.color,
  });
}

// CustomPainter for breathing particles
class _ParticlePainter extends CustomPainter {
  final List<_BreathingParticle> particles;
  final double animationValue;
  final double orbRadius;
  _ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.orbRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      // Animate angle for smooth orbit
      final angle = p.baseAngle + animationValue * 2 * pi * p.speedFactor;
      final r = (orbRadius / 2) + p.orbitRadius * (0.7 + 0.3 * animationValue);
      final dx = center.dx + cos(angle) * r;
      final dy = center.dy + sin(angle) * r;
      final paint = Paint()
        ..color = p.color.withValues(alpha:0.2 + 0.6 * animationValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.orbRadius != orbRadius ||
      oldDelegate.particles != particles;
}

Color _getStageColor(BreathingStage stage) {
  switch (stage) {
    case BreathingStage.inhale:
      return Colors.blue;
    case BreathingStage.hold:
      return Colors.purple;
    case BreathingStage.exhale:
      return Colors.pink;
    case BreathingStage.rest:
      return Colors.indigo;
    default:
      return Colors.blue;
  }
}

Color _getSecondaryStageColor(BreathingStage stage) {
  switch (stage) {
    case BreathingStage.inhale:
      return Colors.cyan;
    case BreathingStage.hold:
      return Colors.deepPurple;
    case BreathingStage.exhale:
      return Colors.red;
    case BreathingStage.rest:
      return Colors.lightBlue;
    default:
      return Colors.lightBlue;
  }
}

// Helper to get the duration for the current stage
int _getDuration(String exerciseType, BreathingStage stage) {
  switch (exerciseType) {
    case 'box':
      return 4; // All stages are 4 seconds in box breathing
    case '4-7-8':
      switch (stage) {
        case BreathingStage.inhale:
          return 4;
        case BreathingStage.hold:
          return 7;
        case BreathingStage.exhale:
          return 8;
        case BreathingStage.rest:
          return 0; // No rest in 4-7-8
        default:
          return 4;
      }
    default:
      return 5;
  }
}

class BreathBreakScreen extends ConsumerStatefulWidget {
  const BreathBreakScreen({super.key});

  @override
  ConsumerState<BreathBreakScreen> createState() => _BreathBreakScreenState();
}

class _BreathBreakScreenState extends ConsumerState<BreathBreakScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String selectedExercise = 'box';
  int selectedCycles = 4;
  bool isExerciseStarted = false;

  // Background gradient animation controllers
  late Animation<Color?> _gradientStartAnimation;
  late Animation<Color?> _gradientEndAnimation;

  // Particle system
  static const int _particleCount = 14;
  late List<_BreathingParticle> _particles;
  final Random _particleRandom = Random();

  // Stage-based gradient colors
  final Map<BreathingStage, List<Color>> _stageColors = {
    BreathingStage.inhale: [Colors.blue[50]!, Colors.blue[200]!],
    BreathingStage.hold: [Colors.purple[50]!, Colors.purple[200]!],
    BreathingStage.exhale: [Colors.pink[50]!, Colors.pink[200]!],
    BreathingStage.rest: [Colors.indigo[50]!, Colors.indigo[200]!],
    BreathingStage.initial: [Colors.grey[50]!, Colors.grey[200]!],
    BreathingStage.completed: [Colors.green[50]!, Colors.green[200]!],
  };

  // Sound feedback control
  bool _enableSound = true;
  bool _enableHaptic = true;
  BreathingStage? _lastStage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    // Initialize gradient animations
    _gradientStartAnimation = ColorTween(
      begin: _stageColors[BreathingStage.initial]![0],
      end: _stageColors[BreathingStage.initial]![0],
    ).animate(_animationController);

    _gradientEndAnimation = ColorTween(
      begin: _stageColors[BreathingStage.initial]![1],
      end: _stageColors[BreathingStage.initial]![1],
    ).animate(_animationController);

    // Initialize particles
    _initParticles();
  }

  void _initParticles() {
    // Create a fixed set of particles with random orbits and speeds
    _particles = List.generate(_particleCount, (i) {
      final angle = _particleRandom.nextDouble() * 2 * pi;
      final orbitRadius = 120 + _particleRandom.nextDouble() * 40;
      final size = 4 + _particleRandom.nextDouble() * 5;
      final speed = 0.5 + _particleRandom.nextDouble() * 0.8;
      final color = Colors.white.withAlpha(120 + _particleRandom.nextInt(80));
      return _BreathingParticle(
        baseAngle: angle,
        orbitRadius: orbitRadius,
        size: size,
        speedFactor: speed,
        color: color,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final breathingState = ref.watch(breathingExerciseProvider);
    final notifier = ref.read(breathingExerciseProvider.notifier);

    ref.listen<BreathingState>(breathingExerciseProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Start exercise if transitioned from initial to another stage
        if (prev?.stage == BreathingStage.initial &&
            next.stage != BreathingStage.initial &&
            next.stage != BreathingStage.completed) {
          if (!isExerciseStarted) {
            setState(() {
              isExerciseStarted = true;
            });
          }
        }
        // Handle animation controller based on stage
        double targetValue = 0.5;
        switch (next.stage) {
          case BreathingStage.inhale:
          case BreathingStage.hold:
            targetValue = 1.0;
            break;
          case BreathingStage.exhale:
          case BreathingStage.rest:
            targetValue = 0.0;
            break;
          default:
            targetValue = 0.5;
        }
        final duration = Duration(
          seconds: next.secondsRemaining,
          milliseconds: 100,
        );
        _animationController.duration = duration;
        if (targetValue == 1.0 && _animationController.value < 1.0) {
          _animationController.forward();
        } else if (targetValue == 0.0 && _animationController.value > 0.0) {
          _animationController.reverse();
        }

        // Update gradient colors based on current stage
        if (prev?.stage != next.stage && next.stage != BreathingStage.initial) {
          setState(() {
            _gradientStartAnimation = ColorTween(
              begin: _gradientStartAnimation.value ?? _stageColors[next.stage]![0],
              end: _stageColors[next.stage]![0],
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeInOut,
              ),
            );

            _gradientEndAnimation = ColorTween(
              begin: _gradientEndAnimation.value ?? _stageColors[next.stage]![1],
              end: _stageColors[next.stage]![1],
            ).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeInOut,
              ),
            );
          });
        }

        // Provide haptic and sound feedback on stage transitions
        if (_lastStage != next.stage && next.stage != BreathingStage.initial && next.stage != BreathingStage.completed) {
          _provideFeedback(next.stage);
          _lastStage = next.stage;
        }

        // Reset state on completion
        if (next.stage == BreathingStage.completed) {
          if (isExerciseStarted) {
            setState(() {
              isExerciseStarted = false;
            });

            // Completion feedback
            if (_enableHaptic) {
              HapticFeedback.mediumImpact();
              Future.delayed(const Duration(milliseconds: 300), () {
                HapticFeedback.mediumImpact();
              });
            }
          }
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Breath Break',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/mindfulness'),
        ),
      ),
      extendBodyBehindAppBar: true, // Allow gradient to extend behind AppBar
      backgroundColor: Colors.transparent, // Make scaffold background transparent
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (_gradientStartAnimation.value ?? _stageColors[breathingState.stage]![0]).withValues(alpha:0.95),
                      (_gradientStartAnimation.value ?? _stageColors[breathingState.stage]![0]).withValues(alpha:0.75),
                      (_gradientEndAnimation.value ?? _stageColors[breathingState.stage]![1]).withValues(alpha:0.75),
                      (_gradientEndAnimation.value ?? _stageColors[breathingState.stage]![1]).withValues(alpha:0.95),
                    ],
                    stops: const [0.0, 0.10, 0.90, 1.0], // Smooth fade at top and bottom
                  ),
                ),
              );
            },
          ),
          // Content layer
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isExerciseStarted) _buildExerciseSelector(),
                    if (isExerciseStarted) _buildExerciseInProgress(breathingState),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          // Static control buttons at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              // Add extra padding to account for the height of the navbar
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 80.0),
              child: isExerciseStarted
                  ? (breathingState.stage != BreathingStage.completed
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20),
                            TextButton(
                              onPressed: () {
                                if (_animationController.isAnimating) {
                                  _animationController.stop();
                                  notifier.pauseExercise();
                                  setState(() {});
                                } else {
                                  _animationController.forward();
                                  notifier.resumeExercise();
                                  setState(() {});
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTokens.buttonPrimaryBg,
                                foregroundColor: AppTokens.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(_animationController.isAnimating ? 'Pause' : 'Resume'),
                            ),
                            const SizedBox(width: 20),
                            TextButton(
                              onPressed: () {
                                notifier.stopExercise();
                                setState(() {
                                  isExerciseStarted = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTokens.buttonSecondaryBg,
                                foregroundColor: AppTokens.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text('End Session'),
                            ),
                          ],
                        )
                      : TextButton(
                          onPressed: () {
                            setState(() {
                              isExerciseStarted = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTokens.buttonPrimaryBg,
                            foregroundColor: AppTokens.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Done'),
                        ))
                  : TextButton(
                      onPressed: () {
                        setState(() {
                          isExerciseStarted = true;
                        });
                        notifier.startExercise(selectedExercise, selectedCycles);
                        if (_enableHaptic) {
                          HapticFeedback.lightImpact();
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppTokens.buttonPrimaryBg,
                        foregroundColor: AppTokens.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Start Exercise', style: TextStyle(fontSize: 18)),
                    ),
            ),
          ),
        ],
      ),
      extendBody: true, // Extend content behind bottom navigation bar
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
    super.dispose();
  }

  Widget _buildExerciseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a breathing exercise',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _buildExerciseOption(
          'Box Breathing',
          'Inhale, hold, exhale, and hold, each for 4 seconds',
          'box',
          Icons.crop_square_outlined,
        ),
        _buildExerciseOption(
          '4-7-8 Breathing',
          'Inhale for 4, hold for 7, exhale for 8 seconds',
          '4-7-8',
          Icons.air,
        ),
        _buildExerciseOption(
          'Calming Breath',
          'Simple inhale and exhale for 5 seconds each',
          'calm',
          Icons.favorite_border,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Number of cycles:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            DropdownButton<int>(
              value: selectedCycles,
              items: [3, 4, 5, 6, 7, 8, 9, 10].map((cycles) {
                return DropdownMenuItem<int>(
                  value: cycles,
                  child: Text('$cycles'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCycles = value;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExerciseOption(
      String title,
      String description,
      String type,
      IconData icon,
      ) {
    final isSelected = selectedExercise == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedExercise = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.bgCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTokens.borderLight! : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.pink[100]!.withAlpha(30),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.pink[100] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.pink[700] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseInProgress(BreathingState state) {
    final String stageText = _getStageText(state.stage);

    return Column(
      children: [
        Text(
          'Cycle ${state.currentCycle} of ${state.totalCycles}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 20),
        BlurText(
          key: ValueKey(stageText),
          text: stageText,
          duration: const Duration(milliseconds: 800),
          type: AnimationType.word,
          textStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${state.secondsRemaining} seconds',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 50),
        Stack(
          alignment: Alignment.center,
          children: [
            // Progress indicator
            SizedBox(
              width: 328, // 8px larger than orb for clear separation
              height: 328,
              child: CircularProgressIndicator(
                value: (() {
                  final stageTotal = _getStageDuration(state.exerciseType, state.stage);
                  if (stageTotal == 0) return 0.0;
                  return (stageTotal - state.secondsRemaining) / stageTotal;
                })(),
                strokeWidth: 3, // thinner line
                backgroundColor: Colors.transparent, // Remove background ring
                color: Colors.white.withAlpha(120), // subtle, semi-transparent
              ),
            ),
            // Enhanced breathing orb
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final Color primaryColor = _getStageColor(state.stage);
                final Color secondaryColor = _getSecondaryStageColor(state.stage);
                final double orbRadius = 320;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glassmorphic + iridescent border effect
                    Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment(0, -0.2),
                          radius: 0.85,
                          colors: [
                            Colors.white.withValues(alpha:0.6), // glass base
                            primaryColor.withValues(alpha:0.15), // pastel tint
                            Colors.white.withValues(alpha:0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7, 0.95, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha:0.18),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                        border: Border.all(
                          width: 6,
                          style: BorderStyle.solid,
                          // Iridescent sweep gradient border
                          color: Colors.transparent,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Frosted glass effect
                          ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: Container(
                                color: Colors.white.withValues(alpha:0.08),
                              ),
                            ),
                          ),
                          // Iridescent edge overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _IridescentBorderPainter(primaryColor, secondaryColor),
                              ),
                            ),
                          ),
                          // Gloss highlight
                          Positioned(
                            top: 48, // moved higher for subtlety
                            left: 84, // narrower gloss
                            right: 84,
                            child: Container(
                              height: 20, // smaller, more subtle
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha:0.07), // much lower opacity
                                    Colors.white.withValues(alpha:0.0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha:0.04),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Breathing icon
                          Center(
                            child: Icon(
                              _getStageIcon(state.stage),
                              color: Colors.white.withValues(alpha:0.92),
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Custom painted particles
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _ParticlePainter(
                          particles: _particles,
                          animationValue: _animationController.value,
                          orbRadius: orbRadius,
                        ),
                        size: Size((orbRadius + 40).toDouble(), (orbRadius + 40).toDouble()),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  String _getStageText(BreathingStage stage) {
    switch (stage) {
      case BreathingStage.inhale:
        return 'Breathe In';
      case BreathingStage.hold:
        return 'Hold';
      case BreathingStage.exhale:
        return 'Breathe Out';
      case BreathingStage.rest:
        return 'Hold again';
      case BreathingStage.completed:
        return 'Completed';
      default:
        return '';
    }
  }

  IconData _getStageIcon(BreathingStage stage) {
    switch (stage) {
      case BreathingStage.inhale:
        return Icons.arrow_upward;
      case BreathingStage.hold:
        return Icons.pause;
      case BreathingStage.exhale:
        return Icons.arrow_downward;
      case BreathingStage.rest:
        return Icons.more_horiz;
      default:
        return Icons.air;
    }
  }

  Widget _buildFeelingButton(String label) {
    return ElevatedButton(
      onPressed: () {
        // Save feeling data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feeling recorded: $label'),
            backgroundColor: Colors.green,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(label),
    );
  }

  // Provide appropriate feedback based on breathing stage
  void _provideFeedback(BreathingStage stage) {
    // Haptic feedback
    if (_enableHaptic) {
      switch (stage) {
        case BreathingStage.inhale:
          HapticFeedback.lightImpact();
          break;
        case BreathingStage.hold:
          HapticFeedback.selectionClick();
          break;
        case BreathingStage.exhale:
          HapticFeedback.mediumImpact();
          break;
        case BreathingStage.rest:
          HapticFeedback.selectionClick();
          break;
        default:
          break;
      }
    }

    // TODO: Add sound feedback using AudioPlayer or similar
    // This would require adding a dependency to pubspec.yaml
    // Example: 
    // if (_enableSound) {
    //   final player = AudioPlayer();
    //   player.play(AssetSource('sounds/${stage.toString().split('.').last}.mp3'));
    // }
  }

  Widget _buildFeedbackToggle({
    required IconData icon,
    required bool enabled,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? Colors.white.withAlpha(255) : Colors.white.withAlpha(127),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white.withAlpha(127),
          size: 20,
        ),
      ),
    );
  }
}

class _IridescentBorderPainter extends CustomPainter {
  final Color primary;
  final Color secondary;
  _IridescentBorderPainter(this.primary, this.secondary);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 6.28319, // 2*pi
        colors: [
          primary.withValues(alpha:0.7),
          secondary.withValues(alpha:0.7),
          primary.withValues(alpha:0.7),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 3, paint);
  }

  @override
  bool shouldRepaint(covariant _IridescentBorderPainter oldDelegate) => true;
}

int _getStageDuration(String exerciseType, BreathingStage stage) {
  switch (exerciseType) {
    case 'box':
      return 4;
    case '4-7-8':
      switch (stage) {
        case BreathingStage.inhale:
          return 4;
        case BreathingStage.hold:
          return 7;
        case BreathingStage.exhale:
          return 8;
        case BreathingStage.rest:
          return 2;
        default:
          return 4;
      }
    case 'calm':
      switch (stage) {
        case BreathingStage.inhale:
          return 5;
        case BreathingStage.exhale:
          return 5;
        case BreathingStage.rest:
          return 2;
        default:
          return 5;
      }
    default:
      return 4;
  }
}
