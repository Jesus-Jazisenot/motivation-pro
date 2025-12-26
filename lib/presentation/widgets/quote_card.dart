import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/quote.dart';
import '../../data/database/database_helper.dart';

class QuoteCard extends StatefulWidget {
  final Quote quote;
  final VoidCallback? onNextQuote;

  const QuoteCard({
    super.key,
    required this.quote,
    this.onNextQuote,
  });

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.quote.isFavorite;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    final updatedQuote = widget.quote.copyWith(isFavorite: _isFavorite);
    final db = DatabaseHelper.instance;
    await db.updateQuote(updatedQuote);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? '❤️ Agregada a favoritas' : 'Removida de favoritas',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor:
              _isFavorite ? AppColors.favorite : AppColors.textSecondary,
        ),
      );
    }
  }

  void _shareQuote() {
    final text = widget.quote.author != null
        ? '"${widget.quote.text}"\n\n- ${widget.quote.author}'
        : '"${widget.quote.text}"';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(AppDimensions.paddingL),
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Categoría
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                      vertical: AppDimensions.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                    child: Text(
                      widget.quote.category.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingXL),

                  // Icono de comillas
                  Icon(
                    Icons.format_quote,
                    size: AppDimensions.iconXL,
                    color: AppColors.primary.withOpacity(0.3),
                  ),

                  const SizedBox(height: AppDimensions.paddingM),

                  // Texto de la frase
                  Text(
                    widget.quote.text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                  ),

                  if (widget.quote.author != null) ...[
                    const SizedBox(height: AppDimensions.paddingL),
                    Text(
                      '- ${widget.quote.author}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],

                  const SizedBox(height: AppDimensions.paddingXL),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Favorito
                      IconButton(
                        onPressed: _toggleFavorite,
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                        ),
                        color: _isFavorite
                            ? AppColors.favorite
                            : AppColors.textSecondary,
                        iconSize: AppDimensions.iconL,
                      ),

                      // Compartir
                      IconButton(
                        onPressed: _shareQuote,
                        icon: const Icon(Icons.share),
                        color: AppColors.textSecondary,
                        iconSize: AppDimensions.iconL,
                      ),

                      // Siguiente frase
                      if (widget.onNextQuote != null)
                        ElevatedButton.icon(
                          onPressed: widget.onNextQuote,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Nueva frase'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingL,
                              vertical: AppDimensions.paddingM,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
