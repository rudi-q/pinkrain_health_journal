import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/util/helpers.dart';
import '../../core/widgets/bottom_navigation.dart';

class MeditationTrack {
  final String title;
  final String subtitle;
  final String description;
  final String assetPath;
  final String category;

  MeditationTrack({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.assetPath,
    required this.category,
  });
}

class GuidedMeditationScreen extends StatefulWidget {
  const GuidedMeditationScreen({super.key});

  @override
  GuidedMeditationScreenState createState() => GuidedMeditationScreenState();
}

class GuidedMeditationScreenState extends State<GuidedMeditationScreen> with WidgetsBindingObserver {
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  Duration _duration = Duration(minutes: 5);
  MeditationTrack? _nowPlaying;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPlayerInitialized = false;

  final List<MeditationTrack> tracks = [
    // Self-Acceptance
    MeditationTrack(
      title: "The Voice You Needed",
      subtitle: "5 min grounding",
      description: "Calm your nerves",
      assetPath: "assets/audio-tracks/The_Voice_You_Needed.m4a",
      category: "Self-Acceptance",
    ),
    MeditationTrack(
      title: "You're Not a Burden",
      subtitle: "5 min grounding",
      description: "You're allowed to exist",
      assetPath: "assets/audio-tracks/Youre_Not_a_Burden.m4a", // Sanitized path
      category: "Self-Acceptance",
    ),
    MeditationTrack(
      title: "The Quiet Part of You Still Counts",
      subtitle: "5 min grounding",
      description: "Even your silence is worthy",
      assetPath: "assets/audio-tracks/The_Quiet_Part_of_You_Still_Counts.m4a",
      category: "Self-Acceptance",
    ),

    // Rest & Stillness
    MeditationTrack(
      title: "This Isn't Laziness",
      subtitle: "5 min grounding",
      description: "Understand your stillness",
      assetPath: "assets/audio-tracks/This_Isnt_Laziness.m4a", // Sanitized path
      category: "Rest & Stillness",
    ),
    MeditationTrack(
      title: "You Don't Have to Earn Rest",
      subtitle: "5 min grounding",
      description: "Rest is your right",
      assetPath: "assets/audio-tracks/You_Dont_Have_to_Earn_Rest.m4a", // Sanitized path
      category: "Rest & Stillness",
    ),

    // Emotional Processing
    MeditationTrack(
      title: "What You Feel is Real",
      subtitle: "5 min grounding",
      description: "Affirm your inner truth",
      assetPath: "assets/audio-tracks/What_You_Feel_is_Real.m4a",
      category: "Emotional Processing",
    ),
    MeditationTrack(
      title: "For When You're Numb and Don't Know Why",
      subtitle: "5 min grounding",
      description: "Sit with the fog",
      assetPath: "assets/audio-tracks/For_When_Youre_Numb_and_Dont_Know_Why.m4a", // Sanitized path
      category: "Emotional Processing",
    ),
    MeditationTrack(
      title: "The Anger You've Been Swallowing",
      subtitle: "5 min grounding",
      description: "Let it surface safely",
      assetPath: "assets/audio-tracks/The_Anger_Youve_Been_Swallowing.m4a", // Sanitized path
      category: "Emotional Processing",
    ),

    // Grief & Loss
    MeditationTrack(
      title: "Grief That Doesn't Have a Name",
      subtitle: "5 min grounding",
      description: "Hold space for the unnamed",
      assetPath: "assets/audio-tracks/Grief_That_Doesnt_Have_a_Name.m4a", // Sanitized path
      category: "Grief & Loss",
    ),
    MeditationTrack(
      title: "When You Miss Who You Used to Be",
      subtitle: "5 min grounding",
      description: "Grieve your old self gently",
      assetPath: "assets/audio-tracks/When_You_Miss_Who_You_Used_to_Be.m4a",
      category: "Grief & Loss",
    ),
  ];

  // Get unique categories from tracks
  List<String> get categories => tracks.map((track) => track.category).toSet().toList();

  // Get tracks for a specific category
  List<MeditationTrack> getTracksByCategory(String category) {
    return tracks.where((track) => track.category == category).toList();
  }

