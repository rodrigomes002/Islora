import 'package:flutter/material.dart';

import '../models/island.dart';
import '../models/phrase.dart';
import '../theme/app_colors.dart';
import '../view_models/learning_view_model.dart';

class LearningHomePage extends StatefulWidget {
  const LearningHomePage({super.key, required this.viewModel});

  final LearningViewModel viewModel;

  @override
  State<LearningHomePage> createState() => _LearningHomePageState();
}

class _LearningHomePageState extends State<LearningHomePage> {
  LearningViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel.loadIslands();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.waves_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('islora', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddIslandDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova ilha'),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: _HomeHeading(islandCount: _viewModel.islands.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _ReviewEntryCard(
                    dueCount: _viewModel.duePhrases.length,
                    onTap: _openReview,
                  ),
                ),
              ),
              if (_viewModel.errorMessage != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _ErrorBanner(
                      message: _viewModel.errorMessage!,
                      onDismiss: _viewModel.clearError,
                    ),
                  ),
                ),
              if (_viewModel.isLoading && _viewModel.islands.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_viewModel.islands.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyIslands(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: _viewModel.islands.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final island = _viewModel.islands[index];
                      return _IslandCard(
                        island: island,
                        onTap: () => _openIsland(island),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openIsland(Island island) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IslandDetailPage(island: island, viewModel: _viewModel),
      ),
    );
  }

  Future<void> _openReview() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewSessionPage(viewModel: _viewModel),
      ),
    );
  }

  Future<void> _showAddIslandDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _AddIslandDialog(viewModel: _viewModel),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ilha criada com sucesso.')));
    }
  }
}

class IslandDetailPage extends StatefulWidget {
  const IslandDetailPage({
    super.key,
    required this.island,
    required this.viewModel,
  });

  final Island island;
  final LearningViewModel viewModel;

  @override
  State<IslandDetailPage> createState() => _IslandDetailPageState();
}

class _IslandDetailPageState extends State<IslandDetailPage> {
  LearningViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _viewModel.loadPhrases(widget.island.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.island.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPhraseDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova frase'),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          final phrases = _viewModel.phrasesFor(widget.island.id);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _IslandHeading(
                    island: widget.island,
                    phraseCount: phrases.length,
                  ),
                ),
              ),
              if (_viewModel.errorMessage != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _ErrorBanner(
                      message: _viewModel.errorMessage!,
                      onDismiss: _viewModel.clearError,
                    ),
                  ),
                ),
              if (_viewModel.isLoading && phrases.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (phrases.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyPhrases(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: phrases.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final phrase = phrases[index];
                      return _PhraseCard(
                        phrase: phrase,
                        onSpeak: () => _viewModel.speak(phrase.englishText),
                        onDelete: () => _deletePhrase(phrase),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddPhraseDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _AddPhraseDialog(islandId: widget.island.id, viewModel: _viewModel),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Frase adicionada à ilha.')));
    }
  }

  Future<void> _deletePhrase(Phrase phrase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir frase?'),
        content: Text('“${phrase.englishText}” será removida desta ilha.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _viewModel.deletePhrase(
        islandId: widget.island.id,
        phraseId: phrase.id,
      );
    }
  }
}

class ReviewSessionPage extends StatefulWidget {
  const ReviewSessionPage({super.key, required this.viewModel});

  final LearningViewModel viewModel;

  @override
  State<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends State<ReviewSessionPage> {
  LearningViewModel get _viewModel => widget.viewModel;

  bool _reviewedAny = false;
  bool _isSubmitting = false;
  int? _revealedPhraseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _viewModel.loadDuePhrases();
      if (mounted) {
        setState(() => _reviewedAny = _viewModel.duePhrases.isNotEmpty);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar frases')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.duePhrases.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_viewModel.duePhrases.isEmpty) {
            return _ReviewFinished(reviewedAny: _reviewedAny);
          }

          final phrase = _viewModel.duePhrases.first;
          final isRevealed = _revealedPhraseId == phrase.id;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_viewModel.errorMessage != null) ...[
                _ErrorBanner(
                  message: _viewModel.errorMessage!,
                  onDismiss: _viewModel.clearError,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                '${_viewModel.duePhrases.length} '
                '${_viewModel.duePhrases.length == 1 ? 'frase restante' : 'frases restantes'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              Card(
                color: AppColors.card,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.style_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        phrase.englishText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (isRevealed) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          phrase.translation.isEmpty
                              ? 'Nenhuma tradução cadastrada.'
                              : phrase.translation,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (!isRevealed)
                FilledButton.icon(
                  onPressed: () =>
                      setState(() => _revealedPhraseId = phrase.id),
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Revelar tradução'),
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: () => _viewModel.speak(phrase.englishText),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Ouvir frase'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitAnswer(phrase, wasCorrect: false),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Errei'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitAnswer(phrase, wasCorrect: true),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Acertei'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitAnswer(Phrase phrase, {required bool wasCorrect}) async {
    setState(() => _isSubmitting = true);
    final saved = await _viewModel.reviewPhrase(
      phrase: phrase,
      wasCorrect: wasCorrect,
    );
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (saved) _revealedPhraseId = null;
    });
  }
}

