import 'package:flutter/material.dart';
import 'package:hex_toolkit_demo/hex_toolkit_demo.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Hex Toolkit Demo',
      theme: ThemeData(
        // Use a more condensed visual density optimized for mouse
        visualDensity: VisualDensity.compact,
        // Smaller text sizes for condensed UI
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 13),
          bodyMedium: TextStyle(fontSize: 12),
          bodySmall: TextStyle(fontSize: 11),
          titleLarge: TextStyle(fontSize: 16),
          titleMedium: TextStyle(fontSize: 14),
          titleSmall: TextStyle(fontSize: 12),
        ),
        // Compact button styles
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size(60, 30),
          ),
        ),
        // Compact input decoration
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          isDense: true,
        ),
        // Compact slider theme
        sliderTheme: SliderThemeData(
          trackHeight: 2,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
        ),
        // Compact app bar theme
        appBarTheme: AppBarTheme(
          toolbarHeight: 40,
          titleTextStyle: TextStyle(fontSize: 16),
        ),
        // Compact icon theme
        iconTheme: IconThemeData(
          size: 18,
        ),
      ),
      home: HexToolkitDemo(),
    ),
  );
}
