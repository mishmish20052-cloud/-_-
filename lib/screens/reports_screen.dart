import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'package:daftar_alhesabat/models/account.dart';
import 'package:daftar_alhesabat/models/transaction.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// ────────────────────────────────────────────────────────────
// مُساعِد التصدير الموحَّد (لمنع تكرار الكود)
// ────────────────────────────────────────────────────────────
class ExportHelper {
  static Future<void> sharePdf(BuildContext context, String title, Future<List<int>> generatePdf) async {
    final pdfBytes = await generatePdf;
    await Printing.sharePdf(bytes: Uint8List.fromList(pdfBytes), filename: '$title.pdf');
  }

  static Future<void> saveExcel(BuildContext context, String title, Future<List<int>> generateExcel) async {
    final excelBytes = await generateExcel;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.xlsx');
    await file.writeAsBytes(excelBytes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ Excel في ${file.path}')));
    }
  }

  static Future<void> saveCsv(BuildContext context, String title, Future<List<int>> generateCsv) async {
    final csvBytes = await generateCsv;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.csv');
    await file.writeAsBytes(csvBytes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ CSV في ${file.path}')));
    }
  }

  static Widget buildExportButtons(BuildContext context, {
    required Future<List<int>> Function() onPdf,
    required Future<List<int>> Function() onExcel,
    required Future<List<int>> Function() onCsv,
    required String title,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => sharePdf(context, title, onPdf()),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('PDF'),
        ),
        ElevatedButton.icon(
          onPressed: () => saveExcel(context, title, onExcel()),
          icon: const Icon(Icons.table_chart),
          label: const Text('Excel'),
        ),
        ElevatedButton.icon(
          onPressed: () => saveCsv(context, title, onCsv()),
          icon: const Icon(Icons.description),
          label: const Text('CSV'),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// الشاشة الرئيسية للتقارير
// ────────────────────────────────────────────────────────────
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final HiveService _hiveService = HiveService();
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _accounts = _hiveService.getAccounts();
      _transactions = _hiveService.transactionsBox.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildReportButton(context, 'تقرير إجمالي المبالغ (لكل عميل)',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => TotalAmountsReportView(accounts: _accounts)))),
            _buildReportButton(context, 'تقرير تفاصيل كل المبالغ (جميع المعاملات)',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailedTransactionsReportView(transactions: _transactions, accounts: _accounts)))),
            _buildReportButton(context, 'تقرير إجمالي المبالغ شهرياً (رسم بياني)',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonthlyAmountsChartView(transactions: _transactions)))),
            _buildReportButton(context, 'تقرير إجمالي التصنيفات (رسم بياني)',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriesPieChartView(accounts: _accounts)))),
            _buildReportButton(context, 'تقرير حركة الحسابات (يومية/أسبوعية)',
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountMovementReportView(transactions: _transactions, accounts: _accounts)))),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context, String title, VoidCallback onPressed) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(title: Text(title), trailing: const Icon(Icons.arrow_forward_ios), onTap: onPressed),
    );
  }
}

