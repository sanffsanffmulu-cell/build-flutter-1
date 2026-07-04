import 'package:flutter/material.dart';
import 'splash.dart';
import 'landing_page.dart';
import 'login_page.dart';
import 'loader_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'buy_account.dart';
import 'lx_menu_page.dart';
import 'debug_connection_page.dart';
import 'touch.dart';
import 'control_panel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return TouchEffect(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'X C U B E',
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'ShareTechMono',
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark().copyWith(
            secondary: Colors.purple,
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const LandingPage());

            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());

            case '/debug':
              return MaterialPageRoute(builder: (_) => const DebugConnectionPage());

            case '/splash':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => SplashPage(
                  username: args['username'],
                  password: args['password'],
                  role: args['role'],
                  sessionKey: args['key'],
                  expiredDate: args['expiredDate'],
                  listBug: args['listBug'] != null 
                      ? List<Map<String, dynamic>>.from(args['listBug']) 
                      : [],
                  listPayload: args['listPayload'] != null 
                      ? List<Map<String, dynamic>>.from(args['listPayload']) 
                      : [],
                  listDDoS: args['listDDoS'] != null 
                      ? List<Map<String, dynamic>>.from(args['listDDoS']) 
                      : [],
                  news: args['news'] != null 
                      ? List<Map<String, dynamic>>.from(args['news']) 
                      : [],
                ),
              );

            case '/loader':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => DashboardPage(
                  username: args['username'],
                  password: args['password'],
                  role: args['role'],
                  sessionKey: args['key'],
                  expiredDate: args['expiredDate'],
                  listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                  listPayload: List<Map<String, dynamic>>.from(args['listPayload'] ?? []),
                  listDDoS: List<Map<String, dynamic>>.from(args['listDDoS'] ?? []),
                  news: List<Map<String, dynamic>>.from(args['news'] ?? []),
                ),
              );

            case '/attack':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => AttackPage(
                  username: args['username'],
                  password: args['password'],
                  listBug: List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                  role: args['role'],
                  expiredDate: args['expiredDate'],
                  sessionKey: args['sessionKey'],
                ),
              );

            case '/seller':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => SellerPage(
                  keyToken: args['keyToken'],
                ),
              );

            case '/admin':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => AdminPage(
                  sessionKey: args['sessionKey'],
                ),
              );

            case '/buy_account':
              return MaterialPageRoute(builder: (_) => const BuyAccountPage());

            case '/lx_menu':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => LxMenuPage(
                  username: args['username'],
                  password: args['password'],
                  role: args['role'],
                  sessionKey: args['sessionKey'],
                  expiredDate: args['expiredDate'],
                  listBug: args['listBug'],
                  listPayload: args['listPayload'],
                ),
              );
              
          case '/control_panel':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ControlCenterPage(),
            );

            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(
                    child: Text(
                      "404 - Not Found",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}