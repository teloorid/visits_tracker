import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getAllCustomers();
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final Dio client;

  CustomerRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CustomerModel>> getAllCustomers() async {
    try {
      final response = await client.get(ApiConstants.customersEndpoint);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList.map((json) => CustomerModel.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Failed to load customers: ${response.statusCode}');
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