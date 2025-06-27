class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'An unexpected server error occurred.'});

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  CacheException({this.message = 'No data found in cache.'});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException({this.message = 'Please check your internet connection.'});

  @override
  String toString() => 'NetworkException: $message';
}

class DataParsingException implements Exception {
  final String message;
  DataParsingException({required this.message});
}