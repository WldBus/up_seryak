import '../models/page_result.dart';

/// Состояние экрана списка. Запечатанный класс: switch по нему компилятор
/// проверяет на полноту, а страница данных доступна только в ListLoaded.
sealed class ListState<T> {
  const ListState();
}

class ListLoading<T> extends ListState<T> {
  const ListLoading();
}

class ListLoaded<T> extends ListState<T> {
  final PageResult<T> page;

  const ListLoaded(this.page);
}

class ListFailed<T> extends ListState<T> {
  final String message;

  const ListFailed(this.message);
}
