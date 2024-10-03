import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Containers in Polygon'),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(
            Icons.refresh,
          ),
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