class _AddIslandDialog extends StatefulWidget {
  const _AddIslandDialog({required this.viewModel});

  final LearningViewModel viewModel;

  @override
  State<_AddIslandDialog> createState() => _AddIslandDialogState();
}

class _AddIslandDialogState extends State<_AddIslandDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Criar uma ilha'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nome da ilha'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Dê um nome para sua ilha'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar ilha'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final saved = await widget.viewModel.addIsland(
      name: _nameController.text,
      description: _descriptionController.text,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
    } else {
      _showViewModelError(context, widget.viewModel);
      setState(() => _isSaving = false);
    }
  }
}

class _AddPhraseDialog extends StatefulWidget {
  const _AddPhraseDialog({required this.islandId, required this.viewModel});

  final int islandId;
  final LearningViewModel viewModel;

  @override
  State<_AddPhraseDialog> createState() => _AddPhraseDialogState();
}

class _AddPhraseDialogState extends State<_AddPhraseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _englishController = TextEditingController();
  final _translationController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _englishController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar frase'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _englishController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Frase em inglês',
                hintText: 'Ex.: What would you like?',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Digite uma frase em inglês'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _translationController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tradução em português (opcional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar frase'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final saved = await widget.viewModel.addPhrase(
      islandId: widget.islandId,
      englishText: _englishController.text,
      translation: _translationController.text,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
    } else {
      _showViewModelError(context, widget.viewModel);
      setState(() => _isSaving = false);
    }
  }
}

class _HomeHeading extends StatelessWidget {
  const _HomeHeading({required this.islandCount});

  final int islandCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seu inglês,\nno seu ritmo.',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Guarde frases úteis e pratique ouvindo.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.sailing_rounded,
                size: 54,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Suas ilhas',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          islandCount == 1
              ? '1 ilha de aprendizado'
              : '$islandCount ilhas de aprendizado',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _IslandHeading extends StatelessWidget {
  const _IslandHeading({required this.island, required this.phraseCount});

  final Island island;
  final int phraseCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.spa_rounded, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            island.name,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (island.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(island.description),
          ],
          const SizedBox(height: 12),
          Text(
            phraseCount == 1 ? '1 frase salva' : '$phraseCount frases salvas',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewEntryCard extends StatelessWidget {
  const _ReviewEntryCard({required this.dueCount, required this.onTap});

  final int dueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.ink,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.style_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dueCount == 0 ? 'Revisão em dia' : 'Hora de revisar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dueCount == 0
                        ? 'Suas frases estarão aqui quando vencerem.'
                        : '$dueCount ${dueCount == 1 ? 'frase pronta' : 'frases prontas'} para praticar',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(onPressed: onTap, child: const Text('Revisar')),
          ],
        ),
      ),
    );
  }
}

class _IslandCard extends StatelessWidget {
  const _IslandCard({required this.island, required this.onTap});

  final Island island;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.spa_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      island.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      island.description.isEmpty
                          ? 'Toque para ver suas frases'
                          : island.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({
    required this.phrase,
    required this.onSpeak,
    required this.onDelete,
  });

  final Phrase phrase;
  final VoidCallback onSpeak;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phrase.englishText,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (phrase.translation.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      phrase.translation,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Ouvir frase',
              onPressed: onSpeak,
              icon: const Icon(Icons.volume_up_rounded),
            ),
            IconButton(
              tooltip: 'Excluir frase',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyIslands extends StatelessWidget {
  const _EmptyIslands();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.travel_explore_rounded,
      title: 'Sua primeira ilha começa aqui',
      message: 'Crie uma ilha para organizar frases por tema ou situação.',
    );
  }
}

class _EmptyPhrases extends StatelessWidget {
  const _EmptyPhrases();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Nenhuma frase por aqui',
      message: 'Adicione uma frase em inglês para começar a praticar.',
    );
  }
}

class _ReviewFinished extends StatelessWidget {
  const _ReviewFinished({required this.reviewedAny});

  final bool reviewedAny;

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: reviewedAny ? Icons.celebration_rounded : Icons.event_available,
      title: reviewedAny ? 'Revisão concluída!' : 'Tudo em dia!',
      message: reviewedAny
          ? 'Muito bem! Suas próximas frases aparecerão aqui quando chegar a hora.'
          : 'Não há frases para revisar agora. Adicione frases e volte mais tarde.',
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 52, color: AppColors.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(message),
      leading: const Icon(Icons.error_outline_rounded),
      actions: [TextButton(onPressed: onDismiss, child: const Text('Fechar'))],
    );
  }
}

void _showViewModelError(BuildContext context, LearningViewModel viewModel) {
  final message = viewModel.errorMessage ?? 'Ocorreu um erro ao salvar.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  viewModel.clearError();
}
