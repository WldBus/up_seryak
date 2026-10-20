import '../models/page_result.dart';

/// Состояния экрана списка. Класс sealed, поэтому компилятор проверяет,
/// что в switch разобраны все варианты, а страница есть только в ListLoaded.
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
