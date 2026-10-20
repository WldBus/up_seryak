import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router.dart';
import '../../core/validators.dart';
import '../../models/theatre.dart';
import '../../state/theatre_list_notifier.dart';
import '../../widgets/entity_form.dart';

class TheatreFormScreen extends StatelessWidget {
  final int? id;

  const TheatreFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<TheatreListNotifier>();
    final year = DateTime.now().year;

    return EntityForm<Theatre>(
      id: id,
      createTitle: 'Новый театр',
      editTitle: 'Изменение театра',
      load: notifier.findById,
      initialValues: (t) => {
        'name': t?.name ?? '',
        'city': t?.city ?? '',
        'address': t?.address ?? '',
        'hallSeats': t?.hallSeats.toString() ?? '',
        'founded': t?.founded.toString() ?? '',
      },
      fields: (v) => [
        TextFieldSpec(
          'name',
          'Название',
          validator: V.combine([
            V.required('Укажите название'),
            V.length(min: 2, max: 80),
          ]),
        ),
        TextFieldSpec(
          'city',
          'Город',
          validator: V.combine([
            V.required('Укажите город'),
            V.length(min: 2, max: 50),
            V.letters(),
          ]),
        ),
        TextFieldSpec(
          'address',
          'Адрес',
          validator: V.combine([
            V.required('Укажите адрес'),
            V.length(min: 5, max: 120),
          ]),
        ),
        TextFieldSpec(
          'hallSeats',
          'Мест в зале',
          numeric: true,
          validator: V.combine([
            V.required('Укажите число мест'),
            V.positive(max: 10000),
          ]),
        ),
        TextFieldSpec(
          'founded',
          'Год основания',
          numeric: true,
          validator: V.combine([
            V.required('Укажите год основания'),
            V.integer(min: 1500, max: year),
          ]),
        ),
      ],
      build: (v, original) => Theatre(
        id: original?.id ?? 0,
        name: v.text('name'),
        city: v.text('city'),
        address: v.text('address'),
        hallSeats: v.intOf('hallSeats')!,
        founded: v.intOf('founded')!,
        deletedAt: original?.deletedAt,
      ),
      save: notifier.save,
      savedLocation: (t) => '/theatres/${t.id}',
      cancelLocation: id == null
          ? listLocation('/theatres', notifier.query.toParams())
          : '/theatres/$id',
    );
  }
}
