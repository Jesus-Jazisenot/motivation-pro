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
    // Actualizar UI INMEDIATAMENTE (antes de guardar en BD)
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // Actualizar en BD
    final updatedQuote = widget.quote.copyWith(isFavorite: _isFavorite);
    await DatabaseHelper.instance.updateQuote(updatedQuote);

    // Mostrar feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite
                ? '❤️ Añadido a favoritos'
                : '💔 Eliminado de favoritos',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
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
              margin: EdgeInsets.all(AppDimensions.paddingL),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppDimensions.paddingXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Categoría
                    Container(
                      padding: EdgeInsets.symmetric(
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

                    SizedBox(height: AppDimensions.paddingL),

                    // Icono de comillas
                    Icon(
                      Icons.format_quote,
                      size: 48,
                      color: AppColors.primary.withOpacity(0.3),
                    ),

                    SizedBox(height: AppDimensions.paddingM),

                    // Texto de la frase
                    Text(
                      widget.quote.text,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                    ),

                    if (widget.quote.author != null) ...[
                      SizedBox(height: AppDimensions.paddingL),
                      Text(
                        '- ${widget.quote.author}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],

                    SizedBox(height: AppDimensions.paddingL),

                    // Botones de acción
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Favorito
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          color: _isFavorite
                              ? AppColors.favorite
                              : AppColors.textSecondary,
                          iconSize: AppDimensions.iconL,
                        ),

                        // Compartir
                        IconButton(
                          onPressed: _shareQuote,
                          icon: Icon(Icons.share),
                          color: AppColors.textSecondary,
                          iconSize: AppDimensions.iconL,
                        ),

                        // Siguiente frase
                        if (widget.onNextQuote != null)
                          ElevatedButton.icon(
                            onPressed: widget.onNextQuote,
                            icon: Icon(Icons.refresh, size: 20),
                            label: const Text('Nueva frase'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 4,
                            ),
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
  }
}
