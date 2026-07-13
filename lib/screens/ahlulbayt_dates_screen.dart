import 'package:flutter/material.dart';
import '../data/ahlulbayt_dates_data.dart';
import '../models/models.dart';
import '../theme.dart';

class AhlulBaytDatesScreen extends StatelessWidget {
  const AhlulBaytDatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ولادات ووفيات أهل البيت'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            tabs: [
              Tab(text: 'الولادات'),
              Tab(text: 'الوفيات والاستشهادات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _EventsList(
                events: ahlulBaytEvents
                    .where((e) => e.kind == EventKind.birth)
                    .toList()),
            _EventsList(
                events: ahlulBaytEvents
                    .where((e) => e.kind == EventKind.death)
                    .toList()),
          ],
        ),
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  final List<AhlulBaytEvent> events;
  const _EventsList({required this.events});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        final isBirth = e.kind == EventKind.birth;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          isBirth ? AppColors.primaryGreen : Colors.grey[800],
                      child: Icon(
                        isBirth ? Icons.brightness_5 : Icons.brightness_2,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.personName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(e.description, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 10),
                Text(
                  e.narrations.length > 1
                      ? 'الروايات الواردة في تاريخ الحدث (${e.narrations.length}):'
                      : 'التاريخ:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ...e.narrations.map((n) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: n.isMostFamous
                            ? AppColors.lightGold.withOpacity(0.35)
                            : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: n.isMostFamous
                            ? Border.all(color: AppColors.gold, width: 1)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${n.hijriDate}${n.hijriYear != null ? " — ${n.hijriYear}" : ""}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (n.isMostFamous)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.star,
                                      size: 14, color: AppColors.gold),
                                ),
                            ],
                          ),
                          if (n.note != null) ...[
                            const SizedBox(height: 2),
                            Text(n.note!,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[700])),
                          ],
                          const SizedBox(height: 4),
                          Text('الرأي مسند إلى: ${n.attributedTo}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700])),
                        ],
                      ),
                    )),
                Text('المصدر العام: ${e.source}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        );
      },
    );
  }
}