  @override
  void initState() {
    super.initState();
    // Register observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Initialize the audio player
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Only initialize if not already initialized
    if (_isPlayerInitialized) {
      devPrint("[DEBUG_LOG] Player already initialized, skipping initialization");
      return;
    }

    devPrint("[DEBUG_LOG] Initializing audio player");
    try {
      _player = AudioPlayer();
      _isPlayerInitialized = true;
      devPrint("[DEBUG_LOG] AudioPlayer instance created successfully");

      // Set up position stream listener
      devPrint("[DEBUG_LOG] Setting up position stream listener");
      _player.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      // Set up duration stream listener
      devPrint("[DEBUG_LOG] Setting up duration stream listener");
      _player.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() => _duration = duration);
        }
      });

      // Set up player completion listener
      devPrint("[DEBUG_LOG] Setting up player state stream listener");
      _player.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          devPrint("[DEBUG_LOG] Track completed, checking for next track");
          // Auto-play next track when current one completes
          if (_nowPlaying != null) {
            final currentIndex = tracks.indexOf(_nowPlaying!);
            if (currentIndex < tracks.length - 1) {
              devPrint("[DEBUG_LOG] Auto-playing next track");
              _playTrack(tracks[currentIndex + 1]);
            } else {
              devPrint("[DEBUG_LOG] No more tracks to play");
            }
          }
        }
      });

      // Handle errors
      devPrint("[DEBUG_LOG] Setting up playback event stream error listener");
      _player.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace st) {
          devPrint("[DEBUG_LOG] Playback event stream error: $e");
          if (e is PlayerException) {
            devPrint("[DEBUG_LOG] PlayerException: code=${e.code}, message=${e.message}");
            setState(() {
              _errorMessage = "Error code: ${e.code}, message: ${e.message}";
            });
          } else {
            setState(() {
              _errorMessage = "An error occurred: $e";
            });
          }
        }
      );

      devPrint("[DEBUG_LOG] Audio player initialized successfully");
    } catch (e) {
      devPrint("[DEBUG_LOG] Failed to initialize audio player: $e");
      setState(() {
        _isPlayerInitialized = false;
        _errorMessage = "Failed to initialize audio player: $e";
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is in background, pause playback
      _player.pause();
    }
  }

  Future<void> _playTrack(MeditationTrack track) async {
    if (!_isPlayerInitialized) {
      setState(() {
        _errorMessage = "Audio player is not initialized. Please restart the app.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Track the retry count
    int retryCount = 0;
    const int maxRetries = 3;

    Future<bool> attemptLoadTrack() async {
      try {
        // 1. Stop any current playback
        await _player.stop();

        // 2. Reset position state
        setState(() {
          _position = Duration.zero;
          _duration = Duration.zero;
        });

        // 3. Load the new asset and seek to start
        devPrint("[DEBUG_LOG] Loading track: ${track.title} from ${track.assetPath}");
        try {
          // Sanitize the asset path by replacing apostrophes with empty strings
          // This is necessary because Flutter's asset loader has issues with apostrophes
          String sanitizedPath = track.assetPath.replaceAll("'", "");
          devPrint("[DEBUG_LOG] Sanitized asset path: $sanitizedPath");

          await _player.setAsset(sanitizedPath);
          devPrint("[DEBUG_LOG] Asset loaded successfully");
          await _player.seek(Duration.zero);
          devPrint("[DEBUG_LOG] Seek completed successfully");
          return true;
        } catch (e) {
          devPrint("[DEBUG_LOG] Error loading track (attempt ${retryCount + 1}): $e");
          if (e.toString().contains("Unable to load")) {
            devPrint("[DEBUG_LOG] Asset loading error - file may not exist or be inaccessible");
          } else if (e.toString().contains("format")) {
            devPrint("[DEBUG_LOG] Format error - file may be corrupted or in unsupported format");
          }
          return false;
        }
      } catch (e) {
        devPrint("[DEBUG_LOG] Unexpected error in attemptLoadTrack (attempt ${retryCount + 1}): $e");
        return false;
      }
    }

    while (retryCount < maxRetries) {
      bool success = await attemptLoadTrack();
      if (success) {
        // Track loaded successfully
        setState(() {
          _nowPlaying = track;
          _isLoading = false;
        });

        try {
          devPrint("[DEBUG_LOG] Starting playback for track: ${track.title}");
          await _player.play();
          devPrint("[DEBUG_LOG] Playback started successfully");
          return; // Exit the method if successful
        } catch (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Failed to play track: $e";
          });
          devPrint("[DEBUG_LOG] Error playing track: $e");
          return; // Exit on play error
        }
      } else {
        // Track failed to load, increment retry count
        retryCount++;
        devPrint("[DEBUG_LOG] Track loading attempt $retryCount failed");

        if (retryCount < maxRetries) {
          // Wait before retrying (exponential backoff)
          int delayMs = 500 * retryCount;
          devPrint("[DEBUG_LOG] Waiting ${delayMs}ms before retry ${retryCount + 1}");
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
    }

    // If we get here, all retries failed
    devPrint("[DEBUG_LOG] All $maxRetries attempts to load track failed: ${track.title}");
    setState(() {
      _isLoading = false;
      _errorMessage = "Failed to load track (${track.title}) after multiple attempts. Please try again later.";
    });

    // Check if the asset file exists in the assets directory
    devPrint("[DEBUG_LOG] Asset path that failed: ${track.assetPath}");
    devPrint("[DEBUG_LOG] Please verify this file exists in the assets directory and is correctly referenced in pubspec.yaml");
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    // Release audio resources
    if (_isPlayerInitialized) {
      _player.stop();
      _player.dispose();
    }

    super.dispose();
  }

  Widget _buildTrackCard(MeditationTrack track) {
    final bool isPlaying = _nowPlaying?.title == track.title;

    return GestureDetector(
      onTap: () {
        if (_isLoading) return; // Prevent multiple taps while loading
        _playTrack(track);
      },
      child: Container(
        padding: EdgeInsets.all(14),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        decoration: BoxDecoration(
          color: isPlaying ? Colors.pink[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isPlaying 
            ? Border.all(color: Colors.pink[200]!, width: 1.5) 
            : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPlaying ? Colors.pink[300] : Colors.pink[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.music_note : Icons.spa, 
                color: Colors.white, 
                size: 20
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title, 
                    style: TextStyle(
                      fontSize: 15, 
                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                      color: isPlaying ? Colors.pink[700] : Colors.black,
                    )
                  ),
                  SizedBox(height: 2),
                  Text(
                    track.subtitle, 
                    style: TextStyle(
                      color: isPlaying ? Colors.pink[400] : Colors.grey.shade700,
                      fontSize: 13,
                    )
                  ),
                  SizedBox(height: 2),
                  Text(
                    track.description, 
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    )
                  ),
                ],
              ),
            ),
            Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline, 
              color: isPlaying ? Colors.pink[400] : Colors.pink[200], 
              size: 28
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category) {
    final categoryTracks = getTracksByCategory(category);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
            child: Text(
              category,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          ...categoryTracks.map((track) => _buildTrackCard(track)),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildPlayer() {
    // Show error message if there is one
    if (_errorMessage != null) {
      // Determine if this is a track loading error or player initialization error
      bool isTrackError = _errorMessage!.contains("Failed to load track") || 
                          _errorMessage!.contains("Failed to play track");

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(height: 8),
            Text(
              isTrackError ? "Track Playback Error" : "Audio Player Error",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
            ),
            SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 14, color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            if (isTrackError && _nowPlaying != null)
              Text(
                "Track: ${_nowPlaying!.title}",
                style: TextStyle(fontSize: 14, color: Colors.red[700], fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                    if (isTrackError && _nowPlaying != null) {
                      // Retry playing the current track
                      _playTrack(_nowPlaying!);
                    } else {
                      // Reinitialize the player
                      _initializePlayer();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[100],
                    foregroundColor: Colors.red[700],
                  ),
                  child: Text("Retry"),
                ),
                if (isTrackError)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _nowPlaying = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[700],
                      ),
                      child: Text("Dismiss"),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    // Show loading indicator
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[300]!),
            ),
            SizedBox(height: 16),
            Text(
              "Loading audio...",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    // No track selected
    if (_nowPlaying == null) return SizedBox.shrink();

    // Normal player UI
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Now Playing", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(_nowPlaying!.title, style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),

          // Elapsed / Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_position), style: TextStyle(fontSize: 12)),
              Text(_formatDuration(_duration), style: TextStyle(fontSize: 12)),
            ],
          ),

          // Draggable slider
          Slider(
            value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
            max: _duration.inMilliseconds.toDouble(),
            min: 0,
            activeColor: Colors.pink.shade300,
            inactiveColor: Colors.pink.shade100,
            onChanged: (value) {
              if (_isPlayerInitialized) {
                final newPos = Duration(milliseconds: value.toInt());
                _player.seek(newPos);
              }
            },
          ),

          SizedBox(height: 4),

          // Prev / Play / Next controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous, size: 32),
                color: Colors.pink.shade300,
                onPressed: () {
                  if (_isPlayerInitialized && _nowPlaying != null) {
                    final currentIndex = tracks.indexOf(_nowPlaying!);
                    if (currentIndex > 0) {
                      _playTrack(tracks[currentIndex - 1]);
                    }
                  }
                },
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  _isPlayerInitialized && _player.playing 
                    ? Icons.pause_circle_filled 
                    : Icons.play_circle_filled,
                  size: 48,
                ),
                color: Colors.pink.shade300,
                onPressed: () {
                  if (_isPlayerInitialized) {
                    _player.playing ? _player.pause() : _player.play();
                  }
                },
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.skip_next, size: 32),
                color: Colors.pink.shade300,
                onPressed: () {
                  if (_isPlayerInitialized && _nowPlaying != null) {
                    final currentIndex = tracks.indexOf(_nowPlaying!);
                    if (currentIndex < tracks.length - 1) {
                      _playTrack(tracks[currentIndex + 1]);
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Your Peace',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select a meditation track from the categories below to begin your mindfulness journey.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Guided Meditation',
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: 20),
              children: [
                _buildHeader(),
                ...categories.map((category) => _buildCategorySection(category)),
              ],
            ),
          ),
          _buildPlayer(),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(context: context, currentRoute: 'meditation'),
    );
  }
}
