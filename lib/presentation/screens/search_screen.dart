import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/quote.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<String> _categories = [];
  String? _selectedCategory;
  List<Quote> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getCategories();
    if (mounted) setState(() => _categories = cats);
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    final category = _selectedCategory;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      List<Quote> results;
      if (query.isNotEmpty && category != null) {
        final byText = await DatabaseHelper.instance.searchQuotes(query);
        results = byText.where((q) => q.category == category).toList();
      } else if (query.isNotEmpty) {
        results = await DatabaseHelper.instance.searchQuotes(query);
      } else if (category != null) {
        results = await DatabaseHelper.instance.getQuotesByCategory(category);
      } else {
        results = await DatabaseHelper.instance.getAllQuotes();
      }

      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(Quote quote) async {
    final updated = quote.copyWith(isFavorite: !quote.isFavorite);
    await DatabaseHelper.instance.updateQuote(updated);
    setState(() {
      final i = _results.indexWhere((q) => q.id == quote.id);
      if (i != -1) _results[i] = updated;
    });
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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscar frases',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // Campo de búsqueda
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'Buscar por texto o autor...',
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          prefixIcon: Icon(Icons.search,
                              color: AppColors.textSecondary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: AppColors.textSecondary,
                                      size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Chips de categoría
                    if (_categories.isNotEmpty)
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Chip "Todas"
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: const Text('Todas'),
                                selected: _selectedCategory == null,
                                onSelected: (_) {
                                  setState(() => _selectedCategory = null);
                                  _search();
                                },
                                selectedColor:
                                    AppColors.primary.withOpacity(0.2),
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == null
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: _selectedCategory == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                backgroundColor: AppColors.surface,
                                side: BorderSide(color: AppColors.border),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            ..._categories.map((cat) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(cat),
                                    selected: _selectedCategory == cat,
                                    onSelected: (_) {
                                      setState(() => _selectedCategory =
                                          _selectedCategory == cat
                                              ? null
                                              : cat);
                                      _search();
                                    },
                                    selectedColor:
                                        AppColors.primary.withOpacity(0.2),
                                    checkmarkColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: _selectedCategory == cat
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: _selectedCategory == cat
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    backgroundColor: AppColors.surface,
                                    side: BorderSide(color: AppColors.border),
                                    padding: EdgeInsets.zero,
                                  ),
                                )),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Botón buscar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _search,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Buscar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Resultados
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : !_hasSearched
                        ? _buildEmptyState(
                            Icons.search,
                            'Busca frases por texto, autor\no filtra por categoría',
                          )
                        : _results.isEmpty
                            ? _buildEmptyState(
                                Icons.sentiment_dissatisfied_outlined,
                                'Sin resultados\nPrueba con otro término',
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: Text(
                                      '${_results.length} ${_results.length == 1 ? 'resultado' : 'resultados'}',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      itemCount: _results.length,
                                      itemBuilder: (_, i) =>
                                          _QuoteResultTile(
                                        quote: _results[i],
                                        onFavoriteToggled: _toggleFavorite,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Tile individual de resultado ─────────────────────────────────────────────

class _QuoteResultTile extends StatelessWidget {
  final Quote quote;
  final void Function(Quote) onFavoriteToggled;

  const _QuoteResultTile({
    required this.quote,
    required this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  quote.category,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => onFavoriteToggled(quote),
                child: Icon(
                  quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: quote.isFavorite
                      ? AppColors.favorite
                      : AppColors.textTertiary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quote.text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(height: 1.5),
          ),
          if (quote.author != null) ...[
            const SizedBox(height: 6),
            Text(
              '— ${quote.author}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
