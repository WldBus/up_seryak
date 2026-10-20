import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/form_guard.dart';
import '../core/format.dart';
import '../core/validators.dart';
import '../models/entity.dart';
import '../repositories/exceptions.dart';

// ---------------------------------------------------------------------------
// Описание полей. Каждая форма — это просто список таких описаний,
// а рисует, проверяет и отправляет её общий виджет EntityForm.
// ---------------------------------------------------------------------------

sealed class FieldSpec {
  /// ключ поля: по нему берётся значение и ищется ошибка из ValidationException
  final String key;
  final String label;

  const FieldSpec(this.key, this.label);
}

/// Обычное текстовое или числовое поле (TextFormField).
class TextFieldSpec extends FieldSpec {
  final Validator? validator;

  /// проверка, которой нужны другие поля (например, свободных мест
  /// не больше, чем всего)
  final String? Function(FormValues values)? cross;
  final bool numeric;
  final int maxLines;
  final String? hint;
  final List<TextInputFormatter>? formatters;

  const TextFieldSpec(
    super.key,
    super.label, {
    this.validator,
    this.cross,
    this.numeric = false,
    this.maxLines = 1,
    this.hint,
    this.formatters,
  });
}

/// Выбор одного варианта — связь многие к одному (театр у спектакля).
class DropdownFieldSpec extends FieldSpec {
  final List<(int, String)> options;
  final String requiredMessage;

  const DropdownFieldSpec(
    super.key,
    super.label, {
    required this.options,
    required this.requiredMessage,
  });
}

/// Выбор нескольких вариантов — связь многие ко многим (жанры, актёры).
class ChipsFieldSpec extends FieldSpec {
  final List<(int, String)> options;
  final int min;
  final String minMessage;

  /// что написать, если вариантов нет (например, театр ещё не выбрали)
  final String emptyHint;

  const ChipsFieldSpec(
    super.key,
    super.label, {
    required this.options,
    this.min = 0,
    this.minMessage = '',
    this.emptyHint = 'Нет вариантов',
  });
}

/// Дата (и время). Выбирается только в календаре, руками не вводится.
class DateFieldSpec extends FieldSpec {
  final bool withTime;
  final DateTime first;
  final DateTime last;
  final String requiredMessage;

  const DateFieldSpec(
    super.key,
    super.label, {
    required this.first,
    required this.last,
    this.withTime = false,
    this.requiredMessage = 'Выберите дату',
  });
}

/// Заголовок группы полей — для связи один к одному
/// (карта зрителя внутри формы зрителя).
class SectionSpec extends FieldSpec {
  final String? hint;

  const SectionSpec(String title, {this.hint}) : super('', title);
}

/// Текущие значения формы: текст из полей и то, что выбрано
/// в списках, флажках и датах.
class FormValues {
  final Map<String, Object?> _values;
  final Map<String, TextEditingController> _controllers;

  FormValues(this._values, this._controllers);

  String text(String key) =>
      _controllers[key]?.text.trim() ?? (_values[key] as String? ?? '');
  int? intOf(String key) => int.tryParse(text(key));
  int? id(String key) => _values[key] as int?;
  List<int> ids(String key) => (_values[key] as List<int>?) ?? const [];
  DateTime? date(String key) => _values[key] as DateTime?;

  void set(String key, Object? value) => _values[key] = value;
}

// ---------------------------------------------------------------------------
// Сам экран формы — один и для создания, и для редактирования.
// ---------------------------------------------------------------------------

class EntityForm<T extends Entity> extends StatefulWidget {
  /// null — создаём новую запись, иначе редактируем
  final int? id;
  final String createTitle;
  final String editTitle;

  /// что сделать перед открытием, например загрузить справочники
  final Future<void> Function()? prepare;
  final Future<T?> Function(int id) load;

  /// начальные значения: из записи при редактировании, пустые при создании.
  /// текст — строкой, связи — `int` / `List<int>`, даты — `DateTime`
  final Map<String, Object?> Function(T? item) initialValues;
  final List<FieldSpec> Function(FormValues values) fields;

