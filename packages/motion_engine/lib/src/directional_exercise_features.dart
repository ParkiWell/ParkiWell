part of 'exercise_specs.dart';

enum _MovementPlane { frontal, sagittal }

final class _PlanarAngleFeature extends FeatureDefinition {
  const _PlanarAngleFeature(
    this.first,
    this.vertex,
    this.last, {
    required this.axisLandmark,
    required this.plane,
    this.invert = false,
  });

  final String first;
  final String vertex;
  final String last;
  final String axisLandmark;
  final _MovementPlane plane;
  final bool invert;
}

double _planarAngle(List<PoseLandmark>? points, _PlanarAngleFeature feature) {
  final Vector3? vertex = _resolvePoint(feature.vertex, points, null);
  final Vector3? first = _resolvePoint(feature.first, points, vertex);
  final Vector3? last = _resolvePoint(feature.last, points, vertex);
  final Vector3? bodyAxis = _horizontalAxis(points, feature.axisLandmark);
  if (vertex == null || first == null || last == null || bodyAxis == null) {
    return double.nan;
  }
  final double width =
      math.sqrt(bodyAxis.x * bodyAxis.x + bodyAxis.z * bodyAxis.z);
  if (!width.isFinite || width < 1e-5) return double.nan;

  // The body-relative plane follows the person's orientation around the
  // vertical axis. Fore-aft reach must stay near zero on a side-raise trace,
  // even when the person's torso is angled relative to the lens.
  final Vector3 unit = bodyAxis / width;
  Vector3 project(Vector3 ray) {
    final double horizontal = feature.plane == _MovementPlane.frontal
        ? ray.x * unit.x + ray.z * unit.z
        : ray.z * unit.x - ray.x * unit.z;
    return Vector3(horizontal, ray.y, 0);
  }

  final double angle = jointAngle(
    project(first - vertex),
    const Vector3(0, 0, 0),
    project(last - vertex),
  );
  return feature.invert ? 180 - angle : angle;
}
