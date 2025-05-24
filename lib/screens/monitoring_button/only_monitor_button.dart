import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class MonitorButton extends StatefulWidget {
  final bool isNight;

  const MonitorButton({super.key, required this.isNight});

  @override
  State<MonitorButton> createState() => _MonitorButtonState();
}

class _MonitorButtonState extends State<MonitorButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool isMonitoring = false;
  final service = FlutterBackgroundService();

  @override
  void initState() {
    super.initState();
    _loadMonitoringState();

    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadMonitoringState() async {
    final prefs = await SharedPreferences.getInstance();
    final serviceStatus = await service.isRunning();

    setState(() {
      isMonitoring = serviceStatus;
    });

    await prefs.setBool('isMonitoring', isMonitoring);

    if (isMonitoring) {
      _animationController.repeat(reverse: true);
    }
  }

  Future<void> _toggleMonitoring() async {
    final serviceRunning = await service.isRunning();

    setState(() {
      isMonitoring = !serviceRunning;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMonitoring', isMonitoring);

    if (isMonitoring) {
      _animationController.repeat(reverse: true);
      await service.startService();
    } else {
      _animationController.stop();
       service.invoke('stopService');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleMonitoring,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isMonitoring ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMonitoring
                        ? (widget.isNight
                        ? Colors.indigo[400]
                        : const Color(0xFF4285F4))
                        : Colors.grey[300],
                    boxShadow: [
                      BoxShadow(
                        color: (isMonitoring
                            ? (widget.isNight
                            ? Colors.indigo[400]
                            : const Color(0xFF4285F4))
                            : Colors.grey[400])!
                            .withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isMonitoring
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: isMonitoring ? Colors.white : Colors.grey[600],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isMonitoring ? 'Monitoring' : 'Start',
                        style: TextStyle(
                          color:
                          isMonitoring ? Colors.white : Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isMonitoring
              ? 'We\'ll notify you when bad weather is detected'
              : 'Tap to start monitoring the weather',
          style: TextStyle(
            color: widget.isNight ? Colors.white70 : const Color(0xFF4D6278),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}