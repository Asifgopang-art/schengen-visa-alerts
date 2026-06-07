import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.setup();
  runApp(const VisaAlertsApp());
}

class AppTheme {
  static const darkNavy = Color(0xFF071527);
  static const midNavy = Color(0xFF0E233D);
  static const cardNavy = Color(0xFF102B4C);
  static const gold = Color(0xFFCBA135);
  static const goldLight = Color(0xFFE8C766);
  static const text = Color(0xFFEAF1FF);
  static const muted = Color(0xFF91A5C5);
  static const danger = Color(0xFFE85A5A);
  static const success = Color(0xFF29C17E);
}

class VisaAlertsApp extends StatelessWidget {
  const VisaAlertsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schengen Visa Alerts UK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.darkNavy,
        colorScheme: const ColorScheme.dark(primary: AppTheme.gold, secondary: AppTheme.goldLight),
        appBarTheme: const AppBarTheme(backgroundColor: AppTheme.darkNavy, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.gold,
            foregroundColor: AppTheme.darkNavy,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.midNavy,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.gold),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class NotificationService {
  static Future<void> setup() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await localNotifications.initialize(settings);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    const channel = AndroidNotificationChannel(
      'visa_alerts',
      'Visa Alerts',
      description: 'Schengen visa appointment notifications',
      importance: Importance.max,
    );
    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;
      await localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Visa Alert',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'visa_alerts',
            'Visa Alerts',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SplashScreen();
        if (snapshot.data == null) return const LoginScreen();
        return const MainShell();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff, color: AppTheme.gold, size: 74),
            SizedBox(height: 18),
            Text('Schengen Visa Alerts UK', style: TextStyle(fontSize: 22, color: AppTheme.gold, fontWeight: FontWeight.w900)),
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppTheme.gold),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email.text.trim(), password: password.text.trim());
      await saveFcmToken();
    } catch (e) {
      showMsg(context, e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    if (email.text.trim().isEmpty) {
      showMsg(context, 'Enter your email first.');
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text.trim());
    showMsg(context, 'Password reset email sent.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 45),
            const Icon(Icons.flight_takeoff, color: AppTheme.gold, size: 72),
            const SizedBox(height: 18),
            const Text('Schengen Visa Alerts UK', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: AppTheme.gold)),
            const SizedBox(height: 8),
            const Text('Real-time visa appointment alerts', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted)),
            const SizedBox(height: 35),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 14),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: loading ? null : login, child: Text(loading ? 'Please wait...' : 'Login')),
            TextButton(onPressed: resetPassword, child: const Text('Forgot password?')),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    setState(() => loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email.text.trim(), password: password.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name.text.trim(),
        'email': email.text.trim(),
        'subscriptionStatus': 'inactive',
        'selectedCountry': 'All',
        'selectedCentre': 'All',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await saveFcmToken();
    } catch (e) {
      showMsg(context, e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Create Your Visa Alerts Account', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppTheme.gold)),
          const SizedBox(height: 25),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 14),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 14),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 22),
          ElevatedButton(onPressed: loading ? null : register, child: Text(loading ? 'Creating...' : 'Register')),
        ],
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final pages = const [AlertsPage(), CountriesPage(), SubscriptionPage(), ProfilePage()];

  @override
  void initState() {
    super.initState();
    saveFcmToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        selectedItemColor: AppTheme.gold,
        unselectedItemColor: AppTheme.muted,
        backgroundColor: AppTheme.midNavy,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Countries'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Subscribe'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('alerts').orderBy('createdAt', descending: true).limit(100);
    return Scaffold(
      appBar: AppBar(title: const Text('Live Visa Alerts')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const EmptyView(icon: Icons.notifications_none, title: 'No alerts yet', subtitle: 'New visa slot alerts will appear here instantly.');
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) => AlertCard(data: docs[i].data()),
          );
        },
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const AlertCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['alert_type'] ?? data['type'] ?? 'New Alert';
    final country = data['country'] ?? '';
    final centre = data['centre'] ?? data['center'] ?? '';
    final category = data['category'] ?? '';
    final earliest = data['earliest'] ?? data['date'] ?? '';
    final link = data['booking_link'] ?? data['link'] ?? '';
    final timestamp = data['createdAt'];
    String timeText = '';
    if (timestamp is Timestamp) timeText = DateFormat('dd MMM yyyy, HH:mm').format(timestamp.toDate());

    return Card(
      color: AppTheme.cardNavy,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.gold),
            const SizedBox(width: 8),
            Expanded(child: Text(title.toString().replaceAll('_', ' '), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
          ]),
          const Divider(height: 22),
          if (country.toString().isNotEmpty) info('Country', country),
          if (centre.toString().isNotEmpty) info('Centre', centre),
          if (category.toString().isNotEmpty) info('Category', category),
          if (earliest.toString().isNotEmpty) info('Earliest', earliest),
          if (timeText.isNotEmpty) info('Time', timeText),
          const SizedBox(height: 12),
          if (link.toString().isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(link.toString()), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Book Now'),
            ),
        ]),
      ),
    );
  }

  Widget info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 82, child: Text(label, style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w700))),
        Expanded(child: Text(value.toString(), style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class CountriesPage extends StatefulWidget {
  const CountriesPage({super.key});

  @override
  State<CountriesPage> createState() => _CountriesPageState();
}

class _CountriesPageState extends State<CountriesPage> {
  final countries = ['All', 'Netherlands', 'Malta', 'Norway', 'Sweden', 'Bulgaria', 'Germany', 'France', 'Spain', 'Italy'];
  final centres = ['All', 'London', 'Manchester', 'Edinburgh', 'Birmingham', 'Cardiff'];
  String selectedCountry = 'All';
  String selectedCentre = 'All';

  Future<void> save() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'selectedCountry': selectedCountry,
      'selectedCentre': selectedCentre,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    showMsg(context, 'Preferences saved.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alert Preferences')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Select country and centre', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.gold)),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          value: selectedCountry,
          decoration: const InputDecoration(labelText: 'Country'),
          items: countries.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => selectedCountry = v ?? 'All'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: selectedCentre,
          decoration: const InputDecoration(labelText: 'Centre'),
          items: centres.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => selectedCentre = v ?? 'All'),
        ),
        const SizedBox(height: 22),
        ElevatedButton(onPressed: save, child: const Text('Save Preferences')),
      ]),
    );
  }
}

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  // Replace these with your real Stripe Payment Links.
  static const oneCountryLink = 'https://buy.stripe.com/00wbJ1cAm3fk3gI6YYfnO06';
  static const allCountriesLink = 'https://buy.stripe.com/00wbJ1cAm3fk3gI6YYfnO06';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Choose your plan', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppTheme.gold)),
        const SizedBox(height: 14),
        planCard('£5/month', 'One selected country alerts', oneCountryLink),
        planCard('£10/month', 'All Schengen country alerts', allCountriesLink),
        const SizedBox(height: 16),
        const Text('After payment, your account should be marked active by your backend/Stripe webhook.', style: TextStyle(color: AppTheme.muted)),
      ]),
    );
  }

  Widget planCard(String title, String desc, String link) {
    return Card(
      color: AppTheme.cardNavy,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 22, color: AppTheme.gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: AppTheme.text)),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication), child: const Text('Subscribe Now')),
        ]),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Icon(Icons.person, color: AppTheme.gold, size: 72),
        const SizedBox(height: 12),
        Text(user.email ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? {};
            return Card(
              color: AppTheme.cardNavy,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  profileRow('Subscription', data['subscriptionStatus'] ?? 'inactive'),
                  profileRow('Country', data['selectedCountry'] ?? 'All'),
                  profileRow('Centre', data['selectedCentre'] ?? 'All'),
                ]),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
          onPressed: () => FirebaseAuth.instance.signOut(),
          child: const Text('Logout'),
        ),
      ]),
    );
  }

  Widget profileRow(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: AppTheme.muted)),
          Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyView({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppTheme.gold, size: 58),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted)),
        ]),
      ),
    );
  }
}

Future<void> saveFcmToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final token = await FirebaseMessaging.instance.getToken();
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'uid': user.uid,
    'email': user.email,
    'fcmToken': token,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

void showMsg(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
