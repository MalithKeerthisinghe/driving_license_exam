import 'package:driving_license_exam/component/appbar.dart';
import 'package:driving_license_exam/component/custompageroute.dart';
import 'package:driving_license_exam/payment.dart';
import 'package:driving_license_exam/services/api_service.dart';
import 'package:driving_license_exam/services/http_service.dart';
import 'package:flutter/material.dart';

import 'models/subscription_models.dart';
import 'services/subscription_service.dart';
import 'component/api_error_handler.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int selectedVehicleIndex = 0;
  int selectedPlanIndex = -1;
  bool isLoading = true;
  bool isVehicleLoading = false;
  bool isUserPlanLoading = true; // Loading state for user subscription
  String? errorMessage;

  List<UserSubscription>? userSubscriptions;
  UserSubscription? currentActivePlan; // The current active subscription
  List<SubscriptionPlan> currentPlans = [];

  final List<Map<String, dynamic>> vehicleTypes = [
    {"name": "Car", "icon": Icons.directions_car, "api_name": "car"},
    {"name": "Bike", "icon": Icons.motorcycle, "api_name": "bike"},
    {
      "name": "Light",
      "icon": Icons.local_shipping,
      "api_name": "light_vehicle"
    },
    {"name": "Heavy", "icon": Icons.fire_truck, "api_name": "heavy_vehicle"},
    {
      "name": "Special",
      "icon": Icons.miscellaneous_services,
      "api_name": "special"
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // Initialize both user subscriptions and subscription plans
  Future<void> _initializeData() async {
    await Future.wait([
      _fetchUserSubscriptions(),
      _fetchSubscriptionPlans(),
    ]);
  }

  Future<void> _fetchUserSubscriptions() async {
    try {
      setState(() {
        isUserPlanLoading = true;
      });

      final userId = await StorageService.getID();
      print("Fetching user subscriptions for userId: $userId");

      if (userId == null) {
        print("User ID is null, cannot fetch subscriptions");
        setState(() {
          isUserPlanLoading = false;
        });
        return;
      }

      final response = await SubscriptionService.getUserSubscriptions(
        userId: userId,
        status: 'active', // Only get active subscriptions
      );

      print("User subscriptions response: ${response.data}");

      if (response.success && response.data != null) {
        setState(() {
          userSubscriptions = response.data;
          // Get the most recent active subscription or the one with the latest end date
          currentActivePlan = _getCurrentActivePlan(response.data!);
          isUserPlanLoading = false;
        });

        print("Current active plan: ${currentActivePlan?.plan.name}");
      } else {
        print("Failed to fetch user subscriptions: ${response.message}");
        setState(() {
          isUserPlanLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user subscriptions: $e");
      setState(() {
        isUserPlanLoading = false;
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

  Future<void> _fetchSubscriptionPlans() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final selectedVehicleApiName =
          vehicleTypes[selectedVehicleIndex]["api_name"];

      print("Fetching plans for vehicle type: $selectedVehicleApiName");

      final response = await SubscriptionService.getSubscriptionPlans(
          vehicleType: selectedVehicleApiName);

      print("Subscription Plans Response: ${response.data}");

      if (response.success && response.data != null) {
        setState(() {
          currentPlans = response.data!;
          selectedPlanIndex = -1;
          isLoading = false;
          isVehicleLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.message.isNotEmpty
              ? response.message
              : 'Failed to load subscription plans';
          isLoading = false;
          isVehicleLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching subscription plans: $e");
      setState(() {
        errorMessage = 'Error loading plans: ${e.toString()}';
        isLoading = false;
        isVehicleLoading = false;
      });
    }
  }

  Future<void> _onVehicleTypeChanged(int newIndex) async {
    if (newIndex == selectedVehicleIndex) return;

    setState(() {
      selectedVehicleIndex = newIndex;
      isVehicleLoading = true;
      selectedPlanIndex = -1;
    });

    await _fetchSubscriptionPlans();
  }

  // Helper method to calculate progress for current plan
  double _calculateProgress() {
    if (currentActivePlan == null) return 0.0;

    // Calculate total days from start date to end date for accuracy
    final totalDays = currentActivePlan!.endDate
        .difference(currentActivePlan!.startDate)
        .inDays;
    final daysRemaining = currentActivePlan!.daysRemaining;

    // Ensure we have valid data
    if (totalDays <= 0) return 0.0;

    // Calculate days used (elapsed)
    final daysUsed = totalDays - daysRemaining;

    // Calculate progress (0.0 to 1.0)
    final progress = daysUsed / totalDays;

    // Clamp between 0 and 1 to avoid invalid values
    return progress.clamp(0.0, 1.0);
  }

  // Helper method to get progress color based on remaining time
  Color _getProgressColor() {
    if (currentActivePlan == null) return Colors.grey;

    final daysRemaining = currentActivePlan!.daysRemaining;

    if (daysRemaining <= 0) {
      return Colors.red; // Expired
    } else if (daysRemaining <= 7) {
      return Colors.orange; // Expiring soon (7 days or less)
    } else if (daysRemaining <= 14) {
      return Colors.yellow.shade700; // Warning (14 days or less)
    } else {
      return Colors.cyan; // Healthy
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            appbar(
                size: size,
                bgcolor: const Color(0xffD7ECFE),
                textColor: Colors.black,
                heading: "SUBSCRIPTION"),

            // Current Plan Section - Now Dynamic
            _buildCurrentPlanSection(),
            const SizedBox(height: 20),

            // Vehicle Type Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select Vehicle Type",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  if (isVehicleLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(vehicleTypes.length, (index) {
                    final isSelected = selectedVehicleIndex == index;
                    return GestureDetector(
                      onTap: isVehicleLoading
                          ? null
                          : () => _onVehicleTypeChanged(index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 40),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xffBDE0FE)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(vehicleTypes[index]["icon"],
                                size: 28,
                                color: isSelected
                                    ? const Color(0xff219EBC)
                                    : Colors.blue),
                            const SizedBox(height: 4),
                            Text(
                              vehicleTypes[index]["name"],
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.black : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Subscription Plans
            _buildPlansSection(size),
          ],
        ),
      ),
    );
  }

  // New method to build current plan section dynamically
  Widget _buildCurrentPlanSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 17),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Current Plan",
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
              _buildCurrentPlanChip(),
            ],
          ),
          const SizedBox(height: 4),
          _buildCurrentPlanTitle(),
          const SizedBox(height: 12),
          _buildCurrentPlanProgress(),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanChip() {
    if (isUserPlanLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (currentActivePlan == null) {
      return Chip(
        label:
            const Text("No active plan", style: TextStyle(color: Colors.grey)),
        backgroundColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      );
    }

    final daysRemaining = currentActivePlan!.daysRemaining;
    Color chipTextColor;

    if (daysRemaining <= 0) {
      chipTextColor = Colors.red;
    } else if (daysRemaining <= 7) {
      chipTextColor = Colors.orange;
    } else if (daysRemaining <= 14) {
      chipTextColor = Colors.yellow.shade700;
    } else {
      chipTextColor = const Color(0xff219EBC);
    }

    return Chip(
      label: Text(currentActivePlan!.formattedTimeRemaining,
          style: TextStyle(color: chipTextColor, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: chipTextColor.withOpacity(0.3), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  Widget _buildCurrentPlanTitle() {
    if (isUserPlanLoading) {
      return Container(
        height: 20,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    if (currentActivePlan == null) {
      return const Text(
        "No Active Subscription",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );
    }

    return Text(
      "${currentActivePlan!.plan.name} - ${currentActivePlan!.plan.formattedPrice}",
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCurrentPlanProgress() {
    if (isUserPlanLoading) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    if (currentActivePlan == null) {
      return LinearProgressIndicator(
        value: 0.0,
        minHeight: 6,
        backgroundColor: Colors.grey.shade300,
        color: Colors.grey,
        borderRadius: BorderRadius.circular(12),
      );
    }

    final progress = _calculateProgress();
    final progressColor = _getProgressColor();

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: Colors.grey.shade300,
          color: progressColor,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(height: 4),
        // Add progress text for clarity
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Started: ${_formatDate(currentActivePlan!.startDate)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
            Text(
              'Expires: ${_formatDate(currentActivePlan!.endDate)}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to format dates
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPlansSection(Size size) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSubscriptionPlans,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (currentPlans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'No subscription plans available for ${vehicleTypes[selectedVehicleIndex]["name"]}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: List.generate(currentPlans.length, (index) {
        final plan = currentPlans[index];
        final isSelected = selectedPlanIndex == index;

        // Check if user already has this plan
        final hasCurrentPlan =
            currentActivePlan != null && currentActivePlan!.plan.id == plan.id;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: Card(
            color: isSelected
                ? const Color.fromARGB(255, 247, 251, 253)
                : Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Color(0xff219EBC),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(plan.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      if (plan.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Popular',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (hasCurrentPlan)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Current',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(plan.formattedPrice,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color.fromARGB(255, 0, 0, 0))),
                  if (plan.description != null && plan.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        plan.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (plan.displayFeatures.isNotEmpty)
                    ...plan.displayFeatures.map<Widget>((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(feature)),
                            ],
                          ),
                        ))
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(child: Text('Access to all features')),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                      height: size.height * 0.05,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: hasCurrentPlan
                              ? Colors.grey.shade400
                              : isSelected
                                  ? const Color(0xff219EBC)
                                  : const Color(0xffD7ECFE),
                        ),
                        onPressed: hasCurrentPlan
                            ? null
                            : () {
                                setState(() {
                                  selectedPlanIndex = index;
                                });
                                if (isSelected) {
                                  Navigator.push(
                                    context,
                                    createFadeRoute(PaymentScreen(
                                      selectedPlan: plan,
                                    )),
                                  );
                                }
                              },
                        child: Text(
                            hasCurrentPlan
                                ? "Current Plan"
                                : isSelected
                                    ? "Continue to Payment"
                                    : "Select Plan",
                            style: TextStyle(
                              color: hasCurrentPlan
                                  ? Colors.white
                                  : isSelected
                                      ? Colors.white
                                      : const Color(0xff219EBC),
                            )),
                      ))
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
