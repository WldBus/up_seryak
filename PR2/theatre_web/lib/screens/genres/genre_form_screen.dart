import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router.dart';
import '../../core/validators.dart';
import '../../models/genre.dart';
import '../../state/genre_list_notifier.dart';
import '../../widgets/entity_form.dart';

class GenreFormScreen extends StatelessWidget {
  final int? id;

  const GenreFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<GenreListNotifier>();

    return EntityForm<Genre>(
      id: id,
      createTitle: 'Новый жанр',
      editTitle: 'Изменение жанра',
      load: notifier.findById,
      initialValues: (g) => {
        'name': g?.name ?? '',
        'description': g?.description ?? '',
      },
      fields: (v) => [
        TextFieldSpec(
          'name',
          'Название',
          validator: V.combine([
            V.required('Укажите название'),
            V.length(min: 2, max: 40),
            V.letters(),
          ]),
        ),
        TextFieldSpec(
          'description',
          'Описание',
          maxLines: 3,
          validator: V.length(max: 300),
        ),
      ],
      build: (v, original) => Genre(
        id: original?.id ?? 0,
        name: v.text('name'),
        description: v.text('description'),
        deletedAt: original?.deletedAt,
      ),
      save: notifier.save,
      savedLocation: (g) => '/genres/${g.id}',
      cancelLocation: id == null
          ? listLocation('/genres', notifier.query.toParams())
          : '/genres/$id',
    );
  }
}
