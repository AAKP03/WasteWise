
import 'dart:async';

import 'package:flutter/material.dart';

import '../data/db_helper.dart';
import '../data/seed_data.dart';
import '../models/eco_badge.dart';

/// Reuses the team's canonical category names and emoji data.
String wasteCategoryLabel(String name) {
  for (final category in wasteCategories) {
    if (category.name == name) return '${category.icon} $name';
  }
  return name;
}

/// Shared status card.
class WasteWiseStatusCard extends StatelessWidget {
  const WasteWiseStatusCard({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.loading = false,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const CircularProgressIndicator(
                    semanticsLabel: 'Loading',
                  )
                else
                  Icon(icon, color: colors.primary, size: 32),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  Tooltip(
                    message: retryLabel,
                    child: FilledButton.tonalIcon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(retryLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACHIEVEMENT BADGES SECTION
// ============================================================

class AchievementBadgesSection extends StatelessWidget {
  const AchievementBadgesSection({
    super.key,
    required this.unlockedBadges,
    required this.lockedBadges,
  });

  final List<EcoBadge> unlockedBadges;
  final List<EcoBadge> lockedBadges;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final totalBadges = unlockedBadges.length + lockedBadges.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Eco Achievements',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${unlockedBadges.length}/$totalBadges',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          'Complete responsible disposal activities to unlock achievements.',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),

        const SizedBox(height: 16),

        if (unlockedBadges.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '🌱',
                  style: TextStyle(fontSize: 38),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your journey starts here!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recycle or donate items to earn your first badge.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: unlockedBadges.map((badge) {
              return _BadgeCard(
                badge: badge,
                unlocked: true,
              );
            }).toList(),
          ),

        const SizedBox(height: 22),

        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            const Text(
              'Locked Achievements',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (lockedBadges.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '🎉 Congratulations! You have unlocked all achievements!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: lockedBadges.map((badge) {
              return _BadgeCard(
                badge: badge,
                unlocked: false,
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ============================================================
// INDIVIDUAL BADGE CARD
// ============================================================

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.unlocked,
  });

  final EcoBadge badge;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 145,
      constraints: const BoxConstraints(minHeight: 175),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked
            ? colors.primaryContainer
            : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? colors.primary.withValues(alpha: 0.5)
              : colors.outlineVariant,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.07),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unlocked ? badge.emoji : '🔒',
            style: const TextStyle(fontSize: 36),
          ),

          const SizedBox(height: 8),

          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            unlocked ? 'Unlocked ✓' : 'Not unlocked',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: unlocked
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// POINTS SCREEN
// ============================================================

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key, this.database});

  final DBHelper? database;

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen>
    with WidgetsBindingObserver {

  int _total = 0;

  List<Map<String, dynamic>> _activities = [];

  bool _loading = true;
  bool _loadInProgress = false;
  bool _reloadRequested = false;

  bool? _wasVisible;

  String? _error;

  DBHelper get _database => widget.database ?? DBHelper();

  // ==========================================================
  // BADGE CALCULATIONS
  // ==========================================================

  List<EcoBadge> get _unlockedBadges {
    return ecoBadges.where((badge) {
      return badge.isUnlocked(
        totalPoints: _total,
        totalDisposals: _activities.length,
      );
    }).toList();
  }

  List<EcoBadge> get _lockedBadges {
    return ecoBadges.where((badge) {
      return !badge.isUnlocked(
        totalPoints: _total,
        totalDisposals: _activities.length,
      );
    }).toList();
  }

  // ==========================================================
  // INITIALIZATION
  // ==========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadPoints();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final visible = Visibility.of(context);

    final becameVisible = _wasVisible == false && visible;

    _wasVisible = visible;

    if (becameVisible) {
      _loadPoints();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && (_wasVisible ?? true)) {
      _loadPoints();
    }
  }

  // ==========================================================
  // LOAD POINTS AND ACTIVITIES
  // ==========================================================

  Future<void> _loadPoints() async {
    if (!mounted) return;

    if (_loadInProgress) {
      _reloadRequested = true;
      return;
    }

    _loadInProgress = true;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      Future<(int, List<Map<String, dynamic>>)> read() async {
        final total = await _database.getTotalEcoPoints();

        final activities = await _database.getEcoPointsLog();

        return (total, activities);
      }

      final (total, activities) = await read().timeout(
        const Duration(seconds: 20),
      );

      if (!mounted) return;

      setState(() {
        _total = total;
        _activities = activities;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error is TimeoutException
            ? 'Loading Eco Points is taking longer than expected. Please retry.'
            : 'Could not load Eco Points. Please try again.';

        _loading = false;
      });
    } finally {
      _loadInProgress = false;

      if (_reloadRequested && mounted) {
        _reloadRequested = false;

        await _loadPoints();
      }
    }
  }

  // ==========================================================
  // DATE FORMATTING
  // ==========================================================

