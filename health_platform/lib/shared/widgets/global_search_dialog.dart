import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

void showGlobalSearchDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogCtx) => const _GlobalSearchDialogContent(),
  );
}

class _GlobalSearchDialogContent extends StatefulWidget {
  const _GlobalSearchDialogContent();

  @override
  State<_GlobalSearchDialogContent> createState() => _GlobalSearchDialogContentState();
}

class _GlobalSearchDialogContentState extends State<_GlobalSearchDialogContent> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic> _results = {
    'total_results': 0,
    'prescriptions': [],
    'lab_reports': [],
    'doctors': [],
  };
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      setState(() {
        _results = {'total_results': 0, 'prescriptions': [], 'lab_reports': [], 'doctors': []};
        _isLoading = false;
        _lastQuery = q;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _lastQuery = q;
    });

    try {
      final res = await ApiClient().searchGlobal(q);
      if (mounted) {
        setState(() {
          _results = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prescriptions = List<Map<String, dynamic>>.from(_results['prescriptions'] ?? []);
    final labReports = List<Map<String, dynamic>>.from(_results['lab_reports'] ?? []);
    final doctors = List<Map<String, dynamic>>.from(_results['doctors'] ?? []);
    final total = (_results['total_results'] ?? 0) as int;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
          children: [
            // Search Input Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Search medicines, test parameters, doctors...',
                        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _performSearch,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_return_rounded, size: 18, color: AppColors.textTertiary),
                    tooltip: 'Search',
                    onPressed: () => _performSearch(_searchController.text),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
              ),

            // Body Results
            Expanded(
              child: _lastQuery.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.manage_search_rounded, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'Instant Health Record Search',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Type any medicine name (e.g. "Metformin"), lab test ("CBC"), or doctor name to find records across your history.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    )
                  : total == 0 && !_isLoading
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textTertiary),
                                const SizedBox(height: 10),
                                Text(
                                  'No records matched "$_lastQuery"',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Try searching by medicine keyword, facility name, or doctor specialization.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                          children: [
                            // Prescriptions Section
                            if (prescriptions.isNotEmpty) ...[
                              _buildSectionHeader('Prescriptions & Doctor Notes', Icons.medication_rounded, prescriptions.length),
                              ...prescriptions.map((rx) => _buildPrescriptionTile(context, rx)),
                              const SizedBox(height: 12),
                            ],

                            // Lab Reports Section
                            if (labReports.isNotEmpty) ...[
                              _buildSectionHeader('Lab Reports & Diagnostic Tests', Icons.science_rounded, labReports.length),
                              ...labReports.map((rep) => _buildLabReportTile(context, rep)),
                              const SizedBox(height: 12),
                            ],

                            // Doctors Section
                            if (doctors.isNotEmpty) ...[
                              _buildSectionHeader('Healthcare Providers & Specialists', Icons.person_rounded, doctors.length),
                              ...doctors.map((doc) => _buildDoctorTile(context, doc)),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.2),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionTile(BuildContext context, Map<String, dynamic> rx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 18),
        ),
        title: Text(
          rx['title'] ?? 'Prescription',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${rx['doctor_name']} • ${rx['date']}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            if (rx['snippet'] != null && rx['snippet'].toString().isNotEmpty)
              Text(
                rx['snippet'].toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textTertiary),
        onTap: () {
          Navigator.pop(context);
          context.go('/records');
        },
      ),
    );
  }

  Widget _buildLabReportTile(BuildContext context, Map<String, dynamic> rep) {
    final status = rep['status'] ?? 'Normal';
    final isAbnormal = status.toString().toLowerCase().contains('abnormal');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isAbnormal ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.science_rounded,
            color: isAbnormal ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            size: 18,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                rep['report_name'] ?? 'Diagnostic Report',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isAbnormal ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isAbnormal ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${rep['category']} • ${rep['date']}',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textTertiary),
        onTap: () {
          Navigator.pop(context);
          context.go('/reports');
        },
      ),
    );
  }

  Widget _buildDoctorTile(BuildContext context, Map<String, dynamic> doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.person_pin_rounded, color: Color(0xFF2563EB), size: 18),
        ),
        title: Text(
          doc['name'] ?? 'Doctor',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Text(
          '${doc['specialization']} • ${doc['clinic']}',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textTertiary),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
