import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'database_helper.dart';
import 'api_service.dart';
import 'weather_model.dart';
import 'weather_data_model.dart';
import 'country_api_service.dart';
import 'country_model.dart';
import 'api_diary_page.dart';
import 'login_page.dart';
import 'travel_place_firestore_service.dart';
import 'sqlite_places_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'user_profile_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'service/notification_service.dart';

const Color primaryColor = Color(0xFF025DD2);
const List<String> placeCategories = [
  'ทะเล',
  'ภูเขา',
  'เมือง',
  'ต่างประเทศ',
];

Future<void> setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;
  // ขออนุญาตรับการแจ้งเตือน
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('Notification permission: ${settings.authorizationStatus}');
  // ดึง FCM Token ของอุปกรณ์
  final token = await messaging.getToken();
  debugPrint('FCM Token: $token');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await setupFirebaseMessaging();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'บันทึกการท่องเที่ยวของฉัน',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// TravelPlace Model
class TravelPlace {
  final int? id;
  final String? firestoreId;
  final String name;
  final String description;
  final String category;
  final int rating;
  final IconData icon;
  final Color color;
  final String imageUrl;
  final String? visitDate;
  final bool isFavorite;

  const TravelPlace({
    this.id,
    this.firestoreId,
    required this.name,
    required this.description,
    required this.category,
    required this.rating,
    this.isFavorite = false,
    required this.icon,
    required this.color,
    required this.imageUrl,
    this.visitDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'rating': rating,
      'imageUrl': imageUrl,
      'visitDate': visitDate,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory TravelPlace.fromMap(Map<String, dynamic> map) {
    final favoriteValue = map['isFavorite'];

    return TravelPlace(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      isFavorite: favoriteValue == true || favoriteValue == 1,
      icon: Icons.location_on,
      color: primaryColor,
      imageUrl: map['imageUrl'] as String? ?? '',
      visitDate: map['visitDate'] as String?,
    );
  }

  factory TravelPlace.fromFirestore(Map<String, dynamic> map) {
    return TravelPlace(
      firestoreId: map['firestoreId'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      isFavorite: map['isFavorite'] == true,
      icon: Icons.location_on,
      color: primaryColor,
      imageUrl: map['imageUrl'] as String? ?? '',
      visitDate: map['visitDate'] as String?,
    );
  }
}

// ===================== SQLite Seed Data =====================
final List<TravelPlace> myTravelList = [
  TravelPlace(
    name: 'เกียวโต (เทส SQLite)',
    description:
        'เมืองเก่าของญี่ปุ่น เต็มไปด้วยวัดและศาลเจ้าโบราณ สวยมากช่วงใบไม้เปลี่ยนสี',
    category: 'เมือง',
    rating: 5,
    icon: Icons.flight,
    color: Colors.deepOrange,
    imageUrl: 'https://picsum.photos/seed/kyoto/500/300',
  ),
];

// ===================== Authentication =====================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          return const MainScreen();
        }
        return const LoginPage();
      },
    );
  }
}

// ===================== Main Screen =====================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    TravelListPage(),
    SqlitePlacesPage(),
    ApiDiaryPage(),
    AboutPage(),
    UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกการท่องเที่ยวของฉัน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: primaryColor,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'รายการ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Cloud',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'ออนไลน์',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'เกี่ยวกับ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

// ===================== Place Image =====================
class PlaceImage extends StatelessWidget {
  final String url;
  final double height;
  final BorderRadius borderRadius;

