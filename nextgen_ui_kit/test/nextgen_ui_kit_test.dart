import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextgen_ui_kit/nextgen_ui_kit.dart';

void main() {
  group('FuturisticLoadingIndicator Tests', () {
    testWidgets('renders dual rings style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FuturisticLoadingIndicator(
                size: 60,
                color: Colors.cyanAccent,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FuturisticLoadingIndicator), findsOneWidget);
    });

    testWidgets('renders cyberOrbit and pulsingCore presets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FuturisticLoadingIndicator.cyberOrbit(size: 40),
                FuturisticLoadingIndicator.pulsingCore(size: 40),
                FuturisticLoadingIndicator.radarScanner(size: 40),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FuturisticLoadingIndicator), findsNWidgets(3));
    });

    testWidgets('renders FuturisticLinearLoadingIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FuturisticLinearLoadingIndicator(
              value: 0.6,
              color: Colors.tealAccent,
            ),
          ),
        ),
      );

      expect(find.byType(FuturisticLinearLoadingIndicator), findsOneWidget);
    });
  });

  group('Progress Indicator Tests', () {
    testWidgets('renders CustomProgressIndicator with value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomProgressIndicator(
              progress: 0.75,
              progressBarName: 'Storage',
              animated: false,
            ),
          ),
        ),
      );

      expect(find.byType(CustomProgressIndicator), findsOneWidget);
      expect(find.text('Storage'), findsOneWidget);
    });

    testWidgets('renders AdvancedProgressIndicator in circular mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AdvancedProgressIndicator(
                progress: 0.5,
                shape: ProgressShape.circular,
                labelStyle: ProgressLabelStyle.percentage,
                animated: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AdvancedProgressIndicator), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('Metric Indicators Tests', () {
    testWidgets('renders MetricBadge and handles tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MetricBadge.success(
                label: 'Operational',
                value: '99.9%',
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Operational'), findsOneWidget);
      expect(find.text('99.9%'), findsOneWidget);

      await tester.tap(find.byType(MetricBadge));
      expect(tapped, isTrue);
    });

    testWidgets('renders PulseIndicator with label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: PulseIndicator(
                label: 'LIVE',
                color: Colors.red,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PulseIndicator), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('renders TrendIndicator with delta value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TrendIndicator(
                value: '+18.4%',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TrendIndicator), findsOneWidget);
      expect(find.text('+18.4%'), findsOneWidget);
    });

    testWidgets('renders MetricCard with title, value, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MetricCard(
              title: 'Total Revenue',
              value: '128,450',
              subtitle: 'vs last quarter',
              trend: '+12.5%',
              icon: Icons.attach_money_rounded,
            ),
          ),
        ),
      );

      expect(find.text('Total Revenue'), findsOneWidget);
      expect(find.text('128,450'), findsOneWidget);
      expect(find.text('vs last quarter'), findsOneWidget);
      expect(find.text('+12.5%'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money_rounded), findsOneWidget);
    });

    testWidgets('renders MetricIndicatorGroup with children', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetricIndicatorGroup(
              children: [
                MetricBadge.info(label: 'Alpha'),
                MetricBadge.warning(label: 'Beta'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MetricIndicatorGroup), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });
  });

  group('CustomTextField Tests', () {
    testWidgets('accepts input and reflects text', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              controller: controller,
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
            ),
          ),
        ),
      );

      expect(find.byType(CustomTextField), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'user@example.com');
      expect(controller.text, 'user@example.com');
    });

    testWidgets('supports password and email factory presets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomTextField.email(),
                CustomTextField.password(),
                CustomTextField.search(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CustomTextField), findsNWidgets(3));
    });
  });

  group('GlobalSyncStatusBanner & Feedback Tests', () {
    testWidgets('displays banner for offline state with config', (tester) async {
      final notifier = ValueNotifier<ServerSyncState>(ServerSyncState.offline);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlobalSyncStatusBanner(
              syncStateNotifier: notifier,
              graceDuration: Duration.zero,
              config: const SyncBannerConfig(
                offlineTitle: 'Offline Mode Active',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(GlobalSyncStatusBanner), findsOneWidget);
      expect(find.text('Offline Mode Active'), findsOneWidget);
    });

    testWidgets('SnackbarHost wraps children properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SnackbarHost(
            child: Scaffold(
              body: Center(child: Text('Main Content')),
            ),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.byType(AppSnackbar), findsOneWidget);
    });
  });

  group('AppLogger Tests', () {
    test('logs formatted message without throwing', () {
      expect(
        () {
          AppLogger.init();
          AppLogger.d('Debug test message', tag: 'TEST');
          AppLogger.i('Info test message', tag: 'TEST');
          AppLogger.w('Warning test message', tag: 'TEST');
          AppLogger.e('Error test message', tag: 'TEST');
          'String log'.logInfo();
        },
        returnsNormally,
      );
    });
  });
}
