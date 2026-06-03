import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:daftar_alhesabat/database/hive_service.dart';
import 'dart:convert';

class HttpServerService {
  HttpServer? _server;
  final HiveService _hiveService = HiveService();

  Future<String?> startServer() async {
    final ipAddress = await _getIpAddress();
    if (ipAddress == null) return null;
    final app = Router();

    app.get('/', (Request request) {
      return Response.ok(_buildHtmlPage(), headers: {'Content-Type': 'text/html'});
    });

    app.get('/api/accounts', (Request request) {
      final accounts = _hiveService.getAccounts();
      final accountsJson = jsonEncode(accounts.map((e) => e.toJson()).toList());
      return Response.ok(accountsJson, headers: {'Content-Type': 'application/json'});
    });

    app.get('/api/transactions/<accountId>', (Request request, String accountId) {
      final transactions = _hiveService.getTransactionsForAccount(accountId);
      final transactionsJson = jsonEncode(transactions.map((e) => e.toJson()).toList());
      return Response.ok(transactionsJson, headers: {'Content-Type': 'application/json'});
    });

    app.get('/api/export/csv', (Request request) {
      final accounts = _hiveService.getAccounts();
      final transactions = _hiveService.transactionsBox.values.toList();
      StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln('Type,ID,Name,Assistant Name,Currency,Category,Balance Due,Balance For,Transaction ID,Account ID,Amount,Transaction Type,Date,Note,Image Path,Is Recurring,Recurring Interval');
      for (var account in accounts) {
        csvBuffer.writeln('Account,${account.id},${_escapeCsv(account.name)},${_escapeCsv(account.assistantName ?? '')},${_escapeCsv(account.currency)},${_escapeCsv(account.category)},${account.balanceDue},${account.balanceFor},,,,,,,,,');
      }
      for (var transaction in transactions) {
        csvBuffer.writeln('Transaction,,,,,,,,${transaction.id},${transaction.accountId},${transaction.amount},${transaction.type},${transaction.date.toIso8601String()},${_escapeCsv(transaction.note ?? '')},${_escapeCsv(transaction.imagePath ?? '')},${transaction.isRecurring},${_escapeCsv(transaction.recurringInterval ?? '')}');
      }
      return Response.ok(csvBuffer.toString(), headers: {
        'Content-Type': 'text/csv',
        'Content-Disposition': 'attachment; filename="daftar_alhesabat_data.csv"',
      });
    });

    _server = await shelf_io.serve(app, ipAddress, 7777);
    print('Serving at http://$ipAddress:7777');
    return 'http://$ipAddress:7777';
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    print('HTTP server stopped.');
  }

