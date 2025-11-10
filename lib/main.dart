import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/bloc/recipes/recipes_barrel.dart';
import 'package:inventory_manager/bloc/consumption_quota/consumption_quota_barrel.dart';
import 'package:inventory_manager/repositories/recipe_repository.dart';
import 'package:inventory_manager/repositories/settings_repository.dart';
import 'package:inventory_manager/services/app_initialization.dart';
import 'package:inventory_manager/services/notification_service.dart';
import 'package:inventory_manager/themes/nixie_theme.dart';
import 'package:inventory_manager/views/home_view.dart';
import 'package:inventory_manager/views/recipes_view.dart';
import 'package:inventory_manager/views/consumption_quota_view.dart';
import 'package:inventory_manager/views/upkeep_view.dart';
import 'package:inventory_manager/views/settings_view.dart';

// Global key for navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final mainNavigationKey = GlobalKey<_MainNavigationScreenState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitialization.initialize();

  // Set up notification tap handler
  NotificationService.onNotificationTap = () {
    // Navigate to quota view (index 1)
    mainNavigationKey.currentState?.navigateToTab(1);
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => RecipeRepository(),
        ),
        RepositoryProvider(
          create: (context) => SettingsRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => InventoryBloc()..add(const LoadInventory()),
          ),
          BlocProvider(
            create: (context) => SettingsBloc(
              repository: context.read<SettingsRepository>(),
            )..add(const LoadSettings()),
          ),
          BlocProvider(
            create: (context) => RecipesBloc(
              repository: context.read<RecipeRepository>(),
            )..add(const LoadFavorites()),
          ),
          BlocProvider(
            create: (context) => ConsumptionQuotaBloc()
              ..add(const LoadConsumptionQuotas()),
          ),
        ],
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            // Default to regular dark theme
            ThemeData currentTheme = NixieTubeTheme.darkTheme;

            // Update theme based on high contrast setting if settings are loaded
            if (state is SettingsLoaded) {
              currentTheme = state.settings.highContrast
                  ? NixieTubeTheme.highContrastDarkTheme
                  : NixieTubeTheme.darkTheme;
            }

            return MaterialApp(
              title: 'Lazy Prepper',
              theme: currentTheme,
              themeMode: ThemeMode.dark,
              navigatorKey: navigatorKey,
              home: MainNavigationScreen(key: mainNavigationKey),
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeView(),
    ConsumptionQuotaView(),
    UpkeepView(),
    RecipesView(),
    SettingsView(),
  ];

  /// Navigate to a specific tab by index
  /// Used by notification tap handler to navigate to quota view
  void navigateToTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.warehouse),
      selectedIcon: Icon(Icons.warehouse),
      label: 'Inventory',
    ),
    NavigationDestination(
      icon: Icon(Icons.track_changes_outlined),
      selectedIcon: Icon(Icons.track_changes),
      label: 'Quota',
    ),
    NavigationDestination(
      icon: Icon(Icons.shopping_cart_outlined),
      selectedIcon: Icon(Icons.shopping_cart),
      label: 'Refill',
    ),
    NavigationDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: 'Recipes',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _destinations,
      ),
    );
  }
}
