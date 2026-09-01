import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_list_state.dart';
import '../../shared/widgets/web_constraint.dart';
import '../../core/config/providers.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  ListStatus _viewStatus = ListStatus.content;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(timelineProvider);
    final groupedEvents = _groupEventsByDate(events);

    final activeStatus = (_viewStatus == ListStatus.content && events.isEmpty)
        ? ListStatus.empty
        : _viewStatus;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Health Timeline'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: WebConstraint(
        maxWidth: 720,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListStatusSelector(
                currentStatus: _viewStatus,
                onStatusChanged: (s) => setState(() => _viewStatus = s),
              ),
              Expanded(
                child: AppListState(
                  status: activeStatus,
                  emptyMessage: 'No Timeline Events',
                  emptyIcon: Icons.timeline_outlined,
                  errorMessage: 'Failed to build health timeline.',
                  onRetry: () => setState(() => _viewStatus = ListStatus.content),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    itemCount: groupedEvents.length,
                    itemBuilder: (context, index) {
                      final date = groupedEvents.keys.elementAt(index);
                      final dateEvents = groupedEvents[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DateHeader(date: date),
                          const SizedBox(height: AppSpacing.sm),
                          ...dateEvents.map((event) => _TimelineEventCard(event: event)),
                          if (index < groupedEvents.length - 1)
                            const SizedBox(height: AppSpacing.md),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<dynamic>> _groupEventsByDate(List<dynamic> events) {
    final Map<String, List<dynamic>> grouped = {};
    for (var event in events) {
      final date = event.eventDate;
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(event);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final Map<String, List<dynamic>> sortedGrouped = {};
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }
    return sortedGrouped;
  }
}

class _DateHeader extends StatelessWidget {
  final String date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(date) ?? DateTime.now();
    final formattedDate = DateFormat('MMMM yyyy').format(parsedDate);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('d').format(parsedDate),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                DateFormat('MMM').format(parsedDate).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          formattedDate,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _TimelineEventCard extends StatelessWidget {
  final dynamic event;

  const _TimelineEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            _getEventTypeIcon(event.eventType),
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                if (event.description != null)
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          AppBadge(
            text: _getEventTypeLabel(event.eventType),
            type: AppBadgeType.neutral,
            isSmall: true,
          ),
        ],
      ),
    );
  }

  IconData _getEventTypeIcon(String type) {
    switch (type) {
      case 'lab_report':
        return Icons.science_outlined;
      case 'prescription':
        return Icons.medication_outlined;
      case 'surgery':
        return Icons.content_cut;
      case 'discharge':
        return Icons.exit_to_app;
      default:
        return Icons.event_outlined;
    }
  }

  String _getEventTypeLabel(String type) {
    switch (type) {
      case 'lab_report':
        return 'Lab Report';
      case 'prescription':
        return 'Prescription';
      case 'surgery':
        return 'Surgery';
      case 'discharge':
        return 'Discharge';
      default:
        return type;
    }
  }
}
