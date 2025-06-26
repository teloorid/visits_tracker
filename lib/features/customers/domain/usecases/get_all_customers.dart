import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

class GetAllCustomers implements UseCase<List<Customer>, NoParams> {
  final CustomerRepository repository;

  GetAllCustomers(this.repository);

  @override
  Future<Either<Failure, List<Customer>>> call(NoParams params) async {
    return await repository.getAllCustomers();
  }
}