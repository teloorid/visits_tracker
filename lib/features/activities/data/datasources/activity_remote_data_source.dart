import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/activity_model.dart';

abstract class ActivityRemoteDataSource {
  Future<List<ActivityModel>> getAllActivities();
}

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  final Dio client;

  ActivityRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ActivityModel>> getAllActivities() async {
    try {
      final response = await client.get(ApiConstants.activitiesEndpoint);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => ActivityModel.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Failed to load activities: ${response.statusCode}');
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