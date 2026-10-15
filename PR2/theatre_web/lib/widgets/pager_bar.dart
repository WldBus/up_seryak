import 'package:flutter/material.dart';

import '../models/page_result.dart';
import '../models/query_params.dart';

/// Переходы между страницами и выбор размера страницы.
class PagerBar extends StatelessWidget {
  final PageResult<Object?> page;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;

  const PagerBar({
    super.key,
    required this.page,
    required this.onPage,
    required this.onSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 4,
        children: [
          Text('Всего записей: ${page.total}'),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Первая страница',
                icon: const Icon(Icons.first_page),
                onPressed: page.hasPrevious ? () => onPage(1) : null,
              ),
              IconButton(
                tooltip: 'Предыдущая',
                icon: const Icon(Icons.chevron_left),
                onPressed: page.hasPrevious
                    ? () => onPage(page.page - 1)
                    : null,
              ),
              Text('${page.page} из ${page.totalPages}'),
              IconButton(
                tooltip: 'Следующая',
                icon: const Icon(Icons.chevron_right),
                onPressed: page.hasNext ? () => onPage(page.page + 1) : null,
              ),
              IconButton(
                tooltip: 'Последняя страница',
                icon: const Icon(Icons.last_page),
                onPressed: page.hasNext ? () => onPage(page.totalPages) : null,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('На странице: '),
              DropdownButton<int>(
                value: page.size,
                underline: const SizedBox.shrink(),
                items: [
                  for (final s in pageSizes)
                    DropdownMenuItem(value: s, child: Text('$s')),
                ],
                onChanged: (v) => onSize(v ?? page.size),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
