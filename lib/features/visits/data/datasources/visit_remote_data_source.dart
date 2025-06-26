import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/visit_model.dart';

abstract class VisitRemoteDataSource {
  Future<List<VisitModel>> getAllVisits();
  Future<VisitModel> addVisit(VisitModel visit);
// Add other methods like updateVisit, deleteVisit if needed
}

class VisitRemoteDataSourceImpl implements VisitRemoteDataSource {
  final Dio client;

  VisitRemoteDataSourceImpl({required this.client});

  @override
  Future<List<VisitModel>> getAllVisits() async {
    try {
      final response = await client.get(ApiConstants.visitsEndpoint);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => VisitModel.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Failed to load visits: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(message: 'No internet connection.');
      }
      throw ServerException(message: e.response?.data['message'] ?? 'An unknown error occurred.');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<VisitModel> addVisit(VisitModel visit) async {
    try {
      final response = await client.post(
        ApiConstants.visitsEndpoint,
        data: visit.toNewVisitJson(), // Use toNewVisitJson for POST
        queryParameters: {'select': '*'}, // Supabase returns inserted row with 'select'
      );
      if (response.statusCode == 201) { // 201 Created
        // Supabase often returns a list of one item for insert
        if (response.data is List && response.data.isNotEmpty) {
          return VisitModel.fromJson(response.data[0]);
        }
        throw ServerException(message: 'Failed to parse new visit response.');
      } else {
        throw ServerException(message: 'Failed to add visit: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(message: 'No internet connection.');
      }
      throw ServerException(message: e.response?.data['message'] ?? 'An unknown error occurred.');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}