// ────────────────────────────────────────────────────────────
// 1. تقرير إجمالي المبالغ (لكل عميل)
// ────────────────────────────────────────────────────────────
class TotalAmountsReportView extends StatelessWidget {
  final List<Account> accounts;
  const TotalAmountsReportView({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقرير إجمالي المبالغ')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(),
                  columnWidths: const {0: FixedColumnWidth(120), 1: FixedColumnWidth(80), 2: FixedColumnWidth(80), 3: FixedColumnWidth(80)},
                  children: [
                    TableRow(children: ['العميل', 'عليه', 'له', 'العملة'].map((t) => _buildCell(t, isHeader: true)).toList()),
                    ...accounts.map((a) => TableRow(children: [a.name, a.balanceDue.toStringAsFixed(2), a.balanceFor.toStringAsFixed(2), a.currency].map((t) => _buildCell(t)).toList())),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ExportHelper.buildExportButtons(
                context,
                title: 'تقرير إجمالي المبالغ',
                onPdf: () => _generatePdf(),
                onExcel: () => _generateExcel(),
                onCsv: () => _generateCsv(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(text, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
  );

  Future<List<int>> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (_) => pw.Column(children: [
      pw.Text('تقرير إجمالي المبالغ', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 20),
      pw.Table.fromTextArray(headers: ['العميل', 'عليه', 'له', 'العملة'], data: accounts.map((a) => [a.name, a.balanceDue.toStringAsFixed(2), a.balanceFor.toStringAsFixed(2), a.currency]).toList()),
    ])));
    return pdf.save();
  }

  Future<List<int>> _generateExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(['العميل', 'عليه', 'له', 'العملة']);
    for (final a in accounts) sheet.appendRow([a.name, a.balanceDue.toStringAsFixed(2), a.balanceFor.toStringAsFixed(2), a.currency]);
    return excel.encode()!;
  }

  Future<List<int>> _generateCsv() async {
    final rows = [['العميل', 'عليه', 'له', 'العملة'], ...accounts.map((a) => [a.name, a.balanceDue.toStringAsFixed(2), a.balanceFor.toStringAsFixed(2), a.currency])];
    return utf8.encode(const ListToCsvConverter().convert(rows));
  }
}

// ────────────────────────────────────────────────────────────
// 2. تقرير تفاصيل كل المبالغ (جميع المعاملات) – مع تحسين الأداء
// ────────────────────────────────────────────────────────────
class DetailedTransactionsReportView extends StatelessWidget {
  final List<Transaction> transactions;
  final Map<String, String> accountNameMap;
  DetailedTransactionsReportView({super.key, required List<Transaction> transactions, required List<Account> accounts})
      : transactions = transactions,
        accountNameMap = {for (var a in accounts) a.id: a.name};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقرير تفاصيل كل المبالغ')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(),
                  columnWidths: const {0: FixedColumnWidth(100), 1: FixedColumnWidth(120), 2: FixedColumnWidth(80), 3: FixedColumnWidth(70), 4: FixedColumnWidth(150)},
                  children: [
                    TableRow(children: ['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة'].map((t) => _buildCell(t, isHeader: true)).toList()),
                    ...transactions.map((t) => TableRow(children: [
                      DateFormat('yyyy-MM-dd').format(t.date),
                      accountNameMap[t.accountId] ?? 'غير معروف',
                      t.amount.toStringAsFixed(2),
                      t.type == 'due' ? 'عليه' : 'له',
                      t.note ?? ''
                    ].map((t) => _buildCell(t)).toList())),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ExportHelper.buildExportButtons(
                context,
                title: 'تقرير تفاصيل المبالغ',
                onPdf: () => _generatePdf(),
                onExcel: () => _generateExcel(),
                onCsv: () => _generateCsv(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(text, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
  );

  Future<List<int>> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (_) => pw.Column(children: [
      pw.Text('تقرير تفاصيل المبالغ', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 20),
      pw.Table.fromTextArray(
        headers: ['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة'],
        data: transactions.map((t) => [DateFormat('yyyy-MM-dd').format(t.date), accountNameMap[t.accountId] ?? 'غير معروف', t.amount.toStringAsFixed(2), t.type == 'due' ? 'عليه' : 'له', t.note ?? '']).toList(),
      ),
    ])));
    return pdf.save();
  }

  Future<List<int>> _generateExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة']);
    for (final t in transactions) {
      sheet.appendRow([DateFormat('yyyy-MM-dd').format(t.date), accountNameMap[t.accountId] ?? 'غير معروف', t.amount.toStringAsFixed(2), t.type == 'due' ? 'عليه' : 'له', t.note ?? '']);
    }
    return excel.encode()!;
  }

  Future<List<int>> _generateCsv() async {
    final rows = [['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة'], ...transactions.map((t) => [DateFormat('yyyy-MM-dd').format(t.date), accountNameMap[t.accountId] ?? 'غير معروف', t.amount.toStringAsFixed(2), t.type == 'due' ? 'عليه' : 'له', t.note ?? ''])];
    return utf8.encode(const ListToCsvConverter().convert(rows));
  }
}

