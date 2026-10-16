import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mysun_app/core/network/json_cache.dart';

void main() {
  test('stores and returns the last response', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = JsonCache(await SharedPreferences.getInstance());
    expect(cache.get('feed'), isNull);
    await cache.put('feed', [
      {'id': 'a1'}
    ]);
    expect(cache.get('feed'), [
      {'id': 'a1'}
    ]);
  });

  test('a cache without storage never throws', () async {
    const cache = JsonCache(null);
    await cache.put('feed', [1]);
    expect(cache.get('feed'), isNull);
  });

  test('only requests without an HTTP answer count as offline', () {
    final req = RequestOptions(path: '/x');
    expect(JsonCache.isOffline(DioException(requestOptions: req)), isTrue);
    expect(
      JsonCache.isOffline(DioException(
          requestOptions: req, response: Response(requestOptions: req, statusCode: 500))),
      isFalse,
    );
  });
}
