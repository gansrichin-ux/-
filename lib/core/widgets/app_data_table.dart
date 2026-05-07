import 'package:flutter/material.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_text_styles.dart';

class AppDataColumn {
  final String label;
  final bool isNumeric;

  const AppDataColumn(this.label, {this.isNumeric = false});
}

class AppDataRow {
  final List<Widget> cells;
  final VoidCallback? onTap;

  const AppDataRow({required this.cells, this.onTap});
}

class AppDataTable extends StatelessWidget {
  final List<AppDataColumn> columns;
  final List<AppDataRow> rows;
  final Widget Function(BuildContext, AppDataRow)? mobileCardBuilder;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.mobileCardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isDesktop(context) && mobileCardBuilder != null) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            mobileCardBuilder!(context, rows[index]),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: AppTextStyles.label,
        dataTextStyle: AppTextStyles.bodyMedium,
        showCheckboxColumn: false,
        columns: columns
            .map((c) => DataColumn(
                  label: Text(c.label),
                  numeric: c.isNumeric,
                ))
            .toList(),
        rows: rows
            .map((r) => DataRow(
                  onSelectChanged: r.onTap != null ? (_) => r.onTap!() : null,
                  cells: r.cells.map((cell) => DataCell(cell)).toList(),
                ))
            .toList(),
      ),
    );
  }
}
