import 'package:flutter/material.dart';
import '../../core/theme/theme_service.dart';
import '../../core/theme/theme_models.dart';

class ThemeSelectorScreen extends StatefulWidget {
  const ThemeSelectorScreen({super.key});

  @override
  State<ThemeSelectorScreen> createState() => _ThemeSelectorScreenState();
}

class _ThemeSelectorScreenState extends State<ThemeSelectorScreen> {
  String? _previewThemeId;

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    final allThemes = themeService.getAllThemes();
    final currentThemeId = _previewThemeId ?? themeService.currentThemeId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temas'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Preview Card
          _buildPreviewCard(currentThemeId, allThemes),

          SizedBox(height: 16),

          // Lista de temas
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: allThemes.length,
              itemBuilder: (context, index) {
                final theme = allThemes[index];
                final isSelected = themeService.isCurrentTheme(theme.id);
                final isPreviewing = _previewThemeId == theme.id;

                return _buildThemeTile(
                  theme,
                  isSelected,
                  isPreviewing,
                  themeService,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(String themeId, List<AppThemeData> themes) {
    final theme = themes.firstWhere((t) => t.id == themeId);

    return Container(
      margin: EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.backgroundDark,
            theme.backgroundMid,
            theme.backgroundLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoración de fondo
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary.withOpacity(0.1),
              ),
            ),
          ),

          // Contenido
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      theme.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theme.name,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            theme.description,
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Paleta de colores
                Row(
                  children: [
                    _buildColorDot(theme.primary, 'Principal'),
                    SizedBox(width: 12),
                    _buildColorDot(theme.accent, 'Acento'),
                    SizedBox(width: 12),
                    _buildColorDot(theme.success, 'Éxito'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeTile(
    AppThemeData theme,
    bool isSelected,
    bool isPreviewing,
    ThemeService themeService,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.primary
              : isPreviewing
                  ? theme.accent.withOpacity(0.5)
                  : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.backgroundDark,
                theme.backgroundLight,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              theme.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              theme.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: theme.primary,
                size: 20,
              ),
            ],
          ],
        ),
        subtitle: Text(
          theme.description,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 13,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vista previa
            IconButton(
              icon: Icon(
                isPreviewing ? Icons.visibility : Icons.visibility_outlined,
                color: isPreviewing ? theme.accent : null,
              ),
              onPressed: () {
                setState(() {
                  _previewThemeId = isPreviewing ? null : theme.id;
                });
              },
              tooltip: 'Vista previa',
            ),

            // Aplicar
            if (!isSelected)
              ElevatedButton(
                onPressed: () async {
                  await themeService.setTheme(theme.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✨ Tema "${theme.name}" aplicado'),
                        backgroundColor: theme.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('Aplicar'),
              ),
          ],
        ),
      ),
    );
  }
}