  String _activityDate(Object? value) {
    final date = DateTime.tryParse(
      value?.toString() ?? '',
    )?.toLocal();

    if (date == null) return 'Date unavailable';

    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  // ==========================================================
  // BUILD SCREEN
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Find the next locked points-based achievement.
    final nextBadge = ecoBadges
        .where((badge) =>
            badge.requiredPoints > 0 &&
            _total < badge.requiredPoints)
        .toList()
      ..sort((a, b) =>
          a.requiredPoints.compareTo(b.requiredPoints));

    // Determine the next achievement target.
    final bool hasNextBadge = nextBadge.isNotEmpty;

    final int nextTarget = hasNextBadge
        ? nextBadge.first.requiredPoints
        : 0;

    // Calculate remaining points and progress.
    final int remaining = hasNextBadge
        ? (nextTarget - _total).clamp(0, nextTarget)
        : 0;

    final double progress = hasNextBadge
        ? (_total / nextTarget).clamp(0.0, 1.0).toDouble()
        : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F4),

      // APP BAR
      appBar: AppBar(
        title: const Text('Eco Points'),
        centerTitle: true,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        actions: [
          IconButton(
            tooltip: 'Refresh points',
            onPressed: _loading ? null : _loadPoints,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: SafeArea(
        child: _loading
            ? const WasteWiseStatusCard(
                loading: true,
                message: 'Loading Eco Points...',
              )
            : _error != null
                ? WasteWiseStatusCard(
                    icon: Icons.error_outline,
                    message: _error!,
                    onRetry: _loadPoints,
                  )
                : CustomScrollView(
                    slivers: [

                      // ==================================================
                      // MAIN CONTENT
                      // ==================================================

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // ==========================================
                              // ECO POINTS CARD
                              // ==========================================

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.eco,
                                      size: 60,
                                      color: colors.onPrimary,
                                    ),

                                    const SizedBox(height: 10),

                                    Semantics(
                                      label: '$_total Eco Points',
                                      child: ExcludeSemantics(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            '$_total',
                                            style: TextStyle(
                                              fontSize: 42,
                                              fontWeight: FontWeight.bold,
                                              color: colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    Text(
                                      'Eco Points',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: colors.onPrimary,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      'Keep recycling to earn more points!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colors.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ==========================================
                              // NEXT ACHIEVEMENT CARD
                              // ==========================================

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: colors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.emoji_events_outlined,
                                          color: colors.primary,
                                        ),

                                        const SizedBox(width: 8),

                                        const Expanded(
                                          child: Text(
                                            'Next Achievement',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    Text('Current points: $_total'),

                                    const SizedBox(height: 8),

                                    if (hasNextBadge) ...[
                                      Text(
                                        'Next achievement: ${nextBadge.first.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text('Target points: $nextTarget'),
                                    ] else
                                      const Text(
                                        'All point-based achievements unlocked!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                    const SizedBox(height: 12),

                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      spacing: 16,
                                      runSpacing: 8,
                                      children: [
                                        const Text('Progress'),

                                        Text(
                                          hasNextBadge
                                              ? '$_total / $nextTarget'
                                              : '100% Completed',
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 10,
                                        semanticsLabel: hasNextBadge
                                            ? 'Progress towards $nextTarget points'
                                            : 'All point-based achievements unlocked',
                                        semanticsValue:
                                            '${(progress * 100).round()}',
                                        backgroundColor:
                                            const Color(0xFFEFF6FF),
                                        color: colors.primary,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    Text(
                                      hasNextBadge
                                          ? 'Earn $remaining more points to unlock ${nextBadge.first.name}.'
                                          : 'Congratulations! You have unlocked all point-based achievements!',
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ==========================================
                              // ECO ACHIEVEMENTS
                              // ==========================================

                              AchievementBadgesSection(
                                unlockedBadges: _unlockedBadges,
                                lockedBadges: _lockedBadges,
                              ),

                              const SizedBox(height: 28),

                              // ==========================================
                              // RECENT ACTIVITY HEADING
                              // ==========================================

                              const Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),

                      // ==================================================
                      // RECENT ACTIVITY LIST
                      // ==================================================

                      if (_activities.isEmpty)
                        const SliverToBoxAdapter(
                          child: WasteWiseStatusCard(
                            icon: Icons.eco_outlined,
                            message: 'No activity yet',
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            20,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _activities[index];

                                final category =
                                    item['category_name']?.toString() ??
                                        'Disposal';

                                final points =
                                    (item['points_earned'] as num?)
                                            ?.toInt() ??
                                        0;

                                return Card(
                                  elevation: 1.5,
                                  margin: const EdgeInsets.only(
                                    bottom: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          const Color(0xFFEFF6FF),
                                      child: Icon(
                                        Icons.recycling,
                                        color: colors.primary,
                                      ),
                                    ),

                                    title: Text(
                                      wasteCategoryLabel(category),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    subtitle: Text(
                                      _activityDate(item['disposed_at']),
                                    ),

                                    trailing: Text(
                                      '${points >= 0 ? '+' : ''}$points',
                                      style: TextStyle(
                                        color: colors.primary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _activities.length,
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