// ────────────────────────────────────────────────────────────
// 3. تقرير إجمالي المبالغ شهرياً (رسم بياني)
// ────────────────────────────────────────────────────────────
class MonthlyAmountsChartView extends StatelessWidget {
  final List<Transaction> transactions;
  const MonthlyAmountsChartView({super.key, required this.transactions});

  Map<String, double> _getMonthlyTotals() {
    final map = <String, double>{};
    for (final t in transactions) {
      final key = DateFormat('yyyy-MM').format(t.date);
      map.update(key, (v) => v + t.amount, ifAbsent: () => t.amount);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotals = _getMonthlyTotals();
    final sortedMonths = monthlyTotals.keys.toList()..sort();
    final barGroups = List.generate(sortedMonths.length, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: monthlyTotals[sortedMonths[i]]!, color: Colors.blue, width: 15)]));

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير إجمالي المبالغ شهرياً')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: BarChart(BarChartData(
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= sortedMonths.length) return const SizedBox();
                      return SideTitleWidget(axisSide: meta.axisSide, child: Text(sortedMonths[value.toInt()], style: const TextStyle(fontSize: 10)));
                    },
                    interval: 1,
                  )),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
              )),
            ),
            const SizedBox(height: 20),
            ExportHelper.buildExportButtons(
              context,
              title: 'تقرير إجمالي المبالغ شهرياً',
              onPdf: () => _generatePdf(monthlyTotals, sortedMonths),
              onExcel: () => _generateExcel(monthlyTotals, sortedMonths),
              onCsv: () => _generateCsv(monthlyTotals, sortedMonths),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<int>> _generatePdf(Map<String, double> totals, List<String> months) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (_) => pw.Column(children: [
      pw.Text('تقرير إجمالي المبالغ شهرياً', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 20),
      pw.Table.fromTextArray(headers: ['الشهر', 'الإجمالي'], data: months.map((m) => [m, totals[m]!.toStringAsFixed(2)]).toList()),
    ])));
    return pdf.save();
  }

  Future<List<int>> _generateExcel(Map<String, double> totals, List<String> months) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(['الشهر', 'الإجمالي']);
    for (final m in months) sheet.appendRow([m, totals[m]!.toStringAsFixed(2)]);
    return excel.encode()!;
  }

  Future<List<int>> _generateCsv(Map<String, double> totals, List<String> months) async {
    final rows = [['الشهر', 'الإجمالي'], ...months.map((m) => [m, totals[m]!.toStringAsFixed(2)])];
    return utf8.encode(const ListToCsvConverter().convert(rows));
  }
}

// ────────────────────────────────────────────────────────────
// 4. تقرير إجمالي التصنيفات (رسم بياني دائري)
// ────────────────────────────────────────────────────────────
class CategoriesPieChartView extends StatelessWidget {
  final List<Account> accounts;
  const CategoriesPieChartView({super.key, required this.accounts});

  Map<String, double> _getCategoryTotals() {
    final map = <String, double>{};
    for (final a in accounts) {
      final diff = (a.balanceDue - a.balanceFor).abs(); // إجمالي المبلغ المتبقي (دين أو ائتمان)
      if (diff > 0) map.update(a.category, (v) => v + diff, ifAbsent: () => diff);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _getCategoryTotals();
    final total = categoryTotals.values.fold(0.0, (s, v) => s + v);
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.brown];
    int i = 0;
    final sections = categoryTotals.entries.map((e) {
      final percent = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0.0';
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${e.key}\n$percent%',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير إجمالي التصنيفات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 40, borderData: FlBorderData(show: false)))),
            const SizedBox(height: 20),
            ExportHelper.buildExportButtons(
              context,
              title: 'تقرير إجمالي التصنيفات',
              onPdf: () => _generatePdf(categoryTotals),
              onExcel: () => _generateExcel(categoryTotals),
              onCsv: () => _generateCsv(categoryTotals),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<int>> _generatePdf(Map<String, double> totals) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (_) => pw.Column(children: [
      pw.Text('تقرير إجمالي التصنيفات', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 20),
      pw.Table.fromTextArray(headers: ['التصنيف', 'الإجمالي'], data: totals.entries.map((e) => [e.key, e.value.toStringAsFixed(2)]).toList()),
    ])));
    return pdf.save();
  }

  Future<List<int>> _generateExcel(Map<String, double> totals) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(['التصنيف', 'الإجمالي']);
    for (final e in totals.entries) sheet.appendRow([e.key, e.value.toStringAsFixed(2)]);
    return excel.encode()!;
  }

