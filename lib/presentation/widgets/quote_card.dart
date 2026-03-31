import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/quote.dart';
import '../../data/database/database_helper.dart';
import '../../core/services/tts_service.dart';

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
  bool _isSpeaking = false;
  bool _isSharingImage = false;
  final ScreenshotController _screenshotController = ScreenshotController();

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
    if (_isSpeaking) TtsService.instance.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleSpeech() async {
    final tts = TtsService.instance;
    if (_isSpeaking) {
      await tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      final text = widget.quote.author != null
          ? '${widget.quote.text}. Por ${widget.quote.author}.'
          : widget.quote.text;
      await tts.speak(text, onCompleted: () {
        if (mounted) setState(() => _isSpeaking = false);
      });
    }
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

  Future<void> _shareAsImage() async {
    if (_isSharingImage) return;
    setState(() => _isSharingImage = true);
    try {
      final image = await _screenshotController.capture(pixelRatio: 2.5);
      if (image == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(image);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.quote.author != null
            ? '— ${widget.quote.author}'
            : '',
      );
    } catch (e) {
      print('Error sharing image: $e');
    } finally {
      if (mounted) setState(() => _isSharingImage = false);
    }
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
            child: Screenshot(
              controller: _screenshotController,
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
                        // Leer en voz alta
                        IconButton(
                          onPressed: _toggleSpeech,
                          icon: Icon(
                            _isSpeaking
                                ? Icons.stop_circle_outlined
                                : Icons.volume_up_outlined,
                          ),
                          color: _isSpeaking
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          iconSize: AppDimensions.iconL,
                          tooltip: _isSpeaking ? 'Detener' : 'Leer en voz alta',
                        ),

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

                        // Compartir texto
                        IconButton(
                          onPressed: _shareQuote,
                          icon: const Icon(Icons.share),
                          color: AppColors.textSecondary,
                          iconSize: AppDimensions.iconL,
                          tooltip: 'Compartir texto',
                        ),

                        // Compartir como imagen
                        IconButton(
                          onPressed: _isSharingImage ? null : _shareAsImage,
                          icon: _isSharingImage
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(Icons.image_outlined),
                          color: AppColors.textSecondary,
                          iconSize: AppDimensions.iconL,
                          tooltip: 'Compartir como imagen',
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
            ), // Screenshot
          ),
        );
      },
    );
  }
}
