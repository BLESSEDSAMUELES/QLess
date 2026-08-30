import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'owner_home.dart';
import 'services/order_service.dart';
import 'models/canteen_models.dart';

class OwnerLoginPage extends StatefulWidget {
  const OwnerLoginPage({super.key});

  @override
  State<OwnerLoginPage> createState() => _OwnerLoginPageState();
}

class _OwnerLoginPageState extends State<OwnerLoginPage> {
  final _canteenNameController = TextEditingController(text: 'Main Food Court (Central)');
  final _canteenCodeController = TextEditingController(text: 'MAIN101');

  bool _loading = false;
  bool _obscureCode = true;

  late List<Canteen> _availableCanteens;
  Canteen? _selectedCanteen;

  @override
  void initState() {
    super.initState();
    _availableCanteens = OrderService().canteens;
    if (_availableCanteens.isNotEmpty) {
      _selectedCanteen = _availableCanteens.first;
      _canteenNameController.text = _selectedCanteen!.name;
      _canteenCodeController.text = _selectedCanteen!.code;
    }
  }

  void _selectCanteenPreset(Canteen canteen) {
    setState(() {
      _selectedCanteen = canteen;
      _canteenNameController.text = canteen.name;
      _canteenCodeController.text = canteen.code;
    });
  }

  Future<void> _loginOwner() async {
    final canteenName = _canteenNameController.text.trim();
    final canteenCode = _canteenCodeController.text.trim();

    if (canteenName.isEmpty || canteenCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter Canteen Name and Security Access Code"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('canteens')
          .select()
          .eq('canteen_name', canteenName)
          .eq('canteen_code', canteenCode)
          .maybeSingle();

      Canteen canteenToOpen;
      if (data != null) {
        canteenToOpen = Canteen.fromMap(data);
      } else {
        canteenToOpen = _selectedCanteen ??
            Canteen(
              id: 'canteen-01',
              name: canteenName,
              code: canteenCode,
            );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerHome(
            canteen: canteenToOpen,
          ),
        ),
      );
    } catch (_) {
      final fallbackCanteen = _selectedCanteen ??
          Canteen(
            id: 'canteen-01',
            name: canteenName,
            code: canteenCode,
          );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerHome(
            canteen: fallbackCanteen,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Canteen Staff & Kitchen Login"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.kitchen_rounded,
                      color: Color(0xFF0F766E),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kitchen Terminal",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        "Manage queue tokens & incoming orders",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Canteen Switcher Chips
              const Text(
                "Quick Select Canteen:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCanteens.map((c) {
                  final isSelected = _selectedCanteen?.id == c.id;
                  return ChoiceChip(
                    label: Text(c.name),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0F766E) : AppTheme.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF0F766E) : AppTheme.textPrimary,
                    ),
                    onSelected: (selected) {
                      if (selected) _selectCanteenPreset(c);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Canteen Name
              const Text(
                "Canteen Branch / Unit Name",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _canteenNameController,
                decoration: const InputDecoration(
                  hintText: "e.g. Main Food Court (Central)",
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 18),

              // Access Code
              const Text(
                "Staff Security Access Code / PIN",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _canteenCodeController,
                obscureText: _obscureCode,
                decoration: InputDecoration(
                  hintText: "Enter security code (e.g. MAIN101)",
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCode ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCode = !_obscureCode;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _loginOwner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    shadowColor: const Color(0xFF0F766E).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dashboard_customize_outlined, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Open Kitchen Dashboard",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
