import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neon Fluid Player',
      theme: ThemeData.dark(),
      home: const NeonPlayerScreen(),
    );
  }
}

class NeonPlayerScreen extends StatefulWidget {
  const NeonPlayerScreen({super.key});

  @override
  State<NeonPlayerScreen> createState() => _NeonPlayerScreenState();
}

class _NeonPlayerScreenState extends State<NeonPlayerScreen> with TickerProviderStateMixin {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<SongModel> _songs = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;

  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _blobController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _audioPlayer.playingStream.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
    });
  }

  void _requestPermission() async {
    bool permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      await _audioQuery.permissionsRequest();
    }
    List<SongModel> songs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    setState(() {
      _songs = songs;
    });
  }

  void _playSong(String? uri, int index) {
    if (uri == null) return;
    try {
      _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri)));
      _audioPlayer.play();
      _audioPlayer.setSpeed(_playbackSpeed);
      setState(() {
        _currentIndex = index;
      });
    } catch (e) {
      print("Ошибка: $e");
    }
  }

  @override
  void dispose() {
    _blobController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Жидкий неоновый фон
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: 100 + (ui.lerpDouble(-40, 40, _blobController.value) ?? 0),
                    left: 30 + (ui.lerpDouble(-30, 50, _blobController.value) ?? 0),
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFFFF007F), Color(0xFF7928CA)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFF007F).withOpacity(0.5), blurRadius: 90, spreadRadius: 25)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 150 + (ui.lerpDouble(50, -50, _blobController.value) ?? 0),
                    right: 20 + (ui.lerpDouble(-40, 40, _blobController.value) ?? 0),
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00F2FE).withOpacity(0.5), blurRadius: 90, spreadRadius: 25)
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Размытие (Жидкое стекло)
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Интерфейс
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "NEON FLUID PLAYER",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFF00F2FE)),
                ),
                
                if (_songs.isEmpty)
                  const Expanded(
                    child: Center(child: Text("Доступ к музыке не получен или треки не найдены...", style: TextStyle(color: Colors.grey))),
                  )
                else ...[
                  const SizedBox(height: 25),
                  
                  // Стеклянный плеер
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            children: [
                              // Аватарка трека
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF00F2FE).withOpacity(0.4), width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(85),
                                  child: QueryArtworkWidget(
                                    id: _songs[_currentIndex].id,
                                    type: ArtworkType.AUDIO,
                                    nullArtworkWidget: const Icon(Icons.music_note, size: 70, color: Color(0xFF00F2FE)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              
                              Text(
                                _songs[_currentIndex].title,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                _songs[_currentIndex].artist ?? "Неизвестный",
                                maxLines: 1,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 15),
                              
                              // Ползунок замедления
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.slow_motion_video, color: Colors.grey, size: 16),
                                  const SizedBox(width: 5),
                                  Text("Скорость: ${_playbackSpeed.toStringAsFixed(1)}x", style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              Slider(
                                value: _playbackSpeed,
                                min: 0.5,
                                max: 1.5,
                                divisions: 10,
                                activeColor: const Color(0xFF00F2FE),
                                inactiveColor: Colors.white10,
                                onChanged: (value) {
                                  setState(() {
                                    _playbackSpeed = value;
                                    _audioPlayer.setSpeed(_playbackSpeed);
                                  });
                                },
                              ),

                              // Кнопки
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous, size: 32),
                                    onPressed: _currentIndex > 0 ? () => _playSong(_songs[_currentIndex - 1].uri, _currentIndex - 1) : null,
                                  ),
                                  const SizedBox(width: 15),
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: const Color(0xFF00F2FE),
                                    child: IconButton(
                                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 30, color: Colors.black),
                                      onPressed: () {
                                        if (_isPlaying) {
                                          _audioPlayer.pause();
                                        } else {
                                          if (_songs.isNotEmpty) _playSong(_songs[_currentIndex].uri, _currentIndex);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  IconButton(
                                    icon: const Icon(Icons.skip_next, size: 32),
                                    onPressed: _currentIndex < _songs.length - 1 ? () => _playSong(_songs[_currentIndex + 1].uri, _currentIndex + 1) : null,
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  
                  // Плейлист
                  Expanded(
                    child: ListView.builder(
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_songs[index].title, maxLines: 1, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(_songs[index].artist ?? "Неизвестен", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          leading: QueryArtworkWidget(
                            id: _songs[index].id,
                            type: ArtworkType.AUDIO,
                            nullArtworkWidget: const Icon(Icons.music_note, color: Colors.grey, size: 20),
                          ),
                          trailing: _currentIndex == index && _isPlaying 
                            ? const Icon(Icons.volume_up, color: Color(0xFF00F2FE)) 
                            : null,
                          onTap: () => _playSong(_songs[index].uri, index),
                        );
                      },
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
