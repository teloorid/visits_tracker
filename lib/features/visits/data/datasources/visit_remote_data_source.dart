import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Import compute function
import '../../../../core/errors/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/visit_model.dart';
import '../utils/visit_parser_utils.dart'; // Import our new utility file

abstract class VisitRemoteDataSource {
  Future<List<VisitModel>> getAllVisits();
  Future<VisitModel> addVisit(VisitModel visit);
}

class VisitRemoteDataSourceImpl implements VisitRemoteDataSource {
  final Dio client;

  VisitRemoteDataSourceImpl({required this.client});

  @override
  Future<List<VisitModel>> getAllVisits() async {
    try {
      final response = await client.get(ApiConstants.visitsEndpoint);
      if (response.statusCode == 200) {
        final List<dynamic> visitsJson = response.data as List<dynamic>;
        // Offload parsing of the list to an Isolate
        return compute(parseVisitsList, visitsJson);
      } else {
        throw ServerException(message: 'Failed to load visits. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown) {
        throw NetworkException(message: 'No internet connection or server unreachable.');
      } else if (e.response != null) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Server error: ${e.response?.statusCode}',
        );
      } else {
        throw ServerException(message: 'An unexpected error occurred: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'An unknown error occurred: $e');
    }
  }

  @override
  Future<VisitModel> addVisit(VisitModel visit) async {
    try {
      final response = await client.post(
        ApiConstants.visitsEndpoint,
        data: visit.toNewVisitJson(),
        queryParameters: {'select': '*'},
      );
      if (response.statusCode == 201) {
        if (response.data is List && response.data.isNotEmpty) {
          // Offload parsing of the single item to an Isolate
          return compute(parseSingleVisit, response.data[0] as Map<String, dynamic>);
        }
        throw ServerException(message: 'Failed to parse new visit response.');
      } else {
        throw ServerException(message: 'Failed to add visit. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown) {
        throw NetworkException(message: 'No internet connection or server unreachable.');
      } else if (e.response != null) {
        throw ServerException(
          message: e.response?.data['message'] ?? 'Server error: ${e.response?.statusCode}',
        );
      } else {
        throw ServerException(message: 'An unexpected error occurred: ${e.message}');
      }
    } catch (e) {
      throw ServerException(message: 'An unknown error occurred: $e');
    }
  }
}