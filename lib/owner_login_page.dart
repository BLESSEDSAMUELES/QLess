import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'owner_home.dart';

class OwnerLoginPage extends StatefulWidget {
  const OwnerLoginPage({super.key});

  @override
  State<OwnerLoginPage> createState() => _OwnerLoginPageState();
}

class _OwnerLoginPageState extends State<OwnerLoginPage> {
  final _canteenNameController = TextEditingController();
  final _canteenCodeController = TextEditingController();

  bool _loading = false;

  Future<void> loginOwner() async {
    final supabase = Supabase.instance.client;

    final canteenName = _canteenNameController.text.trim();
    final canteenCode = _canteenCodeController.text.trim();

    if (canteenName.isEmpty || canteenCode.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter canteen name and code")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final data = await supabase
          .from('canteens')
          .select()
          .eq('canteen_name', canteenName)
          .eq('canteen_code', canteenCode)
          .maybeSingle();

      if (data == null) {
        throw "Invalid canteen name or code";
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerHome(
            canteenName: data['canteen_name'],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      appBar: AppBar(title: const Text("Canteen Owner Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _canteenNameController,
              decoration: const InputDecoration(
                labelText: "Canteen Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _canteenCodeController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Canteen Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : loginOwner,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
