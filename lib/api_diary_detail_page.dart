import 'package:flutter/material.dart';

class ApiDiaryDetailPage extends StatelessWidget {
  final Map<String, dynamic> diary;

  const ApiDiaryDetailPage({
    super.key,
    required this.diary,
  });

  @override
  Widget build(BuildContext context) {
    final title = diary['title']?.toString() ?? '';
    final content = diary['content']?.toString() ?? '';
    final mood = diary['mood']?.toString() ?? '';
    final date = diary['date']?.toString() ?? '';
    final imageUrl = diary['imageUrl']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดสถานที่'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 220,
                  width: double.infinity,
                color: Colors.grey.shade200,
                child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.category_outlined),
                const SizedBox(width: 8),
                Text(mood),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined),
                const SizedBox(width: 8),
                Text(date),
              ],
            ),
            const Divider(height: 32),
            Text(
              'เนื้อหา',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
