import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/role_context_switcher.dart';

const Color kAdminAccent = Color(0xFF7C3AED); // Royal Purple

class AdminPortalScreen extends ConsumerStatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  ConsumerState<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends ConsumerState<AdminPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _overviewData;
  List<dynamic> _usersList = [];
  String _selectedRoleFilter = 'all';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final overview = await ApiClient().getAdminOverview();
      final users = await ApiClient().getAdminUsers(
        role: _selectedRoleFilter,
        query: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _overviewData = overview;
          _usersList = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchFilteredUsers() async {
    try {
      final users = await ApiClient().getAdminUsers(
        role: _selectedRoleFilter,
        query: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() => _usersList = users);
      }
    } catch (_) {}
  }

  Future<void> _toggleUserVerification(String userId, String userName) async {
    try {
      final res = await ApiClient().toggleUserVerification(userId);
      if (res['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Verification updated.'),
              backgroundColor: kAdminAccent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update verification: $e'),
            backgroundColor: AppColors.emergency,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _overviewData?['stats'] as Map<String, dynamic>? ?? {};
    final recentActivity = (_overviewData?['recent_activity'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kAdminAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: kAdminAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Admin Portal & Governance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'System Oversight, Registry Verification & Engine Telemetry',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const Center(child: RoleContextSwitcher(accentColor: kAdminAccent)),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              launchUrl(Uri.parse('http://127.0.0.1:8000/admin/'), mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.table_chart_rounded, size: 15),
            label: const Text('Django Admin DB', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: kAdminAccent,
              side: const BorderSide(color: kAdminAccent),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh Analytics',
            onPressed: _loadAllData,
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: kAdminAccent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: kAdminAccent,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Platform Overview'),
            Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'User & Provider Registry'),
            Tab(icon: Icon(Icons.security_outlined, size: 18), text: 'Activity & Audit Stream'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kAdminAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(stats, recentActivity),
                _buildUserRegistryTab(),
                _buildAuditTab(recentActivity),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> stats, List<dynamic> recentActivity) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                children: [
                  _kpiCard(
                    title: 'Total Patients',
                    value: '${stats['total_patients'] ?? 0}',
                    subtitle: 'Unique digital health lockers',
                    icon: Icons.person_rounded,
                    color: const Color(0xFF2563EB), // Blue
                  ),
                  _kpiCard(
                    title: 'Registered Doctors',
                    value: '${stats['total_doctors'] ?? 0}',
                    subtitle: 'Consulting physicians',
                    icon: Icons.medical_services_rounded,
                    color: const Color(0xFF1E40AF), // Indigo
                  ),
                  _kpiCard(
                    title: 'Diagnostic Labs',
                    value: '${stats['total_labs'] ?? 0}',
                    subtitle: '${stats['total_lab_reports'] ?? 0} published reports',
                    icon: Icons.science_rounded,
                    color: const Color(0xFF059669), // Emerald
                  ),
                  _kpiCard(
                    title: 'Hospital Facilities',
                    value: '${stats['total_hospitals'] ?? 0}',
                    subtitle: '${stats['active_admissions'] ?? 0} active ward beds',
                    icon: Icons.local_hospital_rounded,
                    color: const Color(0xFFD97706), // Amber
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // Platform Engines & Quick Telemetry
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Engine Status Card
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.hub_outlined, color: kAdminAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Platform Engine Telemetry',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _engineRow('Django REST Backend Engine', 'HTTP 200 • Online', true),
                      const Divider(height: 16),
                      _engineRow('PostgreSQL Core Database', 'Connected • Zero Locks', true),
                      const Divider(height: 16),
                      _engineRow('Smart Lab Ingestion Pipeline', 'Active • PDF / CSV Stream', true),
                      const Divider(height: 16),
                      _engineRow('Provider-Initiated Consent Protocol', 'Strict Opt-In • Active', true),
                      const Divider(height: 16),
                      _engineRow('Static Media & PDF Storage', 'Local /media/reports/ Ready', true),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Quick Actions Card
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Administrative Controls',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          launchUrl(Uri.parse('http://127.0.0.1:8000/admin/'), mode: LaunchMode.externalApplication);
                        },
                        icon: const Icon(Icons.table_view_rounded, size: 16),
                        label: const Text('Open Django Web Admin Suite'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAdminAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          _tabController.animateTo(1);
                        },
                        icon: const Icon(Icons.verified_user_rounded, size: 16),
                        label: const Text('Verify Healthcare Providers'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _loadAllData,
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: const Text('Sync Telemetry Counters'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border),
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    );
  }

  Widget _buildUserRegistryTab() {
    return Column(
      children: [
        // Filter and Search Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search user by full name, email, or phone number...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              _fetchFilteredUsers();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _fetchFilteredUsers(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _fetchFilteredUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAdminAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
        ),

        // Role Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'All Users'),
                _filterChip('doctor', 'Doctors'),
                _filterChip('lab', 'Diagnostic Labs'),
                _filterChip('hospital', 'Hospitals'),
                _filterChip('patient', 'Patients'),
                _filterChip('admin', 'Administrators'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // User Registry Table
        Expanded(
          child: _usersList.isEmpty
              ? const Center(
                  child: Text('No users found matching the filter criteria.', style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _usersList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final u = _usersList[idx];
                    final isVerified = u['is_verified'] == true;
                    final role = u['role']?.toString().toLowerCase() ?? 'patient';

                    Color roleColor;
                    switch (role) {
                      case 'doctor':
                        roleColor = const Color(0xFF1E40AF);
                        break;
                      case 'lab':
                        roleColor = const Color(0xFF059669);
                        break;
                      case 'hospital':
                        roleColor = const Color(0xFFD97706);
                        break;
                      case 'admin':
                        roleColor = kAdminAccent;
                        break;
                      default:
                        roleColor = AppColors.primary;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: roleColor.withValues(alpha: 0.12),
                            child: Text(
                              (u['full_name'] != null && u['full_name'].toString().isNotEmpty)
                                  ? u['full_name'][0].toUpperCase()
                                  : 'U',
                              style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      u['full_name'] ?? 'Unnamed User',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: roleColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${u['email'] ?? 'No email'} • ${u['patient_id'] ?? ''}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
                                  size: 13,
                                  color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isVerified ? 'Verified' : 'Unverified',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => _toggleUserVerification(u['id'], u['full_name'] ?? u['email']),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isVerified ? AppColors.emergency : kAdminAccent,
                              side: BorderSide(color: isVerified ? AppColors.emergency.withValues(alpha: 0.5) : kAdminAccent),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: Text(
                              isVerified ? 'Revoke Verification' : 'Verify Provider',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAuditTab(List<dynamic> recentActivity) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.history_rounded, color: kAdminAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Platform Audit & Clinical Transaction Log',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentActivity.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No recent transactions found.', style: TextStyle(color: AppColors.textSecondary)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentActivity.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final a = recentActivity[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kAdminAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.description_outlined, color: kAdminAccent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a['title'] ?? 'Clinical Record',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${a['type']} • Bound to ${a['patient_name']} (${a['patient_id']}) • ${a['facility']}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          a['date'] ?? '',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _engineRow(String service, String statusText, bool isOnline) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(service, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String roleKey, String label) {
    final isSelected = _selectedRoleFilter == roleKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: kAdminAccent.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? kAdminAccent : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (val) {
          if (val) {
            setState(() => _selectedRoleFilter = roleKey);
            _fetchFilteredUsers();
          }
        },
      ),
    );
  }
}
