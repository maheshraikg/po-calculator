import 'package:flutter/material.dart';

import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../domain/models/scheme.dart';
import '../../domain/models/tool.dart';
import '../../widgets/common.dart';
import '../staff/custom_interest_card.dart';
import '../staff/official_forms.dart';
import '../staff/rd_rebate_card.dart';
import '../staff/service_charges.dart';

extension ToolX on Tool {
  IconData get icon => switch (this) {
    Tool.rdRebate => Icons.savings_rounded,
    Tool.customInterest => Icons.calculate_rounded,
    Tool.forms => Icons.description_rounded,
    Tool.serviceCharges => Icons.request_quote_rounded,
  };

  Color get color => switch (this) {
    Tool.rdRebate => Scheme.rd.color,
    Tool.customInterest => Brand.red,
    Tool.forms => const Color(0xFF1565C0),
    Tool.serviceCharges => const Color(0xFF6D4C41),
  };
}

void openTool(BuildContext context, Tool tool) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => ToolScreen(tool: tool)));

class ToolScreen extends StatelessWidget {
  const ToolScreen({super.key, required this.tool});
  final Tool tool;

  @override
  Widget build(BuildContext context) {
    final s = context.s, c = tool.color;
    return Scaffold(
      appBar: AppBar(title: Text(s.toolName(tool))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          switch (tool) {
            Tool.rdRebate => RdRebateCard(color: c),
            Tool.customInterest => CustomInterestCard(color: c),
            Tool.forms => OfficialForms(color: c),
            Tool.serviceCharges => ServiceCharges(color: c),
          },
          Note(s.estimateOnly),
        ],
      ),
    );
  }
}

/// A compact tile for one tool on the Home screen.
class ToolTile extends StatelessWidget {
  const ToolTile({super.key, required this.tool});
  final Tool tool;

  @override
  Widget build(BuildContext context) {
    final s = context.s, t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openTool(context, tool),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              IconBadge(tool.icon, tool.color, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.toolName(tool),
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
