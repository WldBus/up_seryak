import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_web/core/api_client.dart';
import 'package:theatre_web/core/api_exceptions.dart';
import 'package:theatre_web/models/show.dart';
import 'package:theatre_web/models/show_query.dart';
import 'package:theatre_web/repositories/api_show_repository.dart';

// Тесты репозитория без настоящего сервера: вместо сети подставляю свой
// адаптер, который запоминает запросы и отдаёт заранее заготовленный ответ.

class FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];

  FakeAdapter(this.respond);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json; charset=utf-8'],
  },
);

/// сервер выключен: так Dio сообщает о том, что соединиться не удалось
Future<ResponseBody> serverDown(RequestOptions o) => Future.error(
  DioException(requestOptions: o, type: DioExceptionType.connectionError),
);

/// спектакль в том виде, в каком его отдаёт сервер (развёрнутые связи)
const showJson = {
  'id': 1,
  'title': 'Лебединое озеро',
  'code': 'SP-1001',
  'date': '2026-11-02T19:00:00',
  'duration': 165,
  'price': 6500,
  'theatre': {'id': 1, 'name': 'Большой театр'},
  'genres': [
    {'id': 4, 'name': 'Балет'},
  ],
  'actors': [
    {'id': 1, 'fullName': 'Орлова Анна'},
    {'id': 2, 'fullName': 'Соколов Игорь'},
  ],
  'seatsTotal': 400,
  'seatsAvailable': 12,
  'createdAt': '2026-10-22T08:00:00.000Z',
  'deletedAt': null,
};

final newShow = Show(
  id: 0,
  title: 'Чайка',
  code: 'SP-1100',
  date: DateTime(2026, 12, 1, 19),
  duration: 190,
  price: 3500,
  theatreId: 3,
  genreIds: const [1],
  actorIds: const [5, 6],
  seatsTotal: 250,
  seatsAvailable: 250,
);

void main() {
  late FakeAdapter adapter;
  late ApiShowRepository repo;

  void serve(Future<ResponseBody> Function(RequestOptions o) respond) {
    adapter = FakeAdapter(respond);
    final dio = buildDio(
      baseUrl: 'http://test/api',
      retryDelay: Duration.zero,
      log: false,
    )..httpClientAdapter = adapter;
    repo = ApiShowRepository(dio);
  }

  test('find отправляет фильтры и разбирает страницу с сервера', () async {
    serve(
      (_) async => jsonBody(200, {
        'items': [showJson],
        'page': 2,
        'size': 10,
        'total': 11,
        'totalPages': 2,
      }),
    );

    final page = await repo.find(
      const ShowQuery(
        search: ' озеро ',
        genreId: 4,
        sortField: 'price',
        sortAscending: false,
        page: 2,
      ),
    );

    final params = adapter.requests.single.queryParameters;
    expect(adapter.requests.single.path, '/shows');
    expect(params['search'], 'озеро');
    expect(params['genreId'], 4);
    expect(params['sort'], 'price,desc');
    expect(params['page'], 2);
    expect(params.containsKey('theatreId'), isFalse);

    expect(page.total, 11);
    expect(page.hasNext, isFalse);
    final show = page.items.single;
    // из развёрнутых объектов получились id, как в модели
    expect(show.theatreId, 1);
    expect(show.genreIds, [4]);
    expect(show.actorIds, [1, 2]);
    expect(show.date, DateTime(2026, 11, 2, 19));
  });

  test('create отправляет id связей и не отправляет id записи', () async {
    serve((o) async => jsonBody(201, {...showJson, 'id': 25}));

    final created = await repo.create(newShow);

    final request = adapter.requests.single;
    final body = request.data as Map<String, dynamic>;
    expect(request.method, 'POST');
    expect(body['theatreId'], 3);
    expect(body['actorIds'], [5, 6]);
    expect(body.containsKey('id'), isFalse);
    expect(body.containsKey('deletedAt'), isFalse);
    expect(created.id, 25);
  });

  test('ответ 422 превращается в ValidationException с ошибками по полям', () {
    serve(
      (_) async => jsonBody(422, {
        'message': 'Ошибка валидации',
        'errors': {'code': 'Спектакль с кодом SP-1001 уже есть'},
      }),
    );

    expect(
      repo.create(newShow),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.errors['code'],
          'errors[code]',
          'Спектакль с кодом SP-1001 уже есть',
        ),
      ),
    );
  });

  test(
    'сервер недоступен: чтение повторяется 3 раза, потом NetworkException',
    () async {
      serve(serverDown);

      await expectLater(
        repo.find(const ShowQuery()),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('CORS'),
          ),
        ),
      );
      // первая попытка и три повтора
      expect(adapter.requests, hasLength(4));
    },
  );

  test(
    'создание при сбое сети не повторяется — иначе будет вторая запись',
    () async {
      serve(serverDown);

      await expectLater(repo.create(newShow), throwsA(isA<NetworkException>()));
      expect(adapter.requests, hasLength(1));
    },
  );

  test('ответ 409 превращается в ConflictException с текстом сервера', () {
    serve(
      (_) async => jsonBody(409, {
        'message': 'Жанр «Драма» нельзя удалить: он указан у спектаклей (8).',
      }),
    );

    expect(
      repo.softDelete(1),
      throwsA(
        isA<ConflictException>().having(
          (e) => e.message,
          'message',
          contains('спектаклей (8)'),
        ),
      ),
    );
  });

  test('findById при ответе 404 возвращает null', () async {
    serve((_) async => jsonBody(404, {'message': 'Объект не найден'}));

    expect(await repo.findById(99), isNull);
  });

  test('ответ 500 превращается в ServerException с текстом сервера', () {
    serve((_) async => jsonBody(500, {'message': 'Ошибка вызвана намеренно'}));

    expect(
      repo.find(const ShowQuery()),
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          'Ошибка вызвана намеренно',
        ),
      ),
    );
  });

  test('новый поиск отменяет старый запрос', () async {
    final first = Completer<ResponseBody>();
    serve(
      (o) => o.queryParameters['search'] == 'во'
          ? first.future
          : Future.value(
              jsonBody(200, {
                'items': [showJson],
                'page': 1,
                'size': 10,
                'total': 1,
              }),
            ),
    );

    // проверку на старый запрос подключаю сразу, до второго поиска
    final old = expectLater(
      repo.find(const ShowQuery(search: 'во')),
      throwsA(
        isA<NetworkException>().having(
          (e) => e.message,
          'message',
          'Запрос отменён.',
        ),
      ),
    );
    final latest = await repo.find(const ShowQuery(search: 'война'));

    await old;
    expect(latest.items, hasLength(1));
    first.complete(jsonBody(200, {'items': <Object>[]}));
  });
}
