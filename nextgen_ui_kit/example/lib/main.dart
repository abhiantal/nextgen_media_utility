import 'package:flutter/material.dart';
import 'package:nextgen_ui_kit/nextgen_ui_kit.dart';

void main() {
  AppLogger.init();
  AppLogger.i('NextGen UI Kit Showcase initialized', tag: 'APP');
  runApp(const NextGenShowcaseApp());
}

class NextGenShowcaseApp extends StatefulWidget {
  const NextGenShowcaseApp({super.key});

  @override
  State<NextGenShowcaseApp> createState() => _NextGenShowcaseAppState();
}

class _NextGenShowcaseAppState extends State<NextGenShowcaseApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextGen UI Kit Showcase',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF06B6D4), // Cyan seed
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF06B6D4),
        scaffoldBackgroundColor: const Color(0xFF0B0F17),
      ),
      builder: (context, child) => SnackbarHost(
        alignment: Alignment.topCenter,
        child: Stack(
          children: [
            child!,
            const GlobalSyncStatusBanner(
              graceDuration: Duration(seconds: 1),
            ),
          ],
        ),
      ),
      home: ShowcaseHomeScreen(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class ShowcaseHomeScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const ShowcaseHomeScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<ShowcaseHomeScreen> createState() => _ShowcaseHomeScreenState();
}

