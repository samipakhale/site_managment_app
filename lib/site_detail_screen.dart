import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'database_helper.dart'; 
import 'category_detail_screen.dart'; 

class SiteDetailScreen extends StatefulWidget {
  final String siteName;

  const SiteDetailScreen({super.key, required this.siteName});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  double _totalSiteExpense = 0.0;
  bool _isLoadingTotal = true;

  final List<Map<String, dynamic>> _categories = const [
    {'title': 'Material', 'subtitle': 'Sand, Agg, Steel, Cement, Bitumin', 'icon': Icons.inventory_2, 'color': Colors.orange},
    {'title': 'Labour', 'subtitle': 'Worker daily wages & details', 'icon': Icons.engineering, 'color': Colors.blue},
    {'title': 'Equipment', 'subtitle': 'JCB, Poclain, Tractor, Tanker', 'icon': Icons.local_shipping, 'color': Colors.green},
    {'title': 'Vendor', 'subtitle': 'Add vendor, traders, enterprise', 'icon': Icons.store, 'color': Colors.purple},
    {'title': 'Other Expenses', 'subtitle': 'Miscellaneous site expenses', 'icon': Icons.receipt_long, 'color': Colors.redAccent},
  ];

  @override
  void initState() {
    super.initState();
    _loadSiteTotalExpense();
  }

  Future<void> _loadSiteTotalExpense() async {
    double grandTotal = 0.0;
    for (var cat in _categories) {
      final expenses = await DatabaseHelper.instance.getExpenses(widget.siteName, cat['title']);
      for (var exp in expenses) {
        grandTotal += double.tryParse(exp['amount'].toString()) ?? 0.0;
      }
    }
    if (mounted) {
      setState(() {
        _totalSiteExpense = grandTotal;
        _isLoadingTotal = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern Clean Background
      appBar: AppBar(
        title: Text(
          widget.siteName, 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: Column(
        children: [
          // 👉 Top Modern Gradient Summary Banner (Total Site Expense)
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Site total Expense', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                    SizedBox(height: 6),
                    Text('Total Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                _isLoadingTotal
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        '₹ $_totalSiteExpense',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80)),
                      ),
              ],
            ),
          ),

          // 👉 Categories List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        // 👉 Haptic Feedback (Light touch vibration for premium feel)
                        HapticFeedback.lightImpact();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryDetailScreen(
                              siteName: widget.siteName,
                              categoryTitle: cat['title'],
                            ),
                          ),
                        ).then((_) {
                          // Parat aalyavar total expense parat load honya sathi
                          _loadSiteTotalExpense();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // 👉 Modern Gradient Glow & Border Effect for Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cat['color'].withValues(alpha: 0.2),
                                    cat['color'].withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: cat['color'].withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cat['color'].withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(cat['icon'], color: cat['color'], size: 26),
                            ),
                            const SizedBox(width: 16),
                            // 👉 Title and Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat['title'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat['subtitle'],
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            // 👉 Sleek Arrow Icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
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
    );
  }
}