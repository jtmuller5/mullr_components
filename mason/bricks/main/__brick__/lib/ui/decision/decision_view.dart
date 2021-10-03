import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'decision_view_model.dart';

class DecisionView extends StatelessWidget {
  const DecisionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DecisionViewModel>.reactive(
      viewModelBuilder: () => DecisionViewModel(),
      onModelReady: (model) {
        // model.initialize();
      },
      builder: (context, model, child) {
        return Scaffold(
            body: Column(
              children: [
                Container()
              ],
            )
        );
      },
    );
  }
}