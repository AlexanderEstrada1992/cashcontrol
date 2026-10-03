sealed class OperationState<T> {
  const OperationState();
}

final class IdleState<T> extends OperationState<T> {
  const IdleState();
}

final class LoadingState<T> extends OperationState<T> {
  const LoadingState();
}

final class DataState<T> extends OperationState<T> {
  const DataState(this.data);
  final T data;
}

final class ErrorState<T> extends OperationState<T> {
  const ErrorState(this.message);
  final String message;
}
