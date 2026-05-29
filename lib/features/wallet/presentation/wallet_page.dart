import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offlimu/core/di/providers.dart';

enum WalletSection { overview, pay, logs, rewards, identity }

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key, this.section = WalletSection.overview});

  final WalletSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String nodeId = ref.watch(localNodeIdentityProvider).nodeId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F2),
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _WalletBackground()),
          SafeArea(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: _WalletHeader(section: section, nodeId: nodeId),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _WalletNavPills(active: section),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  sliver: SliverToBoxAdapter(
                    child: switch (section) {
                      WalletSection.overview => _WalletOverviewSection(nodeId: nodeId),
                      WalletSection.pay => _WalletPaymentSection(nodeId: nodeId),
                      WalletSection.logs => const _WalletLogsSection(),
                      WalletSection.rewards => const _WalletRewardsSection(),
                      WalletSection.identity => _WalletIdentitySection(nodeId: nodeId),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBackground extends StatelessWidget {
  const _WalletBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF8FBF5),
            Color(0xFFF2F6EE),
            Color(0xFFE8F2E0),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -110,
            right: -90,
            child: _GlowBlob(color: const Color(0xFF4CAF50).withValues(alpha: 0.14)),
          ),
          Positioned(
            top: 110,
            left: -95,
            child: _GlowBlob(color: const Color(0xFF2E7D32).withValues(alpha: 0.10)),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: GridPaper(
                color: const Color(0xFF8BA884),
                divisions: 1,
                subdivisions: 8,
                interval: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({required this.section, required this.nodeId});

  final WalletSection section;
  final String nodeId;

  String get _title => switch (section) {
        WalletSection.overview => 'Local Balance',
        WalletSection.pay => 'Offline Transfer',
        WalletSection.logs => 'Transaction Logs',
        WalletSection.rewards => 'Incentive Earnings',
        WalletSection.identity => 'My Node Identity',
      };

  String get _subtitle => switch (section) {
        WalletSection.overview => 'Append-only wallet, DTN delivery, online reconciliation.',
        WalletSection.pay => 'Prepare a signed spend event before propagation.',
        WalletSection.logs => 'Complete audit trail for payments and issuance events.',
        WalletSection.rewards => 'Relay and gateway participation rewards.',
        WalletSection.identity => 'Share the local node identity without exposing secrets.',
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _title.toUpperCase(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  letterSpacing: 2.0,
                  color: const Color(0xFF3A643B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF556B55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _StatusBadge(label: 'NODE', value: _shortId(nodeId)),
      ],
    );
  }
}

class _WalletNavPills extends StatelessWidget {
  const _WalletNavPills({required this.active});

  final WalletSection active;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _NavPill(label: 'Overview', active: active == WalletSection.overview, onTap: () => context.go('/wallet')),
        _NavPill(label: 'Pay', active: active == WalletSection.pay, onTap: () => context.go('/wallet/pay')),
        _NavPill(label: 'Logs', active: active == WalletSection.logs, onTap: () => context.go('/wallet/logs')),
        _NavPill(label: 'Rewards', active: active == WalletSection.rewards, onTap: () => context.go('/wallet/rewards')),
        _NavPill(label: 'My ID', active: active == WalletSection.identity, onTap: () => context.go('/wallet/id')),
      ],
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = active ? const Color(0xFF4EA058) : const Color(0xFFD5E4D0);
    final Color backgroundColor = active ? const Color(0xFFE7F4E2) : const Color(0xFFF8FBF5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: active ? 1.4 : 1),
        ),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            letterSpacing: 1.4,
            color: active ? const Color(0xFF245A2A) : const Color(0xFF4F6450),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _WalletOverviewSection extends StatelessWidget {
  const _WalletOverviewSection({required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _BalanceCard(nodeId: nodeId),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _ActionTile(
                icon: Icons.send_rounded,
                label: 'Pay',
                onTap: () => context.go('/wallet/pay'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.qr_code_2_rounded,
                label: 'My ID',
                onTap: () => context.go('/wallet/id'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Recent Logs',
          child: Column(
            children: _recentLogs.map((entry) => _TransactionTile(entry: entry)).toList(growable: false),
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Incentive Snapshot',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _MetricCard(
                      title: 'Relay Rewards',
                      value: '8,492.05 DTN',
                      accent: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Gateway Rewards',
                      value: '1,204.80 DTN',
                      accent: const Color(0xFF66A65D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _ProgressLine(
                label: 'Trust Score',
                valueLabel: '0.98',
                progress: 0.98,
                accent: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 10),
              const _ProgressLine(
                label: 'Participation Grade',
                valueLabel: 'A+',
                progress: 0.86,
                accent: Color(0xFF66A65D),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletPaymentSection extends StatelessWidget {
  const _WalletPaymentSection({required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionCard(
          title: 'Step 1: Target Node',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DemoInputField(
                hintText: 'Enter recipient DTN endpoint or node ID',
                trailing: IconButton(
                  tooltip: 'Scan QR',
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Requires a valid OffLiMU node identifier.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF577057),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Step 2: Token Payload',
          trailing: Text(
            'Local Balance  14,204.55 DTN',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF2E7D32),
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: _AmountField(onMax: () {})),
                  const SizedBox(width: 12),
                  _MiniBadge(label: 'MAX', onTap: () {}),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(child: _StatusBadge(label: 'TOKEN', value: 'SpendEvent')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatusBadge(label: 'TTL', value: '72 Hours')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatusBadge(label: 'ENCAP', value: 'Bundle v6')),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 2,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Memo',
                  hintText: 'Optional payment memo or purpose',
                  filled: true,
                  fillColor: const Color(0xFFF8FBF5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD7E4D1)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Pre-flight Audit',
          child: Column(
            children: <Widget>[
              const _AuditRow(label: 'Encapsulation', value: 'Bundle v6 (RFC 5050)'),
              const _AuditRow(label: 'Timestamp', value: '2026-05-29 17:30:13 UTC'),
              const _AuditRow(label: 'Time-to-Live', value: '72 Hours'),
              const _AuditRow(label: 'Est. Bundle Size', value: '~1.4 KB'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Prototype wallet flow for $nodeId will hook into the sync server next.',
                        ),
                      ),
                    );
                  },
                  child: const Text('SIGN & PROPAGATE'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletLogsSection extends StatelessWidget {
  const _WalletLogsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const <Widget>[
            _FilterPill(label: 'All', active: true),
            _FilterPill(label: 'Payments'),
            _FilterPill(label: 'Rewards'),
            _FilterPill(label: 'Pending', accent: Color(0xFFFF8E3D)),
          ],
        ),
        const SizedBox(height: 12),
        ..._logsPageEntries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TransactionCard(entry: entry),
          ),
        ),
      ],
    );
  }
}

class _WalletRewardsSection extends StatelessWidget {
  const _WalletRewardsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _MetricCard(
                title: 'Total Relay Rewards',
                value: '8,492.05 DTN',
                accent: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Pending Rewards',
                value: '325.00 DTN',
                accent: const Color(0xFF66A65D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Network Status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              _ProgressLine(
                label: 'Trust Score',
                valueLabel: '0.98',
                progress: 0.98,
                accent: Color(0xFF2E7D32),
              ),
              SizedBox(height: 10),
              _ProgressLine(
                label: 'Participation Grade',
                valueLabel: 'A+',
                progress: 0.86,
                accent: Color(0xFF66A65D),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Performance (7 Days)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 136,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    for (final _RewardBar bar in _rewardBars)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              Container(
                                height: 88 * bar.forwarded,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 88 * bar.synced,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7AB56D),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(bar.label, style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('Issued events', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ..._rewardEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RewardEntryTile(entry: entry),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletIdentitySection extends StatelessWidget {
  const _WalletIdentitySection({required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Local Node ID',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SelectableText(
            nodeId,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              letterSpacing: 0.6,
              color: const Color(0xFF214A2B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniActionButton(
                  label: 'Copy ID',
                  icon: Icons.copy_rounded,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: nodeId));
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Node ID copied')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniActionButton(
                  label: 'Share ID',
                  icon: Icons.share_rounded,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 184,
              height: 184,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FCF6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD9E7D4)),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 92,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _AuditRow(label: 'Node Type', value: 'Wallet-enabled relay'),
          const _AuditRow(label: 'Transport', value: 'DTN bundle propagation'),
          const _AuditRow(label: 'Reconciliation', value: 'Gateway signed events'),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF4FAF0), Color(0xFFEAF5E4)],
        ),
        border: Border.all(color: const Color(0xFFC9DCC2), width: 1.1),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'LOCAL BALANCE',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 2.4,
                color: const Color(0xFF4A6C4A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '1,420.50 DTN',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: const Color(0xFF214A2B),
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
              ),
            ),
            const SizedBox(height: 10),
            _MiniBadge(label: '≈ \$342.10 USD', onTap: () {}),
            const SizedBox(height: 10),
            Text(
              'Node $nodeId',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF5D725B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC9DCC2), width: 1.2),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 6)),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 28, color: const Color(0xFF2E7D32)),
                const SizedBox(height: 6),
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.4,
                    color: const Color(0xFF24552A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E7D4)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      letterSpacing: 1.4,
                      color: const Color(0xFF28502E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.accent});

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.3,
              color: const Color(0xFF5A7358),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF214A2B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.valueLabel,
    required this.progress,
    required this.accent,
  });

  final String label;
  final String valueLabel;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFDDE8D8),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.entry});

  final _LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E7D4)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: entry.accent),
            ),
            child: Icon(entry.icon, color: entry.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(entry.subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: entry.amount.startsWith('-') ? const Color(0xFF214A2B) : const Color(0xFF2E7D32),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardEntryTile extends StatelessWidget {
  const _RewardEntryTile({required this.entry});

  final _LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E7D4)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(entry.icon, color: entry.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(entry.title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(entry.subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: entry.amount.startsWith('+') ? const Color(0xFF2E7D32) : const Color(0xFF214A2B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.entry});

  final _LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E7D4)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(entry.icon, size: 22, color: entry.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(entry.timestamp, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              _StatusBadge(label: 'STATE', value: entry.subtitle),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.idLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4F6450),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            entry.amount,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: entry.amount.startsWith('-') ? const Color(0xFF214A2B) : const Color(0xFF2E7D32),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD9E7D4)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF4F6450),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF214A2B),
        side: const BorderSide(color: Color(0xFF4EA058)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _DemoInputField extends StatelessWidget {
  const _DemoInputField({required this.hintText, required this.trailing});

  final String hintText;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E7D4)),
      ),
      child: TextField(
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6A8067),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
          suffixIcon: trailing,
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.onMax});

  final VoidCallback onMax;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E7D4)),
      ),
      child: Row(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Text(
              '#',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                isDense: true,
                hintText: '0.00',
                hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF6A8067),
                  fontWeight: FontWeight.w800,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF214A2B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _MiniBadge(label: 'MAX', onTap: onMax),
          ),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF214A2B),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, this.active = false, this.accent});

  final String label;
  final bool active;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = accent ?? (active ? const Color(0xFF4EA058) : const Color(0xFFD9E7D4));
    final Color textColor = accent ?? (active ? const Color(0xFF245A2A) : const Color(0xFF4F6450));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F4E2) : const Color(0xFFF8FBF5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E7D4)),
      ),
      child: Text(
        '$label $value',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF4F6450),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _LedgerEntry {
  const _LedgerEntry({
    required this.title,
    required this.subtitle,
    required this.idLabel,
    required this.timestamp,
    required this.amount,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String idLabel;
  final String timestamp;
  final String amount;
  final IconData icon;
  final Color accent;
}

class _RewardBar {
  const _RewardBar({required this.label, required this.forwarded, required this.synced});

  final String label;
  final double forwarded;
  final double synced;
}

const List<_LedgerEntry> _recentLogs = <_LedgerEntry>[
  _LedgerEntry(
    title: 'To: Node 9xA...B4',
    subtitle: 'Pending mesh sync',
    idLabel: 'Payment Out • Tx 2cC4...1bE9',
    timestamp: 'Today • 08:14',
    amount: '-45.00',
    icon: Icons.schedule_rounded,
    accent: Color(0xFF4EA058),
  ),
  _LedgerEntry(
    title: 'From: Node 2zR...L9',
    subtitle: 'Block #49281',
    idLabel: 'Relay reward • Tx 9a4B...7dF1',
    timestamp: 'Yesterday • 19:42',
    amount: '+120.00',
    icon: Icons.check_circle_outline_rounded,
    accent: Color(0xFF2E7D32),
  ),
  _LedgerEntry(
    title: 'Gateway Fee',
    subtitle: 'Block #49100',
    idLabel: 'Settlement • Tx 5fF1...8aD2',
    timestamp: 'Yesterday • 17:06',
    amount: '-1.50',
    icon: Icons.remove_circle_outline_rounded,
    accent: Color(0xFF66A65D),
  ),
];

const List<_LedgerEntry> _logsPageEntries = <_LedgerEntry>[
  _LedgerEntry(
    title: 'Relay Reward',
    subtitle: '2023-10-27T08:14:32Z',
    idLabel: 'Tx: 9a4B...7dF1',
    timestamp: 'Confirmed',
    amount: '+12.50 DTN',
    icon: Icons.emoji_events_outlined,
    accent: Color(0xFF2E7D32),
  ),
  _LedgerEntry(
    title: 'Payment Out',
    subtitle: '2023-10-27T07:55:10Z',
    idLabel: 'Tx: 2cC4...1bE9',
    timestamp: 'Pending',
    amount: '-50.00 DTN',
    icon: Icons.arrow_upward_rounded,
    accent: Color(0xFF66A65D),
  ),
  _LedgerEntry(
    title: 'Payment In',
    subtitle: '2023-10-26T22:10:05Z',
    idLabel: 'Tx: 5fF1...8aD2',
    timestamp: 'Rejected',
    amount: '+100.00 DTN',
    icon: Icons.arrow_downward_rounded,
    accent: Color(0xFF4EA058),
  ),
];

const List<_LedgerEntry> _rewardEntries = <_LedgerEntry>[
  _LedgerEntry(
    title: 'Relay',
    subtitle: 'Bndl_x8F... • Sig valid • 10 mins ago',
    idLabel: 'Reward event',
    timestamp: 'Confirmed',
    amount: '+2.50 DTN',
    icon: Icons.wifi_tethering_rounded,
    accent: Color(0xFF2E7D32),
  ),
  _LedgerEntry(
    title: 'Gateway',
    subtitle: 'Sync_2A... • Sig valid • 45 mins ago',
    idLabel: 'Reward event',
    timestamp: 'Confirmed',
    amount: '+1.20 DTN',
    icon: Icons.router_rounded,
    accent: Color(0xFF4EA058),
  ),
  _LedgerEntry(
    title: 'Relay',
    subtitle: 'Bndl_y9C... • Sig valid • 2 hrs ago',
    idLabel: 'Reward event',
    timestamp: 'Confirmed',
    amount: '+3.10 DTN',
    icon: Icons.wifi_tethering_rounded,
    accent: Color(0xFF2E7D32),
  ),
  _LedgerEntry(
    title: 'Relay',
    subtitle: 'Bndl_Z0D... • Sig valid • 5 hrs ago',
    idLabel: 'Reward event',
    timestamp: 'Confirmed',
    amount: '+1.50 DTN',
    icon: Icons.wifi_tethering_rounded,
    accent: Color(0xFF4EA058),
  ),
];

const List<_RewardBar> _rewardBars = <_RewardBar>[
  _RewardBar(label: 'Mon', forwarded: 0.35, synced: 0.22),
  _RewardBar(label: 'Tue', forwarded: 0.44, synced: 0.20),
  _RewardBar(label: 'Wed', forwarded: 0.50, synced: 0.30),
  _RewardBar(label: 'Thu', forwarded: 0.38, synced: 0.26),
  _RewardBar(label: 'Fri', forwarded: 0.68, synced: 0.36),
  _RewardBar(label: 'Sat', forwarded: 0.76, synced: 0.42),
  _RewardBar(label: 'Sun', forwarded: 0.40, synced: 0.34),
];

String _shortId(String nodeId) {
  if (nodeId.length <= 12) {
    return nodeId;
  }
  return '${nodeId.substring(0, 4)}…${nodeId.substring(nodeId.length - 4)}';
}
