import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Transaction {
  final String date;
  final String time;
  final String part;
  final String tranType;
  final String from;
  final String to;
  final String endQty;
  final String user;

  Transaction({
    required this.date,
    required this.time,
    required this.part,
    required this.tranType,
    required this.from,
    required this.to,
    required this.endQty,
    required this.user,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: json['DATE'] ?? '',
      time: json['TIME'] ?? '',
      part: (json['PART'] ?? '').trim(),
      tranType: json['TRAN_TYPE'] ?? '',
      from: json['FROM'] ?? '',
      to: json['TO'] ?? '',
      endQty: json['END_QTY'] ?? '',
      user: (json['USER'] ?? '').trim(),
    );
  }
}

class ResultScreen extends StatefulWidget {
  final String serialNumber;

  const ResultScreen({Key? key, required this.serialNumber}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<List<Transaction>> _transactionsFuture;

  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];

  String _searchText = '';
  String _selectedTranType = 'All';
  bool _sortAscending = true;

  final List<String> _tranTypeOptions = [
    'All',
    'Create',
    'Print',
    'Activate',
    'Move',
    'Consume',
  ]; // example types

  Future<List<Transaction>> fetchTransactions() async {
    final url = Uri.parse(
        'http://172.27.80.209:5000/serial/history?serial_number=${widget
            .serialNumber}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      if (jsonList.isEmpty) {
        throw Exception('No records found for this serial.');
      }
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch data. (${response.statusCode})');
    }
  }

  @override
  void initState() {
    super.initState();
    _transactionsFuture = fetchTransactions();
    _transactionsFuture.then((list) {
      setState(() {
        _transactions = list;
        _applyFilters();
      });
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _transactionsFuture = fetchTransactions();
    });
    final list = await _transactionsFuture;
    setState(() {
      _transactions = list;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Transaction> filtered = _transactions;

    // Filter by transaction type
    if (_selectedTranType != 'All') {
      filtered =
          filtered.where((txn) => txn.tranType == _selectedTranType).toList();
    }

    if (_searchText.isNotEmpty) {
      final lowerSearch = _searchText.toLowerCase();
      filtered = filtered.where((txn) {
        return txn.part.toLowerCase().contains(lowerSearch) ||
            txn.user.toLowerCase().contains(lowerSearch);
      }).toList();
    }

    filtered.sort((a, b) {
      final aDate = DateTime.tryParse(formatDateTime(a.date, a.time)) ??
          DateTime(0);
      final bDate = DateTime.tryParse(formatDateTime(b.date, b.time)) ??
          DateTime(0);
      return _sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
    });

    _filteredTransactions = filtered;
  }

  String formatDateTime(String date, String time) {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        final month = parts[0].padLeft(2, '0');
        final day = parts[1].padLeft(2, '0');
        final year = '20${parts[2]}';
        return '$month-$day-$year       $time';
      }
    } catch (_) {}
    return '$date $time';
  }

  Widget _buildTransactionCard(Transaction txn) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(txn.part, style: const TextStyle(fontWeight: FontWeight
            .bold)),
        subtitle: Text(formatDateTime(txn.date, txn.time)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Transaction Type:', txn.tranType),
                _row('From:', txn.from.isEmpty ? '-' : txn.from),
                _row('To:', txn.to.isEmpty ? '-' : txn.to),
                _row('End Quantity:', txn.endQty),
                _row('User:', txn.user),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(width: 6),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _onFilterChanged() {
    setState(() {
      _applyFilters();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001F3F), // Dark navy color
        title: Text(
          'Serial: ${widget.serialNumber}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white), // white back arrow
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No records found.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            );
          } else {

            return RefreshIndicator(
              onRefresh: _refresh,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        // Search field
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search by Part or User',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) {
                            _searchText = value;
                            _onFilterChanged();
                          },
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const Text('Transaction Type: '),
                              const SizedBox(width: 12),
                              DropdownButton<String>(
                                value: _selectedTranType,
                                items: _tranTypeOptions
                                    .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _selectedTranType = value;
                                    _onFilterChanged();
                                  }
                                },
                              ),
                              const SizedBox(width: 24),
                              const Text('Sort: '),
                              const SizedBox(width: 12),
                              DropdownButton<bool>(
                                value: _sortAscending,
                                items: const [
                                  DropdownMenuItem(
                                    value: true,
                                    child: Text('Newest'),
                                  ),
                                  DropdownMenuItem(
                                    value: false,
                                    child: Text('Oldest'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    _sortAscending = value;
                                    _onFilterChanged();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _filteredTransactions.isEmpty
                        ? const Center(
                      child: Text(
                        'No records found after filtering.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                        : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(_filteredTransactions[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}