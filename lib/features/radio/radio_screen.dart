import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  static const Color _brand = Color(0xFF8B1D76);

  final AudioPlayer _player = AudioPlayer();
  int _currentIndex = 0;
  double _volume = 0.8;

  final List<Map<String, String>> _stations = [
    {
      'name': 'BBC World Service',
      'url': 'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service',
    },
    {
      'name': 'Classic FM',
      'url': 'https://media-ice.musicradio.com/ClassicFMMP3',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _player.setUrl(_stations[_currentIndex]['url']!);
      await _player.setVolume(_volume);
    } catch (e) {
      debugPrint('Error initializing player: $e');
    }
  }

  Future<void> _togglePlay() async {
    try {
      if (_player.playing) {
        await _player.stop();
      } else {
        await _player.play();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Play error: $e');
    }
  }

  Future<void> _changeStation(int newIndex) async {
    try {
      _currentIndex = newIndex;
      await _player.setUrl(_stations[_currentIndex]['url']!);
      if (_player.playing) {
        await _player.play();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Station change error: $e');
    }
  }

  void _nextStation() {
    final next = (_currentIndex + 1) % _stations.length;
    _changeStation(next);
  }

  void _previousStation() {
    final prev = (_currentIndex - 1 + _stations.length) % _stations.length;
    _changeStation(prev);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Color(0xFF1A0E18),
              _brand,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.radio, color: Colors.white),
                    const Text(
                      'TIMVENI RADIO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _player.playing
                            ? Icons.power_settings_new
                            : Icons.power_settings_new_outlined,
                        color: Colors.white,
                      ),
                      onPressed: _togglePlay,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _stations[_currentIndex]['name']!,
                style: const TextStyle(
                  color: _brand,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData &&
                      snapshot.data!.processingState ==
                          ProcessingState.buffering) {
                    return const CircularProgressIndicator(color: Colors.white);
                  }
                  return const SizedBox(height: 24);
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _brand.withOpacity(0.3),
                  ),
                  child: Icon(
                    _player.playing ? Icons.pause : Icons.play_arrow,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.skip_previous,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: _previousStation,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: _nextStation,
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, color: Colors.white),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        min: 0,
                        max: 1,
                        activeColor: _brand,
                        inactiveColor: Colors.white24,
                        onChanged: (value) async {
                          setState(() => _volume = value);
                          await _player.setVolume(_volume);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Share.share(
                    'Listen live to ${_stations[_currentIndex]['name']} on Timveni Nkhani App!',
                  );
                },
                child: const Text(
                  'SHARE',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
