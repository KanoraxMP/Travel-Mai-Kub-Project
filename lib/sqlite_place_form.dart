import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:my_first_app_1/main.dart';

class SqlitePlaceForm extends StatefulWidget {
  final TravelPlace? place;

  const SqlitePlaceForm({
    super.key,
    this.place,
  });

  @override
  State<SqlitePlaceForm> createState() => _SqlitePlaceFormState();
}

class _SqlitePlaceFormState extends State<SqlitePlaceForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;

  String? _category;
  int _rating = 5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final place = widget.place;

    _nameController = TextEditingController(
      text: place?.name ?? '',
    );

    _descriptionController = TextEditingController(
      text: place?.description ?? '',
    );

    _imageUrlController = TextEditingController(
      text: place?.imageUrl ?? '',
    );

    _category = place?.category;
    _rating = place?.rating ?? 5;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageUrlController.clear();
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเลือกรูปภาพได้: $error'),
        ),
      );
    }
  }

  Future<String> _saveImageToAppDirectory(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();

    final extension = p.extension(imageFile.path).isNotEmpty
        ? p.extension(imageFile.path)
        : '.jpg';

    final fileName =
        'travel_${DateTime.now().microsecondsSinceEpoch}$extension';

    final savedImage = await imageFile.copy(
      p.join(directory.path, fileName),
    );

    return savedImage.path;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.place != null;

    return AlertDialog(
      title: Text(isEditing ? 'แก้ไขสถานที่' : 'เพิ่มสถานที่'),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อสถานที่',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'กรุณากรอกชื่อสถานที่'
                          : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียด',
                  ),
                  maxLines: 2,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'กรุณากรอกรายละเอียด'
                          : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'หมวดหมู่',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ทะเล',
                      child: Text('ทะเล'),
                    ),
                    DropdownMenuItem(
                      value: 'ภูเขา',
                      child: Text('ภูเขา'),
                    ),
                    DropdownMenuItem(
                      value: 'เมือง',
                      child: Text('เมือง'),
                    ),
                    DropdownMenuItem(
                      value: 'ต่างประเทศ',
                      child: Text('ต่างประเทศ'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _category = value);
                  },
                  validator: (value) =>
                      value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _rating,
                  decoration: const InputDecoration(
                    labelText: 'คะแนน',
                  ),
                  items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1} ดาว'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _rating = value);
                    }
                  },
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL รูปภาพ',
                  ),
                  validator: (value) {
                    if (_selectedImage != null) {
                      return null;
                    }

                    if (value == null || value.trim().isEmpty) {
                      if (widget.place?.imageUrl.isNotEmpty == true) {
                        return null;
                      }

                      return 'กรุณาเลือกรูปภาพหรือกรอก URL รูปภาพ';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),

                if (_selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 50),
                    ),
                  )
                else if (_imageUrlController.text.trim().isNotEmpty &&
                    (_imageUrlController.text.startsWith('http://') ||
                        _imageUrlController.text.startsWith('https://')))
                  Image.network(
                    _imageUrlController.text.trim(),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  )
                else if (_imageUrlController.text.trim().isNotEmpty &&
                    File(_imageUrlController.text).existsSync())
                  Image.file(
                    File(_imageUrlController.text),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  )
                else
                  const Icon(Icons.image_outlined, size: 50),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('แกลเลอรี'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('ถ่ายรูป'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSaving ? null : () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
        ),
        ElevatedButton(      
          onPressed: _isSaving
            ? null
            : () async {
              if (!_formKey.currentState!.validate()) return;
                // เก็บ State ไว้ก่อนเริ่ม async
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.maybeOf(context);
                setState(() => _isSaving = true);
              try {
                String imagePath = _imageUrlController.text.trim();
              if (_selectedImage != null) {
                imagePath = await _saveImageToAppDirectory(
                _selectedImage!,
                );
              }
              final result = TravelPlace(
                id: widget.place?.id,
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                category: _category!,
                rating: _rating,
                icon: Icons.location_on,
                color: const Color(0xFF025DD2),
                imageUrl: imagePath,
                visitDate: widget.place?.visitDate,
              );
              if (!mounted) return;
                navigator.pop(result);
            } catch (error) {
              if (!mounted) return;
                setState(() => _isSaving = false);
                messenger?.showSnackBar(
          SnackBar(
              content: Text('บันทึกรูปภาพไม่สำเร็จ: $error'),
            ),
          );
        }
      },
          child: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึก'),
        ),
      ],
    );
  }
}