import 'package:flutter/material.dart';
import 'models/canteen_models.dart';
import 'theme/app_theme.dart';

class OwnerHome extends StatelessWidget {
  final Canteen canteen;

  OwnerHome({super.key, Canteen? canteen, String? canteenName})
      : canteen = canteen ??
            Canteen(
              id: 'canteen-01',
              name: canteenName ?? 'Main Food Court',
              code: 'MAIN101',
            );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text("${canteen.name} Dashboard"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.kitchen_rounded,
                  size: 60,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                canteen.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Access Code: ${canteen.code} • ${canteen.location}",
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Phase 4 will activate the full Kitchen Display System (KDS),\nLive Token Calling & Menu Stock CRUD Manager!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
