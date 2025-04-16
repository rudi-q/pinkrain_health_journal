import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/appbar.dart';
import '../../../core/widgets/bottom_navigation.dart';

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
  
  // Stage-based gradient colors
  final Map<BreathingStage, List<Color>> _stageColors = {
    BreathingStage.inhale: [Colors.blue[50]!, Colors.blue[200]!],
    BreathingStage.hold: [Colors.purple[50]!, Colors.purple[200]!],
    BreathingStage.exhale: [Colors.pink[50]!, Colors.pink[200]!],
    BreathingStage.rest: [Colors.indigo[50]!, Colors.indigo[200]!],
    BreathingStage.initial: [Colors.grey[50]!, Colors.grey[200]!],
    BreathingStage.completed: [Colors.green[50]!, Colors.green[200]!],
  };

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
        
        // Reset state on completion
        if (next.stage == BreathingStage.completed) {
          if (isExerciseStarted) {
            setState(() {
              isExerciseStarted = false;
            });
          }
        }
      });
    });

    return Scaffold(
      appBar: buildAppBar('Breath Break'),
      extendBodyBehindAppBar: true, // Allow gradient to extend behind AppBar
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _gradientStartAnimation.value ?? _stageColors[breathingState.stage]![0],
                  _gradientEndAnimation.value ?? _stageColors[breathingState.stage]![1],
                ],
              ),
            ),
            child: child,
          );
        },
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: AppBar().preferredSize.height + 20),
                if (!isExerciseStarted) _buildExerciseSelector(),
                if (isExerciseStarted) _buildExerciseInProgress(breathingState),
                const SizedBox(height: 30),
                if (!isExerciseStarted)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isExerciseStarted = true;
                      });
                      notifier.startExercise(selectedExercise, selectedCycles);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[100],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Start Exercise',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                // Fixed position buttons when exercise is in progress
                if (isExerciseStarted && breathingState.stage != BreathingStage.completed)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            notifier.stopExercise();
                            setState(() {
                              isExerciseStarted = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Stop'),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_animationController.isAnimating) {
                              _animationController.stop();
                              notifier.pauseExercise();
                              // Force update to properly show Resume text
                              setState(() {});
                            } else {
                              notifier.resumeExercise();
                              // Force update to properly show Pause text
                              setState(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink[100],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            // Use the notifier's state to determine if paused
                            breathingState.secondsRemaining > 0 && _animationController.isAnimating 
                              ? 'Pause' 
                              : 'Resume',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isExerciseStarted && breathingState.stage == BreathingStage.completed)
                  Column(
                    children: [
                      const Text(
                        'Great job!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "You've completed your breathing exercise. How do you feel?",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFeelingButton('😌 Calm'),
                          _buildFeelingButton('😊 Better'),
                          _buildFeelingButton('😐 Same'),
                        ],
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          notifier.stopExercise();
                          setState(() {
                            isExerciseStarted = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[100],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(
        context: context,
        currentRoute: 'breath',
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        const SizedBox(height: 30),
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
          color: isSelected ? Colors.pink[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.pink[100]! : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.pink[100]!.withValues(alpha:0.3),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.pink[700] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.pink[300],
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
        Text(
          stageText,
          style: const TextStyle(
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
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              width: 200 + (_animationController.value * 100),
              height: 200 + (_animationController.value * 100),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink[100]!.withValues(alpha:0.5),
                    spreadRadius: 1,
                    blurRadius: 15 * _animationController.value,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 180 + (_animationController.value * 80),
                  height: 180 + (_animationController.value * 80),
                  decoration: BoxDecoration(
                    color: Colors.pink[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStageIcon(state.stage),
                    color: Colors.white,
                    size: 40 + (_animationController.value * 20),
                  ),
                ),
              ),
            );
          },
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
        return 'Rest';
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
}