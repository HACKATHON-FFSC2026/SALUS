// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [ActiveSosListPage]
class ActiveSosListRoute extends PageRouteInfo<void> {
  const ActiveSosListRoute({List<PageRouteInfo>? children})
    : super(ActiveSosListRoute.name, initialChildren: children);

  static const String name = 'ActiveSosListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ActiveSosListPage();
    },
  );
}

/// generated route for
/// [ArViewPage]
class ArViewRoute extends PageRouteInfo<void> {
  const ArViewRoute({List<PageRouteInfo>? children})
    : super(ArViewRoute.name, initialChildren: children);

  static const String name = 'ArViewRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ArViewPage();
    },
  );
}

/// generated route for
/// [CreateShelterPage]
class CreateShelterRoute extends PageRouteInfo<void> {
  const CreateShelterRoute({List<PageRouteInfo>? children})
    : super(CreateShelterRoute.name, initialChildren: children);

  static const String name = 'CreateShelterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateShelterPage();
    },
  );
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginPage();
    },
  );
}

/// generated route for
/// [MainPage]
class MainRoute extends PageRouteInfo<void> {
  const MainRoute({List<PageRouteInfo>? children})
    : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainPage();
    },
  );
}

/// generated route for
/// [OperationsPortalPage]
class OperationsPortalRoute extends PageRouteInfo<void> {
  const OperationsPortalRoute({List<PageRouteInfo>? children})
    : super(OperationsPortalRoute.name, initialChildren: children);

  static const String name = 'OperationsPortalRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const OperationsPortalPage();
    },
  );
}

/// generated route for
/// [ShelterLocationPickerPage]
class ShelterLocationPickerRoute
    extends PageRouteInfo<ShelterLocationPickerRouteArgs> {
  ShelterLocationPickerRoute({
    Key? key,
    GeoPoint? initialLocation,
    String? initialAddress,
    List<PageRouteInfo>? children,
  }) : super(
         ShelterLocationPickerRoute.name,
         args: ShelterLocationPickerRouteArgs(
           key: key,
           initialLocation: initialLocation,
           initialAddress: initialAddress,
         ),
         initialChildren: children,
       );

  static const String name = 'ShelterLocationPickerRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ShelterLocationPickerRouteArgs>(
        orElse: () => const ShelterLocationPickerRouteArgs(),
      );
      return ShelterLocationPickerPage(
        key: args.key,
        initialLocation: args.initialLocation,
        initialAddress: args.initialAddress,
      );
    },
  );
}

class ShelterLocationPickerRouteArgs {
  const ShelterLocationPickerRouteArgs({
    this.key,
    this.initialLocation,
    this.initialAddress,
  });

  final Key? key;

  final GeoPoint? initialLocation;

  final String? initialAddress;

  @override
  String toString() {
    return 'ShelterLocationPickerRouteArgs{key: $key, initialLocation: $initialLocation, initialAddress: $initialAddress}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShelterLocationPickerRouteArgs) return false;
    return key == other.key &&
        initialLocation == other.initialLocation &&
        initialAddress == other.initialAddress;
  }

  @override
  int get hashCode =>
      key.hashCode ^ initialLocation.hashCode ^ initialAddress.hashCode;
}

/// generated route for
/// [SosPage]
class SosRoute extends PageRouteInfo<void> {
  const SosRoute({List<PageRouteInfo>? children})
    : super(SosRoute.name, initialChildren: children);

  static const String name = 'SosRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SosPage();
    },
  );
}

/// generated route for
/// [SosResponseDetailPage]
class SosResponseDetailRoute extends PageRouteInfo<SosResponseDetailRouteArgs> {
  SosResponseDetailRoute({
    Key? key,
    required SOSAlert sosAlert,
    List<PageRouteInfo>? children,
  }) : super(
         SosResponseDetailRoute.name,
         args: SosResponseDetailRouteArgs(key: key, sosAlert: sosAlert),
         initialChildren: children,
       );

  static const String name = 'SosResponseDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SosResponseDetailRouteArgs>();
      return SosResponseDetailPage(key: args.key, sosAlert: args.sosAlert);
    },
  );
}

class SosResponseDetailRouteArgs {
  const SosResponseDetailRouteArgs({this.key, required this.sosAlert});

  final Key? key;

  final SOSAlert sosAlert;

  @override
  String toString() {
    return 'SosResponseDetailRouteArgs{key: $key, sosAlert: $sosAlert}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SosResponseDetailRouteArgs) return false;
    return key == other.key && sosAlert == other.sosAlert;
  }

  @override
  int get hashCode => key.hashCode ^ sosAlert.hashCode;
}

/// generated route for
/// [SplashPage]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashPage();
    },
  );
}
