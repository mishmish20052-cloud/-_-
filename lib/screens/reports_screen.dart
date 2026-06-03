
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
      appBar: AppBar(
        title: const Text('التقارير'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildReportButton(
              context,
              'تقرير إجمالي المبالغ (لكل عميل)',
              () => _showTotalAmountsReport(context),
            ),
            _buildReportButton(
              context,
              'تقرير تفاصيل كل المبالغ (جميع المعاملات)',
              () => _showDetailedTransactionsReport(context),
            ),
            _buildReportButton(
              context,
              'تقرير إجمالي المبالغ شهرياً (رسم بياني)',
              () => _showMonthlyAmountsChart(context),
            ),
            _buildReportButton(
              context,
              'تقرير إجمالي التصنيفات (رسم بياني)',
              () => _showCategoriesPieChart(context),
            ),
            _buildReportButton(
              context,
              'تقرير حركة الحسابات (يومية/أسبوعية)',
              () => _showAccountMovementReport(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton(BuildContext context, String title, VoidCallback onPressed) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onPressed,
      ),
    );
  }

  // --- Report Views --- //

  void _showTotalAmountsReport(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => TotalAmountsReportView(accounts: _accounts)));
  }

  void _showDetailedTransactionsReport(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailedTransactionsReportView(transactions: _transactions, accounts: _accounts)));
  }

  void _showMonthlyAmountsChart(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => MonthlyAmountsChartView(transactions: _transactions)));
  }

  void _showCategoriesPieChart(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CategoriesPieChartView(accounts: _accounts)));
  }

  void _showAccountMovementReport(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => AccountMovementReportView(transactions: _transactions, accounts: _accounts)));
  }
}

// --- Individual Report Views (Placeholders) --- //

