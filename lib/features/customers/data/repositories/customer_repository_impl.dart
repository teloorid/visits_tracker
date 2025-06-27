// File: lib/features/customers/data/repositories/customer_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CustomerRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Customer>>> getAllCustomers() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteCustomers = await remoteDataSource.getAllCustomers();
        return Right(remoteCustomers);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: 'An unexpected error occurred while fetching customers: $e'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}