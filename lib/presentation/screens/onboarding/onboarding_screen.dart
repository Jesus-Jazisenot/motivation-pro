import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/models/user_profile.dart';
import '../main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Datos del usuario
  String _name = '';
  List<String> _challenges = [];
  List<String> _preferredTimes = [];
  List<String> _values = [];
  String _tonePreference = 'balanced';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      print('🔵 Iniciando guardado de perfil...');

      // Guardar perfil en base de datos
      final profile = UserProfile(
        name: _name,
        challenges: _challenges,
        preferredTimes: _preferredTimes,
        values: _values,
        tonePreference: _tonePreference,
      );

      print('🔵 Perfil creado: ${profile.name}');

      final db = DatabaseHelper.instance;
      print('🔵 Database obtenida');

      await db.insertUserProfile(profile);
      print('🔵 Perfil guardado en DB');

      if (!mounted) return;

      print('🔵 Navegando a Home...');

      // Navegar a Home
// Navegar a Main Navigation
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNavigation(),
        ),
      );

      print('🔵 Navegación completada');
    } catch (e, stackTrace) {
      print('❌ ERROR AL FINALIZAR ONBOARDING:');
      print('Error: $e');
      print('StackTrace: $stackTrace');

      // Mostrar error al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
              // Progress indicator
              _buildProgressIndicator(),

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildNamePage(),
                    _buildChallengesPage(),
                    _buildTimesPage(),
                    _buildValuesPage(),
                    _buildTonePage(),
                  ],
                ),
              ),

              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: List.generate(
          5,
          (index) => Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingXS,
              ),
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNamePage() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Bienvenido! 👋',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            '¿Cómo te llamas?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          TextField(
            autofocus: true,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: const InputDecoration(
              hintText: 'Tu nombre',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: (value) {
              setState(() {
                _name = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesPage() {
    final challenges = [
      {
        'icon': Icons.fitness_center,
        'title': 'Motivación',
        'value': 'motivation'
      },
      {'icon': Icons.spa, 'title': 'Bienestar', 'value': 'wellness'},
      {
        'icon': Icons.work_outline,
        'title': 'Productividad',
        'value': 'productivity'
      },
      {
        'icon': Icons.favorite_outline,
        'title': 'Relaciones',
        'value': 'relationships'
      },
      {'icon': Icons.emoji_events, 'title': 'Metas', 'value': 'goals'},
      {'icon': Icons.psychology, 'title': 'Mentalidad', 'value': 'mindset'},
    ];

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿En qué áreas quieres mejorar?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'Selecciona todas las que apliquen',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppDimensions.paddingM,
                mainAxisSpacing: AppDimensions.paddingM,
                childAspectRatio: 1.3,
              ),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                final isSelected = _challenges.contains(challenge['value']);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _challenges.remove(challenge['value']);
                      } else {
                        _challenges.add(challenge['value'] as String);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          challenge['icon'] as IconData,
                          size: AppDimensions.iconXL,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        const SizedBox(height: AppDimensions.paddingS),
                        Text(
                          challenge['title'] as String,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
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
    );
  }

  Widget _buildTimesPage() {
    final times = [
      {'icon': Icons.wb_sunny, 'title': 'Mañana', 'value': 'morning'},
      {'icon': Icons.wb_twilight, 'title': 'Tarde', 'value': 'afternoon'},
      {'icon': Icons.nightlight_round, 'title': 'Noche', 'value': 'night'},
    ];

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cuándo prefieres recibir motivación?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'Configuraremos notificaciones para ti',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          ...times.map((time) {
            final isSelected = _preferredTimes.contains(time['value']);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _preferredTimes.remove(time['value']);
                    } else {
                      _preferredTimes.add(time['value'] as String);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        time['icon'] as IconData,
                        size: AppDimensions.iconL,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Text(
                        time['title'] as String,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildValuesPage() {
    final values = [
      'Perseverancia',
      'Gratitud',
      'Disciplina',
      'Creatividad',
      'Empatía',
      'Sabiduría',
      'Valentía',
      'Amor',
    ];

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Qué valores son importantes para ti?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'Selecciona 3-5 valores',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          Expanded(
            child: Wrap(
              spacing: AppDimensions.paddingM,
              runSpacing: AppDimensions.paddingM,
              children: values.map((value) {
                final isSelected = _values.contains(value);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _values.remove(value);
                      } else {
                        if (_values.length < 5) {
                          _values.add(value);
                        }
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingL,
                      vertical: AppDimensions.paddingM,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTonePage() {
    final tones = [
      {
        'icon': Icons.rocket_launch,
        'title': 'Motivador',
        'subtitle': 'Energético y directo',
        'value': 'motivational'
      },
      {
        'icon': Icons.self_improvement,
        'title': 'Equilibrado',
        'subtitle': 'Reflexivo y positivo',
        'value': 'balanced'
      },
      {
        'icon': Icons.auto_stories,
        'title': 'Filosófico',
        'subtitle': 'Profundo y contemplativo',
        'value': 'philosophical'
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Qué tono prefieres?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            'Esto afectará el tipo de frases que verás',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          ...tones.map((tone) {
            final isSelected = _tonePreference == tone['value'];

            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _tonePreference = tone['value'] as String;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tone['icon'] as IconData,
                        size: AppDimensions.iconL,
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      const SizedBox(width: AppDimensions.paddingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tone['title'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: AppDimensions.paddingXS),
                            Text(
                              tone['subtitle'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? Colors.white70
                                        : AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final canProceed = _canProceed();

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousPage,
                icon: const Icon(Icons.arrow_back),
                label: Text(AppStrings.buttonBack),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: canProceed ? _nextPage : null,
              icon: Icon(
                _currentPage == 4 ? Icons.check : Icons.arrow_forward,
              ),
              label: Text(
                _currentPage == 4
                    ? AppStrings.buttonStart
                    : AppStrings.buttonNext,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _name.isNotEmpty;
      case 1:
        return _challenges.isNotEmpty;
      case 2:
        return _preferredTimes.isNotEmpty;
      case 3:
        return _values.isNotEmpty;
      case 4:
        return true;
      default:
        return false;
    }
  }
}
