import 'package:flutter/material.dart';
import 'package:whatsapp_flutter/src/constants/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  final String username;

  const TypingIndicator({required this.username});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    )..repeat();

    _animation1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.33, curve: Curves.easeInOut),
      ),
    );

    _animation2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.33, 0.66, curve: Curves.easeInOut),
      ),
    );

    _animation3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.66, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.username} está escribiendo...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(_animation1),
              SizedBox(width: 6),
              _buildDot(_animation2),
              SizedBox(width: 6),
              _buildDot(_animation3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot(Animation<double> animation) {
    return ScaleTransition(
      scale: animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
