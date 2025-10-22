import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/login.dart';
import '../auth/sign_up.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    if (!navigator.mounted) return;
    navigator.push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await user.delete();
      messenger.showSnackBar(
        const SnackBar(content: Text('Compte supprimé.')),
      );
      if (!navigator.mounted) return;
      navigator.push(
        MaterialPageRoute(builder: (_) => const SignUpPage()),
      );
    } on FirebaseAuthException catch (error) {
      final message = error.message ?? 'Suppression impossible.';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations utilisateur',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('UID : ${user?.uid ?? 'Inconnu'}'),
            Text('Email : ${user?.email ?? 'Non renseigné'}'),
            const SizedBox(height: 24),
            // Bouton de déconnexion simple.
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
            const SizedBox(height: 12),
            // Suppression de compte pour illustrer l'opération delete.
            OutlinedButton.icon(
              onPressed: () => _deleteAccount(context),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Supprimer le compte'),
            ),
          ],
        ),
      ),
    );
  }
}
