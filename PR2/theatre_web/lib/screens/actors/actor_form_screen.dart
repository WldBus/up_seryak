import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router.dart';
import '../../core/validators.dart';
import '../../models/actor.dart';
import '../../state/actor_list_notifier.dart';
import '../../state/catalog.dart';
import '../../widgets/entity_form.dart';

class ActorFormScreen extends StatelessWidget {
  final int? id;

  const ActorFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<ActorListNotifier>();
    final catalog = context.read<Catalog>();
    final year = DateTime.now().year;
    final name = V.combine([V.length(min: 2, max: 50), V.letters()]);

    return EntityForm<Actor>(
      id: id,
      createTitle: 'Новый актёр',
      editTitle: 'Изменение актёра',
      prepare: catalog.refresh,
      load: notifier.findById,
      initialValues: (a) => {
        'lastName': a?.lastName ?? '',
        'firstName': a?.firstName ?? '',
        'country': a?.country ?? '',
        'birthYear': a?.birthYear.toString() ?? '',
        'theatreId': a?.theatreId,
      },
      fields: (v) => [
        TextFieldSpec(
          'lastName',
          'Фамилия',
          validator: V.combine([V.required('Укажите фамилию'), name]),
        ),
        TextFieldSpec(
          'firstName',
          'Имя',
          validator: V.combine([V.required('Укажите имя'), name]),
        ),
        TextFieldSpec(
          'country',
          'Страна',
          validator: V.combine([V.required('Укажите страну'), name]),
        ),
        TextFieldSpec(
          'birthYear',
          'Год рождения',
          numeric: true,
          validator: V.combine([
            V.required('Укажите год рождения'),
            V.integer(min: 1900, max: year - 10),
          ]),
        ),
        DropdownFieldSpec(
          'theatreId',
          'Театр (труппа)',
          options: [for (final t in catalog.activeTheatres) (t.id, t.name)],
          requiredMessage: 'Выберите театр',
        ),
      ],
      build: (v, original) => Actor(
        id: original?.id ?? 0,
        lastName: v.text('lastName'),
        firstName: v.text('firstName'),
        country: v.text('country'),
        birthYear: v.intOf('birthYear')!,
        theatreId: v.id('theatreId')!,
        deletedAt: original?.deletedAt,
      ),
      save: notifier.save,
      savedLocation: (a) => '/actors/${a.id}',
      cancelLocation: id == null
          ? listLocation('/actors', notifier.query.toParams())
          : '/actors/$id',
    );
  }
}