  const PlaceImage({
    super.key,
    required this.url,
    required this.height,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
  if (url.trim().isEmpty) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(
        Icons.broken_image,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  final imageFile = File(url);
  final isLocalFile = !url.startsWith('http://') &&
      !url.startsWith('https://');

    return ClipRRect(
    borderRadius: borderRadius,
    child: isLocalFile
        ? Image.file(
            imageFile,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorImage();
            },
          )
        : Image.network(
            url,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;

              return Container(
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorImage();
            },
          ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// ===================== Travel List Page =====================

class TravelListPage extends StatefulWidget {
  const TravelListPage({super.key});

  @override
  State<TravelListPage> createState() => _TravelListPageState();
}

class _TravelListPageState extends State<TravelListPage> {
  final TravelPlaceFirestoreService firestoreService =
      TravelPlaceFirestoreService();

  final ApiService apiService = ApiService();
  final CountryApiService countryApiService = CountryApiService();

  late final Stream<List<TravelPlace>> placesStream;
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  String selectedCategory = 'ทั้งหมด';

  bool favoritesOnly = false;

  Future<WeatherModel>? weatherFuture;
  Future<CountryModel>? countryFuture;

  @override
  void initState() {
    super.initState();

    placesStream = watchFirestorePlaces();
    weatherFuture = getAndSaveWeather();
    countryFuture = countryApiService.getThailand();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      await DatabaseHelper.instance.getAll();
    } catch (e) {
      debugPrint('โหลดข้อมูล SQLite ไม่สำเร็จ: $e');
    }
  }

  Future<void> refreshWeather() async {
    setState(() {
      weatherFuture = getAndSaveWeather();
    });
  }

  Future<void> saveWeatherToDatabase(WeatherModel weather) async {
    final weatherData = WeatherDataModel(
      latitude: weather.latitude,
      longitude: weather.longitude,
      temperature: weather.temperature,
      fetchedAt: DateTime.now().toIso8601String(),
    );

    final id =
        await DatabaseHelper.instance.insertWeather(weatherData);

    debugPrint('บันทึก Weather ลง SQLite สำเร็จ ID: $id');
  }

  Future<WeatherModel> getAndSaveWeather() async {
    final weather = await apiService.getWeather();
    await saveWeatherToDatabase(weather);
    return weather;
  }

  Stream<List<TravelPlace>> watchFirestorePlaces() {
    return firestoreService.watchPlaces().map((items) {
      return items
          .map((item) => TravelPlace.fromFirestore(item))
          .toList();
    });
  }

  Future<void> togglePlaceFavorite(
    TravelPlace place,
    bool value,
  ) async {
    final documentId = place.firestoreId;

    if (documentId == null || documentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบรหัสข้อมูล Firestore'),
        ),
      );
      return;
    }

    try {
      await firestoreService.toggleFavorite(documentId, value);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'เพิ่ม "${place.name}" ในรายการโปรดแล้ว'
                : 'นำ "${place.name}" ออกจากรายการโปรดแล้ว',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เปลี่ยนสถานะรายการโปรดไม่สำเร็จ: $e'),
        ),
      );
    }
  }

Future<void> deletePlace(TravelPlace place) async {
  final documentId = place.firestoreId;

  if (documentId == null || documentId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ไม่พบรหัสข้อมูล Firestore'),
      ),
    );
    return;
  }

  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text(
          'คุณต้องการลบ "${place.name}" ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบ'),
          ),
        ],
      );
    },
  );

  if (confirm != true) return;
  if (!mounted) return;

  try {
    await firestoreService.deletePlace(documentId);

    await NotificationService.instance.cancelTravelReminders(
      documentId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ลบสถานที่สำเร็จ'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ลบข้อมูลไม่สำเร็จ: $e'),
      ),
    );
  }
}

  List<TravelPlace> filterPlaces(List<TravelPlace> places) {
    final query = searchQuery.trim().toLowerCase();

    return places.where((place) {
      final matchesName =
          place.name.toLowerCase().contains(query);

      final matchesCategory =
          selectedCategory == 'ทั้งหมด' ||
          place.category == selectedCategory;

      final matchesFavorite =
          !favoritesOnly || place.isFavorite;

      return matchesName &&
          matchesCategory &&
          matchesFavorite;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลิสต์รายการท่องเที่ยว'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชสภาพอากาศ',
            onPressed: refreshWeather,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'เพิ่มสถานที่',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPlacePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<WeatherModel>(
            future: weatherFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'โหลดข้อมูลสภาพอากาศไม่สำเร็จ',
                    style: TextStyle(
                      color: Colors.red[700],
                    ),
                  ),
                );
              }

              final weather = snapshot.data;

              if (weather == null) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'อุณหภูมิปัจจุบัน: ${weather.temperature} °C',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          FutureBuilder<CountryModel>(
            future: countryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('ไม่สามารถโหลดข้อมูลประเทศได้'),
                );
              }

              final country = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  'ประเทศ: ${country.name} | เมืองหลวง: ${country.capital}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<TravelPlace>>(
              stream: placesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'เกิดข้อผิดพลาดในการโหลดข้อมูล:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final places = snapshot.data ?? [];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        12,
                        12,
                        6,
                      ),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'ค้นหาชื่อสถานที่',
                          hintText: 'พิมพ์ชื่อสถานที่ที่ต้องการค้นหา',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'กรองตามหมวดหมู่',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'ทั้งหมด',
                            child: Text('ทั้งหมด'),
                          ),
                          ...placeCategories.map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
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
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      title: const Text('แสดงเฉพาะรายการโปรด'),
                      secondary: Icon(
                        favoritesOnly
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: favoritesOnly
                            ? Colors.red
                            : Colors.grey,
                      ),
                      value: favoritesOnly,
                      onChanged: (value) {
                        setState(() {
                          favoritesOnly = value;
                        });
                      },
                    ),
                    Expanded(
                      child: places.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.travel_explore,
                                    size: 72,
                                    color: primaryColor,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'ยังไม่มีสถานที่ท่องเที่ยว',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'กดปุ่ม + เพื่อเพิ่มสถานที่แรกของคุณ',
                                  ),
                                ],
                              ),
                            )
                          : _buildFilteredList(places),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredList(List<TravelPlace> places) {
    final filteredPlaces = filterPlaces(places);
    filteredPlaces.sort((a, b) {
      if (a.isFavorite == b.isFavorite) {
        return 0;
      }
      return a.isFavorite ? -1 : 1;
    });
    if (filteredPlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                favoritesOnly
                    ? 'ไม่พบรายการโปรดที่ตรงกับเงื่อนไข'
                    : 'ไม่พบสถานที่ที่ตรงกับเงื่อนไข',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  searchController.clear();

                  setState(() {
                    searchQuery = '';
                    selectedCategory = 'ทั้งหมด';
                    favoritesOnly = false;
                  });
                },
                child: const Text('ล้างตัวกรอง'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredPlaces.length,
      itemBuilder: (context, index) {
        final place = filteredPlaces[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: SizedBox(
                  width: 80,
                  height: 90,
                  child: PlaceImage(
                    url: place.imageUrl,
                    height: 90,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                title: Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text('หมวดหมู่: ${place.category}'),
                    const SizedBox(height: 5),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < place.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),                
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
              IconButton(
                tooltip: place.isFavorite
                ? 'นำออกจากรายการโปรด'
                : 'เพิ่มในรายการโปรด',
                icon: Icon(
                  place.isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
                  color: place.isFavorite
                  ? Colors.red
                  : Colors.grey,
                ),
                onPressed: () {
              togglePlaceFavorite(place, !place.isFavorite);
              },
            ),
          PopupMenuButton<String>(
          tooltip: 'จัดการสถานที่',
          onSelected: (value) async {
          if (value == 'edit') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPlacePage(place: place),
              ),
            );
          } else if (value == 'delete') {
            await deletePlace(place);
          } else if (value == 'detail') {
              await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TravelDetailPage(place: place),
              ),
            );
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'detail',
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('รายละเอียด'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('แก้ไข'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('ลบ'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    ],
  ),
  onTap: () {
    Navigator.push(
      context,
        MaterialPageRoute(
          builder: (context) => TravelDetailPage(place: place),
        ),
      );
    },
  ),
  const Divider(height: 1),
            ],
          ),
        );
      },
    );
  }
}

