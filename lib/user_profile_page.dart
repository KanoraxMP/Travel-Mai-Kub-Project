import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  @override
  void initState() {
  super.initState();
  _loadProfileImage();
}

Future<void> _loadProfileImage() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final directory = await getApplicationDocumentsDirectory();
  final savedImage = File(
    '${directory.path}/profile_photo_${user.uid}',
  );

  if (await savedImage.exists() && mounted) {
    setState(() {
      _profileImage = savedImage;
    });
  } else if (mounted) {
    setState(() {
      _profileImage = null;
    });
  }
}

Future<void> _pickProfileImage() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  try {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage == null) return;

    // เปิดหน้าครอปรูปภาพ
    final CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: pickedImage.path,
      aspectRatio: const CropAspectRatio(
        ratioX: 1,
        ratioY: 1,
      ),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'ครอปรูปโปรไฟล์',
          toolbarColor: const Color(0xFF025DD2),
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
      ],
    );

    // หากยกเลิกการครอป ให้คงรูปโปรไฟล์เดิมไว้
    if (croppedImage == null) return;

    final directory = await getApplicationDocumentsDirectory();

    
  final savedImage = await File(croppedImage.path).copy(
    '${directory.path}/profile_photo_${user.uid}',
  );

  // ล้างแคชของรูปเดิม เพื่อให้โหลดรูปใหม่
  await FileImage(savedImage).evict();

  if (!mounted) return;

  setState(() {
    _profileImage = savedImage;
  });

  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เลือกรูปหรือครอปรูปไม่สำเร็จ: $e'),
      ),
    );
  }
}

Future<void> _editDisplayName() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final nameController = TextEditingController(
    text: user.displayName ?? '',
  );

  final formKey = GlobalKey<FormState>();

  final newName = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        user.displayName?.isNotEmpty == true
            ? 'แก้ไขชื่อผู้ใช้'
            : 'เพิ่มชื่อผู้ใช้',
      ),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: nameController,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(
            labelText: 'ชื่อผู้ใช้',
            hintText: 'กรอกชื่อที่ต้องการ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณากรอกชื่อผู้ใช้';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(
                dialogContext,
                nameController.text.trim(),
              );
            }
          },
          child: const Text('บันทึก'),
        ),
      ],
    ),
  );

  // nameController.dispose();

  if (newName == null || newName.isEmpty) return;

  try {
    await user.updateDisplayName(newName);
    // await user.reload();

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('บันทึกชื่อผู้ใช้สำเร็จ'),
      ),
    );
  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('บันทึกชื่อไม่สำเร็จ: ${e.message ?? e.code}'),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF025DD2),
        foregroundColor: Colors.white,
        title: const Text('โปรไฟล์ของฉัน'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickProfileImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : null,
                  child: _profileImage == null
                ? const Icon(
                  Icons.person,
                  size: 62,
                )
                 : null,
                ),
              ),
              const SizedBox(height: 24),             
              Card (
                color: const Color(0xBD98AEC0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                 child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 28,
                          color: Color(0xFF263746),
                        ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ชื่อผู้ใช้',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 4),         
                  Text(
                    user?.displayName?.isNotEmpty == true
                    ? user!.displayName!
                    : 'ยังไม่มีชื่อผู้ใช้งาน',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 8, 8, 8),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _editDisplayName,
                  icon: Icon(
                    user?.displayName?.isNotEmpty == true
                    ? Icons.edit
                    : Icons.person_add_alt_1,
                  ),
                label: Text(
                  user?.displayName?.isNotEmpty == true
                  ? 'แก้ไขชื่อ'
                  : 'เพิ่มชื่อ',
                ),
              ),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: Color(0x80FFFFFF)),
        ),
        Row(
          children: [
            const Icon(
              Icons.email_outlined,
              size: 28,
              color: Color(0xFF263746),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'อีเมล',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'ไม่พบอีเมล',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),
            ],
          ),
        ),
      ),
    );
  }
}