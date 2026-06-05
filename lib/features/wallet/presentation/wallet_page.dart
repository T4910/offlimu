import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offlimu/core/di/providers.dart';
import 'package:offlimu/domain/entities/wallet_ledger_entry.dart';

enum WalletSection { overview, pay, logs, rewards, identity }

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key, this.section = WalletSection.overview});

  final WalletSection section;

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  late WalletSection _activeSection = widget.section;

  @override
  void didUpdateWidget(covariant WalletPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      _activeSection = widget.section;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodeId = ref.watch(localNodeIdentityProvider).nodeId;
    final dashboard =
        ref.watch(walletDashboardProvider).valueOrNull ??
        WalletLedgerDashboard.empty();

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
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
                    child: _WalletHeader(
                      section: _activeSection,
                      nodeId: nodeId,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _WalletNavPills(
                      active: _activeSection,
                      onChanged: (section) {
                        setState(() {
                          _activeSection = section;
                        });
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey<WalletSection>(_activeSection),
                        child: switch (_activeSection) {
                          WalletSection.overview => _WalletOverviewSection(
                            nodeId: nodeId,
                            dashboard: dashboard,
                            onSectionSelected: _setSection,
                          ),
                          WalletSection.pay => _WalletPaymentSection(
                            nodeId: nodeId,
                            dashboard: dashboard,
                          ),
                          WalletSection.logs => _WalletLogsSection(
                            dashboard: dashboard,
                          ),
                          WalletSection.rewards => _WalletRewardsSection(
                            dashboard: dashboard,
                          ),
                          WalletSection.identity => _WalletIdentitySection(
                            nodeId: nodeId,
                          ),
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setSection(WalletSection section) {
    setState(() {
      _activeSection = section;
    });
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
            child: _GlowBlob(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: 110,
            left: -95,
            child: _GlowBlob(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
            ),
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
    WalletSection.rewards => 'Reward Earnings',
    WalletSection.identity => 'My Node Identity',
  };

  String get _subtitle => switch (section) {
    WalletSection.overview => 'The ledger stays append-only and updates live.',
    WalletSection.pay =>
      'Prepare a signed spend event and persist it as a pending ledger entry.',
    WalletSection.logs =>
      'Complete audit trail for payments, confirmations, and rejections.',
    WalletSection.rewards =>
      'Relay and gateway participation rewards derived from the ledger.',
    WalletSection.identity =>
      'Share the local node identity without exposing private material.',
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
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _StatusBadge(label: 'NODE', value: _shortId(nodeId)),
          ],
        ),
      ],
    );
  }
}

class _WalletNavPills extends StatelessWidget {
  const _WalletNavPills({required this.active, required this.onChanged});

  final WalletSection active;
  final ValueChanged<WalletSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _NavPill(
          label: 'Overview',
          active: active == WalletSection.overview,
          onTap: () => onChanged(WalletSection.overview),
        ),
        _NavPill(
          label: 'Pay',
          active: active == WalletSection.pay,
          onTap: () => onChanged(WalletSection.pay),
        ),
        _NavPill(
          label: 'Logs',
          active: active == WalletSection.logs,
          onTap: () => onChanged(WalletSection.logs),
        ),
        _NavPill(
          label: 'Rewards',
          active: active == WalletSection.rewards,
          onTap: () => onChanged(WalletSection.rewards),
        ),
        _NavPill(
          label: 'My ID',
          active: active == WalletSection.identity,
          onTap: () => onChanged(WalletSection.identity),
        ),
      ],
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = active
        ? const Color(0xFF4EA058)
        : const Color(0xFFD5E4D0);
    final Color backgroundColor = active
        ? const Color(0xFFE7F4E2)
        : const Color(0xFFF8FBF5);

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
  const _WalletOverviewSection({
    required this.nodeId,
    required this.dashboard,
    required this.onSectionSelected,
  });

  final String nodeId;
  final WalletLedgerDashboard dashboard;
  final ValueChanged<WalletSection> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _BalanceCards(nodeId: nodeId, dashboard: dashboard),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _ActionTile(
                icon: Icons.send_rounded,
                label: 'Pay',
                onTap: () => onSectionSelected(WalletSection.pay),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.qr_code_2_rounded,
                label: 'My ID',
                onTap: () => onSectionSelected(WalletSection.identity),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Recent Ledger',
          child: dashboard.recentEntries.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No recent ledger entries',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF577057),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: dashboard.recentEntries
                      .map((entry) => _LedgerTile(entry: entry))
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Reward Snapshot',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _MetricCard(
                      title: 'Relay Rewards',
                      value: _formatDtn(
                        dashboard.relayRewardsMinorUnits,
                        includeSign: false,
                      ),
                      accent: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'Gateway Rewards',
                      value: _formatDtn(
                        dashboard.gatewayRewardsMinorUnits,
                        includeSign: false,
                      ),
                      accent: const Color(0xFF66A65D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ProgressLine(
                label: 'Trust Score',
                valueLabel: dashboard.trustScore.toStringAsFixed(2),
                progress: dashboard.trustScore,
                accent: const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 10),
              _ProgressLine(
                label: 'Participation Grade',
                valueLabel: dashboard.participationGrade.isEmpty
                    ? '-'
                    : dashboard.participationGrade,
                progress: dashboard.trustScore,
                accent: const Color(0xFF66A65D),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WalletPaymentSection extends ConsumerStatefulWidget {
  const _WalletPaymentSection({required this.nodeId, required this.dashboard});

  final String nodeId;
  final WalletLedgerDashboard dashboard;

  @override
  ConsumerState<_WalletPaymentSection> createState() =>
      _WalletPaymentSectionState();
}

class _WalletPaymentSectionState extends ConsumerState<_WalletPaymentSection> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _submitSpend() async {
    final recipient = _recipientController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount before signing.')),
      );
      return;
    }

    final amountMinorUnits = (amount * 100).round();
    String? errorMessage;
    try {
      await ref
          .read(initiateWalletSpendUseCaseProvider)
          .initiate(
            localNodeId: widget.nodeId,
            recipientNodeId: recipient,
            amountMinorUnits: amountMinorUnits,
            memo: _memoController.text.trim(),
          );
    } on ArgumentError catch (error) {
      errorMessage = error.message ?? error.toString();
    } on StateError catch (error) {
      errorMessage = error.message;
    }

    if (errorMessage != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    if (!mounted) {
      return;
    }

    _recipientController.clear();
    _amountController.clear();
    _memoController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pending spend persisted to the ledger.')),
    );
  }

  void _fillMaxAmount() {
    _amountController.text = (widget.dashboard.availableBalanceMinorUnits / 100)
        .toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Offline Transfer',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF214A2B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SectionCard(
          title: 'Step 1: Target Node',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _InputField(
                controller: _recipientController,
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF577057)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Step 2: Token Payload',
          trailing: Text(
            'Available  ${_formatDtn(widget.dashboard.availableBalanceMinorUnits, includeSign: false)}',
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
                  Expanded(
                    child: _AmountField(
                      controller: _amountController,
                      onMax: _fillMaxAmount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const <Widget>[
                  Expanded(
                    child: _StatusBadge(label: 'TOKEN', value: 'SpendEvent'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatusBadge(label: 'TTL', value: '72 Hours'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _StatusBadge(label: 'ENCAP', value: 'Bundle v6'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InputField(
                controller: _memoController,
                hintText: 'Optional payment memo or purpose',
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Pre-flight Audit',
          child: Column(
            children: <Widget>[
              _AuditRow(
                label: 'Local balance',
                value: _formatDtn(
                  widget.dashboard.balanceMinorUnits,
                  includeSign: false,
                ),
              ),
              _AuditRow(
                label: 'Available balance',
                value: _formatDtn(
                  widget.dashboard.availableBalanceMinorUnits,
                  includeSign: false,
                ),
              ),
              _AuditRow(
                label: 'Pending spends',
                value: widget.dashboard.pendingSpendCount.toString(),
              ),
              _AuditRow(
                label: 'Reserved value',
                value: _formatDtn(
                  widget.dashboard.pendingSpendMinorUnits,
                  includeSign: false,
                ),
              ),
              _AuditRow(
                label: 'Ledger updated',
                value: _formatTimestamp(widget.dashboard.lastUpdated),
              ),
              _AuditRow(
                label: 'Est. bundle size',
                value: '~${widget.dashboard.estimatedBundleBytes} bytes',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submitSpend,
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
  const _WalletLogsSection({required this.dashboard});

  final WalletLedgerDashboard dashboard;

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
        if (dashboard.logEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                'No logs yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6A8067),
                ),
              ),
            ),
          )
        else
          ...dashboard.logEntries.map(
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
  const _WalletRewardsSection({required this.dashboard});

  final WalletLedgerDashboard dashboard;

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
                value: _formatDtn(dashboard.relayRewardsMinorUnits),
                accent: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Pending Rewards',
                value: _formatDtn(
                  dashboard.pendingRewardMinorUnits,
                  includeSign: false,
                ),
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
            children: <Widget>[
              _ProgressLine(
                label: 'Trust Score',
                valueLabel: dashboard.trustScore.toStringAsFixed(2),
                progress: dashboard.trustScore,
                accent: const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 10),
              _ProgressLine(
                label: 'Participation Grade',
                valueLabel: dashboard.participationGrade,
                progress: 0.86,
                accent: const Color(0xFF66A65D),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Reward Ledger',
          child: Column(
            children: dashboard.rewardEntries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RewardEntryTile(entry: entry),
                  ),
                )
                .toList(growable: false),
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
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceCards extends StatelessWidget {
  const _BalanceCards({required this.nodeId, required this.dashboard});

  final String nodeId;
  final WalletLedgerDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final localCard = _BalanceCard(
          title: 'Local Balance',
          amountMinorUnits: dashboard.balanceMinorUnits,
          nodeId: nodeId,
          subtitle: 'Current append-only ledger balance',
        );
        final availableCard = _BalanceCard(
          title: 'Available Balance',
          amountMinorUnits: dashboard.availableBalanceMinorUnits,
          nodeId: nodeId,
          subtitle: dashboard.pendingSpendMinorUnits > 0
              ? '${_formatDtn(dashboard.pendingSpendMinorUnits, includeSign: false)} reserved in pending spends'
              : 'Ready for new offline transactions',
        );

        if (constraints.maxWidth < 680) {
          return Column(
            children: <Widget>[
              localCard,
              const SizedBox(height: 12),
              availableCard,
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: localCard),
            const SizedBox(width: 12),
            Expanded(child: availableCard),
          ],
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.amountMinorUnits,
    required this.nodeId,
    required this.subtitle,
  });

  final String title;
  final int amountMinorUnits;
  final String nodeId;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFF4FAF0),
            Color(0xFFEAF5E4),
          ],
        ),
        border: Border.all(color: const Color(0xFFC9DCC2), width: 1.1),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 2.4,
                color: const Color(0xFF4A6C4A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formatDtn(amountMinorUnits, includeSign: false),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: const Color(0xFF214A2B),
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
              ),
            ),
            const SizedBox(height: 10),
            _MiniBadge(label: _formatUsdApprox(amountMinorUnits), onTap: () {}),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5D725B)),
            ),
            const SizedBox(height: 4),
            Text(
              'Node ${_shortId(nodeId)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF5D725B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
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
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
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
                ?trailing,
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
  const _MetricCard({
    required this.title,
    required this.value,
    required this.accent,
  });

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
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
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

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.entry});

  final WalletLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E7D4)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _entryAccent(entry)),
                ),
                child: Icon(
                  _entryIcon(entry),
                  color: _entryAccent(entry),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(entry.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusBadge(label: 'STATE', value: _entryState(entry)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.memo ?? entry.subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4F6450)),
          ),
          const SizedBox(height: 10),
          Text(
            _formatDtn(entry.amountMinorUnits),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: entry.isDebit
                  ? const Color(0xFF214A2B)
                  : const Color(0xFF2E7D32),
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

  final WalletLedgerEntry entry;

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
            child: Icon(
              _entryIcon(entry),
              color: _entryAccent(entry),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(entry.title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  entry.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDtn(entry.amountMinorUnits),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: entry.isCredit
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF214A2B),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});

  final WalletLedgerEntry entry;

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
          Icon(_entryIcon(entry), size: 22, color: _entryAccent(entry)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  entry.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatDtn(entry.amountMinorUnits),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: entry.isDebit
                  ? const Color(0xFF214A2B)
                  : const Color(0xFF2E7D32),
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
  const _MiniActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    this.trailing,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget? trailing;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E7D4)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6A8067)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
          suffixIcon: trailing,
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.onMax});

  final TextEditingController controller;
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
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
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
    final Color borderColor =
        accent ?? (active ? const Color(0xFF4EA058) : const Color(0xFFD9E7D4));
    final Color textColor =
        accent ?? (active ? const Color(0xFF245A2A) : const Color(0xFF4F6450));

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

