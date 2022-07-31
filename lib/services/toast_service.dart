import 'package:auto_route/auto_route.dart';
import 'package:mullr_components/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';

/// Service for displaying toasts, snackbars, banners, or other
/// temporary info boxes
/// SimpleDialog can get you most of the way there

class ToastService {
  void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        message,
        textAlign: TextAlign.center,
      ),
    ));
  }

  /// TODO https://github.com/ponnamkarthik/FlutterToast/issues/302
  Future<void> showToast(String message,
      {Color color = Colors.blueAccent}) async {
    await Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: color,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Future<bool> askConfirmation({
    required BuildContext context,
    required String title,
    required String subtitle,
    String yes = 'Continue',
    String no = 'Cancel',
  }) async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(title),
              content: Text(subtitle),
              actions: [
                TextButton(
                  child: Text(no),
                  onPressed: () {
                    AutoRouter.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text(
                    yes,
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () {
                    AutoRouter.of(context).pop(true);
                  },
                )
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> confirmLeave(
    BuildContext context, {
    String title = 'Exit the app?',
    String yes = 'Exit',
    String no = 'Stay',
  }) async {
    bool leave = false;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text(title)),
          actions: [
            TextButton(
              child: Text(no),
              onPressed: () async {
                leave = false;
                await GetIt.instance.get<NavigationServiceInterface>().back();
              },
            ),
            TextButton(
              child: Text(
                yes,
                //style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                leave = true;
                await GetIt.instance.get<NavigationServiceInterface>().back();
              },
            )
          ],
        );
      },
    );
    return leave;
  }

  /// Simple function to close the keyboard. Used before showing a snackbar
  void closeKeyboard(BuildContext context) {
    FocusScope.of(context)
        .requestFocus(FocusNode()); // Unfocus text fields on page change
  }

  bool isKeyBoardOpen(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom == 0;
  }

  void unfocusAll(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}
