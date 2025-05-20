import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/appbar.dart';
import '../../core/widgets/bottom_navigation.dart';

class MeditationTrack {
  final String title;
  final String subtitle;
  final String description;
  final String assetPath;

  MeditationTrack({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.assetPath,
  });
}

class GuidedMeditationScreen extends StatefulWidget {
  const GuidedMeditationScreen({super.key});

  @override
  GuidedMeditationScreenState createState() => GuidedMeditationScreenState();
}

class GuidedMeditationScreenState extends State<GuidedMeditationScreen> {
  final AudioPlayer _player = AudioPlayer();
  Duration _position = Duration.zero;
  Duration _duration = Duration(minutes: 5);
  MeditationTrack? _nowPlaying;

  final List<MeditationTrack> tracks = [
    MeditationTrack(
      title: "The Voice You Needed",
      subtitle: "5 min grounding",
      description: "Calm your nerves",
      assetPath: "assets/audio-tracks/The_Voice_You_Needed.m4a",
    ),
    MeditationTrack(
      title: "You’re Not a Burden",
      subtitle: "5 min grounding",
      description: "You’re allowed to exist",
      assetPath: "assets/audio-tracks/You’re_Not_a_Burden.m4a",
    ),
    MeditationTrack(
      title: "This Isn’t Laziness",
      subtitle: "5 min grounding",
      description: "Understand your stillness",
      assetPath: "assets/audio-tracks/This_Isn’t_Laziness.m4a",
    ),
    MeditationTrack(
      title: "Grief That Doesn’t Have a Name",
      subtitle: "5 min grounding",
      description: "Hold space for the unnamed",
      assetPath: "assets/audio-tracks/Grief_That_Doesn’t_Have_a_Name.m4a",
    ),
    MeditationTrack(
      title: "You Don’t Have to Earn Rest",
      subtitle: "5 min grounding",
      description: "Rest is your right",
      assetPath: "assets/audio-tracks/You_Don’t_Have_to_Earn_Rest.m4a",
    ),
    MeditationTrack(
      title: "The Quiet Part of You Still Counts",
      subtitle: "5 min grounding",
      description: "Even your silence is worthy",
      assetPath: "assets/audio-tracks/The_Quiet_Part_of_You_Still_Counts.m4a",
    ),
    MeditationTrack(
      title: "What You Feel is Real",
      subtitle: "5 min grounding",
      description: "Affirm your inner truth",
      assetPath: "assets/audio-tracks/What_You_Feel_is_Real.m4a",
    ),
    MeditationTrack(
      title: "For When You’re Numb and Don’t Know Why",
      subtitle: "5 min grounding",
      description: "Sit with the fog",
      assetPath: "assets/audio-tracks/For_When_You’re_Numb_and_Don’t_Know_Why.m4a",
    ),
    MeditationTrack(
      title: "The Anger You’ve Been Swallowing",
      subtitle: "5 min grounding",
      description: "Let it surface safely",
      assetPath: "assets/audio-tracks/The_Anger_You’ve_Been_Swallowing.m4a",
    ),
    MeditationTrack(
      title: "When You Miss Who You Used to Be",
      subtitle: "5 min grounding",
      description: "Grieve your old self gently",
      assetPath: "assets/audio-tracks/When_You_Miss_Who_You_Used_to_Be.m4a",
    ),
  ];

  Future<void> _playTrack(MeditationTrack track) async {
    // 1. Stop any current playback
    await _player.stop();

    // 2. Reset position state (optional, but keeps UI in sync)
    setState(() {
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    // 3. Load the new asset and seek to start
    await _player.setAsset(track.assetPath);
    await _player.seek(Duration.zero);

    // 4. Update nowPlaying and start
    setState(() => _nowPlaying = track);
    _player.play();

    // 5. Listen for updates as before
    _player.positionStream.listen((pos) {
      setState(() => _position = pos);
    });
    _player.durationStream.listen((dur) {
      if (dur != null) setState(() => _duration = dur);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Widget _buildTrackCard(MeditationTrack track) {
    return GestureDetector(
      onTap: () => _playTrack(track),
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.spa, color: Colors.pink.shade200),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(track.subtitle, style: TextStyle(color: Colors.grey.shade700)),
                  Text(track.description, style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildPlayer() {
    if (_nowPlaying == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              final newPos = Duration(milliseconds: value.toInt());
              _player.seek(newPos);
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
                  // find previous track
                  final currentIndex = tracks.indexOf(_nowPlaying!);
                  if (currentIndex > 0) {
                    _playTrack(tracks[currentIndex - 1]);
                  }
                },
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  _player.playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 48,
                ),
                color: Colors.pink.shade300,
                onPressed: () {
                  _player.playing ? _player.pause() : _player.play();
                },
              ),
              SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.skip_next, size: 32),
                color: Colors.pink.shade300,
                onPressed: () {
                  // find next track
                  final currentIndex = tracks.indexOf(_nowPlaying!);
                  if (currentIndex < tracks.length - 1) {
                    _playTrack(tracks[currentIndex + 1]);
                  }
                },
              ),
            ],
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
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 20),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                return _buildTrackCard(tracks[index]);
              },
            ),
          ),
          _buildPlayer(),
        ],
      ),
      bottomNavigationBar: buildBottomNavigationBar(context: context, currentRoute: 'meditation'),
    );
  }
}
