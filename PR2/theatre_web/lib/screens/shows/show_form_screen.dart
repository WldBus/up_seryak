import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/router.dart';
import '../../core/validators.dart';
import '../../models/show.dart';
import '../../state/catalog.dart';
import '../../state/show_list_notifier.dart';
import '../../widgets/entity_form.dart';

/// Форма спектакля (и создание, и редактирование). Тут сразу все три вида
/// связей: театр — выпадающий список (многие к одному), жанры и актёры —
/// флажки (многие ко многим). Актёры показываются только из труппы
/// выбранного театра.
class ShowFormScreen extends StatelessWidget {
  final int? id;

  const ShowFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<ShowListNotifier>();
    final catalog = context.read<Catalog>();
    final today = DateUtils.dateOnly(DateTime.now());

    return EntityForm<Show>(
      id: id,
      createTitle: 'Новый спектакль',
      editTitle: 'Изменение спектакля',
      // справочники из кэша: с сервера только в первый раз
      prepare: catalog.ensureLoaded,
      load: notifier.findById,
      initialValues: (s) => {
        'title': s?.title ?? '',
        'code': s?.code ?? '',
        'theatreId': s?.theatreId,
        'actorIds': s?.actorIds ?? <int>[],
        'genreIds': s?.genreIds ?? <int>[],
        'date': s?.date,
        'duration': s?.duration.toString() ?? '',
        'price': s?.price.toString() ?? '',
        'seatsTotal': s?.seatsTotal.toString() ?? '',
        'seatsAvailable': s?.seatsAvailable.toString() ?? '',
      },
      // каскад: поменяли театр — из выбранных актёров оставляем
      // только тех, кто из его труппы
      onChanged: (key, v) {
        if (key != 'theatreId') return;
        final troupe = catalog
            .activeActorsOf(v.id('theatreId'))
            .map((a) => a.id);
        v.set('actorIds', v.ids('actorIds').where(troupe.contains).toList());
      },
      fields: (v) => [
        TextFieldSpec(
          'title',
          'Название',
          validator: V.combine([
            V.required('Укажите название'),
            V.length(min: 2, max: 100),
          ]),
        ),
        TextFieldSpec(
          'code',
          'Код постановки',
          hint: 'SP-1025',
          formatters: [
            LengthLimitingTextInputFormatter(7),
            _UpperCaseFormatter(),
          ],
          validator: V.combine([
            V.required('Укажите код'),
            V.pattern(RegExp(r'^SP-\d{4}$'), 'Формат кода: SP-0000'),
          ]),
        ),
        DropdownFieldSpec(
          'theatreId',
          'Театр',
          options: [for (final t in catalog.activeTheatres) (t.id, t.name)],
          requiredMessage: 'Выберите театр',
        ),
        ChipsFieldSpec(
          'actorIds',
          'Актёры (труппа выбранного театра)',
          options: [
            for (final a in catalog.activeActorsOf(v.id('theatreId')))
              (a.id, a.fullName),
          ],
          min: 1,
          minMessage: 'Выберите хотя бы одного актёра',
          emptyHint: v.id('theatreId') == null
              ? 'Сначала выберите театр — список зависит от его труппы'
              : 'В труппе театра пока нет актёров',
        ),
        ChipsFieldSpec(
          'genreIds',
          'Жанры',
          options: [for (final g in catalog.activeGenres) (g.id, g.name)],
          min: 1,
          minMessage: 'Выберите хотя бы один жанр',
        ),
        DateFieldSpec(
          'date',
          'Дата и время показа',
          withTime: true,
          first: today,
          last: DateTime(today.year + 2, 12, 31),
          requiredMessage: 'Выберите дату показа',
        ),
        TextFieldSpec(
          'duration',
          'Длительность, мин',
          numeric: true,
          validator: V.combine([
            V.required('Укажите длительность'),
            V.integer(min: 30, max: 300),
          ]),
        ),
        TextFieldSpec(
          'price',
          'Цена билета, ₽',
          numeric: true,
          validator: V.combine([
            V.required('Укажите цену'),
            V.positive(max: 50000),
          ]),
        ),
        TextFieldSpec(
          'seatsTotal',
          'Мест всего',
          numeric: true,
          validator: V.combine([
            V.required('Укажите число мест'),
            V.positive(max: 5000),
          ]),
        ),
        TextFieldSpec(
          'seatsAvailable',
          'Свободно мест',
          numeric: true,
          validator: V.combine([
            V.required('Укажите число свободных мест'),
            V.integer(min: 0),
          ]),
          cross: (v) {
            final total = v.intOf('seatsTotal');
            final free = v.intOf('seatsAvailable');
            if (total != null && free != null && free > total) {
              return 'Свободных мест не может быть больше, чем всего';
            }
            return null;
          },
        ),
      ],
      build: (v, original) => Show(
        id: original?.id ?? 0,
        title: v.text('title'),
        code: v.text('code'),
        theatreId: v.id('theatreId')!,
        actorIds: v.ids('actorIds'),
        genreIds: v.ids('genreIds'),
        date: v.date('date')!,
        duration: v.intOf('duration')!,
        price: v.intOf('price')!,
        seatsTotal: v.intOf('seatsTotal')!,
        seatsAvailable: v.intOf('seatsAvailable')!,
        deletedAt: original?.deletedAt,
      ),
      save: notifier.save,
      savedLocation: (s) => '/shows/${s.id}',
      cancelLocation: id == null ? showsLocation(notifier.query) : '/shows/$id',
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) => next.copyWith(text: next.text.toUpperCase());
}
