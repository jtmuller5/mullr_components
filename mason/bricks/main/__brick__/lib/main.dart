import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_portal/flutter_portal.dart';
import '../app/app_router.gr.dart';
import '../models/notification_payload.dart';
import '../services/navigation_service.dart';
import '../services/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mullr_components/features/navigating/basic_navigator_observer.dart';
import 'package:stacked/stacked.dart';
import '../app/app_router.dart';
import '../app/get_it.dart';
import '../app/themes/light_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  configureDependencies();
  setupHive();
  await Hive.initFlutter();
  // await Hive.openBox<Vote>('votes');
  //if (!kIsWeb) await MobileAds.instance.initialize();
  //setPathUrlStrategy();
  runApp(App());
}

void setupHive() {
  /*if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(VoteAdapter());
  }*/
}

class App extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // systemOverlaysAreVisible = true when application is not full screen
    /*SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      print('Fullscreen: ' + systemOverlaysAreVisible.toString());
      appService.setFullScreen(systemOverlaysAreVisible);
    });*/

    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemStatusBarContrastEnforced: false),
      child: ViewModelBuilder<AppModel>.reactive(
        viewModelBuilder: () => AppModel(),
        onModelReady: (model) {
          // model.initialize();
        },
        builder: (context, model, child) {
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, nativeNavigator) {
                return GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  child: Portal(
                      child: MaterialApp.router(
                        debugShowCheckedModeBanner: false,
                        themeMode: ThemeMode.system,
                        theme: lightTheme,
                        routerDelegate: appRouter.delegate(
                          navigatorObservers: () {
                            return [
                              if (kDebugMode) BasicNavigatorObserver(),
                              CommentNavigatorObserver(),
                            ];
                          },
                        ),
                        routeInformationParser: appRouter.defaultRouteParser(),
                      )),
                );
              },
            );
        },
      ),
    );
  }
}

class AppModel extends BaseViewModel {}