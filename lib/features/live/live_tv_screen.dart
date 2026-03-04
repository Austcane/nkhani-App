import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LiveTvScreen extends StatefulWidget {
  const LiveTvScreen({super.key});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  static const Color _brand = Color(0xFF8B1D76);

  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  int _currentIndex = 0;

  final List<Map<String, String>> _channels = [
    {
      'name': 'Bad Bunny Live',
      'url': 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    },
    {
      'name': 'Timveni',
      'url': 'https://live-hls-web-aje.getaj.net/AJE/index.m3u8',
    },
    {
      'name': 'Zodiak',
      'url': 'https://dwamdstream102.akamaized.net/hls/live/2015525/dwstream102/index.m3u8',
    },
    {
      'name': 'Times',
      'url': 'https://live.france24.com/hls/live/2037222-b/F24_EN_HI_HLS/master.m3u8',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(_channels[_currentIndex]['url']!),
    );

    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      isLive: true,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _changeChannel(int index) async {
    if (index == _currentIndex) return;

    await _videoController.pause();
    await _videoController.dispose();
    _chewieController?.dispose();

    _currentIndex = index;

    await _initializePlayer();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
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
              const SizedBox(height: 20),
              const Text(
                'LIVE TV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _brand.withOpacity(0.6),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _chewieController != null &&
                          _chewieController!
                              .videoPlayerController.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Chewie(controller: _chewieController!),
                        )
                      : const AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _channels[_currentIndex]['name']!,
                style: const TextStyle(
                  color: _brand,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _channels.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 3,
                  ),
                  itemBuilder: (context, index) {
                    final isActive = _currentIndex == index;
                    return GestureDetector(
                      onTap: () => _changeChannel(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isActive ? _brand : Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: _brand.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _channels[index]['name']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
