String safeDestination(String? value) {
  final uri = Uri.tryParse(value ?? '');
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      !RegExp(r'^/gastos(?:/(?:nuevo|[A-Za-z0-9_-]+))?$').hasMatch(uri.path)) {
    return '/gastos';
  }
  return uri.toString();
}

String? sessionRedirect({
  required Uri location,
  required bool ready,
  required bool authenticated,
  required bool forbidden,
}) {
  final transit = [
    '/login',
    '/cargando',
    '/sin-permiso',
  ].contains(location.path);
  final target = safeDestination(
    transit ? location.queryParameters['from'] : location.toString(),
  );
  String redirect(String path) =>
      Uri(path: path, queryParameters: {'from': target}).toString();
  if (!ready) {
    return location.path == '/cargando' ? null : redirect('/cargando');
  }
  if (!authenticated) {
    return location.path == '/login' ? null : redirect('/login');
  }
  if (forbidden) {
    return location.path == '/sin-permiso' ? null : redirect('/sin-permiso');
  }
  if (location.path == '/login' || location.path == '/cargando') return target;
  return null;
}
