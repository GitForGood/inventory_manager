import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/inventory/inventory_barrel.dart';
import 'package:inventory_manager/bloc/settings/settings_barrel.dart';
import 'package:inventory_manager/bloc/recipes/recipes_barrel.dart';
import 'package:inventory_manager/bloc/quota/quota_barrel.dart';
import 'package:inventory_manager/repositories/recipe_repository.dart';
import 'package:inventory_manager/repositories/settings_repository.dart';
import 'package:inventory_manager/repositories/quota_repository.dart';
import 'package:inventory_manager/services/app_initialization.dart';
import 'package:inventory_manager/themes/nixie_theme.dart';
import 'package:inventory_manager/views/home_view.dart';
import 'package:inventory_manager/views/recipes_view.dart';
import 'package:inventory_manager/views/quota_view.dart';
import 'package:inventory_manager/views/settings_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitialization.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => InventoryBloc()..add(const LoadInventory()),
        ),
        BlocProvider(
          create: (context) =>
              SettingsBloc(repository: SettingsRepository())
                ..add(const LoadSettings()),
        ),
        BlocProvider(
          create: (context) =>
              RecipesBloc(repository: RecipeRepository())
                ..add(const LoadFavorites()),
        ),
        BlocProvider(
          create: (context) =>
              QuotaBloc(repository: QuotaRepository())
                ..add(const LoadQuotaSchedules()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          // Default to dark mode
          ThemeMode themeMode = ThemeMode.dark;

          // Update theme mode if settings are loaded
          if (state is SettingsLoaded) {
            themeMode = state.settings.themeMode;
          }

          return MaterialApp(
            title: 'Inventory Manager',
            theme: NixieTubeTheme.darkTheme,
            highContrastTheme: NixieTubeTheme.highContrastDarkTheme,
            themeMode: themeMode,
            home: const MainNavigationScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
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
    RecipesView(),
    QuotaView(),
    SettingsView(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Inventory',
    ),
    NavigationDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: 'Recipes',
    ),
    NavigationDestination(
      icon: Icon(Icons.track_changes_outlined),
      selectedIcon: Icon(Icons.track_changes),
      label: 'Quota',
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
