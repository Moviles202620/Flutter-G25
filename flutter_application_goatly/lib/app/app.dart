import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_state.dart';
import 'routes.dart';
import 'theme.dart';

class GoatlyApp extends StatelessWidget {
  const GoatlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: Routes.login,
        routes: Routes.map,
      ),
    );
  }
}
