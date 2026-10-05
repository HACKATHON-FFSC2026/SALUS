import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salus/features/admin/domain/models/admin_portal_record.dart';
import 'package:salus/features/admin/presentation/widgets/assigned_road_reports_map.dart';

class _FakeTileProvider extends TileProvider {
  static final _transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPng);
}

AdminPortalRecord _report({
  required String id,
  required String targetType,
  double? latitude,
  double? longitude,
}) => AdminPortalRecord(
  id: id,
  targetType: targetType,
  targetLocationLatitude: latitude,
  targetLocationLongitude: longitude,
);

void main() {
  testWidgets('shows assigned road reports and opens a tapped report', (
    tester,
  ) async {
    final reports = [
      _report(
        id: 'road-1',
        targetType: 'road',
        latitude: -18.88,
        longitude: 47.51,
      ),
      _report(
        id: 'road-2',
        targetType: 'road',
        latitude: -18.89,
        longitude: 47.52,
      ),
      _report(id: 'shelter-report', targetType: 'shelter'),
    ];
    AdminPortalRecord? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssignedRoadReportsMap(
            reports: reports,
            onTapReport: (report) => selected = report,
            tileProvider: _FakeTileProvider(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Incidents routiers affectés · 2'), findsOneWidget);
    expect(find.byIcon(Icons.report_problem), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.report_problem).first);
    expect(selected, reports.first);
  });

  testWidgets('hides map when there are no geolocated road reports', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssignedRoadReportsMap(
            reports: [_report(id: 'shelter-report', targetType: 'shelter')],
            onTapReport: (_) {},
            tileProvider: _FakeTileProvider(),
          ),
        ),
      ),
    );

    expect(find.byType(FlutterMap), findsNothing);
  });
}
