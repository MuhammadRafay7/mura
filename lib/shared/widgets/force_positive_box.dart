import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A low-level layout shield that sanitizes constraints.
/// Essential for complex animations and extreme browser resizing
/// on Flutter Web.
class ForcePositiveBox extends SingleChildRenderObjectWidget {
  const ForcePositiveBox({super.key, super.child});

  @override
  RenderForcePositiveBox createRenderObject(BuildContext context) =>
      RenderForcePositiveBox();
}

class RenderForcePositiveBox extends RenderProxyBox {
  BoxConstraints _getSafeConstraints(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: math.max(0.0, constraints.minWidth),
      minHeight: math.max(0.0, constraints.minHeight),
      maxWidth: math.max(0.0, constraints.maxWidth),
      maxHeight: math.max(0.0, constraints.maxHeight),
    );
  }

  @override
  void performLayout() {
    if (child != null) {
      // Force constraints into the non-negative domain
      final BoxConstraints safeConstraints = _getSafeConstraints(constraints);
      child!.layout(safeConstraints, parentUsesSize: true);
      size = child!.size;
    } else {
      size = computeSizeForNoChild(_getSafeConstraints(constraints));
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      super.computeMinIntrinsicWidth(math.max(0.0, height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      super.computeMaxIntrinsicWidth(math.max(0.0, height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(math.max(0.0, width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(math.max(0.0, width));

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Ensure hit testing remains accurate even if parent size is technically 0
    return child?.hitTest(result, position: position) ?? false;
  }
}
