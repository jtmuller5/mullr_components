import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

class ColorService {
  ///The colorPickerDialog is an asynchronous bool function,
  ///that returns true if the user closed the dialog picker with the Select button.
  ///If Cancel was selected or user dismissed the dialog by clicking outside of it, false is returned
  Future<bool> showColorPickerDialog(BuildContext context,
      Color startingColor,
      Function(Color) onColorChanged,) async {
    return ColorPicker(
      color: startingColor,
      onColorChanged: onColorChanged,
      width: 40,
      height: 40,
      borderRadius: 8,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      /*heading: Text(
        'Select color',
        style: Theme.of(context).textTheme.subtitle1,
      ),*/
      subheading: Text(
        'Select color shade',
        style: Theme
            .of(context)
            .textTheme
            .subtitle1,
      ),
      wheelSubheading: Text(
        'Selected color and its shades',
        style: Theme
            .of(context)
            .textTheme
            .subtitle1,
      ),
      showMaterialName: false,
      showColorName: false,
      showColorCode: false,
      materialNameTextStyle: Theme
          .of(context)
          .textTheme
          .caption,
      colorNameTextStyle: Theme
          .of(context)
          .textTheme
          .caption,
      colorCodeTextStyle: Theme
          .of(context)
          .textTheme
          .caption,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
    ).showPickerDialog(
      context,
      constraints: const BoxConstraints(minHeight: 460, minWidth: 300, maxWidth: 320),
    );
  }

  /// Get the color from a gradient at a specific position
  /// Position should be between 0 and 1
  Color? colorAlongGradient({
    required List<Color> colors,
    List<double>? stops,
    required double position,
  }) {
    stops ??= List.generate(colors.length, (index) => index * (1 / (colors.length-1)));

    for (var s = 0; s < stops.length - 1; s++) {
      final leftStop = stops[s],
          rightStop = stops[s + 1];
      final leftColor = colors[s],
          rightColor = colors[s + 1];
      if (position <= leftStop) {
        return leftColor;
      } else if (position < rightStop) {
        final sectionT = (position - leftStop) / (rightStop - leftStop);
        return Color.lerp(leftColor, rightColor, sectionT);
      }
    }
    return colors.last;
  }
}

/// Get the color from a gradient at a specific position
/// Position should be between 0 and 1
extension ColorGetter on Gradient {
  Color? colorAtPosition({
    required double position,
  }) {

    List<double> _stops = stops ?? List.generate(colors.length, (index) => index * (1 / (colors.length-1)));

    for (var stop = 0; stop < _stops.length - 1; stop++) {
      final leftStop = _stops[stop],
          rightStop = _stops[stop + 1];
      final leftColor = colors[stop],
          rightColor = colors[stop + 1];
      if (position <= leftStop) {
        return leftColor;
      } else if (position < rightStop) {
        final sectionT = (position - leftStop) / (rightStop - leftStop);
        return Color.lerp(leftColor, rightColor, sectionT);
      }
    }
    return colors.last;
  }
}
