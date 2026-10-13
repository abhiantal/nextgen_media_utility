# Metrics, KPIs & Status Badges

NextGen UI Kit includes an executive metric and KPI suite for dashboards, monitoring tools, and analytics.

---

## 1. Executive Metric Card (`MetricCard`)

```dart
MetricCard(
  title: 'Monthly Recurring Revenue',
  value: '$124,500',
  subtitle: 'vs previous quarter',
  trend: '+18.4%',
  trendDirection: TrendDirection.up,
  icon: Icons.trending_up_rounded,
  iconColor: Color(0xFF10B981),
  variant: MetricCardVariant.elevated,
  badge: MetricBadge.success(label: 'Target Met', size: MetricBadgeSize.small),
  onTap: () => print('Viewing MRR breakdown'),
)
```

### Visual Variants:
* `MetricCardVariant.elevated`: Elevated surface with subtle border and shadow.
* `MetricCardVariant.glass`: Frosted glassmorphism background with translucent blur.
* `MetricCardVariant.gradient`: Vibrant linear gradient fill.
* `MetricCardVariant.flat`: Flat tinted surface.
* `MetricCardVariant.outlined`: Crisp bordered card with zero elevation.

---

## 2. Status Badges & Pills (`MetricBadge`)

```dart
// Pre-configured status badges
MetricBadge.success(label: 'Active', value: '1,420')
MetricBadge.warning(label: 'Pending Approval', value: '5')
MetricBadge.error(label: 'Outages', value: '0')
MetricBadge.info(label: 'V2 Migration')

// Live pulsating beacon
MetricBadge.live(label: 'LIVE STREAM')

// Interactive custom badge
MetricBadge(
  label: 'PRO MEMBER',
  icon: Icons.star_rounded,
  color: Color(0xFFF59E0B),
  style: MetricBadgeStyle.glow,
  onTap: () => showUpgradeModal(),
)
```

---

## 3. Directional Trend Indicator (`TrendIndicator`)

Automatically colors positive trends emerald and negative trends red:

```dart
TrendIndicator(value: '+14.5%') // Green up-arrow
TrendIndicator(value: '-3.2%')  // Red down-arrow
TrendIndicator(
  value: '-12 ms',
  isPositiveGood: false, // Lower latency is better! Shows green.
)
```