class _ShowcaseHomeScreenState extends State<ShowcaseHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _sliderProgress = 0.68;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            PulseIndicator(size: 8, color: Color(0xFF06B6D4)),
            SizedBox(width: 8),
            Text(
              'NextGen UI Kit',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.3),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.bolt_rounded), text: 'Indicators'),
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Metrics & KPIs'),
            Tab(icon: Icon(Icons.input_rounded), text: 'Inputs & Forms'),
            Tab(icon: Icon(Icons.notifications_active_rounded), text: 'Feedback & Sync'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIndicatorsTab(),
          _buildMetricsTab(),
          _buildInputsTab(),
          _buildFeedbackTab(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: INDICATORS & PROGRESS
  // -------------------------------------------------------------
  Widget _buildIndicatorsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Futuristic Loading Presets'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runSpacing: 20,
              children: [
                _buildLoaderShowcase(
                  'Dual Rings',
                  FuturisticLoadingIndicator.dualRings(
                    size: 54,
                    color: const Color(0xFF00E5FF),
                    secondaryColor: const Color(0xFFD500F9),
                  ),
                ),
                _buildLoaderShowcase(
                  'Cyber Orbit',
                  FuturisticLoadingIndicator.cyberOrbit(
                    size: 54,
                    color: const Color(0xFF10B981),
                    secondaryColor: const Color(0xFFF59E0B),
                  ),
                ),
                _buildLoaderShowcase(
                  'Pulsing Core',
                  FuturisticLoadingIndicator.pulsingCore(
                    size: 54,
                    color: const Color(0xFFFF0055),
                  ),
                ),
                _buildLoaderShowcase(
                  'Radar HUD',
                  FuturisticLoadingIndicator.radarScanner(
                    size: 54,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Futuristic Laser Progress Bar'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Indeterminate Laser Sweep:'),
                const SizedBox(height: 10),
                const FuturisticLinearLoadingIndicator(
                  minHeight: 6,
                  color: Color(0xFF06B6D4),
                  glowRadius: 6,
                ),
                const SizedBox(height: 20),
                Text('Determinate Progress (${(_sliderProgress * 100).toInt()}%):'),
                const SizedBox(height: 10),
                FuturisticLinearLoadingIndicator(
                  value: _sliderProgress,
                  minHeight: 6,
                  color: const Color(0xFF10B981),
                  glowRadius: 5,
                ),
                Slider(
                  value: _sliderProgress,
                  onChanged: (v) => setState(() => _sliderProgress = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Circular & Arc Progress Meters'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runSpacing: 24,
              children: [
                AdvancedProgressIndicator(
                  progress: _sliderProgress,
                  size: 110,
                  futuristicStyle: true,
                  shape: ProgressShape.circular,
                  name: 'CPU Load',
                ),
                AdvancedProgressIndicator(
                  progress: _sliderProgress,
                  size: 110,
                  shape: ProgressShape.arc,
                  arcStartAngle: 180,
                  arcSweepAngle: 180,
                  name: 'Memory',
                  labelStyle: ProgressLabelStyle.percentage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoaderShowcase(String label, Widget loader) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        loader,
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: METRICS & KPIS
  // -------------------------------------------------------------
  Widget _buildMetricsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Executive KPI Cards'),
        const SizedBox(height: 12),
        MetricCard(
          title: 'Total Revenue',
          value: r'$84,230',
          subtitle: '+14.2% vs previous period',
          trend: '+14.2%',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF10B981),
          variant: MetricCardVariant.elevated,
          badge: MetricBadge.success(label: 'On Target', size: MetricBadgeSize.small),
        ),
        const SizedBox(height: 14),
        const MetricCard(
          title: 'Server Latency',
          value: '42 ms',
          subtitle: '99.98% SLA Uptime',
          trend: '-8.5%',
          icon: Icons.speed_rounded,
          iconColor: Color(0xFF0284C7),
          variant: MetricCardVariant.glass,
        ),
        const SizedBox(height: 14),
        const MetricCard(
          title: 'Active Subscribers',
          value: '18,420',
          subtitle: 'Pro tier customers',
          trend: '+24.0%',
          icon: Icons.people_alt_rounded,
          variant: MetricCardVariant.gradient,
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Interactive Status Badges & Pills'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: MetricIndicatorGroup(
              spacing: 10,
              runSpacing: 10,
              children: [
                MetricBadge.live(),
                MetricBadge.success(
                  label: 'Completed',
                  value: '100%',
                  onTap: () => AppSnackbar.success('Success Badge tapped!'),
                ),
                MetricBadge.warning(
                  label: 'Pending Review',
                  value: '3',
                  onTap: () => AppSnackbar.warning('Warning Badge tapped!'),
                ),
                MetricBadge.error(
                  label: 'Failed Builds',
                  value: '1',
                  onTap: () => AppSnackbar.error('Error Badge tapped!'),
                ),
                MetricBadge.info(label: 'Sync In Progress'),
                const TrendIndicator(value: '+34.5%'),
                const TrendIndicator(value: '-12.3%'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: INPUTS & FORMS
  // -------------------------------------------------------------
  Widget _buildInputsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Modern Text Fields'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                CustomTextField.search(
                  hintText: 'Search products, tags, docs...',
                ),
                const SizedBox(height: 16),
                CustomTextField.email(
                  required: true,
                ),
                const SizedBox(height: 16),
                CustomTextField.password(
                  required: true,
                ),
                const SizedBox(height: 16),
                CustomTextField.phone(),
                const SizedBox(height: 16),
                CustomTextField.multiline(
                  label: 'Feedback & Notes',
                  hintText: 'Share your thoughts here...',
                  maxLength: 200,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 4: FEEDBACK & CLOUD SYNC
  // -------------------------------------------------------------
  Widget _buildFeedbackTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader('Interactive Modern Snackbars'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => AppSnackbar.success(
                    'Changes Saved!',
                    description: 'Your profile has been updated successfully.',
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Success Toast'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => AppSnackbar.error(
                    'Upload Failed',
                    description: 'Network timeout during payload transfer.',
                  ),
                  icon: const Icon(Icons.error_rounded),
                  label: const Text('Error Toast'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => AppSnackbar.warning(
                    'Disk Space Low',
                    description: 'Remaining volume is below 15%.',
                  ),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Warning Toast'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => AppSnackbar.info(
                    title: 'New Update Available',
                    message: 'NextGen UI Kit v0.1.0 is now live.',
                  ),
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('Info Toast'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Simulate Global Sync States'),
        const SizedBox(height: 8),
        const Text(
          'Toggle cloud synchronization status to observe the smart sliding banner with grace period handling:',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      SyncStatusController.update(ServerSyncState.synced),
                  child: const Text('Synced (Hidden)'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      SyncStatusController.update(ServerSyncState.syncing),
                  child: const Text('Syncing'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      SyncStatusController.update(ServerSyncState.offline),
                  child: const Text('Offline Mode'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      SyncStatusController.update(ServerSyncState.serverPaused),
                  child: const Text('Server Paused'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      SyncStatusController.update(ServerSyncState.authExpired),
                  child: const Text('Session Expired'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      SyncStatusController.update(ServerSyncState.restored),
                  child: const Text('Sync Restored'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}