// ===================== Travel Detail Page =====================
class TravelDetailPage extends StatelessWidget {
  final TravelPlace place;

  const TravelDetailPage({
    super.key,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(place.name),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PlaceImage(
              url: place.imageUrl,
              height: 240,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    place.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(place.category),
                    backgroundColor: place.color.withValues(
                      alpha: 0.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < place.rating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (place.visitDate != null &&
                      place.visitDate!.isNotEmpty)
                    Text('วันที่ไปเที่ยว: ${place.visitDate}'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    place.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== About Page =====================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เกี่ยวกับแอปพลิเคชัน'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: primaryColor,
                  child: Icon(
                    Icons.person,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'ผู้พัฒนาแอปพลิเคชัน',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'นายธนัทภัทร ทูลธรรม',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'รหัส : 66011212097',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'สังกัด : ภาควิทยาการคอมพิวเตอร์ (CS)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 8),
                Text(
                  'แอปนี้พัฒนาขึ้นเพื่อรวบรวมสถานที่ท่องเที่ยวที่อยากไปและเคยไปมาแล้วเป็นความทรงจำสักครั้งหนึ่งในชีวิต 🌍',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
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

// ===================== Add Place Page =====================
class AddPlacePage extends StatefulWidget {
  const AddPlacePage({super.key});

  @override
  State<AddPlacePage> createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedImagePath;
  String? selectedCategory;
  int selectedRating = 5;
  DateTime? selectedDate;
  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImagePath = pickedFile.path;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเลือกรูปภาพได้: $e'),
        ),
      );
    }
  }

Future<String?> _saveImagePermanently() async {
  if (_selectedImagePath == null) {
    return null;
  }

  final appDirectory =
      await getApplicationDocumentsDirectory();

  final imageDirectory = Directory(
    path.join(appDirectory.path, 'travel_images'),
  );

  if (!await imageDirectory.exists()) {
    await imageDirectory.create(recursive: true);
  }

  final extension = path.extension(_selectedImagePath!);
  final fileName =
      'travel_${DateTime.now().microsecondsSinceEpoch}'
      '${extension.isEmpty ? '.jpg' : extension}';

  final savedPath = path.join(
    imageDirectory.path,
    fileName,
  );

  final savedFile = await File(
    _selectedImagePath!,
  ).copy(savedPath);

  return savedFile.path;
}

Future<void> savePlace() async {
  if (!_formKey.currentState!.validate()) return;
  if (isSaving) return;

  setState(() {
    isSaving = true;
  });

  try {
    final savedImagePath = await _saveImagePermanently();

    final place = TravelPlace(
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      category: selectedCategory!,
      rating: selectedRating,
      icon: Icons.location_on,
      color: primaryColor,
      imageUrl: savedImagePath ?? imageUrlController.text.trim(),
      visitDate: selectedDate?.toIso8601String().split('T').first,
      isFavorite: false,
    );

    final documentId =
        await TravelPlaceFirestoreService().addPlace({
      'name': place.name,
      'description': place.description,
      'category': place.category,
      'rating': place.rating,
      'imageUrl': place.imageUrl,
      'visitDate': place.visitDate,
      'isFavorite': false,
    });

    if (place.visitDate != null && place.visitDate!.isNotEmpty) {
      await NotificationService.instance.scheduleTravelReminders(
        documentId: documentId,
        placeName: place.name,
        visitDate: place.visitDate!,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เพิ่มสถานที่สำเร็จ'),
      ),
    );

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เพิ่มสถานที่ไม่สำเร็จ: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มสถานที่'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสถานที่',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อสถานที่';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกรายละเอียด';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
              ),
              items: placeCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณาเลือกหมวดหมู่';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              leading: const Icon(
                Icons.calendar_month,
                color: primaryColor,
              ),
              title: Text(
                selectedDate == null
                    ? 'เลือกวันที่ไปเที่ยว'
                    : 'วันที่ไปเที่ยว: ${selectedDate!.toIso8601String().split('T').first}',
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: pickDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: selectedRating,
              decoration: const InputDecoration(
                labelText: 'คะแนน (1-5)',
                border: OutlineInputBorder(),
              ),
              items: List.generate(5, (index) {
                final rating = index + 1;

                return DropdownMenuItem<int>(
                  value: rating,
                  child: Text('$rating ดาว'),
                );
              }),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedRating = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL รูปภาพ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_selectedImagePath != null) {
                return null;
              }

  if (value == null || value.trim().isEmpty) {
    return 'กรุณากรอก URL หรือเลือกรูปภาพ';
  }

  final uri = Uri.tryParse(value.trim());

  if (uri == null ||
      !uri.hasScheme ||
      !(uri.scheme == 'http' ||
          uri.scheme == 'https')) {
    return 'กรุณากรอก URL ที่ขึ้นต้นด้วย http:// หรือ https://';
  }

    return null;
  },
            ),
            const SizedBox(height: 24),
            
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                onPressed: isSaving
            ? null
            : () => _pickImage(ImageSource.gallery),
        icon: const Icon(Icons.photo_library),
        label: const Text('เลือกจาก Gallery'),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: OutlinedButton.icon(
        onPressed: isSaving
            ? null
            : () => _pickImage(ImageSource.camera),
        icon: const Icon(Icons.camera_alt),
        label: const Text('ถ่ายรูป'),
      ),
    ),
  ],
),

