import 'dart:async';
import 'package:flutter/material.dart';
import 'package:locally/common/routes/app_routes.dart';

class GifSplash extends StatefulWidget {
  const GifSplash({super.key});

  @override
  GifSplashState createState() => GifSplashState();
}

class GifSplashState extends State<GifSplash> {
  @override
  void initState() {
    super.initState();
    // ... in your GifSplashState initState method
    Timer(const Duration(seconds: 0), () {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.appGate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // same as native splash
      body: Image.asset(
        'assets/splash/final.gif', // your GIF
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,

        // --------------------------
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:locally/common/routes/app_routes.dart';

// class GifSplash extends StatefulWidget {
//   const GifSplash({super.key});

//   @override
//   State<GifSplash> createState() => _GifSplashState();
// }

// class _GifSplashState extends State<GifSplash> {
//   late VideoPlayerController _controller;

//   @override
//   void initState() {
//     super.initState();

//     _controller = VideoPlayerController.asset(
//       'assets/splash/splash_screen.mp4',
//     )
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       });

//     _controller.addListener(() {
//       if (_controller.value.position >= _controller.value.duration) {
//         Navigator.pushReplacementNamed(context, AppRoutes.appGate);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: _controller.value.isInitialized
//           ? SizedBox.expand(
//               child: FittedBox(
//                 fit: BoxFit.cover,
//                 child: SizedBox(
//                   width: _controller.value.size.width,
//                   height: _controller.value.size.height,
//                   child: VideoPlayer(_controller),
//                 ),
//               ),
//             )
//           : const SizedBox(),
//     );
//   }
// }
