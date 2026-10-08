import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_helper.dart';

class CategoryDetailScreen extends StatefulWidget {
  final String siteName;
  final String categoryTitle;

  const CategoryDetailScreen({super.key, required this.siteName, required this.categoryTitle});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _filteredExpenses = [];
  bool _isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _searchController.addListener(_filterSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getExpenses(widget.siteName, widget.categoryTitle);
    setState(() {
      _expenses = data;
      _filteredExpenses = data;
      _isLoading = false;
    });
  }

  void _filterSearch() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExpenses = _expenses.where((exp) {
        final title = exp['title']?.toLowerCase() ?? '';
        final desc = exp['desc']?.toLowerCase() ?? '';
        final date = exp['date']?.toLowerCase() ?? '';
        return title.contains(query) || desc.contains(query) || date.contains(query);
      }).toList();
    });
  }

  final List<String> _materialOptions = ['Sand', 'Agg', 'Steel', 'Cement', 'Bitumin'];
  final List<String> _equipmentOptions = ['J.C.B (Per Hr.)', 'Poclain (Per Hr.)', 'Tractor (Halday / Days)', 'Tanker (Nos.)'];
  
  String? _selectedSubMaterial;
  String? _selectedSubEquipment;

  String _getUnitHintForMaterial(String material) {
    switch (material) {
      case 'Sand':
      case 'Agg':
        return 'Unit (Brass madhe)';
      case 'Steel':
        return 'Unit (Kg / Tons madhe)';
      case 'Cement':
        return 'Unit (Bags madhe)';
      case 'Bitumin':
        return 'Unit (Drums / Litres)';
      default:
        return 'Unit / Qty';
    }
  }

  double _calculateTotalAmount() {
    double total = 0.0;
    for (var exp in _filteredExpenses) {
      total += double.tryParse(exp['amount'].toString()) ?? 0.0;
    }
    return total;
  }

  Future<void> _deleteExpense(int id) async {
    await DatabaseHelper.instance.deleteExpenseById(widget.siteName, widget.categoryTitle, id);
    _loadExpenses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entry deleted successfully!'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _generateAndSharePdf() async {
    final pdf = pw.Document();
    double totalAmount = _calculateTotalAmount();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Construction Expense Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Site Name: ${widget.siteName}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Category: ${widget.categoryTitle}', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 14),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                headers: ['Title / Item', 'Details / Qty', 'Date', 'Amount (Rs)'],
                data: _filteredExpenses.map((exp) {
                  return [
                    exp['title'].toString(),
                    exp['desc'].toString(),
                    exp['date'].toString(),
                    exp['amount'].toString(),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Total Amount: Rs $totalAmount', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: '${widget.siteName}_${widget.categoryTitle}_report.pdf');
  }

  void _showAddOrEditDialog({Map<String, dynamic>? existingExpense}) {
    bool isEditing = existingExpense != null;

    if (widget.categoryTitle == 'Material') {
      _selectedSubMaterial = isEditing ? existingExpense['title'] : _materialOptions.first;
    } else if (widget.categoryTitle == 'Equipment') {
      _selectedSubEquipment = isEditing ? existingExpense['title'] : _equipmentOptions.first;
    }

    final TextEditingController titleController = TextEditingController(text: isEditing ? existingExpense['title'] : '');
    final TextEditingController qtyController = TextEditingController();
    final TextEditingController amountController = TextEditingController(text: isEditing ? existingExpense['amount'].toString() : '');
    final TextEditingController descController = TextEditingController(text: isEditing ? existingExpense['desc'] : '');

    if (isEditing && existingExpense['desc'].toString().contains('Unit:')) {
      try {
        var parts = existingExpense['desc'].toString().split('|');
        if (parts.isNotEmpty) {
          qtyController.text = parts[0].replaceAll('Unit:', '').trim();
          if (parts.length > 1) {
            descController.text = parts[1].trim();
          }
        }
      } catch (_) {}
    }

    DateTime selectedDate = isEditing && existingExpense['date'] != null
        ? (DateTime.tryParse(existingExpense['date'].toString().split(' ')[0]) ?? DateTime.now())
        : DateTime.now();

    TimeOfDay selectedTime = isEditing && existingExpense['date'] != null
        ? (TimeOfDay(
            hour: int.tryParse(existingExpense['date'].toString().split(' ')[1].split(':')[0]) ?? DateTime.now().hour,
            minute: int.tryParse(existingExpense['date'].toString().split(' ')[1].split(':')[1]) ?? DateTime.now().minute,
          ))
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, dialogSetState) {
          String currentMaterial = _selectedSubMaterial ?? _materialOptions.first;
          String dynamicQtyHint = widget.categoryTitle == 'Material' 
              ? _getUnitHintForMaterial(currentMaterial) 
              : (widget.categoryTitle == 'Equipment' ? 'Vapar (Hours / Days / Nos)' : 'Unit / Qty');

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              isEditing ? '${widget.categoryTitle} Edit ' : '${widget.categoryTitle} Add New Expense', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.categoryTitle == 'Material') ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubMaterial,
                      decoration: InputDecoration(
                        labelText: ' Select Material ',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _materialOptions.map((String opt) {
                        return DropdownMenuItem<String>(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (String? val) {
                        dialogSetState(() {
                          _selectedSubMaterial = val;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                  ] else if (widget.categoryTitle == 'Equipment') ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubEquipment,
                      decoration: InputDecoration(
                        labelText: 'Select Equipment',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _equipmentOptions.map((String opt) {
                        return DropdownMenuItem<String>(value: opt, child: Text(opt));
                      }).toList(),
                      onChanged: (String? val) => dialogSetState(() => _selectedSubEquipment = val),
                    ),
                    const SizedBox(height: 14),
                  ] else if (widget.categoryTitle == 'Labour') ...[
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Worker Name',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else if (widget.categoryTitle == 'Vendor') ...[
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Vendor / Trader Name',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Expense name (Item Title)',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (widget.categoryTitle == 'Material' || widget.categoryTitle == 'Equipment') ...[
                    TextField(
                      controller: qtyController,
                      decoration: InputDecoration(
                        labelText: dynamicQtyHint,
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter Amount (₹)',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Tip / Description / Gadi No',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 👉 Separate Date Picker Container
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        dialogSetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.calendar_today, size: 18, color: Color(0xFF3B82F6)),
                              SizedBox(width: 8),
                              Text('Date):', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 👉 Separate Time Picker Container
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        dialogSetState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.access_time, size: 18, color: Color(0xFF3B82F6)),
                              SizedBox(width: 8),
                              Text('Time):', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  String expenseTitle;
                  if (widget.categoryTitle == 'Material') {
                    expenseTitle = _selectedSubMaterial ?? 'Material';
                  } else if (widget.categoryTitle == 'Equipment') {
                    expenseTitle = _selectedSubEquipment ?? 'Equipment';
                  } else {
                    expenseTitle = titleController.text.trim();
                  }

                  if (amountController.text.trim().isNotEmpty && (widget.categoryTitle == 'Material' || widget.categoryTitle == 'Equipment' || expenseTitle.isNotEmpty)) {
                    
                    String fullDesc = qtyController.text.trim().isNotEmpty
                        ? 'Unit: ${qtyController.text.trim()} | ${descController.text.trim()}'
                        : descController.text.trim();

                    String formattedDateTime = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')} ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                    Map<String, dynamic> expenseData = {
                      'id': isEditing ? existingExpense['id'] : DateTime.now().millisecondsSinceEpoch,
                      'title': expenseTitle,
                      'amount': amountController.text.trim(),
                      'desc': fullDesc,
                      'date': formattedDateTime,
                    };

                    if (isEditing) {
                      await DatabaseHelper.instance.updateExpense(widget.siteName, widget.categoryTitle, expenseData);
                    } else {
                      await DatabaseHelper.instance.addExpense(widget.siteName, widget.categoryTitle, expenseData);
                    }
                    
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                    if (mounted) {
                      _loadExpenses();
                    }
                  }
                },
                child: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = _calculateTotalAmount();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.categoryTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1E293B))),
            Text(widget.siteName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 22),
              tooltip: 'PDF Report Download & Share',
              onPressed: _generateAndSharePdf,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : Column(
              children: [
                // 👉 Modern Gradient Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Entries', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text('${_filteredExpenses.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(height: 35, width: 1, color: Colors.white24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Expense (Total)', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Text('₹ $totalAmount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80))),
                        ],
                      ),
                    ],
                  ),
                ),

                // 👉 Modern Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by entry or vehicle number...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                Expanded(
                  child: _filteredExpenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              const Text('No matching entries found.', style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                onPressed: () => _showAddOrEditDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add your first entry', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: _filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final exp = _filteredExpenses[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _showAddOrEditDialog(existingExpense: exp),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.receipt, color: Color(0xFF3B82F6), size: 20),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                exp['title'], 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${exp['desc']} • ${exp['date']}', 
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '₹ ${exp['amount']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A)),
                                            ),
                                            const SizedBox(height: 4),
                                            InkWell(
                                              onTap: () async {
                                                bool? confirm = await showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    title: const Text('Are you sure you want to delete this entry?'),
                                                    content: const Text('This entry will be deleted permanently and cannot be recovered.'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Nahi')),
                                                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hoy, delete kara', style: TextStyle(color: Colors.red))),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  _deleteExpense(exp['id']);
                                                }
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.all(4),
                                                child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showAddOrEditDialog(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}