if (_selectedImagePath != null) ...[
  const SizedBox(height: 12),
  ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      File(_selectedImagePath!),
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  ),
  TextButton.icon(
    onPressed: isSaving
        ? null
        : () {
            setState(() {
              _selectedImagePath = null;
            });
          },
    icon: const Icon(Icons.delete_outline),
    label: const Text('นำรูปที่เลือกออก'),
  ),
],

const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: isSaving ? null : savePlace,
              icon: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(isSaving ? 'กำลังบันทึก...' : 'บันทึก'),
            ),
          ],
        ),
      ),
    );
  }
}


 // ===================== Edit Place Page =====================

class EditPlacePage extends StatefulWidget {
  final TravelPlace place;

  const EditPlacePage({
    super.key,
    required this.place,
  });

  @override
  State<EditPlacePage> createState() => _EditPlacePageState();
}

class _EditPlacePageState extends State<EditPlacePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController imageUrlController;

  String? selectedCategory;
  late int selectedRating;
  DateTime? selectedDate;

  String? _selectedImagePath;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.place.name,
    );

    descriptionController = TextEditingController(
      text: widget.place.description,
    );

    imageUrlController = TextEditingController(
      text: widget.place.imageUrl,
    );

    selectedCategory = placeCategories.contains(widget.place.category)
        ? widget.place.category
        : null;

    selectedRating = widget.place.rating.clamp(1, 5);

    if (widget.place.visitDate != null) {
      selectedDate = DateTime.tryParse(widget.place.visitDate!);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) return;

      setState(() {
        _selectedImagePath = pickedFile.path;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเลือกรูปภาพได้: $e'),
        ),
      );
    }
  }

  Future<String?> _saveImagePermanently() async {
    if (_selectedImagePath == null) {
      return null;
    }

    final appDirectory =
        await getApplicationDocumentsDirectory();

    final imageDirectory = Directory(
      path.join(appDirectory.path, 'travel_images'),
    );

    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final extension = path.extension(_selectedImagePath!);

    final fileName =
        'travel_${DateTime.now().microsecondsSinceEpoch}'
        '${extension.isEmpty ? '.jpg' : extension}';

    final savedPath = path.join(
      imageDirectory.path,
      fileName,
    );

    final savedFile = await File(
      _selectedImagePath!,
    ).copy(savedPath);

    return savedFile.path;
  }