  Future<List<int>> _generateCsv(Map<String, double> totals) async {
    final rows = [['التصنيف', 'الإجمالي'], ...totals.entries.map((e) => [e.key, e.value.toStringAsFixed(2)])];
    return utf8.encode(const ListToCsvConverter().convert(rows));
  }
}

// ────────────────────────────────────────────────────────────
// 5. تقرير حركة الحسابات (يومية) – مع تحسين الأداء
// ────────────────────────────────────────────────────────────
class AccountMovementReportView extends StatelessWidget {
  final List<Transaction> transactions;
  final Map<String, String> accountNameMap;
  AccountMovementReportView({super.key, required List<Transaction> transactions, required List<Account> accounts})
      : transactions = transactions,
        accountNameMap = {for (var a in accounts) a.id: a.name};

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Transaction>>{};
    for (final t in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(t.date);
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }
    final sortedDates = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير حركة الحسابات')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...sortedDates.map((date) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(date, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      border: TableBorder.all(),
                      columnWidths: const {0: FixedColumnWidth(120), 1: FixedColumnWidth(80), 2: FixedColumnWidth(70), 3: FixedColumnWidth(150)},
                      children: [
                        TableRow(children: ['العميل', 'المبلغ', 'النوع', 'ملاحظة'].map((t) => _buildCell(t, isHeader: true)).toList()),
                        ...grouped[date]!.map((t) => TableRow(children: [
                          accountNameMap[t.accountId] ?? 'غير معروف',
                          t.amount.toStringAsFixed(2),
                          t.type == 'due' ? 'عليه' : 'له',
                          t.note ?? ''
                        ].map((t) => _buildCell(t)).toList())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              )),
              ExportHelper.buildExportButtons(
                context,
                title: 'تقرير حركة الحسابات',
                onPdf: () => _generatePdf(grouped, sortedDates),
                onExcel: () => _generateExcel(grouped, sortedDates),
                onCsv: () => _generateCsv(grouped, sortedDates),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false}) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(text, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
  );

  Future<List<int>> _generatePdf(Map<String, List<Transaction>> grouped, List<String> dates) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (_) => pw.Column(children: [
      pw.Text('تقرير حركة الحسابات', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 20),
      ...dates.map((date) => pw.Column(children: [
        pw.Text(date, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['العميل', 'المبلغ', 'النوع', 'ملاحظة'],
          data: grouped[date]!.map((t) => [accountNameMap[t.accountId] ?? 'غير معروف', t.amount.toStringAsFixed(2), t.type == 'due' ? 'عليه' : 'له', t.note ?? '']).toList(),
        ),
        pw.SizedBox(height: 20),
      ])),
    ])));
    return pdf.save();
  }

  Future<List<int>> _generateExcel(Map<String, List<Transaction>> grouped, List<String> dates) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة']);
    for (final date in dates) {
      for (final t in grouped[date]!) {
        sheet.appendRow([date, accountNameMap[t.accountId] ?? 'غير معروف', t.amount.toStringAsFixed(2), t.type == 'due' ? 'عليه' : 'له', t.note ?? '']);
      }
    }
    return excel.encode()!;
  }

  Future<List<int>> _generateCsv(Map<String, List<Transaction>> grouped, List<String> dates) async {
    final rows = [['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة']];
    for (final date in dates) {
      for (final t in grouped[date]!) {
        rows.add([date, accountNameMap[t.accountId] ?? 'غير معروف', t.amount.toStringAsFixed(2), t.type == 'due' ? 'عليه' : 'له', t.note ?? '']);
      }
    }
    return utf8.encode(const ListToCsvConverter().convert(rows));
  }
}
