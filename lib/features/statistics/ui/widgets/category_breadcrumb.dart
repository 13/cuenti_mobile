import 'package:cuentimobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The trail of categories drilled into, each step tappable to climb back.
///
/// [onPopTo] is given the depth to return to: 0 is the top level, 1 is the
/// first category in [path], and so on.
class CategoryBreadcrumb extends StatelessWidget {
  const CategoryBreadcrumb({
    required this.path,
    required this.onPopTo,
    super.key,
  });

  final List<String> path;
  final void Function(int depth) onPopTo;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final linkStyle = style?.copyWith(
      color: Theme.of(context).colorScheme.primary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          InkWell(
            onTap: () => onPopTo(0),
            child: Text(L.of(context).statsAllCategories, style: linkStyle),
          ),
          for (var i = 0; i < path.length; i++) ...[
            Text('  \u203a  ', style: style),
            // The last step is where the user already is, so it is a label
            // rather than a link back to itself.
            if (i == path.length - 1)
              Text(path[i], style: style)
            else
              InkWell(
                onTap: () => onPopTo(i + 1),
                child: Text(path[i], style: linkStyle),
              ),
          ],
        ],
      ),
    );
  }
}
