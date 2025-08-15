import 'package:flutter/material.dart';

class ZoomControls extends StatelessWidget {
  /// Callback for when the zoom in button is pressed
  final VoidCallback onScaleUp;

  /// Callback for when the zoom out button is pressed
  final VoidCallback onScaleDown;

  /// Constructor for the ZoomControls widget
  const ZoomControls({
    Key? key,
    required this.onScaleUp,
    required this.onScaleDown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom in button
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white),
            onPressed: onScaleUp,
            tooltip: 'Zoom in (increase scale by 10%)',
          ),
          const SizedBox(height: 4),
          // Zoom out button
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white),
            onPressed: onScaleDown,
            tooltip: 'Zoom out (decrease scale by 10%)',
          ),
        ],
      ),
    );
  }
}
