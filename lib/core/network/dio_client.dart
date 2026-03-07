import 'package:dio/dio.dart';
import '../constants/endpoint_constants.dart';

const _kDefaultReceiveTimeout = 120000;
const _kDefaultConnectionTimeout = 120000;

class DioClient {
  DioClient({required this.dio}) {
    dio
      ..options.baseUrl = EndpointConstants.baseUrl
      ..options.connectTimeout = const Duration(milliseconds: _kDefaultConnectionTimeout)
      ..options.receiveTimeout = const Duration(milliseconds: _kDefaultReceiveTimeout);
  }

  final Dio dio;

  Dio addInterceptors(Iterable<Interceptor> interceptors) {
    return dio..interceptors.addAll(interceptors);
  }
}
