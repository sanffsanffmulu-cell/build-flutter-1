import 'package:flutter/material.dart';

class TouchEffect extends StatefulWidget {
  final Widget child;
  
  const TouchEffect({Key? key, required this.child}) : super(key: key);

  @override
  State<TouchEffect> createState() => _TouchEffectState();
}

class _TouchEffectState extends State<TouchEffect> {
  final List<TouchPoint> _touchPoints = [];

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _addTouchPoint(event.localPosition, event.timeStamp);
      },
      onPointerMove: (event) {
        _addTouchPoint(event.localPosition, event.timeStamp);
      },
      child: Stack(
        children: [
          widget.child,
          ..._touchPoints.map((point) => _buildTouchEffect(point)),
        ],
      ),
    );
  }

  void _addTouchPoint(Offset position, Duration timestamp) {
    final newPoint = TouchPoint(
      id: DateTime.now().millisecondsSinceEpoch,
      position: position,
      createdAt: timestamp,
    );
    
    setState(() {
      _touchPoints.add(newPoint);
    });
    
    // Hapus efek setelah 0.5 detik
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _touchPoints.removeWhere((point) => point.id == newPoint.id);
        });
      }
    });
  }

  Widget _buildTouchEffect(TouchPoint point) {
    return Positioned(
      left: point.position.dx - 50,
      top: point.position.dy - 50,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.5, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: 1.0 - (scale - 0.5) / 0.5,
              child: Image.asset(
                'assets/images/epep.png',  // Sesuaikan path gambar Anda
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

class TouchPoint {
  final int id;
  final Offset position;
  final Duration createdAt;
  
  TouchPoint({
    required this.id,
    required this.position,
    required this.createdAt,
  });
}