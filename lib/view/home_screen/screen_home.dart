import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  List<String> ringtones = [];
  AudioPlayer? audioPlayer;
  bool isPlaying = false;
  String? currentPlayingRingtone;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    requestPermissions();
  }

  @override
  void dispose() {
    audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      if (kDebugMode) {
        print('Storage permission granted: ${status.isGranted}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting storage permission: $e');
      }
    }
  }

  Future<void> playRingtone(String ringtone) async {
    final path =
        '/system/media/audio/ringtones/$ringtone.ogg'; // Ensure .ogg is added to the path
    //    print('Attempting to play ringtone from path: $path');
    try {
      if (isPlaying && currentPlayingRingtone == ringtone) {
        //   print('Stopping current player...');
        await audioPlayer?.stop();
        setState(() {
          isPlaying = false;
        });
      } else {
        //  print('Playing ringtone...');
        await audioPlayer?.play(DeviceFileSource(path));
        setState(() {
          isPlaying = true;
          currentPlayingRingtone = ringtone;
        });
        audioPlayer?.onPlayerComplete.listen((_) {
          setState(() {
            isPlaying = false;
            currentPlayingRingtone = null;
          });
          //   print('Player finished playing.');
        });
        //  print('Player started.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing ringtone: $e');
      }
      setState(() {
        isPlaying = false;
        currentPlayingRingtone = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringtone Player'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          children: [
            if (ringtones.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemBuilder: (context, index) {
                    final ringtone = ringtones[index];
                    return Card(
                      child: ListTile(
                        title: Text(ringtone),
                        onTap: () => playRingtone(ringtone),
                      ),
                    );
                  },
                  itemCount: ringtones.length,
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                const channel = MethodChannel('flutter_channel');
                try {
                  final List<dynamic> result =
                      await channel.invokeMethod('getRingtones');
                  setState(() {
                  //   print(result);
                    ringtones = result.cast<String>();
                    // print('Ringtones loaded: $ringtones');
                  });
                } on PlatformException catch (e) {
                  if (kDebugMode) {
                    print("Failed to get ringtones: '${e.message}'.");
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('Unexpected error: $e');
                  }
                }
              },
              child: const Text('Get Ringtones'),
            ),
          ],
        ),
      ),
    );
  }
}
