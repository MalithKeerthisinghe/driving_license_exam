import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/exammain.dart';
import 'package:driving_license_exam/premium.dart';
import 'package:driving_license_exam/previous_result_study.dart';
import 'package:driving_license_exam/profile.dart';
import 'package:driving_license_exam/studymaterial.dart';
import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'services/subscription_service.dart';
import 'models/subscription_models.dart';

// Create placeholder screens for each tab (you should replace these with your actual screens)

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  Animation<double>? _fadeAnimation;

  // List of screens to display for each tab
  final List<Widget> _screens = [
    const HomeContent(), // This will be your original home content
    const StudyMaterialsScreen(),
    const MockExamScreen(),
    const SubscriptionScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Animation duration
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
        setState(() {}); // Trigger rebuild when animation value changes
      });
    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      // Reset and replay animation on tab change
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff219EBC),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Study"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Exam"),
          BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium), label: "Premium"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation!,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ), // Display the current screen
    );
  }
}

// Extract your original home content into a separate widget
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? username;
  UserSubscription? currentActivePlan;
  bool isSubscriptionLoading = true;
  bool hasSubscriptionError = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      getUserData(),
      _fetchUserSubscription(),
    ]);
  }

  Future<void> getUserData() async {
    try {
      print('=== Getting User Data ===');

      // Get user ID
      final userId = await StorageService.getID();
      print('User ID: ${userId ?? 'No ID found'}');

      // Get user object
      final user = await StorageService.getUser();
      if (user != null) {
        print('User Name: ${user.name}');
        print('User Email: ${user.email}');
        print('User DOB: ${user.dateOfBirth}');
        print('Full User Object: $user');
        setState(() {
          username = user.name;
        });
      } else {
        print('No user data found in storage');
      }

      // Check authentication status
      final token = await StorageService.getToken();
      final isLoggedIn = await StorageService.isLoggedIn();
      print('Has Token: ${token != null}');
      print('Is Logged In: $isLoggedIn');

      print('========================');
    } catch (e) {
      print('Error getting user data: $e');
    }
  }

  Future<void> _fetchUserSubscription() async {
    try {
      setState(() {
        isSubscriptionLoading = true;
        hasSubscriptionError = false;
      });

      final userId = await StorageService.getID();
      print("Fetching user subscription for userId: $userId");

      if (userId == null) {
        print("User ID is null, cannot fetch subscription");
        setState(() {
          isSubscriptionLoading = false;
          hasSubscriptionError = true;
        });
        return;
      }

      final response = await SubscriptionService.getUserSubscriptions(
        userId: userId,
        status: 'active',
      );

      print("User subscription response: ${response.data}");

      if (response.success && response.data != null) {
        setState(() {
          currentActivePlan = _getCurrentActivePlan(response.data!);
          isSubscriptionLoading = false;
        });

        print("Current active plan for home: ${currentActivePlan?.plan.name}");
      } else {
        print("Failed to fetch user subscription: ${response.message}");
        setState(() {
          isSubscriptionLoading = false;
          hasSubscriptionError = true;
        });
      }
    } catch (e) {
      print("Error fetching user subscription: $e");
      setState(() {
        isSubscriptionLoading = false;
        hasSubscriptionError = true;
      });
    }
  }

  // Helper method to determine the current active plan
  UserSubscription? _getCurrentActivePlan(
      List<UserSubscription> subscriptions) {
    if (subscriptions.isEmpty) return null;

    // Filter only active and non-expired subscriptions
    final activeSubscriptions = subscriptions
        .where((sub) => sub.status.toLowerCase() == 'active' && !sub.isExpired)
        .toList();

    if (activeSubscriptions.isEmpty) return null;

    // If multiple active subscriptions, return the one with the latest end date
    activeSubscriptions.sort((a, b) => b.endDate.compareTo(a.endDate));
    return activeSubscriptions.first;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Back,",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            Text(
              username ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: size.height * 0.016),
            // Banner image
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/home.png', // Replace with your image asset
                height: size.height * 0.25,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: size.height * 0.016),
            // Dynamic Subscription card
            _buildSubscriptionCard(),
            const SizedBox(height: 20),
            const Text(
              "Your Progress",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Progress card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Text("Overall Completion"),
                      Spacer(),
                      Text("68%"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 0.68,
                    backgroundColor: Colors.grey.shade300,
                    color: const Color(0xFF219EBC),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _progressCard(
                          icon: Icons.menu_book,
                          ontap: () => Navigator.push(
                                context,
                                createFadeRoute(const PreviousResultStudy()),
                              ),
                          label: "Study",
                          percent: "75%",
                          subtext: "complete"),
                      const SizedBox(width: 12),
                      _progressCard(
                          ontap: () => {
                                Navigator.push(
                                  context,
                                  createFadeRoute(const PreviousResultStudy()),
                                )
                              },
                          icon: Icons.check_circle_outline,
                          label: "Tests",
                          percent: "62%",
                          subtext: "passed"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Study Materials Button
            _menuButton(
              "Study Materials",
              Icons.menu_book,
              onTap: () {
                final homeState = context.findAncestorStateOfType<_HomeState>();
                homeState?.setState(() {
                  homeState._currentIndex = 1;
                });
              },
            ),
            const SizedBox(height: 12),
            // Mock Exams Button
            _menuButton(
              "Mock Exams",
              Icons.assignment_turned_in,
              onTap: () {
                final homeState = context.findAncestorStateOfType<_HomeState>();
                homeState?.setState(() {
                  homeState._currentIndex = 2;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // New method to build dynamic subscription card
  Widget _buildSubscriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubscriptionHeader(),
          const SizedBox(height: 12),
          _buildSubscriptionContent(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionHeader() {
    if (isSubscriptionLoading) {
      return Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text("Loading Subscription..."),
          const Spacer(),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      );
    }

    if (hasSubscriptionError || currentActivePlan == null) {
      return Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text("No Active Subscription"),
          const Spacer(),
          GestureDetector(
            onTap: () {
              final homeState = context.findAncestorStateOfType<_HomeState>();
              homeState?.setState(() {
                homeState._currentIndex = 3; // Go to subscription tab
              });
            },
            child: const Text("Get Premium",
                style: TextStyle(
                    color: Color(0xFF219EBC), fontWeight: FontWeight.w600)),
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _getSubscriptionStatusColor(),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text("Active Subscription"),
        const Spacer(),
        Text(currentActivePlan!.plan.name,
            style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSubscriptionContent() {
    if (isSubscriptionLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        height: 60,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Colors.grey,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (hasSubscriptionError || currentActivePlan == null) {
      return GestureDetector(
        onTap: () {
          final homeState = context.findAncestorStateOfType<_HomeState>();
          homeState?.setState(() {
            homeState._currentIndex = 3; // Go to subscription tab
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          height: 60,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Color(0xFFFFE4E1), // Light red gradient
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: const Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text("Get premium access to unlock",
                        style: TextStyle(color: Colors.grey)),
                  ),
                  SizedBox(height: 0.4),
                  Text(
                    "all features",
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF219EBC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Icon(Icons.star, color: Colors.orange),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      height: 60,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            _getSubscriptionGradientColor(),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text("Subscription expires in",
                    style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 0.4),
              Text(
                currentActivePlan!.formattedTimeRemaining,
                style: TextStyle(
                  fontSize: 15,
                  color: _getTimeRemainingColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(_getSubscriptionIcon(), color: _getTimeRemainingColor()),
        ],
      ),
    );
  }

  Color _getSubscriptionStatusColor() {
    if (currentActivePlan == null) return Colors.red;

    final daysRemaining = currentActivePlan!.daysRemaining;

    if (daysRemaining <= 0) {
      return Colors.red; // Expired
    } else if (daysRemaining <= 7) {
      return Colors.orange; // Expiring soon
    } else {
      return Colors.green; // Active
    }
  }

  Color _getSubscriptionGradientColor() {
    if (currentActivePlan == null) return const Color(0xFFFFE4E1);

    final daysRemaining = currentActivePlan!.daysRemaining;

    if (daysRemaining <= 0) {
      return const Color(0xFFFFE4E1); // Light red
    } else if (daysRemaining <= 7) {
      return const Color(0xFFFFF0E6); // Light orange
    } else {
      return const Color(0xFFBDE0FE); // Light blue (original)
    }
  }

  Color _getTimeRemainingColor() {
    if (currentActivePlan == null) return const Color(0xFF219EBC);

    final daysRemaining = currentActivePlan!.daysRemaining;

    if (daysRemaining <= 0) {
      return Colors.red; // Expired
    } else if (daysRemaining <= 7) {
      return Colors.orange; // Expiring soon
    } else {
      return const Color(0xFF219EBC); // Healthy
    }
  }

  IconData _getSubscriptionIcon() {
    if (currentActivePlan == null) return Icons.star;

    final daysRemaining = currentActivePlan!.daysRemaining;

    if (daysRemaining <= 0) {
      return Icons.error; // Expired
    } else if (daysRemaining <= 7) {
      return Icons.warning; // Expiring soon
    } else {
      return Icons.alarm_on_rounded; // Healthy
    }
  }

  Widget _progressCard(
      {required IconData icon,
      required String label,
      required VoidCallback ontap,
      required String percent,
      required String subtext}) {
    return Expanded(
      child: InkWell(
        onTap: ontap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xff219EBC), size: 28),
                    const SizedBox(width: 12),
                    Text(label, style: const TextStyle(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(percent,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(subtext,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String title, IconData icon,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF219EBC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
