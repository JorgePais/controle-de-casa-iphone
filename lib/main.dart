import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:remote/blocs/connectivity/connectivity_bloc.dart';
import 'package:remote/blocs/device_discovery/device_discovery_bloc.dart';
import 'package:remote/blocs/tv_connection/tv_connection_bloc.dart';
import 'package:remote/core/repositories/tv_repository.dart';
import 'package:remote/core/services/app_diagnostics.dart';
import 'package:remote/di/service_locator.dart';
import 'package:remote/l10n/app_localizations.dart';
import 'package:remote/ui/screens/device_selection/device_selection_screen.dart';
import 'package:remote/ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final previousErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    unawaited(AppDiagnostics.record('error', details.toString()));
    previousErrorHandler?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(AppDiagnostics.record('error', '$error\n$stack'));
    return false;
  };
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await configureDependencies();

  runApp(const RemoteApp());
}

class RemoteApp extends StatelessWidget {
  const RemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = sl<TvRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ConnectivityCubit()),
        BlocProvider(create: (_) => TvConnectionBloc(repository: repository)),
        BlocProvider(
          create: (_) =>
              DeviceDiscoveryBloc(repository: repository)
                ..add(const DiscoveryStarted()),
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeviceSelectionScreen(),
      ),
    );
  }
}
