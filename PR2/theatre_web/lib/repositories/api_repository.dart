import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/entity.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import 'entity_repository.dart';

/// Общий код репозиториев поверх REST API. Интерфейсы репозиториев
/// с ПР2 не поменялись — поменялась только реализация. В наследниках
/// остаются адрес ресурса и то, как условия отбора превращаются
/// в параметры запроса.
abstract class ApiRepository<T extends Entity, Q>
    implements EntityRepository<T, Q> {
  final Dio dio;

  /// адрес ресурса, например '/shows'
  final String path;
  final T Function(Map<String, dynamic> json) fromJson;

  /// токен последнего запроса списка: новый запрос отменяет старый
  CancelToken? _findToken;

  ApiRepository(this.dio, {required this.path, required this.fromJson});

  /// условия отбора → параметры строки запроса
  Map<String, dynamic> queryOf(Q query);

  /// тело для POST и PUT. id в адресе, а deletedAt ставит сервер
  Map<String, dynamic> bodyOf(T item) => item.toJson()
    ..remove('id')
    ..remove('deletedAt');

  @override
  Future<PageResult<T>> find(Q query) {
    // пока печатают в поиске, старый запрос ещё может идти. отменяю его,
    // чтобы его ответ не пришёл позже нового и не показал не тот список
    _findToken?.cancel('устарел');
    final token = _findToken = CancelToken();
    return guard(() async {
      final response = await dio.get(
        path,
        queryParameters: queryOf(query),
        cancelToken: token,
      );
      return _page(response.data);
    });
  }

  /// все записи без страниц, вместе с удалёнными — для справочников.
  /// сервер отдаёт не больше 100 за раз, поэтому иду по страницам
  @override
  Future<List<T>> findAll() => guard(() async {
    final all = <T>[];
    var page = 1;
    while (true) {
      final response = await dio.get(
        path,
        queryParameters: {'page': page, 'size': 100, 'includeDeleted': true},
      );
      final result = _page(response.data);
      all.addAll(result.items);
      if (!result.hasNext) return all;
      page++;
    }
  });

  @override
  Future<T?> findById(int id) => guard(() async {
    try {
      // удалённую запись тоже показываю, в карточке будет пометка
      final response = await dio.get(
        '$path/$id',
        queryParameters: {'includeDeleted': true},
      );
      return fromJson(_map(response.data));
    } on DioException catch (e) {
      if (e.error is NotFoundException) return null;
      rethrow;
    }
  });

  @override
  Future<T> create(T item) => guard(() async {
    final response = await dio.post(path, data: bodyOf(item));
    return fromJson(_map(response.data));
  });

  @override
  Future<T> update(T item) => guard(() async {
    final response = await dio.put('$path/${item.id}', data: bodyOf(item));
    return fromJson(_map(response.data));
  });

  @override
  Future<void> softDelete(int id) => guard(() => dio.delete('$path/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => dio.delete('$path/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) => guard(() => dio.post('$path/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await dio.post('$path/bulk-delete', data: {'ids': ids});
    final deleted = _map(response.data)['deleted'];
    return deleted is int ? deleted : 0;
  });

  PageResult<T> _page(dynamic data) {
    final json = _map(data);
    final items = json['items'];
    return PageResult(
      items: [
        if (items is List)
          for (final e in items.whereType<Map<String, dynamic>>()) fromJson(e),
      ],
      page: json['page'] is int ? json['page'] as int : 1,
      size: json['size'] is int ? json['size'] as int : 10,
      total: json['total'] is int ? json['total'] as int : 0,
    );
  }

  Map<String, dynamic> _map(dynamic data) =>
      data is Map<String, dynamic> ? data : const {};
}

/// общие параметры списка: поиск, сортировка, страница, удалённые
Map<String, dynamic> listParams({
  required String search,
  required String sortField,
  required bool sortAscending,
  required int page,
  required int size,
  required bool includeDeleted,
}) => {
  if (search.trim().isNotEmpty) 'search': search.trim(),
  'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
  'page': page,
  'size': size,
  if (includeDeleted) 'includeDeleted': true,
};

/// параметры для простых списков (театры, актёры, жанры, зрители)
Map<String, dynamic> listQueryParams(ListQuery q) => listParams(
  search: q.search,
  sortField: q.sortField,
  sortAscending: q.sortAscending,
  page: q.page,
  size: q.size,
  includeDeleted: q.includeDeleted,
);
