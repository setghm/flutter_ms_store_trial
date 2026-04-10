import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ms_store_trial/ms_store_trial.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  MsStoreAppLicense? _license;
  late final StreamSubscription<MsStoreAppLicense> _licenseUpdates;

  @override
  void initState() {
    super.initState();

    // Subscribe to license updates first.
    _licenseUpdates = MsStoreTrial.instance.licenseStream.listen((event) {
      _license = event;
      if (mounted) {
        setState(() {
          // Update UI.
        });
      }
    });

    // IMPORTANT: Restore user app license.
    MsStoreTrial.instance.restoreLicense();
  }

  @override
  void dispose() {
    _licenseUpdates.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isFullVersion = _license != null ? !(_license!.isTrial) : false;
    final isTrialTimeLimited = _license?.hasTrialPeriod ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Example'),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 40,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isFullVersion
                ? ColorScheme.of(context).primaryContainer
                : ColorScheme.of(context).tertiaryContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: isFullVersion
                  ? ColorScheme.of(context).onPrimaryContainer
                  : ColorScheme.of(context).onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                child: isFullVersion
                ? const Text('Status: Full version')
                : const Text('Status: Trial version'),
              ),
            ),

            if (isTrialTimeLimited)
              _TrialCountdown(initialDuration: _license!.trialTimeRemaining),

            OutlinedButton.icon(
              onPressed: isFullVersion
                ? () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('You\'re premium'),
                    content: Text('You\'ve unlocked the power of the full version'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Done')
                      ),
                    ],
                  ),
                )
                : null,
              icon: isFullVersion
                ? const Icon(Icons.lock_open)
                : const Icon(Icons.lock),
              label: isFullVersion
                ? const Text('Unlocked button')
                : const Text('Locked button'),
            ),

            if (!isFullVersion)
              OutlinedButton.icon(
                onPressed: () async {
                  final response = await MsStoreTrial.instance.requestPurchase();
                  debugPrint('Purchase status: ${response.status}, error: ${response.extendedError}');
                  // If success, license update will be delivered through the license stream.
                },
                icon: const Icon(Icons.shopping_cart),
                label: Text('Purchase full version'),
              ),
          ]
        ),
      ),
    );
  }
}

class _TrialCountdown extends StatefulWidget {
  final Duration initialDuration;

  const _TrialCountdown({super.key, required this.initialDuration});

  @override
  State<StatefulWidget> createState() => _TrialCountdownState();
}

class _TrialCountdownState extends State<_TrialCountdown> {
  late Duration _remainingTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.initialDuration;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0 && mounted) {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = twoDigits(duration.inDays);
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$days:$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_timer == null) {
      return const SizedBox.shrink();
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Your trial ends in '),
          TextSpan(
            text: _formatDuration(_remainingTime),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
