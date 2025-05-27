import 'package:driving_license_exam/component/appbar.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/study_course.dart';
import 'package:flutter/material.dart';

import 'models/study_models.dart';
import 'services/api_service.dart';
import 'component/api_error_handler.dart';
import 'services/study_service.dart';

class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  List<Category> categories = [];
  bool isLoading = true;
  String? errorMessage;

  // Map category names to icons and colors
  final Map<String, Map<String, dynamic>> categoryConfig = {
    'alertness': {
      'icon': Icons.visibility,
      'borderColor': Colors.orange,
    },
    'attitud': {
      'icon': Icons.emoji_emotions,
      'borderColor': Colors.indigo,
    },
    'attitude': {
      'icon': Icons.emoji_emotions,
      'borderColor': Colors.indigo,
    },
    'hazard_awareness': {
      'icon': Icons.warning_amber,
      'borderColor': Colors.red,
    },
    'safety_procedures': {
      'icon': Icons.shield,
      'borderColor': Colors.green,
    },
    'equipment_operations': {
      'icon': Icons.construction,
      'borderColor': Colors.amber,
    },
    'emergency_response': {
      'icon': Icons.health_and_safety,
      'borderColor': Colors.deepOrange,
    },
  };

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await StudyService.getAllCategories();

      if (response.success && response.data != null) {
        setState(() {
          categories = response.data!;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to load categories';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading categories: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Get icon for category
  IconData _getCategoryIcon(String categoryName) {
    return categoryConfig[categoryName.toLowerCase()]?['icon'] ?? Icons.book;
  }

  // Get border color for category
  Color _getCategoryBorderColor(String categoryName) {
    return categoryConfig[categoryName.toLowerCase()]?['borderColor'] ??
        Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Column(
        children: [
          // Header
          appbar(
              size: size,
              bgcolor: const Color(0xff28A164),
              textColor: Colors.white,
              heading: 'STUDY  MATERIALS'),

          // Search and Featured Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Explore categories to enhance your knowledge"),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search study materials...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Featured Banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Image.asset('assets/images/studymaterial.png',
                          width: double.infinity, fit: BoxFit.cover),
                      Container(
                        padding: const EdgeInsets.all(8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent
                            ],
                            begin: Alignment.center,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: const Color(0xff219EBC),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              child: const Text(
                                'Featured ',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            const Text(
                              'Complete Safety Training',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Categories",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (errorMessage != null)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _fetchCategories,
                        iconSize: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Category Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCategoryGrid(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (categories.isEmpty) {
      return const Center(
        child: Text(
          'No categories available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return GridView.builder(
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                createFadeRoute(StudyCourseScreen(
                  size: MediaQuery.of(context).size,
                  categoryTitle: category.displayName,
                  categoryId: category.id, // Pass category ID if needed
                )));
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                  color: _getCategoryBorderColor(category.name), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_getCategoryIcon(category.name), size: 28),
                const SizedBox(height: 8),
                Text(
                  category.displayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
                // Note: API doesn't provide lesson count, so we'll show a placeholder
                // You can fetch lesson count separately if needed
                const Text("View lessons",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
