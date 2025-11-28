import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:DHB/screens/nearby_facilities_screen.dart';
import 'package:DHB/screens/monitor_analytics_screen.dart';
import 'package:DHB/screens/health_qr_screen.dart';
import 'package:DHB/screens/medications_screen.dart';
import 'package:DHB/screens/appointments_screen.dart';

const supabaseUrl = 'https://lnybxilouatjribioujv.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxueWJ4aWxvdWF0anJpYmlvdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyMDU4MTksImV4cCI6MjA2NDc4MTgxOX0.86A7FEkUHsmphPS8LyHoOr3ZtkGlaGw1sQJrOoWI1LQ';

class UserMedication {
  final String id;
  final String name;
  final String dosage;
  final String dosageForm;
  final String time;
  final String frequency;

  UserMedication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.dosageForm,
    required this.time,
    required this.frequency,
  });

  factory UserMedication.fromMap(Map<String, dynamic> map) {
    return UserMedication(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      dosageForm: map['dosage_form'] ?? '',
      time: map['times'] is List && map['times'].isNotEmpty
          ? map['times'][0]
          : 'No time set',
      frequency: map['frequency'] ?? '',
    );
  }
}

class UserAppointment {
  final String id;
  final String doctorName;
  final String specialization;
  final DateTime date;
  final String time;
  final String location;
  final String type;
  final String badge;

  UserAppointment({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.date,
    required this.time,
    required this.location,
    required this.type,
    required this.badge,
  });

  factory UserAppointment.fromMap(Map<String, dynamic> map) {
    return UserAppointment(
      id: map['id'] ?? '',
      doctorName: map['doctor_name'] ?? '',
      specialization: map['specialization'] ?? '',
      date: DateTime.parse(map['date']),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      type: map['type'] ?? '',
      badge: map['badge'] ?? '',
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  String userName = "User";
  int medicationCount = 0;
  int appointmentCount = 0;
  bool isLoading = true;
  bool isLoadingMedications = false;
  bool isLoadingAppointments = false;
  List<UserMedication> userMedications = [];
  List<UserAppointment> userAppointments = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUserMedications();
    _fetchUserAppointments();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => isLoading = true);
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        final profile = await supabase
            .from('profiles')
            .select('username')
            .eq('id', userId)
            .single();

        setState(() => userName = profile['username'] ?? 'User');

        final apps = await supabase
            .from('appointments')
            .select('*')
            .eq('user_id', userId);

        setState(() => appointmentCount = apps.length);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserMedications() async {
    try {
      setState(() => isLoadingMedications = true);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('medications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        userMedications =
            response.map<UserMedication>((med) => UserMedication.fromMap(med)).toList();
        medicationCount = userMedications.length;
      });
    } catch (e) {
      debugPrint('Error fetching medications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load medications: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoadingMedications = false);
    }
  }

  Future<void> _fetchUserAppointments() async {
    try {
      setState(() => isLoadingAppointments = true);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: true)
          .limit(2);

      setState(() {
        userAppointments = response
            .map<UserAppointment>((appt) => UserAppointment.fromMap(appt))
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching appointments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointments: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoadingAppointments = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fb),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hello, $userName!",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    "Stay on top of your health journey. Every step counts!",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text("Quick Actions",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Medications Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Your Medications",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => _navigateToMedicationsScreen(context),
                        child: Text('View All ($medicationCount)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  isLoadingMedications
                      ? const Center(child: CircularProgressIndicator())
                      : userMedications.isEmpty
                          ? _buildEmptyState('No medications added', Icons.medication)
                          : Column(
                              children: userMedications.take(2).map((med) => _buildMedicationCard(
                                    name: med.name,
                                    dosage: '${med.dosage} ${med.dosageForm}',
                                    time: '${med.time} (${med.frequency})',
                                  )).toList(),
                            ),
                  const SizedBox(height: 24),

                  // Appointments Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Your Appointments",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => _navigateToAppointmentsScreen(context),
                        child: Text('View All ($appointmentCount)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  isLoadingAppointments
                      ? const Center(child: CircularProgressIndicator())
                      : userAppointments.isEmpty
                          ? _buildEmptyState('No appointments scheduled', Icons.calendar_today)
                          : Column(
                              children: userAppointments
                                  .map((appt) => _buildAppointmentCard(appt: appt))
                                  .toList(),
                            ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 3.2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildQuickActionItem(
          icon: Icons.analytics,
          label: "Health Analytics",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MonitorAnalyticsScreen()),
          ),
        ),
        _buildQuickActionItem(
          icon: Icons.location_on,
          label: "Nearby Facilities",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NearbyFacilitiesScreen()),
          ),
        ),
        _buildQuickActionItem(
          icon: Icons.qr_code,
          label: "Health QR",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HealthQrScreen(qrData: '')),
          ),
        ),
        _buildQuickActionItem(
          icon: Icons.add,
          label: "Add New",
          onTap: () => _showAddOptions(context),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Text(message, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMedicationCard({
    required String name,
    required String dosage,
    required String time,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medication, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dosage,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time.split(' ')[0], // Just show the time part
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  time.split(' ').length > 1 ? time.split(' ')[1] : '', // Frequency
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard({required UserAppointment appt}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.orange),
        title: Text(appt.doctorName.isEmpty ? "Doctor" : appt.doctorName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "${appt.specialization.isNotEmpty ? appt.specialization + " | " : ""}"
          "${DateFormat('MMM dd, yyyy').format(appt.date)} at ${appt.time}\n"
          "${appt.location}",
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            appt.badge,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToMedicationsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MedicationScreen()),
    ).then((_) {
      _fetchUserMedications();
      _loadUserData();
    });
  }

  void _navigateToAppointmentsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppointementsScreen()),
    ).then((_) {
      _loadUserData();
      _fetchUserAppointments();
    });
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.medication),
            title: const Text('Add Medication'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MedicationScreen()),
              ).then((_) {
                _fetchUserMedications();
                _loadUserData();
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Add Appointment'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppointementsScreen()),
              ).then((_) {
                _loadUserData();
                _fetchUserAppointments();
              });
            },
          ),
        ],
      ),
    );
  }
}