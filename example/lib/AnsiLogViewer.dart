import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ansicolor/ansicolor.dart';

class AnsiLogViewer extends StatelessWidget {
  final String logText;
  const AnsiLogViewer(this.logText, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = logText.split('\n');

    return Container(
      color: Colors.white10,
      child: lines.isEmpty
          ? const Center(
        child: Text(
          "empty logs",
          style: TextStyle(color: Colors.black),
        ),
      )
          : ListView.builder(
            itemCount: lines.length,
            itemBuilder: (context, index) {

              final line = lines[index];
              return Text(
                line,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              );
            }


      ),
    );
  }

}