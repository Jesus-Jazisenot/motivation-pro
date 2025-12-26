import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/quote.dart';
import '../widgets/quote_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Quote> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    final db = DatabaseHelper.instance;
    final favorites = await db.getFavoriteQuotes();

    setState(() {
      _favorites = favorites;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(Quote quote) async {
    final updatedQuote = quote.copyWith(isFavorite: false);
    final db = DatabaseHelper.instance;
    await db.updateQuote(updatedQuote);

    setState(() {
      _favorites.removeWhere((q) => q.id == quote.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removida de favoritas'),
          duration: Duration(seconds: 2),
        ),
      );
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
              // Header
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: AppColors.favorite,
                      size: AppDimensions.iconL,
                    ),
                    const SizedBox(width: AppDimensions.paddingM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Favoritas',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          '${_favorites.length} frases guardadas',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _favorites.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 80,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: AppDimensions.paddingL),
                                Text(
                                  'No tienes favoritas aún',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: AppDimensions.paddingM),
                                Text(
                                  'Toca el ❤️ en cualquier frase\npara guardarla aquí',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFavorites,
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                bottom: AppDimensions.paddingXL,
                              ),
                              itemCount: _favorites.length,
                              itemBuilder: (context, index) {
                                final quote = _favorites[index];
                                return Dismissible(
                                  key: Key(quote.id.toString()),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) => _removeFavorite(quote),
                                  background: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.paddingL,
                                      vertical: AppDimensions.paddingS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusXL,
                                      ),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(
                                      right: AppDimensions.paddingL,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: AppDimensions.iconL,
                                    ),
                                  ),
                                  child: QuoteCard(
                                    quote: quote,
                                    onNextQuote: null,
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
