import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/router.dart';
import '../../core/validators.dart';
import '../../models/spectator.dart';
import '../../state/spectator_list_notifier.dart';
import '../../widgets/entity_form.dart';

/// Форма зрителя вместе с картой. Связь один к одному: у карты нет
/// своего экрана, её поля идут отдельной группой прямо в этой форме.
class SpectatorFormScreen extends StatelessWidget {
  final int? id;

  const SpectatorFormScreen({super.key, this.id});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<SpectatorListNotifier>();
    final today = DateUtils.dateOnly(DateTime.now());
    final name = V.combine([V.length(min: 2, max: 50), V.letters()]);

    return EntityForm<Spectator>(
      id: id,
      createTitle: 'Новый зритель',
      editTitle: 'Изменение зрителя',
      load: notifier.findById,
      initialValues: (s) => {
        'lastName': s?.lastName ?? '',
        'firstName': s?.firstName ?? '',
        'email': s?.email ?? '',
        'phone': s?.phone ?? '',
        'card.number': s?.card.number ?? '',
        'card.issuedAt': s?.card.issuedAt ?? today,
        'card.discount': s?.card.discount.toString() ?? '0',
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
          'email',
          'Электронная почта',
          hint: 'name@mail.ru',
          validator: V.combine([
            V.required('Укажите почту'),
            V.length(max: 100),
            V.email(),
          ]),
        ),
        TextFieldSpec(
          'phone',
          'Телефон',
          hint: '+79161234567',
          validator: V.combine([V.required('Укажите телефон'), V.phone()]),
        ),
        const SectionSpec(
          'Карта зрителя',
          hint: 'Один к одному: карта принадлежит только этому зрителю',
        ),
        TextFieldSpec(
          'card.number',
          'Номер карты',
          hint: '6 цифр',
          numeric: true,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: V.combine([
            V.required('Укажите номер карты'),
            V.pattern(RegExp(r'^\d{6}$'), 'Номер карты — ровно 6 цифр'),
          ]),
        ),
        DateFieldSpec(
          'card.issuedAt',
          'Дата выдачи карты',
          first: DateTime(2000),
          last: today,
        ),
        TextFieldSpec(
          'card.discount',
          'Скидка по карте, %',
          numeric: true,
          validator: V.combine([
            V.required('Укажите скидку'),
            V.integer(min: 0, max: 50),
          ]),
        ),
      ],
      build: (v, original) => Spectator(
        id: original?.id ?? 0,
        lastName: v.text('lastName'),
        firstName: v.text('firstName'),
        email: v.text('email'),
        phone: v.text('phone'),
        card: SpectatorCard(
          number: v.text('card.number'),
          issuedAt: v.date('card.issuedAt')!,
          discount: v.intOf('card.discount')!,
        ),
        deletedAt: original?.deletedAt,
      ),
      save: notifier.save,
      savedLocation: (s) => '/spectators/${s.id}',
      cancelLocation: id == null
          ? listLocation('/spectators', notifier.query.toParams())
          : '/spectators/$id',
    );
  }
}