  /// что делать при изменении значения — нужно для каскада
  /// (выбрали театр — сузился список актёров)
  final void Function(String key, FormValues values)? onChanged;
  final T Function(FormValues values, T? original) build;
  final Future<T> Function(T item) save;
  final String Function(T saved) savedLocation;
  final String cancelLocation;

  const EntityForm({
    super.key,
    required this.id,
    required this.createTitle,
    required this.editTitle,
    this.prepare,
    required this.load,
    required this.initialValues,
    required this.fields,
    this.onChanged,
    required this.build,
    required this.save,
    required this.savedLocation,
    required this.cancelLocation,
  });

  bool get isEditing => id != null;

  @override
  State<EntityForm<T>> createState() => _EntityFormState<T>();
}

class _EntityFormState<T extends Entity> extends State<EntityForm<T>> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, Object?> _values = {};
  final Map<String, TextEditingController> _controllers = {};
  late final FormValues _form = FormValues(_values, _controllers);
  late final FormGuard _guard;

  T? _original;
  bool _loading = true;
  bool _notFound = false;
  String? _loadError;
  bool _saving = false;

  /// ошибки после сохранения (например, «уже занято»): поле → текст.
  /// показываются под полем, как обычные ошибки
  Map<String, String> _serverErrors = {};

  @override
  void initState() {
    super.initState();
    _guard = context.read<FormGuard>();
    _init();
  }

  Future<void> _init() async {
    try {
      await widget.prepare?.call();
      final id = widget.id;
      if (id != null) {
        _original = await widget.load(id);
        if (_original == null) {
          if (mounted) setState(() => _notFound = true);
          return;
        }
      }
      if (!mounted) return;
      _values.addAll(widget.initialValues(_original));
      // контроллеры создаю один раз и сразу с текстом. controller и
      // initialValue вместе ставить нельзя — будет ошибка
      for (final spec in widget.fields(_form).whereType<TextFieldSpec>()) {
        final c = TextEditingController(
          text: _values[spec.key] as String? ?? '',
        );
        c.addListener(() => _onTextChanged(spec.key));
        _controllers[spec.key] = c;
      }
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loadError = '$e');
    }
  }

  void _onTextChanged(String key) {
    // ошибка «уже занято» была про старое значение — как только
    // начали править поле, убираем её
    _serverErrors.remove(key);
    _guard.dirty = true;
  }

  void _setValue(String key, Object? value) {
    setState(() {
      _values[key] = value;
      _serverErrors.remove(key);
      widget.onChanged?.call(key, _form);
    });
    _guard.dirty = true;
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await widget.save(widget.build(_form, _original));
      _guard.dirty = false;
      messenger.showSnackBar(const SnackBar(content: Text('Сохранено')));
      if (mounted) context.go(widget.savedLocation(saved));
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverErrors = Map.of(e.errors);
      });
      _formKey.currentState!.validate(); // чтобы ошибки появились под полями
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Не удалось сохранить: $e')),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _guard.dirty = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? widget.editTitle : widget.createTitle;
    // PopScope ловит обычный возврат (Navigator.pop), а переходы go_router
    // ловит onExit в роутере — оба спрашивают FormGuard
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _guard.confirmLeave(context) && context.mounted) {
          context.go(widget.cancelLocation);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => context.go(widget.cancelLocation),
          ),
          title: Text(title),
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loadError != null) {
      return Center(child: Text('Не удалось загрузить: $_loadError'));
    }
    if (_notFound) return const Center(child: Text('Запись не найдена'));
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              // ошибки показываются после того, как поле начали менять,
              // а не сразу на пустой форме
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final spec in widget.fields(_form)) ...[
                    _field(spec),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    children: [
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => context.go(widget.cancelLocation),
                        child: const Text('Отмена'),
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(widget.isEditing ? 'Сохранить' : 'Создать'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(FieldSpec spec) => switch (spec) {
    TextFieldSpec() => _text(spec),
    DropdownFieldSpec() => _dropdown(spec),
    ChipsFieldSpec() => _chips(spec),
    DateFieldSpec() => _date(spec),
    SectionSpec() => _section(spec),
  };

  Widget _text(TextFieldSpec spec) {
    return TextFormField(
      controller: _controllers[spec.key],
      keyboardType: spec.numeric ? TextInputType.number : null,
      inputFormatters:
          spec.formatters ??
          (spec.numeric ? [FilteringTextInputFormatter.digitsOnly] : null),
      maxLines: spec.maxLines,
      // в браузере удобно, когда Enter отправляет форму
      textInputAction: spec.maxLines == 1 ? TextInputAction.next : null,
      onFieldSubmitted: spec.maxLines == 1 ? (_) => _submit() : null,
      decoration: InputDecoration(
        labelText: spec.label,
        hintText: spec.hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          spec.validator?.call(value) ??
          spec.cross?.call(_form) ??
          _serverErrors[spec.key],
    );
  }

  Widget _dropdown(DropdownFieldSpec spec) {
    final current = _values[spec.key] as int?;
    // значение должно быть в списке вариантов, иначе DropdownButton упадёт
    final valid = spec.options.any((o) => o.$1 == current) ? current : null;
    return DropdownButtonFormField<int>(
      key: ValueKey('${spec.key}-${spec.options.length}'),
      initialValue: valid,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: spec.label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final (id, name) in spec.options)
          DropdownMenuItem(value: id, child: Text(name)),
      ],
      onChanged: (v) => _setValue(spec.key, v),
      validator: (v) =>
          v == null ? spec.requiredMessage : _serverErrors[spec.key],
    );
  }

  Widget _chips(ChipsFieldSpec spec) {
    final allowed = spec.options.map((o) => o.$1).toSet();
    final initial = _form.ids(spec.key).where(allowed.contains).toList();
    return FormField<List<int>>(
      // варианты поменялись (каскад) — пересоздаём поле
      key: ValueKey('${spec.key}-${allowed.join(',')}'),
      initialValue: initial,
      validator: (value) {
        if ((value?.length ?? 0) < spec.min) return spec.minMessage;
        return _serverErrors[spec.key];
      },
      builder: (field) {
        final selected = field.value ?? const [];
        return InputDecorator(
          decoration: InputDecoration(
            labelText: spec.label,
            border: const OutlineInputBorder(),
            // ошибку показываю так же, как у обычного поля
            errorText: field.errorText,
          ),
          child: spec.options.isEmpty
              ? Text(
                  spec.emptyHint,
                  style: TextStyle(color: Theme.of(context).hintColor),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (id, name) in spec.options)
                      FilterChip(
                        label: Text(name),
                        selected: selected.contains(id),
                        onSelected: (_) {
                          final next = [...selected];
                          next.contains(id) ? next.remove(id) : next.add(id);
                          field.didChange(
                            next,
                          ); // без этого форма не узнает про изменение
                          _setValue(spec.key, next);
                        },
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _date(DateFieldSpec spec) {
    return FormField<DateTime>(
      initialValue: _form.date(spec.key),
      validator: (v) {
        if (v == null) return spec.requiredMessage;
        if (v.isBefore(spec.first)) {
          return 'Не раньше ${formatDate(spec.first)}';
        }
        if (v.isAfter(spec.last)) {
          return 'Не позже ${formatDate(spec.last)}';
        }
        return null;
      },
      builder: (field) {
        final v = field.value;
        return InkWell(
          onTap: () => _pickDate(spec, field),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: spec.label,
              border: const OutlineInputBorder(),
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.calendar_month),
            ),
            child: Text(
              v == null
                  ? ''
                  : (spec.withTime ? formatDateTime(v) : formatDate(v)),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate(
    DateFieldSpec spec,
    FormFieldState<DateTime> field,
  ) async {
    final now = DateTime.now();
    final current = field.value ?? now;
    final initial = current.isBefore(spec.first)
        ? spec.first
        : (current.isAfter(spec.last) ? spec.last : current);
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: spec.first,
      lastDate: spec.last,
      helpText: spec.label,
    );
    if (day == null || !mounted) return;
    var result = day;
    if (spec.withTime) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
      );
      if (time == null) return;
      result = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    }
    field.didChange(result);
    _setValue(spec.key, result);
  }

  Widget _section(SectionSpec spec) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(spec.label, style: theme.textTheme.titleMedium),
          if (spec.hint != null)
            Text(spec.hint!, style: TextStyle(color: theme.hintColor)),
          const Divider(),
        ],
      ),
    );
  }
}