  Future<String?> _getIpAddress() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting IP address: $e');
    }
    return null;
  }

  String _escapeCsv(String? field) {
    if (field == null) return '';
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"' + field.replaceAll('"', '""') + '"';
    }
    return field;
  }

  String _buildHtmlPage() {
    // استخدام raw string (r''') لمنع تفسير $ من قبل Dart
    return r'''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>دفتر الحسابات - استعراض البيانات</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background-color: #f4f4f4; color: #333; }
        .container { max-width: 1200px; margin: auto; background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #0056b3; text-align: center; margin-bottom: 20px; }
        .filters { display: flex; gap: 10px; margin-bottom: 20px; justify-content: center; }
        .filters input, .filters select { padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: right; }
        th { background-color: #0056b3; color: white; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #f1f1f1; cursor: pointer; }
        .details { margin-top: 20px; padding: 15px; background-color: #e9f7ef; border-left: 5px solid #28a745; border-radius: 4px; display: none; }
        .details h2 { color: #28a745; }
        .export-btn { display: block; width: fit-content; margin: 20px auto; padding: 10px 20px; background-color: #28a745; color: white; text-decoration: none; border-radius: 5px; }
        .export-btn:hover { background-color: #218838; }
    </style>
</head>
<body>
    <div class="container">
        <h1>دفتر الحسابات - استعراض البيانات</h1>
        <div class="filters">
            <input type="text" id="searchName" placeholder="بحث بالاسم...">
            <select id="filterCurrency"><option value="">كل العملات</option></select>
            <button onclick="applyFilters()">تطبيق الفلاتر</button>
            <a href="/api/export/csv" class="export-btn">تصدير كل البيانات CSV</a>
        </div>
        <h2>قائمة العملاء</h2>
        <table id="accountsTable"><thead><tr><th>الاسم</th><th>الاسم المساعد</th><th>العملة</th><th>التصنيف</th><th>المبلغ المستحق (عليه)</th><th>المبلغ المستحق (له)</th></thead><tbody></tbody></table>
        <div id="transactionsDetails" class="details"><h2 id="detailsAccountName"></h2><h3>المعاملات</h3><table id="transactionsTable"><thead><tr><th>المبلغ</th><th>النوع</th><th>التاريخ</th><th>الملاحظة</th></thead><tbody></tbody></table></div>
    </div>
    <script>
        let allAccounts = [];
        let allCurrencies = new Set();
        
        async function loadAccounts() {
            const response = await fetch('/api/accounts');
            if (!response.ok) return;
            allAccounts = await response.json();
            displayAccounts(allAccounts);
            populateCurrencyFilter();
        }
        
        function populateCurrencyFilter() {
            allCurrencies.clear();
            allAccounts.forEach(account => allCurrencies.add(account.currency));
            const filterCurrencySelect = document.getElementById('filterCurrency');
            filterCurrencySelect.innerHTML = '<option value="">كل العملات</option>';
            allCurrencies.forEach(currency => {
                const option = document.createElement('option');
                option.value = currency;
                option.textContent = currency;
                filterCurrencySelect.appendChild(option);
            });
        }
        
        function displayAccounts(accounts) {
            const tableBody = document.querySelector('#accountsTable tbody');
            tableBody.innerHTML = '';
            accounts.forEach(account => {
                const row = tableBody.insertRow();
                row.onclick = () => showTransactions(account.id, account.name);
                const balanceDue = typeof account.balanceDue === 'number' ? account.balanceDue.toFixed(2) : '0.00';
                const balanceFor = typeof account.balanceFor === 'number' ? account.balanceFor.toFixed(2) : '0.00';
                row.innerHTML = `<td>${escapeHtml(account.name)}</td><td>${escapeHtml(account.assistantName || '')}</td><td>${escapeHtml(account.currency)}</td><td>${escapeHtml(account.category)}</td><td>${balanceDue}</td><td>${balanceFor}</td>`;
            });
        }
        
        async function showTransactions(accountId, accountName) {
            document.getElementById('detailsAccountName').textContent = `معاملات العميل: ${accountName}`;
            const response = await fetch(`/api/transactions/${accountId}`);
            if (!response.ok) return;
            const transactions = await response.json();
            const tableBody = document.querySelector('#transactionsTable tbody');
            tableBody.innerHTML = '';
            transactions.forEach(transaction => {
                const row = tableBody.insertRow();
                const amount = typeof transaction.amount === 'number' ? transaction.amount.toFixed(2) : '0.00';
                const typeText = transaction.type == 'due' ? 'عليه' : 'له';
                let dateStr = '';
                try {
                    dateStr = new Date(transaction.date).toLocaleDateString('ar-EG');
                } catch(e) { dateStr = ''; }
                row.innerHTML = `<td>${amount}</td><td>${typeText}</td><td>${dateStr}</td><td>${escapeHtml(transaction.note || '')}</td>`;
            });
            document.getElementById('transactionsDetails').style.display = 'block';
        }
        
        function applyFilters() {
            const searchName = document.getElementById('searchName').value.toLowerCase();
            const filterCurrency = document.getElementById('filterCurrency').value;
            let filteredAccounts = allAccounts.filter(account => {
                const assistant = account.assistantName || '';
                const matchesName = account.name.toLowerCase().includes(searchName) || assistant.toLowerCase().includes(searchName);
                const matchesCurrency = filterCurrency === '' || account.currency === filterCurrency;
                return matchesName && matchesCurrency;
            });
            displayAccounts(filteredAccounts);
        }
        
        function escapeHtml(str) {
            if (!str) return '';
            return str.replace(/[&<>]/g, function(m) {
                if (m === '&') return '&amp;';
                if (m === '<') return '&lt;';
                if (m === '>') return '&gt;';
                return m;
            });
        }
        
        loadAccounts();
    </script>
</body>
</html>
    ''';
  }
}
