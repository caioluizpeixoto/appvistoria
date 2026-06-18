import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

class LocalFailure extends Failure {
  const LocalFailure({required super.message, super.code});
}

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Sem conexão com a internet.'});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.code});
}

class PdfFailure extends Failure {
  const PdfFailure({required super.message});
}
