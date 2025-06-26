import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([this.properties = const <dynamic>[]]);

  final List<dynamic> properties;

  @override
  List<Object?> get props => properties;
}

// General failures
class ServerFailure extends Failure {
  final String message;
  ServerFailure({this.message = 'An unexpected server error occurred.'}) : super([message]);
}

class CacheFailure extends Failure {
  final String message;
  CacheFailure({this.message = 'No data found in cache.'}) : super([message]);
}

class NetworkFailure extends Failure {
  final String message;
  NetworkFailure({this.message = 'Please check your internet connection.'}) : super([message]);
}

// Specific API failures
class NotFoundFailure extends ServerFailure {
  NotFoundFailure({String message = 'Resource not found.'}) : super(message: message);
}

class UnauthorizedFailure extends ServerFailure {
  UnauthorizedFailure({String message = 'Unauthorized access.'}) : super(message: message);
}

class InvalidInputFailure extends ServerFailure {
  InvalidInputFailure({String message = 'Invalid input provided.'}) : super(message: message);
}