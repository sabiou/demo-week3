import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../profile/profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  CollectionReference<Map<String, dynamic>> get _notesRef =>
      FirebaseFirestore.instance.collection('demoNotes');

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$day/$month à $hours:$minutes';
  }

  Future<void> _toggleDone(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final current = doc.data()?['done'] == true;
    await doc.reference.update({'done': !current});
  }

  Future<void> _delete(DocumentSnapshot<Map<String, dynamic>> doc) async {
    await doc.reference.delete();
  }

  Future<void> _openCreateTask(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: _TaskForm(notesRef: _notesRef),
        );
      },
    );
  }

  Future<void> _openEditTask(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: _TaskForm(
            notesRef: _notesRef,
            initialDoc: doc,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démo Firestore'),
      ),
      body: Column(
        children: [
          Expanded(
            // StreamBuilder écoute la collection et se met à jour automatiquement.
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  _notesRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Aucune note pour l\'instant.'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final title = data['title'] as String? ?? 'Sans titre';
                    final description =
                        data['description'] as String? ?? 'Pas de description';
                    final isDone = data['done'] == true;
                    final createdAt = data['createdAt'] as Timestamp?;

                    final dateLabel = createdAt != null
                        ? 'Créé le ${_formatDate(createdAt.toDate())}'
                        : 'Date inconnue';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openEditTask(context, doc),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          decoration: isDone
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _toggleDone(doc),
                                      icon: Icon(
                                        isDone
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: isDone
                                            ? Colors.green
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description.isEmpty
                                      ? 'Description vide'
                                      : description,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                          isDone ? 'Terminée' : 'En cours'),
                                      avatar: Icon(
                                        isDone ? Icons.check : Icons.more_horiz,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateLabel,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _delete(doc),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateTask(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle tâche'),
      ),
    );
  }
}

class _TaskForm extends StatefulWidget {
  const _TaskForm({required this.notesRef, this.initialDoc});

  final CollectionReference<Map<String, dynamic>> notesRef;
  final DocumentSnapshot<Map<String, dynamic>>? initialDoc;

  bool get isEditing => initialDoc != null;

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialDoc?.data();
    if (data != null) {
      _titleController.text = data['title'] as String? ?? '';
      _descriptionController.text = data['description'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.isEditing) {
        await widget.initialDoc!.reference.update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'updatedAt': Timestamp.now(),
        });
      } else {
        await widget.notesRef.add({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'createdAt': Timestamp.now(),
          'done': false,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'enregistrer la tâche.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditing ? 'Modifier la tâche' : 'Ajouter une tâche',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Champ titre : le validator rappelle qu'il est obligatoire.
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de la tâche',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le titre est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Champ description pour expliquer la tâche à réaliser.
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveTask,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Mettre à jour' : 'Enregistrer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