class TotalAmountsReportView extends StatelessWidget {
  final List<Account> accounts;
  const TotalAmountsReportView({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقرير إجمالي المبالغ')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Report content here
              Table(
                border: TableBorder.all(),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      _buildTableCell('العميل', isHeader: true),
                      _buildTableCell('عليه', isHeader: true),
                      _buildTableCell('له', isHeader: true),
                      _buildTableCell('العملة', isHeader: true),
                    ],
                  ),
                  ...accounts.map((account) => TableRow(
                    children: [
                      _buildTableCell(account.name),
                      _buildTableCell(account.balanceDue.toStringAsFixed(2)),
                      _buildTableCell(account.balanceFor.toStringAsFixed(2)),
                      _buildTableCell(account.currency),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _exportToPdf(context, 'تقرير إجمالي المبالغ', _generateTotalAmountsPdf),
                    icon: const Icon(Icons.picture_as_pdf), label: const Text('تصدير PDF')),
                  ElevatedButton.icon(
                    onPressed: () => _exportToExcel(context, 'تقرير إجمالي المبالغ', _generateTotalAmountsExcel),
                    icon: const Icon(Icons.table_chart), label: const Text('تصدير Excel')),
                  ElevatedButton.icon(
                    onPressed: () => _exportToCsv(context, 'تقرير إجمالي المبالغ', _generateTotalAmountsCsv),
                    icon: const Icon(Icons.description), label: const Text('تصدير CSV')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _exportToPdf(BuildContext context, String title, Future<List<int>> Function() generatePdf) async {
    final pdfBytes = await generatePdf();
    await Printing.sharePdf(bytes: pdfBytes, filename: '$title.pdf');
  }

  Future<List<int>> _generateTotalAmountsPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('تقرير إجمالي المبالغ', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['العميل', 'عليه', 'له', 'العملة'],
                data: accounts.map((account) => [
                  account.name,
                  account.balanceDue.toStringAsFixed(2),
                  account.balanceFor.toStringAsFixed(2),
                  account.currency,
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _exportToExcel(BuildContext context, String title, Future<List<int>> Function() generateExcel) async {
    final excelBytes = await generateExcel();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.xlsx');
    await file.writeAsBytes(excelBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ملف Excel في ${file.path}')));
    // Optionally, open the file or share it
  }

  Future<List<int>> _generateTotalAmountsExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow(['العميل', 'عليه', 'له', 'العملة']);
    for (var account in accounts) {
      sheetObject.appendRow([
        account.name,
        account.balanceDue.toStringAsFixed(2),
        account.balanceFor.toStringAsFixed(2),
        account.currency,
      ]);
    }
    return excel.encode()!;
  }

  Future<void> _exportToCsv(BuildContext context, String title, Future<List<int>> Function() generateCsv) async {
    final csvBytes = await generateCsv();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.csv');
    await file.writeAsBytes(csvBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ملف CSV في ${file.path}')));
    // Optionally, open the file or share it
  }

  Future<List<int>> _generateTotalAmountsCsv() async {
    List<List<dynamic>> rows = [];
    rows.add(['العميل', 'عليه', 'له', 'العملة']);
    for (var account in accounts) {
      rows.add([
        account.name,
        account.balanceDue.toStringAsFixed(2),
        account.balanceFor.toStringAsFixed(2),
        account.currency,
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    return Future.value(utf8.encode(csv));
  }
}

class DetailedTransactionsReportView extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Account> accounts;
  const DetailedTransactionsReportView({super.key, required this.transactions, required this.accounts});

  String _getAccountName(String accountId) {
    return accounts.firstWhere((acc) => acc.id == accountId, orElse: () => Account(id: '', name: 'غير معروف', currency: '', category: '')).name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقرير تفاصيل كل المبالغ')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Table(
                border: TableBorder.all(),
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    children: [
                      _buildTableCell('التاريخ', isHeader: true),
                      _buildTableCell('العميل', isHeader: true),
                      _buildTableCell('المبلغ', isHeader: true),
                      _buildTableCell('النوع', isHeader: true),
                      _buildTableCell('ملاحظة', isHeader: true),
                    ],
                  ),
                  ...transactions.map((transaction) => TableRow(
                    children: [
                      _buildTableCell(DateFormat('yyyy-MM-dd').format(transaction.date)),
                      _buildTableCell(_getAccountName(transaction.accountId)),
                      _buildTableCell(transaction.amount.toStringAsFixed(2)),
                      _buildTableCell(transaction.type == 'due' ? 'عليه' : 'له'),
                      _buildTableCell(transaction.note ?? ''),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _exportToPdf(context, 'تقرير تفاصيل المبالغ', _generateDetailedTransactionsPdf),
                    icon: const Icon(Icons.picture_as_pdf), label: const Text('تصدير PDF')),
                  ElevatedButton.icon(
                    onPressed: () => _exportToExcel(context, 'تقرير تفاصيل المبالغ', _generateDetailedTransactionsExcel),
                    icon: const Icon(Icons.table_chart), label: const Text('تصدير Excel')),
                  ElevatedButton.icon(
                    onPressed: () => _exportToCsv(context, 'تقرير تفاصيل المبالغ', _generateDetailedTransactionsCsv),
                    icon: const Icon(Icons.description), label: const Text('تصدير CSV')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _exportToPdf(BuildContext context, String title, Future<List<int>> Function() generatePdf) async {
    final pdfBytes = await generatePdf();
    await Printing.sharePdf(bytes: pdfBytes, filename: '$title.pdf');
  }

  Future<List<int>> _generateDetailedTransactionsPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('تقرير تفاصيل كل المبالغ', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة'],
                data: transactions.map((transaction) => [
                  DateFormat('yyyy-MM-dd').format(transaction.date),
                  _getAccountName(transaction.accountId),
                  transaction.amount.toStringAsFixed(2),
                  transaction.type == 'due' ? 'عليه' : 'له',
                  transaction.note ?? '',
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _exportToExcel(BuildContext context, String title, Future<List<int>> Function() generateExcel) async {
    final excelBytes = await generateExcel();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.xlsx');
    await file.writeAsBytes(excelBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ملف Excel في ${file.path}')));
  }

  Future<List<int>> _generateDetailedTransactionsExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow(['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة']);
    for (var transaction in transactions) {
      sheetObject.appendRow([
        DateFormat('yyyy-MM-dd').format(transaction.date),
        _getAccountName(transaction.accountId),
        transaction.amount.toStringAsFixed(2),
        transaction.type == 'due' ? 'عليه' : 'له',
        transaction.note ?? '',
      ]);
    }
    return excel.encode()!;
  }

  Future<void> _exportToCsv(BuildContext context, String title, Future<List<int>> Function() generateCsv) async {
    final csvBytes = await generateCsv();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.csv');
    await file.writeAsBytes(csvBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ملف CSV في ${file.path}')));
  }

  Future<List<int>> _generateDetailedTransactionsCsv() async {
    List<List<dynamic>> rows = [];
    rows.add(['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة']);
    for (var transaction in transactions) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(transaction.date),
        _getAccountName(transaction.accountId),
        transaction.amount.toStringAsFixed(2),
        transaction.type == 'due' ? 'عليه' : 'له',
        transaction.note ?? '',
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    return Future.value(utf8.encode(csv));
  }
}

class MonthlyAmountsChartView extends StatelessWidget {
  final List<Transaction> transactions;
  const MonthlyAmountsChartView({super.key, required this.transactions});

  Map<String, double> _getMonthlyTotals() {
    Map<String, double> monthlyTotals = {};
    for (var transaction in transactions) {
      final monthYear = DateFormat('yyyy-MM').format(transaction.date);
      monthlyTotals.update(monthYear, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
    }
    return monthlyTotals;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotals = _getMonthlyTotals();
    final sortedMonths = monthlyTotals.keys.toList()..sort();

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < sortedMonths.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthlyTotals[sortedMonths[i]]!,
              color: Colors.blue,
              width: 15,
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير إجمالي المبالغ شهرياً')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(sortedMonths[value.toInt()]),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exportToPdf(context, 'تقرير إجمالي المبالغ شهرياً', _generateMonthlyAmountsPdf),
                  icon: const Icon(Icons.picture_as_pdf), label: const Text('تصدير PDF')),
                ElevatedButton.icon(
                  onPressed: () => _exportToExcel(context, 'تقرير إجمالي المبالغ شهرياً', _generateMonthlyAmountsExcel),
                  icon: const Icon(Icons.table_chart), label: const Text('تصدير Excel')),
                ElevatedButton.icon(
                  onPressed: () => _exportToCsv(context, 'تقرير إجمالي المبالغ شهرياً', _generateMonthlyAmountsCsv),
                  icon: const Icon(Icons.description), label: const Text('تصدير CSV')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPdf(BuildContext context, String title, Future<List<int>> Function() generatePdf) async {
    final pdfBytes = await generatePdf();
    await Printing.sharePdf(bytes: pdfBytes, filename: '$title.pdf');
  }

  Future<List<int>> _generateMonthlyAmountsPdf() async {
    final pdf = pw.Document();
    final monthlyTotals = _getMonthlyTotals();
    final sortedMonths = monthlyTotals.keys.toList()..sort();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('تقرير إجمالي المبالغ شهرياً', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['الشهر', 'الإجمالي'],
                data: sortedMonths.map((month) => [
                  month,
                  monthlyTotals[month]!.toStringAsFixed(2),
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _exportToExcel(BuildContext context, String title, Future<List<int>> Function() generateExcel) async {
    final excelBytes = await generateExcel();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.xlsx');
    await file.writeAsBytes(excelBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ملف Excel في ${file.path}')));
  }

  Future<List<int>> _generateMonthlyAmountsExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow(['الشهر', 'الإجمالي']);
    final monthlyTotals = _getMonthlyTotals();
    final sortedMonths = monthlyTotals.keys.toList()..sort();
    for (var month in sortedMonths) {
      sheetObject.appendRow([
        month,
        monthlyTotals[month]!.toStringAsFixed(2),
      ]);
    }
    return excel.encode()!;
  }

  Future<void> _exportToCsv(BuildContext context, String title, Future<List<int>> Function() generateCsv) async {
    final csvBytes = await generateCsv();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.csv');
    await file.writeAsBytes(csvBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ملف CSV في ${file.path}')));
  }

  Future<List<int>> _generateMonthlyAmountsCsv() async {
    List<List<dynamic>> rows = [];
    rows.add(['الشهر', 'الإجمالي']);
    final monthlyTotals = _getMonthlyTotals();
    final sortedMonths = monthlyTotals.keys.toList()..sort();
    for (var month in sortedMonths) {
      rows.add([
        month,
        monthlyTotals[month]!.toStringAsFixed(2),
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    return Future.value(utf8.encode(csv));
  }
}

class CategoriesPieChartView extends StatelessWidget {
  final List<Account> accounts;
  const CategoriesPieChartView({super.key, required this.accounts});

  Map<String, double> _getCategoryTotals() {
    Map<String, double> categoryTotals = {};
    for (var account in accounts) {
      categoryTotals.update(account.category, (value) => value + (account.balanceDue - account.balanceFor).abs(), ifAbsent: () => (account.balanceDue - account.balanceFor).abs());
    }
    return categoryTotals;
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _getCategoryTotals();
    final totalSum = categoryTotals.values.fold(0.0, (sum, item) => sum + item);

    List<PieChartSectionData> pieSections = [];
    int i = 0;
    final colors = [Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple, Colors.orange];
    categoryTotals.forEach((category, total) {
      final percentage = (total / totalSum * 100).toStringAsFixed(1);
      pieSections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: total,
          title: '$category\n$percentage%',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
      i++;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير إجمالي التصنيفات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: pieSections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exportToPdf(context, 'تقرير إجمالي التصنيفات', _generateCategoriesPdf),
                  icon: const Icon(Icons.picture_as_pdf), label: const Text('تصدير PDF')),
                ElevatedButton.icon(
                  onPressed: () => _exportToExcel(context, 'تقرير إجمالي التصنيفات', _generateCategoriesExcel),
                  icon: const Icon(Icons.table_chart), label: const Text('تصدير Excel')),
                ElevatedButton.icon(
                  onPressed: () => _exportToCsv(context, 'تقرير إجمالي التصنيفات', _generateCategoriesCsv),
                  icon: const Icon(Icons.description), label: const Text('تصدير CSV')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPdf(BuildContext context, String title, Future<List<int>> Function() generatePdf) async {
    final pdfBytes = await generatePdf();
    await Printing.sharePdf(bytes: pdfBytes, filename: '$title.pdf');
  }

  Future<List<int>> _generateCategoriesPdf() async {
    final pdf = pw.Document();
    final categoryTotals = _getCategoryTotals();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('تقرير إجمالي التصنيفات', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['التصنيف', 'الإجمالي'],
                data: categoryTotals.entries.map((entry) => [
                  entry.key,
                  entry.value.toStringAsFixed(2),
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _exportToExcel(BuildContext context, String title, Future<List<int>> Function() generateExcel) async {
    final excelBytes = await generateExcel();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.xlsx');
    await file.writeAsBytes(excelBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ملف Excel في ${file.path}')));
  }

  Future<List<int>> _generateCategoriesExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow(['التصنيف', 'الإجمالي']);
    final categoryTotals = _getCategoryTotals();
    categoryTotals.forEach((category, total) {
      sheetObject.appendRow([
        category,
        total.toStringAsFixed(2),
      ]);
    });
    return excel.encode()!;
  }

  Future<void> _exportToCsv(BuildContext context, String title, Future<List<int>> Function() generateCsv) async {
    final csvBytes = await generateCsv();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.csv');
    await file.writeAsBytes(csvBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ملف CSV في ${file.path}')));
  }

  Future<List<int>> _generateCategoriesCsv() async {
    List<List<dynamic>> rows = [];
    rows.add(['التصنيف', 'الإجمالي']);
    final categoryTotals = _getCategoryTotals();
    categoryTotals.forEach((category, total) {
      rows.add([
        category,
        total.toStringAsFixed(2),
      ]);
    });
    String csv = const ListToCsvConverter().convert(rows);
    return Future.value(utf8.encode(csv));
  }
}

class AccountMovementReportView extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Account> accounts;
  const AccountMovementReportView({super.key, required this.transactions, required this.accounts});

  String _getAccountName(String accountId) {
    return accounts.firstWhere((acc) => acc.id == accountId, orElse: () => Account(id: '', name: 'غير معروف', currency: '', category: '')).name;
  }

  @override
  Widget build(BuildContext context) {
    // Group transactions by day or week
    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date); // Daily grouping
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    final sortedDates = groupedTransactions.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير حركة الحسابات')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Report content here
              ...sortedDates.map((date) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(date, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Table(
                    border: TableBorder.all(),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        children: [
                          _buildTableCell('العميل', isHeader: true),
                          _buildTableCell('المبلغ', isHeader: true),
                          _buildTableCell('النوع', isHeader: true),
                          _buildTableCell('ملاحظة', isHeader: true),
                        ],
                      ),
                      ...groupedTransactions[date]!.map((transaction) => TableRow(
                        children: [
                          _buildTableCell(_getAccountName(transaction.accountId)),
                          _buildTableCell(transaction.amount.toStringAsFixed(2)),
                          _buildTableCell(transaction.type == 'due' ? 'عليه' : 'له'),
                          _buildTableCell(transaction.note ?? ''),
                        ],
                      )),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              )),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _exportToPdf(context, 'تقرير حركة الحسابات', _generateAccountMovementPdf),
                    icon: const Icon(Icons.picture_as_pdf), label: const Text('تصدير PDF')),
                  ElevatedButton.icon(
                    onPressed: () => _exportToExcel(context, 'تقرير حركة الحسابات', _generateAccountMovementExcel),
                    icon: const Icon(Icons.table_chart), label: const Text('تصدير Excel')),
                  ElevatedButton.icon(
                    onPressed: () => _exportToCsv(context, 'تقرير حركة الحسابات', _generateAccountMovementCsv),
                    icon: const Icon(Icons.description), label: const Text('تصدير CSV')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _exportToPdf(BuildContext context, String title, Future<List<int>> Function() generatePdf) async {
    final pdfBytes = await generatePdf();
    await Printing.sharePdf(bytes: pdfBytes, filename: '$title.pdf');
  }

  Future<List<int>> _generateAccountMovementPdf() async {
    final pdf = pw.Document();
    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }
    final sortedDates = groupedTransactions.keys.toList()..sort();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('تقرير حركة الحسابات', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              ...sortedDates.map((date) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(date, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    headers: ['العميل', 'المبلغ', 'النوع', 'ملاحظة'],
                    data: groupedTransactions[date]!.map((transaction) => [
                      _getAccountName(transaction.accountId),
                      transaction.amount.toStringAsFixed(2),
                      transaction.type == 'due' ? 'عليه' : 'له',
                      transaction.note ?? '',
                    ]).toList(),
                  ),
                  pw.SizedBox(height: 20),
                ],
              )),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _exportToExcel(BuildContext context, String title, Future<List<int>> Function() generateExcel) async {
    final excelBytes = await generateExcel();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.xlsx');
    await file.writeAsBytes(excelBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ملف Excel في ${file.path}')));
  }

  Future<List<int>> _generateAccountMovementExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    sheetObject.appendRow(['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة']);
    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }
    final sortedDates = groupedTransactions.keys.toList()..sort();

    for (var date in sortedDates) {
      for (var transaction in groupedTransactions[date]!) {
        sheetObject.appendRow([
          DateFormat('yyyy-MM-dd').format(transaction.date),
          _getAccountName(transaction.accountId),
          transaction.amount.toStringAsFixed(2),
          transaction.type == 'due' ? 'عليه' : 'له',
          transaction.note ?? '',
        ]);
      }
    }
    return excel.encode()!;
  }

  Future<void> _exportToCsv(BuildContext context, String title, Future<List<int>> Function() generateCsv) async {
    final csvBytes = await generateCsv();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$title.csv');
    await file.writeAsBytes(csvBytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ ملف CSV في ${file.path}')));
  }

  Future<List<int>> _generateAccountMovementCsv() async {
    List<List<dynamic>> rows = [];
    rows.add(['التاريخ', 'العميل', 'المبلغ', 'النوع', 'ملاحظة']);
    Map<String, List<Transaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }
    final sortedDates = groupedTransactions.keys.toList()..sort();

    for (var date in sortedDates) {
      for (var transaction in groupedTransactions[date]!) {
        rows.add([
          DateFormat('yyyy-MM-dd').format(transaction.date),
          _getAccountName(transaction.accountId),
          transaction.amount.toStringAsFixed(2),
          transaction.type == 'due' ? 'عليه' : 'له',
          transaction.note ?? '',
        ]);
      }
    }
    String csv = const ListToCsvConverter().convert(rows);
    return Future.value(utf8.encode(csv));
  }
}
