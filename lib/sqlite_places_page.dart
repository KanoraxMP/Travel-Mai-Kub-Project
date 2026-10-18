import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_first_app_1/main.dart';
import 'database_helper.dart';
import 'sqlite_place_form.dart';

class SqlitePlacesPage extends StatefulWidget {
  const SqlitePlacesPage({super.key});

  @override
  State<SqlitePlacesPage> createState() => _SqlitePlacesPageState();
}

class _SqlitePlacesPageState extends State<SqlitePlacesPage> {
  List<TravelPlace> places = [];
  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();

  // ค้นหาชื่อสถานที่
  String searchQuery = '';

  // กรองหมวดหมู่
  String selectedCategory = 'ทั้งหมด';
  // แสดงรายการโปรด
  bool favoritesOnly = false;

  // กรองข้อมูลตามชื่อสถานที่และหมวดหมู่
  
  List<TravelPlace> get filteredPlaces {
    final result = places.where((place) {
      final matchesName = place.name
        .toLowerCase()
        .contains(searchQuery.trim().toLowerCase());

      final matchesCategory = selectedCategory == 'ทั้งหมด' ||
        place.category == selectedCategory;

      final matchesFavorite = !favoritesOnly || place.isFavorite;

      return matchesName && matchesCategory && matchesFavorite;
    }).toList();

    result.sort((a, b) {
      if (a.isFavorite == b.isFavorite) {
        return 0;
      }
      return a.isFavorite ? -1 : 1;
    });
    return result;
  }

  @override
  void initState() {
    super.initState();
    loadPlaces();
  }

  Future<void> loadPlaces() async {
    setState(() => isLoading = true);

    try {
      final data = await DatabaseHelper.instance.getAll();

      if (!mounted) return;

      setState(() {
        places = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> showPlaceForm({TravelPlace? place}) async {
    final result = await showDialog<TravelPlace>(
      context: context,
      builder: (dialogContext) => SqlitePlaceForm(place: place),
    );

    if (result == null) return;

    try {
      if (place == null) {
        await DatabaseHelper.instance.insert(result);
      } else {
        await DatabaseHelper.instance.update(result);
      }

      await loadPlaces();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            place == null ? 'เพิ่มสถานที่สำเร็จ' : 'แก้ไขสถานที่สำเร็จ',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> deletePlace(TravelPlace place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ "${place.name}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true || place.id == null) return;

    try {
      await DatabaseHelper.instance.delete(place.id!);
      await loadPlaces();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบสถานที่สำเร็จ')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
      );
    }
  }

  
  Future<void> toggleFavorite(TravelPlace place) async {
    if (place.id == null) return;

    try {
      await DatabaseHelper.instance.updateFavorite(
        place.id!,
        !place.isFavorite,
      );

      await loadPlaces();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            place.isFavorite
              ? 'นำออกจากรายการโปรดแล้ว'
              : 'เพิ่มในรายการโปรดแล้ว',
          ),
        ),
    ) ;
    } catch (e) {
      if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยนสถานะรายการโปรดไม่สำเร็จ: $e')),
      );
    }
  }

  @override
    void dispose() {
      searchController.dispose();
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF025DD2),
        foregroundColor: Colors.white,
        title: const Text('ลิสต์รายการท่องเที่ยวใน Cloud'),
        actions: [
          IconButton(
            onPressed: () => showPlaceForm(),
            icon: const Icon(Icons.add),
            tooltip: 'เพิ่มสถานที่',
          ),
          IconButton(
            onPressed: loadPlaces,
            icon: const Icon(Icons.refresh),
            tooltip: 'โหลดข้อมูลใหม่',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ช่องค้นหาชื่อสถานที่
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                      labelText: 'ค้นหาชื่อสถานที่',
                      hintText: 'พิมพ์ชื่อสถานที่ที่ต้องการค้นหา',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),              
                // ตัวกรองหมวดหมู่
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'กรองตามหมวดหมู่',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ทั้งหมด',
                        child: Text('ทั้งหมด'),
                      ),
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
                      if (value == null) return;

                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      favoritesOnly
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: favoritesOnly ? Colors.red : Colors.grey,
                    ),
                    title: const Text('แสดงเฉพาะรายการโปรด'),
                    subtitle: const Text(
                      'ซ่อนสถานที่ที่ไม่ได้กดหัวใจ',
                    ),
                    value: favoritesOnly,
                    onChanged: (value) {
                      setState(() {
                        favoritesOnly = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // รายการสถานที่หลังค้นหาและกรอง
                Expanded(
                  child: places.isEmpty
                      ? const Center(
                          child: Text('ยังไม่มีสถานที่ใน SQLite'),
                        )
                      : filteredPlaces.isEmpty
                          ? const Center(
                              child: Text(
                                'ไม่พบสถานที่ที่ตรงกับเงื่อนไข',
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredPlaces.length,
                              itemBuilder: (context, index) {
                                final place = filteredPlaces[index];

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: ListTile(
                                    leading: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: 
                                      Builder(
                                        builder: (context) {
                                          final imagePath = place.imageUrl.trim();
                                            if (imagePath.isEmpty) {
                                              return const Icon(Icons.image_not_supported);
                                            }
                                            if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
                                                return Image.network(
                                                imagePath,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                              );
                                            }
                                  final imageFile = File(imagePath);

                                  return Image.file(
                                    imageFile,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                                    title: Text(place.name),
                                    subtitle: Text(
                                      '${place.category} • '
                                      '${place.rating} ดาว',
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TravelDetailPage(
                                            place: place,
                                          ),
                                        ),
                                      );
                                    }, 
                                    trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                // ปุ่มรายการโปรด
                                                IconButton(
                                                  tooltip: place.isFavorite
                                                  ? 'นำออกจากรายการโปรด'
                                                  : 'เพิ่มในรายการโปรด',
                                                  icon: Icon(
                                                          place.isFavorite
                                                          ? Icons.favorite
                                                          : Icons.favorite_border,
                                                          color: place.isFavorite ? Colors.red : Colors.grey,
                                                        ),
                                                        onPressed: () {
                                                          toggleFavorite(place);
                                                        },
                                                ),
                                                IconButton(
                                                  tooltip: 'แก้ไขสถานที่',
                                                  icon: const Icon(
                                                                Icons.edit,
                                                                color: Colors.blue,
                                                              ),
                                                  onPressed: () {
                                                    showPlaceForm(place: place);
                                                  },
                                                ),
                                                // ปุ่มลบ
                                                IconButton(
                                                  tooltip: 'ลบสถานที่',
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    deletePlace(place);
                                                  },
                                                ),
                                              ],
                                            ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}