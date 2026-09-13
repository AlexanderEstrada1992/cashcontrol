class AppApiException implements Exception {
  const AppApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends AppApiException {
  const NetworkFailure() : super('No hay conexión con el servidor. Verifique su conexión a Internet.');
}

class AuthenticationFailure extends AppApiException {
  const AuthenticationFailure() : super('Su sesión ha expirado. Inicie sesión nuevamente.');
}

class ValidationFailure extends AppApiException {
  const ValidationFailure(this.fieldErrors) : super('Revise los datos ingresados.');
  final Map<String, String> fieldErrors;
}

class ServerFailure extends AppApiException {
  const ServerFailure() : super('Ocurrió un error en el servidor. Intente nuevamente.');
}

class HttpFailure extends AppApiException {
  const HttpFailure(super.message);
}
