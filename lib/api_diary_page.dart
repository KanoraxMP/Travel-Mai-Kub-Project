import 'package:flutter/material.dart';
import 'diary_api_service.dart';
import 'api_diary_detail_page.dart';
import 'api_form_page.dart';

class ApiDiaryPage extends StatefulWidget {
  const ApiDiaryPage({super.key});

  @override
  State<ApiDiaryPage> createState() => _ApiDiaryPageState();
}

class _ApiDiaryPageState extends State<ApiDiaryPage> {
  Future<List<dynamic>>? diariesFuture;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  void _loadDiaries() {
    setState(() {
      diariesFuture = DiaryApiService.getDiaries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF025DD2),
        foregroundColor: Colors.white,
        title: const Text('ลิสต์ Diary ท่องเที่ยว'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
              context,
            MaterialPageRoute(
              builder: (context) => const ApiFormPage(),
            ),
          );
          if (result == true) {
            _loadDiaries();
          }
        },
      ),
    ],
  ),
      body: FutureBuilder<List<dynamic>>(
        future: diariesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'ไม่สามารถโหลดข้อมูลได้\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final diaries = snapshot.data ?? [];

          if (diaries.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีข้อมูล Diary สถานที่ออนไลน์'),
            );
          }

          return ListView.builder(
            itemCount: diaries.length,
            itemBuilder: (context, index) {
              final diary = diaries[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  // กดการ์ดเพื่อดูรายละเอียด
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ApiDiaryDetailPage(
                          diary: Map<String, dynamic>.from(diary),
                        ),
                      ),
                    );
                  },

                  title: Text(
                    diary['title']?.toString() ?? '',
                  ),
                  subtitle: Text(
                    diary['content']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        diary['mood']?.toString() ?? '',
                      ),

                      // ปุ่มแก้ไข
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApiFormPage(
                                diary: diary,
                              ),
                            ),
                          );

                          if (result == true) {
                            _loadDiaries();
                          }
                        },
                      ),

                      // ปุ่มลบ
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('ยืนยันการลบ'),
                                content: const Text(
                                  'คุณต้องการลบ Diary นี้ใช่หรือไม่?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context, false);
                                    },
                                    child: const Text('ยกเลิก'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text('ลบ'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm != true) {
                            return;
                          }

                          final id = diary['id'].toString();

                          try {
                            await DiaryApiService.deleteDiary(id);

                            if (!mounted) return;

                            _loadDiaries();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ลบ Diary สำเร็จ'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'ลบ Diary ไม่สำเร็จ: $e',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}