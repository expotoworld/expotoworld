import 'package:flutter/material.dart';

/// A widget that displays scrolling text in a marquee style
/// The text scrolls continuously and infinitely
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity; // pixels per second
  final double spacing; // space between repeated text

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.velocity = 30.0,
    this.spacing = 40.0,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _spacing;

  @override
  void initState() {
    super.initState();
    _spacing = widget.spacing;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Will be recalculated
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: _MarqueeTextContent(
            text: widget.text,
            style: widget.style,
            velocity: widget.velocity,
            spacing: _spacing,
            controller: _controller,
            containerWidth: constraints.maxWidth,
          ),
        );
      },
    );
  }
}

class _MarqueeTextContent extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity;
  final double spacing;
  final AnimationController controller;
  final double containerWidth;

  const _MarqueeTextContent({
    required this.text,
    this.style,
    required this.velocity,
    required this.spacing,
    required this.controller,
    required this.containerWidth,
  });

  @override
  State<_MarqueeTextContent> createState() => _MarqueeTextContentState();
}

class _MarqueeTextContentState extends State<_MarqueeTextContent> {
  double _textWidth = 0;
  bool _measured = false;

  @override
  Widget build(BuildContext context) {
    // First, measure the text width
    if (!_measured) {
      return Opacity(
        opacity: 0,
        child: _buildTextForMeasurement(),
      );
    }

    // Calculate the total scroll distance (text + spacing)
    final totalWidth = _textWidth + widget.spacing;
    
    // Calculate duration based on velocity
    final durationMs = (totalWidth / widget.velocity * 1000).round();
    
    // Update controller duration if needed
    if (widget.controller.duration?.inMilliseconds != durationMs) {
      widget.controller.duration = Duration(milliseconds: durationMs);
      widget.controller.repeat();
    }

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final offset = widget.controller.value * totalWidth;
        
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // First text instance
              Transform.translate(
                offset: Offset(-offset, 0),
                child: _buildText(),
              ),
              // Second text instance (for seamless loop)
              Transform.translate(
                offset: Offset(totalWidth - offset, 0),
                child: _buildText(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextForMeasurement() {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: widget.text,
              style: widget.style ?? DefaultTextStyle.of(context).style,
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          
          if (mounted) {
            setState(() {
              _textWidth = textPainter.width;
              _measured = true;
            });
          }
        });
        
        return Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
          overflow: TextOverflow.visible,
        );
      },
    );
  }

  Widget _buildText() {
    return Text(
      widget.text,
      style: widget.style,
      maxLines: 1,
      overflow: TextOverflow.visible,
    );
  }
}
