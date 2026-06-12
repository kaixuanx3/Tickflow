import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const ComingSoon(
          icon: Icons.notifications_none,
          title: 'Notifications',
          message: 'Price alerts and the triggered feed — build order phase 5.',
        ),
      );
}