Future<void> updatePlace() async {
  if (isSaving) return;

  if (!_formKey.currentState!.validate()) return;

  final documentId = widget.place.firestoreId;

  if (documentId == null || documentId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ไม่พบรหัสข้อมูล Firestore จึงไม่สามารถแก้ไขได้',
        ),
      ),
    );
    return;
  }

  setState(() {
    isSaving = true;
  });

  try {
    final savedImagePath = await _saveImagePermanently();

    final visitDate =
        selectedDate?.toIso8601String().split('T').first;

    await TravelPlaceFirestoreService().updatePlace(
      documentId,
      {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': selectedCategory!,
        'rating': selectedRating,
        'imageUrl': savedImagePath ?? imageUrlController.text.trim(),
        'visitDate': visitDate,
      },
    );

    if (visitDate != null && visitDate.isNotEmpty) {
      await NotificationService.instance.scheduleTravelReminders(
        documentId: documentId,
        placeName: nameController.text.trim(),
        visitDate: visitDate,
      );
    } else {
      await NotificationService.instance.cancelTravelReminders(
        documentId,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('แก้ไขสถานที่สำเร็จ'),
      ),
    );

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('แก้ไขสถานที่ไม่สำเร็จ: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขสถานที่'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสถานที่',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อสถานที่';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'รายละเอียด',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกรายละเอียด';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
              ),
              items: placeCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'กรุณาเลือกหมวดหมู่';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              leading: const Icon(
                Icons.calendar_month,
                color: primaryColor,
              ),
              title: Text(
                selectedDate == null
                    ? 'เลือกวันที่ไปเที่ยว'
                    : 'วันที่ไปเที่ยว: '
                        '${selectedDate!.toIso8601String().split('T').first}',
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: isSaving ? null : pickDate,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: selectedRating,
              decoration: const InputDecoration(
                labelText: 'คะแนน (1-5)',
                border: OutlineInputBorder(),
              ),
              items: List.generate(5, (index) {
                final rating = index + 1;

                return DropdownMenuItem<int>(
                  value: rating,
                  child: Text('$rating ดาว'),
                );
              }),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedRating = value;
                });
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL รูปภาพ หรือพาธรูปเดิม',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (_selectedImagePath != null) {
                  return null;
                }

                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอก URL หรือเลือกรูปภาพ';
                }

                final imageValue = value.trim();
                final uri = Uri.tryParse(imageValue);

                if (uri != null &&
                    uri.hasScheme &&
                    (uri.scheme == 'http' ||
                        uri.scheme == 'https')) {
                  return null;
                }

                if (File(imageValue).existsSync()) {
                  return null;
                }

                return 'กรุณากรอก URL ที่ถูกต้อง หรือเลือกรูปภาพใหม่';
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('เลือกจาก Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ถ่ายรูป'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _selectedImagePath != null
                  ? Image.file(
                      File(_selectedImagePath!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 200,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    )
                  : PlaceImage(
                      url: widget.place.imageUrl,
                      height: 200,
                      borderRadius: BorderRadius.circular(8),
                    ),
            ),

            if (_selectedImagePath != null)
              TextButton.icon(
                onPressed: isSaving
                    ? null
                    : () {
                        setState(() {
                          _selectedImagePath = null;
                        });
                      },
                icon: const Icon(Icons.delete_outline),
                label: const Text('ยกเลิกรูปที่เลือก'),
              ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: isSaving ? null : updatePlace,
              icon: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                isSaving ? 'กำลังบันทึก...' : 'บันทึกการแก้ไข',
              ),
            ),
          ],
        ),
      ),
    );
  }
}