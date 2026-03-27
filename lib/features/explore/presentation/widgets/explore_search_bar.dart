import 'package:flutter/material.dart';
import 'package:cajun_local/core/theme/app_layout.dart';
import 'package:cajun_local/core/theme/theme.dart';

class ExploreSearchBar extends StatelessWidget {
  const ExploreSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = AppLayout.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.specWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.specNavy.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.specNavy),
          decoration: InputDecoration(
            hintText: 'Search listings, categories…',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.specNavy.withValues(alpha: 0.35),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.specNavy.withValues(alpha: 0.45),
              size: 20,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: AppTheme.specNavy.withValues(alpha: 0.45),
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                );
              },
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
          textInputAction: TextInputAction.search,
        ),
      ),
    );
  }
}
