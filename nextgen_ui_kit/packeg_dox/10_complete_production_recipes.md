# Complete Production Recipes

Copy-paste templates for real-world application screens.

---

## Recipe: Executive Analytics Dashboard

```dart
import 'package:flutter/material.dart';
import 'package:nextgen_ui_kit/nextgen_ui_kit.dart';

class ExecutiveDashboardScreen extends StatelessWidget {
  const ExecutiveDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Overview'),
        actions: [
          MetricBadge.live(),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // KPI Grid
          MetricCard(
            title: 'Gross Revenue',
            value: '$148,920',
            subtitle: '+18.4% vs last quarter',
            trend: '+18.4%',
            icon: Icons.payments_rounded,
            variant: MetricCardVariant.gradient,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Active Users',
                  value: '24.8K',
                  trend: '+12.1%',
                  icon: Icons.people_alt_rounded,
                  variant: MetricCardVariant.elevated,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: MetricCard(
                  title: 'Avg Latency',
                  value: '38 ms',
                  trend: '-4.2%',
                  icon: Icons.speed_rounded,
                  variant: MetricCardVariant.glass,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Resource Gauges
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  AdvancedProgressIndicator(
                    progress: 0.78,
                    size: 110,
                    shape: ProgressShape.circular,
                    futuristicStyle: true,
                    name: 'Storage',
                  ),
                  AdvancedProgressIndicator(
                    progress: 0.45,
                    size: 110,
                    shape: ProgressShape.arc,
                    name: 'Compute',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Recipe: Authentication & Sign In Screen

```dart
import 'package:flutter/material.dart';
import 'package:nextgen_ui_kit/nextgen_ui_kit.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    AppSnackbar.success(
      'Welcome back!',
      description: 'Logged in as ${_emailController.text}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FuturisticLoadingIndicator.dualRings(size: 64),
              const SizedBox(height: 24),
              const Text(
                'NextGen Portal',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 28),
              CustomTextField.email(
                controller: _emailController,
                required: true,
              ),
              const SizedBox(height: 16),
              CustomTextField.password(
                controller: _passwordController,
                required: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSignIn,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
