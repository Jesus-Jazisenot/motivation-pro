import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/affirmation.dart';

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  List<Affirmation> _affirmations = [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await DatabaseHelper.instance.getAllAffirmations();
    if (mounted) setState(() => _affirmations = list);
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final affirmation = Affirmation(
      text: text.length > 200 ? text.substring(0, 200) : text,
      createdAt: DateTime.now(),
    );
    await DatabaseHelper.instance.insertAffirmation(affirmation);
    _controller.clear();
    await _load();
  }

  Future<void> _toggleActive(Affirmation a) async {
    await DatabaseHelper.instance.updateAffirmation(
      a.copyWith(active: !a.active),
    );
    await _load();
  }

  Future<void> _delete(int id) async {
    await DatabaseHelper.instance.deleteAffirmation(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundDark,
              AppColors.backgroundMid,
              AppColors.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Mis Afirmaciones',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Escribe afirmaciones positivas sobre ti mismo. Empieza con "Yo soy...", "Yo tengo...", "Yo puedo..."',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),

              // Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLength: 200,
                          decoration: InputDecoration(
                            hintText: 'Yo soy capaz de lograr mis metas...',
                            hintStyle:
                                TextStyle(color: AppColors.textTertiary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            counterText: '',
                          ),
                          style: TextStyle(color: AppColors.textPrimary),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _add,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: _affirmations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.self_improvement,
                                size: 52, color: AppColors.textTertiary),
                            const SizedBox(height: 14),
                            Text(
                              'Aún no tienes afirmaciones.\nEscribe la primera arriba.',
                              style: TextStyle(
                                  color: AppColors.textSecondary, height: 1.6),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _affirmations.length,
                        itemBuilder: (context, i) {
                          final a = _affirmations[i];
                          return Dismissible(
                            key: ValueKey(a.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete_outline,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) => _delete(a.id!),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: a.active
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.text,
                                      style: TextStyle(
                                        color: a.active
                                            ? AppColors.textPrimary
                                            : AppColors.textTertiary,
                                        fontSize: 14,
                                        height: 1.4,
                                        decoration: a.active
                                            ? null
                                            : TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: a.active,
                                    onChanged: (_) => _toggleActive(a),
                                    activeThumbColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
