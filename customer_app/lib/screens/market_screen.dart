import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../utils/animations.dart';
import '../widgets/glass_container.dart';
import '../models/models.dart';
import '../localization/string_extension.dart';
import 'main_shell.dart';
import 'dart:math' as math;

class MarketScreen extends StatefulWidget {
  final AppState appState;
  const MarketScreen({super.key, required this.appState});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with TickerProviderStateMixin {
  String _selectedPeriod = '1W';
  static const List<String> _periods = ['1D', '1W', '1M', '1Y', 'ALL'];

  late final List<double> _chartValues;
  late final List<bool> _isUpFlags;

  @override
  void initState() {
    super.initState();
    _generateChart();
  }

  void _generateChart() {
    final rnd = math.Random(7);
    final count = _selectedPeriod == '1D'
        ? 24
        : _selectedPeriod == '1W'
            ? 28
            : _selectedPeriod == '1M'
                ? 32
                : _selectedPeriod == '1Y'
                    ? 40
                    : 50;
    _chartValues = List.generate(count, (i) {
      final base = 30 + math.sin(i * 0.4) * 22;
      final noise = rnd.nextDouble() * 30;
      return base + noise;
    });
    _isUpFlags = List.generate(count, (i) {
      if (i == 0) return true;
      return _chartValues[i] >= _chartValues[i - 1];
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaggeredItem(
                index: 0,
                child: Text(
                  'Terra Currency Market'.tr(context),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: EarthTheme.forestGreen,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              StaggeredItem(
                index: 1,
                child: Text(
                  'Trade tokens at peer-to-peer rates'.tr(context),
                  style: TextStyle(
                    fontSize: 14,
                    color: EarthTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Wallet summary card with animated counters
              StaggeredItem(
                index: 2,
                child: _buildWalletCard(),
              ),
              const SizedBox(height: 14),

              // Chart card
              StaggeredItem(
                index: 3,
                child: _buildChartCard(),
              ),
              const SizedBox(height: 16),

              // Trade buttons
              StaggeredItem(
                index: 4,
                child: Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: 'Buy Terra'.tr(context),
                        icon: Icons.arrow_downward_rounded,
                        height: 54,
                        onPressed: () => _showTradeSheet(context, 'buy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_upward_rounded,
                            size: 18),
                        label: Text('Sell Terra'.tr(context)),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: EarthTheme.clayOchre,
                          side: const BorderSide(
                            color: EarthTheme.clayOchre,
                            width: 1.4,
                          ),
                        ),
                        onPressed: () => _showTradeSheet(context, 'sell'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              StaggeredItem(
                index: 5,
                child: _buildTradesCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF233D34), Color(0xFF152721), Color(0xFF0F201B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
        boxShadow: EarthTheme.forestGlow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    EarthTheme.terracotta.withValues(alpha: 0.30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Your Wallet'.tr(context),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  PillBadge(
                    label: 'LIVE',
                    color: const Color(0xFF7BB892),
                    textColor: Colors.white,
                    dot: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TERRA TOKENS',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.55),
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedCounter(
                          value: widget.appState.tokenBalance,
                          decimals: 1,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'USD BALANCE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.55),
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedCounter(
                            value: widget.appState.fiatBalance,
                            decimals: 2,
                            prefix: '\$',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final isUp = _chartValues.last >= _chartValues.first;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
        border: Border.all(color: EarthTheme.borderLight),
        boxShadow: EarthTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'TERRA/USD',
                        style: TextStyle(
                          fontSize: 11,
                          color: EarthTheme.muted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isUp
                              ? const Color(0xFFEAF4EE)
                              : EarthTheme.dangerBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUp
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 11,
                              color: isUp
                                  ? EarthTheme.success
                                  : EarthTheme.danger,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '4.20%',
                              style: TextStyle(
                                fontSize: 10,
                                color: isUp
                                    ? EarthTheme.success
                                    : EarthTheme.danger,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${widget.appState.terraRate.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: EarthTheme.forestGreen,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'High',
                    style: TextStyle(
                      fontSize: 10,
                      color: EarthTheme.muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Text(
                    '\$1.34',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: EarthTheme.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Low',
                    style: TextStyle(
                      fontSize: 10,
                      color: EarthTheme.muted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Text(
                    '\$1.18',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: EarthTheme.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          AnimatedBarChart(
            values: _chartValues,
            colorFor: (i, isUpFlag) => _isUpFlags[i]
                ? const Color(0xFF7BB892)
                : EarthTheme.terracotta,
            maxHeight: 110,
            duration: const Duration(milliseconds: 850),
          ),

          const SizedBox(height: 14),
          // Period pills
          Row(
            children: _periods.map((p) {
              final active = p == _selectedPeriod;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = p;
                        _generateChart();
                      });
                    },
                    child: AnimatedContainer(
                      duration: EarthTheme.dur,
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? EarthTheme.terracotta
                            : EarthTheme.warmSandLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active
                              ? EarthTheme.terracotta
                              : EarthTheme.borderLight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? Colors.white
                                : EarthTheme.muted,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTradesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
        border: Border.all(color: EarthTheme.borderLight),
        boxShadow: EarthTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [EarthTheme.terracotta, EarthTheme.clayOchre],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recent Trades'.tr(context),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: EarthTheme.forestGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.appState.trades.isEmpty)
            _buildEmptyTrades()
          else
            ...widget.appState.trades.reversed.take(5).map(
              (t) => _buildTradeItem(t),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTrades() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [EarthTheme.sageLight, EarthTheme.ochreLight],
              ),
            ),
            child: const Center(
              child: Text('📈', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No trades yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: EarthTheme.forestGreen,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Buy or sell Terra to see your trade history',
            style: TextStyle(
              fontSize: 12,
              color: EarthTheme.muted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTradeItem(Trade trade) {
    final isBuy = trade.type == 'buy';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBuy ? EarthTheme.sageLight : EarthTheme.terracottaSoft,
        borderRadius: BorderRadius.circular(EarthTheme.radiusSm),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Icon(
                isBuy
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                size: 18,
                color: isBuy ? EarthTheme.success : EarthTheme.terracotta,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isBuy ? 'Bought' : 'Sold'} ${trade.amount.toStringAsFixed(1)} TERRA',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: EarthTheme.charcoal,
                  ),
                ),
                Text(
                  'Today at ${trade.time}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: EarthTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${isBuy ? '-' : '+'}\$${trade.usd.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: isBuy ? EarthTheme.terracotta : EarthTheme.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTradeSheet(BuildContext context, String type) {
    final isBuy = type == 'buy';
    double amount = 20;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final usd = amount * widget.appState.terraRate;
            final available = isBuy
                ? widget.appState.fiatBalance
                : widget.appState.tokenBalance;

            return Container(
              padding: EdgeInsets.fromLTRB(
                22,
                14,
                22,
                MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              decoration: const BoxDecoration(
                color: EarthTheme.warmSand,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: EarthTheme.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isBuy
                                ? const [EarthTheme.success, EarthTheme.sageGreen]
                                : const [
                                    EarthTheme.terracotta,
                                    EarthTheme.clayOchre,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          isBuy
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBuy ? 'Buy Terra' : 'Sell Terra',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: EarthTheme.forestGreen,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              isBuy
                                  ? 'Convert USD to Terra tokens'
                                  : 'Convert Terra tokens to USD',
                              style: TextStyle(
                                fontSize: 12,
                                color: EarthTheme.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(EarthTheme.radiusMd),
                      border: Border.all(color: EarthTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount (TERRA)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: EarthTheme.muted,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  fillColor: Colors.transparent,
                                  filled: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: EarthTheme.forestGreen,
                                  letterSpacing: -0.4,
                                ),
                                controller: TextEditingController(
                                  text: amount.toStringAsFixed(0),
                                ),
                                onChanged: (v) {
                                  setModalState(() {
                                    amount = double.tryParse(v) ?? 0;
                                  });
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: EarthTheme.ochreLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'TERRA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: EarthTheme.clayOchre,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 1,
                          color: EarthTheme.borderLight,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rate: \$${widget.appState.terraRate.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: EarthTheme.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '≈ \$${usd.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: EarthTheme.forestGreen,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text(
                        'Available:',
                        style: TextStyle(
                          fontSize: 12,
                          color: EarthTheme.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBuy
                            ? '\$${available.toStringAsFixed(2)}'
                            : '${available.toStringAsFixed(1)} TERRA',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: EarthTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [25, 50, 75, 100].map((pct) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              final max = isBuy
                                  ? widget.appState.fiatBalance /
                                      widget.appState.terraRate
                                  : widget.appState.tokenBalance;
                              amount = (max * pct / 100).floorToDouble();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  EarthTheme.sageLight,
                                  EarthTheme.mintFaint,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: EarthTheme.mint,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$pct%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: EarthTheme.forestGreen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  GradientButton(
                    label: isBuy
                        ? 'Buy ${amount.toStringAsFixed(0)} TERRA'
                        : 'Sell ${amount.toStringAsFixed(0)} TERRA',
                    icon: isBuy
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    height: 56,
                    onPressed: () {
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Enter a valid amount')),
                        );
                        return;
                      }
                      final ok = widget.appState
                          .executeTradeSimple(type, amount);
                      Navigator.pop(context);
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isBuy
                                ? 'Bought ${amount.toStringAsFixed(0)} TERRA! 🪙'
                                : 'Sold ${amount.toStringAsFixed(0)} TERRA for \$${usd.toStringAsFixed(2)}!'),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Insufficient ${isBuy ? 'USD' : 'TERRA'} balance!'),
                            backgroundColor: EarthTheme.warning,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
