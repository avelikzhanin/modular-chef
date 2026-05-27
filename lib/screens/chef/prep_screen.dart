import 'package:flutter/material.dart';
import 'package:modular_chef/shell/role_switcher.dart';
import 'package:modular_chef/theme/app_colors.dart';

/// Шеф-экран «День заготовки» — Step 1 (выбор способа на каждый белок)
/// → Step 2 (таймлайн процессов, как в chef/serene_2).
class PrepScreen extends StatefulWidget {
  const PrepScreen({super.key});

  @override
  State<PrepScreen> createState() => _PrepScreenState();
}

class _PrepScreenState extends State<PrepScreen> {
  int _step = 0;

  // Step 1: какой способ выбран для каждого белка
  final Map<String, String> _methods = {
    'Курица': 'Запечь 40мин',
    'Лосось': 'В фольге 20мин',
    'Стейк': 'Сковорода 10мин',
  };

  static const _proteins = <_Protein>[
    _Protein('Курица', '🍗', [
      'Запечь 40мин',
      'Гриль 25мин',
      'Отварить 30мин',
      'Тушить 45мин',
    ]),
    _Protein('Лосось', '🐟', [
      'В фольге 20мин',
      'Гриль 15мин',
      'Слабосолёный 24ч',
    ]),
    _Protein('Стейк', '🥩', [
      'Сковорода 10мин',
      'Гриль 15мин',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: const [RoleSwitcher(), SizedBox(width: 8)],
      ),
      body: _step == 0 ? _buildStep1(context) : _buildStep2(context),
    );
  }

  Widget _buildStep1(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  _StepBadge(text: 'ШАГ 1 из 2', active: true),
                  SizedBox(width: 8),
                  _StepBadge(text: 'ШАГ 2', active: false),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Способ приготовления',
                style: tt.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Для каждого белка выберите, как готовить — конвейер пересчитается.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            children: [
              for (final p in _proteins) ...[
                _ProteinPicker(
                  protein: p,
                  selected: _methods[p.name],
                  onPick: (m) => setState(() => _methods[p.name] = m),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => setState(() => _step = 1),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  textStyle:
                      tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Продолжить'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pipeline = _buildPipeline();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _step = 0),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Шаг 1'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const Spacer(),
                  const _StepBadge(text: 'ШАГ 1', active: false),
                  const SizedBox(width: 8),
                  const _StepBadge(text: 'ШАГ 2 из 2', active: true),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Таймлайн заготовки',
                style: tt.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Параллельные процессы — плита, духовка, нарезка.',
                style: tt.bodyMedium,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              for (int i = 0; i < pipeline.length; i++) ...[
                _PipelineStep(
                  step: pipeline[i],
                  isLast: i == pipeline.length - 1,
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('🧼', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Подготовьте контейнеры заранее — сэкономит 10 минут в конце.',
                        style: tt.bodyMedium?.copyWith(
                          color: AppColors.onTertiaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_PipelineEntry> _buildPipeline() {
    // Простой mock-конвейер на основе выбранных способов.
    final out = <_PipelineEntry>[];
    int t = 0;
    for (final p in _proteins) {
      final m = _methods[p.name] ?? p.methods.first;
      final mins = int.tryParse(RegExp(r'(\d+)').firstMatch(m)?.group(1) ?? '0') ?? 0;
      out.add(_PipelineEntry(
        emoji: p.emoji,
        title: '${p.name}: $m',
        durationMin: mins,
        startMin: t,
        lane: p.name == 'Курица' ? _Lane.oven : (p.name == 'Лосось' ? _Lane.stove : _Lane.pan),
      ));
      t += 5; // небольшой сдвиг между стартами на разных конфорках
    }
    return out;
  }
}

class _Protein {
  const _Protein(this.name, this.emoji, this.methods);
  final String name;
  final String emoji;
  final List<String> methods;
}

enum _Lane { oven, stove, pan }

extension on _Lane {
  String get label => switch (this) {
        _Lane.oven => 'Духовка',
        _Lane.stove => 'Плита',
        _Lane.pan => 'Сковорода',
      };
  IconData get icon => switch (this) {
        _Lane.oven => Icons.local_fire_department_outlined,
        _Lane.stove => Icons.soup_kitchen_outlined,
        _Lane.pan => Icons.outdoor_grill_outlined,
      };
}

class _PipelineEntry {
  const _PipelineEntry({
    required this.emoji,
    required this.title,
    required this.durationMin,
    required this.startMin,
    required this.lane,
  });
  final String emoji;
  final String title;
  final int durationMin;
  final int startMin;
  final _Lane lane;
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.text, required this.active});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: tt.labelSmall?.copyWith(
          color: active ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ProteinPicker extends StatelessWidget {
  const _ProteinPicker({
    required this.protein,
    required this.selected,
    required this.onPick,
  });
  final _Protein protein;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(protein.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                protein.name,
                style: tt.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in protein.methods)
                _MethodChip(
                  label: m,
                  selected: m == selected,
                  onTap: () => onPick(m),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: tt.labelLarge?.copyWith(
            color: selected
                ? AppColors.onPrimaryContainer
                : AppColors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({required this.step, required this.isLast});
  final _PipelineEntry step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(step.lane.icon,
                    color: AppColors.onPrimaryContainer, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          step.lane.label.toUpperCase(),
                          style: tt.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '+${step.startMin} мин → ${step.startMin + step.durationMin}',
                            style: tt.labelSmall?.copyWith(
                              color: AppColors.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${step.emoji}  ${step.title}',
                      style: tt.bodyLarge?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
