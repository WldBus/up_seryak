/// Ошибки при сохранении в виде «поле → текст». Сделал как ответ сервера 422
/// из приложения Б, чтобы форма показывала их под полями и в ПР4 её
/// не переделывать.
class ValidationException implements Exception {
  final Map<String, String> errors;

  const ValidationException(this.errors);

  @override
  String toString() => errors.values.join('; ');
}

/// Нельзя удалить запись, потому что на неё кто-то ссылается.
class DeleteBlockedException implements Exception {
  final String message;

  const DeleteBlockedException(this.message);

  @override
  String toString() => message;
}
