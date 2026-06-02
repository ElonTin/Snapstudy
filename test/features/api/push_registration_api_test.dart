import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/features/notifications/data/services/push_registration_api.dart';
import '../../helpers/dio_test_helper.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  test('registerDevice succeeds on 200', () async {
    final dio = createMockDio(
      response: Response(
        requestOptions: RequestOptions(
          path: '/api/notifications/devices',
          baseUrl: 'http://localhost:5000',
        ),
        statusCode: 200,
      ),
    );

    final api = PushRegistrationApi(dio: dio);
    final result = await api.registerDevice(
      fcmToken: 'token-abc',
      userId: 'user-1',
      authBearer: 'bearer-x',
    );

    expect(result.isSuccess, true);
  });

  test('registerDevice treats 404 as success (backend optional)', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 404,
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final api = PushRegistrationApi(dio: dio);
    final result = await api.registerDevice(fcmToken: 'token');

    expect(result.isSuccess, true);
  });

  test('registerDevice returns failure on server error', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 500,
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    final api = PushRegistrationApi(dio: dio);
    final result = await api.registerDevice(fcmToken: 'token');

    expect(result.isFailure, true);
    expect(result.failureOrNull, isA<Failure>());
  });
}