IconData _entryIcon(WalletLedgerEntry entry) {
  return switch (entry.kind) {
    WalletLedgerEventKind.openingGrant => Icons.spa_rounded,
    WalletLedgerEventKind.relayReward => Icons.wifi_tethering_rounded,
    WalletLedgerEventKind.gatewayReward => Icons.router_rounded,
    WalletLedgerEventKind.spend => Icons.arrow_upward_rounded,
    WalletLedgerEventKind.confirmation => Icons.check_circle_outline_rounded,
    WalletLedgerEventKind.rejection => Icons.block_rounded,
  };
}

Color _entryAccent(WalletLedgerEntry entry) {
  return switch (entry.kind) {
    WalletLedgerEventKind.openingGrant => const Color(0xFF4EA058),
    WalletLedgerEventKind.relayReward => const Color(0xFF2E7D32),
    WalletLedgerEventKind.gatewayReward => const Color(0xFF66A65D),
    WalletLedgerEventKind.spend => const Color(0xFF2E7D32),
    WalletLedgerEventKind.confirmation => const Color(0xFF4EA058),
    WalletLedgerEventKind.rejection => const Color(0xFFFF8E3D),
  };
}

String _entryState(WalletLedgerEntry entry) {
  return switch (entry.status) {
    WalletLedgerStatus.confirmed => 'CONFIRMED',
    WalletLedgerStatus.pending => 'PENDING',
    WalletLedgerStatus.rejected => 'REJECTED',
  };
}

String _formatDtn(int minorUnits, {bool includeSign = true}) {
  final absValue = minorUnits.abs();
  final major = absValue ~/ 100;
  final minor = absValue % 100;
  final formattedMajor = _formatThousands(major);
  final prefix = includeSign ? (minorUnits < 0 ? '-' : '+') : '';
  return '$prefix$formattedMajor.${minor.toString().padLeft(2, '0')} DTN';
}

String _formatUsdApprox(int minorUnits) {
  final usdValue = (minorUnits.abs() / 100) * 0.24;
  return '≈ ${minorUnits < 0 ? '-' : ''}\$${usdValue.toStringAsFixed(2)} USD';
}

String _formatThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _formatTimestamp(DateTime timestamp) {
  final year = timestamp.year.toString().padLeft(4, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  final day = timestamp.day.toString().padLeft(2, '0');
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute UTC';
}

String _shortId(String nodeId) {
  if (nodeId.length <= 12) {
    return nodeId;
  }
  return '${nodeId.substring(0, 4)}…${nodeId.substring(nodeId.length - 4)}';
}
