import 'package:flutter/material.dart';
import 'diary_api_service.dart';

class ApiFormPage extends StatefulWidget {
  final Map<String, dynamic>? diary;

  const ApiFormPage({
    super.key,
    this.diary,
  });

  @override
  State<ApiFormPage> createState() => _ApiFormPageState();
}

class _ApiFormPageState extends State<ApiFormPage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final moodController = TextEditingController();
  final dateController = TextEditingController();
  final imageUrlController = TextEditingController();

  bool isLoading = false;
  String? selectedCountry;
  String? selectedCity;
  int selectedRating = 0;

final List<String> countries = [
  'ประเทศไทย',
  'ญี่ปุ่น',
  'เกาหลีใต้',
  'สหรัฐอเมริกา',
  'นิวซีแลนด์',
  'คิโวทอส',
];

final Map<String, List<String>> citiesByCountry = {
  'ประเทศไทย': [
    'กรุงเทพมหานคร',
    'เชียงใหม่',
    'ภูเก็ต',
    'เชียงราย',
    'ขอนแก่น',
  ],
  'ญี่ปุ่น': [
    'โตเกียว',
    'เกียวโต',
    'โอซาก้า',
    'ฮอกไกโด',
  ],
  'เกาหลีใต้': [
    'โซล',
    'ปูซาน',
    'เกาะเชจู',
  ],
  'สหรัฐอเมริกา': [
    'นิวยอร์ก',
    'ลอสแอนเจลิส',
    'ซานฟรานซิสโก',
  ],
  'นิวซีแลนด์': [
    'โอ๊คแลนด์',
    'เวลลิงตัน',
    'ควีนส์ทาวน์',
  ],
  'คิโวทอส': [
    'ไฮแลนด์เดอร์',
    'อะบิดอส',
    'เกเฮนน่า',
    'ทรีนิตี้',
    'ซานไห่จิง',
    'เฮียกคิยาโค',
    'เรดวินเทอร์',
    'ไวล์ฮันต์',
    'เขต ดี.ยู.',
    'อาเรียส',
    'มิลเลนเนียม',
    'โอดิสซีย์',
  ],
  };

  @override
  void initState() {
    super.initState();

    if (widget.diary != null) {
      debugPrint('ข้อมูล Diary ที่ส่งมา: ${widget.diary}');
      titleController.text =
        widget.diary!['title']?.toString() ?? '';

      contentController.text =
        widget.diary!['content']?.toString() ?? '';

      moodController.text =
        widget.diary!['mood']?.toString() ?? '';

      dateController.text =
        widget.diary!['date']?.toString() ?? '';
      imageUrlController.text =
        widget.diary!['imageUrl']?.toString() ?? '';
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        dateController.text =
            '${pickedDate.year}-'
            '${pickedDate.month.toString().padLeft(2, '0')}-'
            '${pickedDate.day.toString().padLeft(2, '0')}';
      });
    }
  }
  
  Future<void> _addDiary() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (widget.diary == null) {
        // เพิ่ม Diary ใหม่
        await DiaryApiService.createDiary(
          titleController.text,
          contentController.text,
          moodController.text,
          dateController.text,
        );
      } else {
        // แก้ไข Diary เดิม
        final id = widget.diary!['id'].toString();

        await DiaryApiService.updateDiary(
          id,
          titleController.text,
          contentController.text,
          moodController.text,
          dateController.text,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.diary == null
                  ? 'เพิ่ม สถานที่ ไม่สำเร็จ: $e'
                  : 'แก้ไข สถานที่ ไม่สำเร็จ: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    moodController.dispose();
    dateController.dispose();
    super.dispose();
    imageUrlController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่ม Diary สถานที่ออนไลน์'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'เนื้อหา',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
              labelText: 'URL รูปภาพ',
              hintText: 'https://example.com/image.jpg',
              prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
              labelText: 'ประเทศ',
              prefixIcon: Icon(Icons.public),
              border: OutlineInputBorder(),
            ),
            value: selectedCountry,
            items: countries.map((country) {
            return DropdownMenuItem<String>(
              value: country,
              child: Text(country),
              );
            }).toList(),
          onChanged: (value) {
            setState(() {
            selectedCountry = value;
            selectedCity = null;
            });
          },
        ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
            labelText: 'เมือง',
            prefixIcon: Icon(Icons.location_city),
            border: OutlineInputBorder(),
          ),
          value: selectedCity,
          items: (citiesByCountry[selectedCountry] ?? [])
        .map((city) {
        return DropdownMenuItem<String>(
          value: city,
          child: Text(city),
        );
        }).toList(),
        onChanged: selectedCountry == null
        ? null
          : (value) {
          setState(() {
            selectedCity = value;
          });
        },
      ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'คะแนนสถานที่',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final rating = index + 1;

            return IconButton(
              onPressed: () {
                setState(() {
                  selectedRating = rating;
                });
              },
              icon: Icon(
                rating <= selectedRating
                  ? Icons.star
                  : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
            );
          }),
        ),
        Text(
          selectedRating == 0
            ? 'ยังไม่ได้ให้คะแนน'
            : '$selectedRating / 5 ดาว',
        ),
      ],
    ),
  ),
          const SizedBox(height: 12), 
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'วันที่จะเดินทาง',
                hintText: 'เลือกวันที่จากปฏิทิน',
                prefixIcon: Icon(Icons.calendar_month),
              ),
              onTap: _selectDate,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _addDiary,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('เพิ่มเมือง Diary'),
            ),
          ],
        ),
      ),
    );
  }
}