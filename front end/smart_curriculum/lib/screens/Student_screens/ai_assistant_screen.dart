// lib/screens/Student_screens/ai_assistant_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_curriculum/config.dart';
import 'package:smart_curriculum/services/Student_service/student_api_service.dart';
import 'package:smart_curriculum/utils/constants.dart';
import 'package:smart_curriculum/utils/logger.dart';

import 'mini_session_player.dart';
import 'ai_chatbot_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class RoadmapItem {
  final int id;
  final String topic;
  final String subtopic;
  final String status;
  final int? parentId;
  final int? position;
  final List<dynamic> resources;

  RoadmapItem({
    required this.id,
    required this.topic,
    required this.subtopic,
    required this.status,
    this.parentId,
    this.position,
    this.resources = const [],
  });

  factory RoadmapItem.fromMap(Map<String, dynamic> m) {
    return RoadmapItem(
      id: (m['id'] is int)
          ? m['id']
          : int.tryParse(m['id']?.toString() ?? '') ?? 0,
      topic: (m['topic'] ?? '').toString(),
      subtopic: (m['subtopic'] ?? '').toString(),
      status: (m['status'] ?? 'pending').toString(),
      parentId: m['parent_id'] is int
          ? m['parent_id']
          : (m['parent_id'] != null
              ? int.tryParse(m['parent_id'].toString())
              : null),
      position: m['position'] is int
          ? m['position']
          : (m['position'] != null
              ? int.tryParse(m['position'].toString())
              : null),
      resources: m['resources'] is List ? m['resources'] : [],
    );
  }
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  bool loading = false;
  bool loadingRoadmap = true;
  String statusMessage = '';
  List<RoadmapItem> roadmapItems = [];
  int? studentId;
  String studentName = 'Student';

  @override
  void initState() {
    super.initState();
    studentId = ApiService.loggedInStudentId;
    studentName = ApiService.loggedInStudentName ?? 'Student';
    _loadProgressAndRoadmap();
  }

  Future<void> _loadProgressAndRoadmap() async {
    if (mounted) {
      setState(() {
        loadingRoadmap = true;
        statusMessage = '';
      });
    }

    if (studentId == null) {
      if (mounted) {
        setState(() {
          roadmapItems = [];
          loadingRoadmap = false;
        });
      }
      return;
    }

    await _loadProgress();
    await _fetchRoadmap();

    if (mounted) {
      setState(() => loadingRoadmap = false);
    }
  }

  Future<void> _loadProgress() async {
    if (studentId == null) return;
    final data = await ApiService.fetchProgress(studentId!);
    if (data != null && !data.containsKey('_error')) {
      // optional: you can set statusMessage = "Progress: ${data['progress']}"
    }
  }

  Future<void> _fetchRoadmap() async {
    if (studentId == null) return;
    try {
      final uri = Uri.parse("$aiBase/roadmap_list").replace(queryParameters: {
        "student_id": studentId.toString(),
      });

      final res = await http.get(uri);
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final parsed = jsonDecode(res.body);
        List itemsRaw = [];
        if (parsed is Map && parsed.containsKey('roadmap')) {
          itemsRaw = parsed['roadmap'] as List;
        } else if (parsed is List) {
          itemsRaw = parsed;
        } else if (parsed is Map && parsed.containsKey('_list')) {
          itemsRaw = parsed['_list'];
        }

        final List<RoadmapItem> list = itemsRaw.map((e) {
          if (e is Map<String, dynamic>) return RoadmapItem.fromMap(e);
          return RoadmapItem.fromMap(Map<String, dynamic>.from(e));
        }).toList();

        // sort by position (stable)
        list.sort((a, b) {
          final pa = a.position ?? 0;
          final pb = b.position ?? 0;
          return pa.compareTo(pb);
        });

        if (mounted) {
          setState(() {
            roadmapItems = list;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            roadmapItems = [];
          });
        }
      }
    } catch (e) {
      Logger.error("fetchRoadmap error: $e");
      if (mounted) {
        setState(() {
          roadmapItems = [];
        });
      }
    }
  }

  // ------------------- Unlocking logic -------------------
  // New rules:
  // - Parent (top-level) items that have children are locked (can't be opened directly).
  // - For top-level sequence: the next top-level unlocks only when the ENTIRE previous top-level
  //   is complete. If the previous top-level had children, all children must be 'done'.
  // - Children unlock sequentially under their parent: first child unlocked, subsequent child
  //   unlocked only after previous sibling's status == 'done'.
  bool _hasChildren(RoadmapItem item) {
    return roadmapItems.any((c) => c.parentId == item.id);
  }

  bool _allChildrenDone(RoadmapItem parent) {
    final children =
        roadmapItems.where((c) => c.parentId == parent.id).toList();
    if (children.isEmpty) return false;
    return children.every((c) => c.status == 'done');
  }

  bool canOpenTopic(RoadmapItem item) {
    if (item.status == 'done') return true;

    // If top-level and has children -> locked (user must open children instead)
    if (item.parentId == null && _hasChildren(item)) {
      return false;
    }

    // ordering by position for predictable sequence
    final ordered = List<RoadmapItem>.from(roadmapItems)
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));

    // If item is a child -> unlock based on sibling sequence
    if (item.parentId != null) {
      final siblings = ordered
          .where((t) => t.parentId == item.parentId)
          .toList()
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
      final idx = siblings.indexWhere((s) => s.id == item.id);
      if (idx == -1) return false;
      if (idx == 0) return true;
      return siblings[idx - 1].status == 'done';
    }

    // Item is top-level and has no children:
    // find top-level items in order (including those with children)
    final topOrdered = ordered.where((t) => t.parentId == null).toList();
    final idx = topOrdered.indexWhere((t) => t.id == item.id);
    if (idx == -1) return false;

    // First top-level unlocked
    if (idx == 0) return true;

    // Previous top-level:
    final prevTop = topOrdered[idx - 1];
    // If previous top had children -> require all those children done
    if (_hasChildren(prevTop)) {
      return _allChildrenDone(prevTop);
    }
    // Otherwise require previous top itself done
    return prevTop.status == 'done';
  }

  int? getNextUpId() {
    final ordered = List<RoadmapItem>.from(roadmapItems)
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    for (final item in ordered) {
      if (item.status != 'done' && canOpenTopic(item)) return item.id;
    }
    return null;
  }

  List<Map<String, dynamic>> groupByParent() {
    final parents = roadmapItems.where((i) => i.parentId == null).toList()
      ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
    return parents.map((parent) {
      final children = roadmapItems
          .where((c) => c.parentId == parent.id)
          .toList()
        ..sort((a, b) => (a.position ?? 0).compareTo(b.position ?? 0));
      return {
        "parent": parent,
        "children": children,
      };
    }).toList();
  }

  Map<String, int> getProgress() {
    if (roadmapItems.isEmpty)
      return {'percentage': 0, 'completed': 0, 'total': 0};
    final completed = roadmapItems.where((i) => i.status == 'done').length;
    final percentage = ((completed / roadmapItems.length) * 100).round();
    return {
      'percentage': percentage,
      'completed': completed,
      'total': roadmapItems.length
    };
  }

  // ------------------- Actions -------------------
  Future<void> _onGenerateRoadmap() async {
    if (studentId == null) return;

    if (mounted) {
      setState(() {
        loading = true;
        statusMessage = "Asking AI to design your roadmap...";
      });
    }

    final recommendedTopic = await _getAIRecommendedTopic();
    if (recommendedTopic == null) {
      if (mounted) {
        setState(() {
          loading = false;
          statusMessage = "Unable to determine topic from profile.";
        });
      }
      return;
    }

    final res = await ApiService.generateRoadmap(studentId!, recommendedTopic);
    if (mounted) {
      setState(() => loading = false);
    }

    if (res != null && !res.containsKey('_error')) {
      if (mounted) {
        setState(() {
          statusMessage = "Roadmap generated for: $recommendedTopic";
        });
      }
      await _fetchRoadmap();
    } else {
      if (mounted) {
        setState(() {
          statusMessage = "Failed to generate roadmap.";
        });
      }
    }
  }

  Future<String?> _getAIRecommendedTopic() async {
    final studentId = ApiService.loggedInStudentId;
    if (studentId == null) return 'General Study Skills';

    final profile = await ApiService.fetchFullProfileById(studentId);
    var strength = '';
    var weakness = '';
    var interest = '';

    if (profile != null) {
      strength = (profile['strength'] ?? profile['strengths'] ?? '').toString();
      weakness =
          (profile['weakness'] ?? profile['weaknesses'] ?? '').toString();
      interest = (profile['interest'] ?? profile['interests'] ?? '').toString();
    }

    if (strength.isEmpty && weakness.isEmpty && interest.isEmpty)
      return 'General Study Skills';

    final prompt = """
Use student profile:
Strength: $strength
Weakness: $weakness
Interest: $interest

Generate 1 best study topic they should learn next.  
Return ONLY the topic name without explanation.
""";

    final reply = await ApiService.chatbot(prompt);
    if (reply == null || reply.trim().isEmpty) return null;
    return reply.trim();
  }

  void _openChat() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AiChatbotScreen()));
  }

  void _onTopicClick(RoadmapItem topic) {
    if (!canOpenTopic(topic)) return;
    _openMiniSession(topic);
  }

  // ------------------- NEW: robust client-side open flow -------------------
  // 1) Try fetch mini sessions for this roadmap_id
  // 2) If found -> open that mini_session by id via open_mini_session
  // 3) If not found -> fallback to next_mini_session (which creates/returns next session)
  Future<void> _openMiniSession(RoadmapItem topic) async {
    if (studentId == null) return;

    if (mounted) {
      setState(() {
        loading = true;
        statusMessage = "Opening session for ${topic.subtopic} ...";
      });
    }

    try {
      final sessions = await ApiService.fetchMiniSessions(
        studentId: studentId!,
        roadmapId: topic.id,
      );

      if (sessions != null && sessions.isNotEmpty) {
        final first = sessions.first;
        int? miniId;
        if (first is Map && first.containsKey("id")) {
          final raw = first["id"];
          miniId = raw is int ? raw : int.tryParse(raw?.toString() ?? "");
        } else if (first is int) {
          miniId = first;
        }

        if (miniId != null) {
          final res = await ApiService.openMiniSession(miniId);
          if (mounted) {
            setState(() => loading = false);
          }

          if (res == null ||
              res.containsKey("_error") ||
              res.containsKey("detail")) {
            if (mounted) {
              setState(() {
                statusMessage =
                    "Could not open that session, trying next session...";
              });
            }
            await _openNextFallback();
            return;
          }

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MiniSessionPlayer(session: res)),
            ).then((_) => _fetchRoadmap());
          }
          return;
        }
      }

      // no sessions found -> fallback
      await _openNextFallback();
    } catch (e) {
      Logger.error("_openMiniSession error: $e");
      if (mounted) {
        setState(() {
          statusMessage = "Unable to open session.";
          loading = false;
        });
      }
    }
  }

  Future<void> _openNextFallback() async {
    final res2 = await ApiService.getNextMiniSession(studentId!);
    if (mounted) {
      setState(() => loading = false);
    }

    if (res2 == null || res2.containsKey('_error')) {
      if (mounted) {
        setState(() {
          statusMessage = "Unable to open session.";
        });
      }
      return;
    }

    if ((res2['mini_session_id'] ?? 0) == 0) {
      if (mounted) {
        setState(() {
          statusMessage = "🎉 All sessions completed!";
        });
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MiniSessionPlayer(session: res2)),
      ).then((_) => _fetchRoadmap());
    }
  }

  // ------------------- Build UI -------------------
  @override
  Widget build(BuildContext context) {
    final progress = getProgress();
    final grouped = groupByParent();
    final nextUp = getNextUpId();

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientEnd,
          ],
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton(
            mini: true,
            onPressed: _openChat,
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            child: const Icon(Icons.question_answer),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                // Header Row (title + progress)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.map,
                              size: 22, color: AppColors.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Learning Path',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryColor)),
                        ],
                      ),
                    ),

                    // Circular progress
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 42,
                            height: 42,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: (progress['percentage'] ?? 0) / 100,
                                  strokeWidth: 4,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryColor),
                                ),
                                Center(
                                  child: Text("${progress['percentage']}%",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textColor,
                                          fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("${progress['completed']}/${progress['total']}",
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Controls (Generate only)
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: loading ? null : _onGenerateRoadmap,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 4),
                      child: loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text("Generate Roadmap",
                              style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),

                    // status message with ellipsis to avoid overflow
                    Flexible(
                      child: Text(
                        statusMessage,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Roadmap list
                Expanded(
                  child: loadingRoadmap
                      ? const Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor)),
                            SizedBox(height: 8),
                            Text("Loading roadmap...",
                                style: TextStyle(color: AppColors.textColor))
                          ]),
                        )
                      : grouped.isEmpty
                          ? const Center(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.map,
                                        size: 48,
                                        color: AppColors.subtitleColor),
                                    SizedBox(height: 8),
                                    Text(
                                        "No roadmap yet. Generate one to get started.",
                                        style: TextStyle(
                                            color: AppColors.textColor),
                                        textAlign: TextAlign.center)
                                  ]),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.only(bottom: 80, top: 6),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemCount: grouped.length,
                              itemBuilder: (context, i) {
                                final parent =
                                    grouped[i]['parent'] as RoadmapItem;
                                final children =
                                    grouped[i]['children'] as List<RoadmapItem>;
                                final isParentOpen = canOpenTopic(parent);
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 8)
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TopicCard(
                                        topic: parent,
                                        canOpen: isParentOpen,
                                        isParent: true,
                                        isNextUp: nextUp == parent.id,
                                        onTap: () => _onTopicClick(parent),
                                      ),
                                      if (children.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 12, left: 6),
                                          child: Column(
                                            children: children
                                                .map((c) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 8.0),
                                                      child: TopicCard(
                                                        topic: c,
                                                        canOpen:
                                                            canOpenTopic(c),
                                                        isChild: true,
                                                        isNextUp:
                                                            nextUp == c.id,
                                                        onTap: () =>
                                                            _onTopicClick(c),
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Topic Card Widget ----------
class TopicCard extends StatelessWidget {
  final RoadmapItem topic;
  final bool canOpen;
  final bool isParent;
  final bool isChild;
  final bool isNextUp;
  final VoidCallback? onTap;

  const TopicCard({
    super.key,
    required this.topic,
    this.canOpen = false,
    this.isParent = false,
    this.isChild = false,
    this.isNextUp = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = topic.status == 'done'
        ? const Color(0xFF16A34A)
        : canOpen
            ? const Color(0xFF2563EB)
            : const Color(0xFFAAAAAA);

    final displayStatus = topic.status == 'done'
        ? '✅ Completed'
        : isNextUp
            ? '🚀 Next Up'
            : canOpen
                ? 'Ready'
                : 'Locked';

    return GestureDetector(
      onTap: canOpen ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: canOpen ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isNextUp
                ? const Color(0xFFF0F9FF)
                : (isParent ? Colors.white : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: isNextUp
                ? Border.all(
                    color: statusColor, width: 1.6, style: BorderStyle.solid)
                : Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08), blurRadius: 6)
            ],
          ),
          child: Row(
            children: [
              if (isChild)
                Container(
                  width: 6,
                  height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.subtopic,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(topic.topic,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(displayStatus,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ],
          ),
        ),
      ),
    );
  }
}
