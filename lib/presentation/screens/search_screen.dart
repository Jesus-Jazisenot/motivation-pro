import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/quote_api_service.dart';
import '../../core/services/translation_service.dart';
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

  // Resultados locales
  List<Quote> _localResults = [];
  bool _isLoadingLocal = false;
  bool _hasSearched = false;

  // Resultados de API
  List<Quote> _apiResults = [];
  bool _isLoadingApi = false;
  int _apiPage = 1;
  bool _hasMoreApi = true;
  bool _apiSearched = false;

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
      _isLoadingLocal = true;
      _hasSearched = true;
      _apiResults = [];
      _apiSearched = false;
      _apiPage = 1;
      _hasMoreApi = true;
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

      if (mounted) setState(() => _localResults = results);
    } finally {
      if (mounted) setState(() => _isLoadingLocal = false);
    }
  }

  Future<void> _searchOnline() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final hasInternet = await ConnectivityService.instance.hasConnectionLight();
    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Sin conexión a internet'),
          backgroundColor: AppColors.warning,
        ));
      }
      return;
    }

    setState(() {
      _isLoadingApi = true;
      _apiSearched = true;
    });

    try {
      final apiQuotes = await QuoteApiService.instance
          .searchQuotesByText(query, page: _apiPage);

      if (apiQuotes.isEmpty) {
        setState(() => _hasMoreApi = false);
        return;
      }

      // Traducir y guardar en BD las que no existan ya
      final newQuotes = <Quote>[];
      for (final aq in apiQuotes) {
        try {
          String text = aq.text;
          // Traducir si parece inglés (palabras cortas en inglés)
          if (!_looksSpanish(text)) {
            final translated =
                await TranslationService.instance.translateToSpanish(text);
            if (translated != text) text = translated;
          }

          final quote = Quote(
            text: text,
            author: aq.author,
            category: aq.category,
            source: 'api-search',
            language: text == aq.text ? 'en' : 'es',
            lastShown: null,
            viewCount: 0,
          );

          // Guardar en BD si no existe
          final existing =
              await DatabaseHelper.instance.searchQuotes(aq.text);
          if (existing.isEmpty) {
            final id = await DatabaseHelper.instance.insertQuote(quote);
            newQuotes.add(quote.copyWith(id: id));
          } else {
            newQuotes.add(existing.first);
          }
        } catch (_) {}
      }

      setState(() {
        _apiResults.addAll(newQuotes);
        _apiPage++;
        if (apiQuotes.length < 20) _hasMoreApi = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error buscando en internet: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoadingApi = false);
    }
  }

  bool _looksSpanish(String text) {
    final spanishWords = {
      'el', 'la', 'los', 'las', 'de', 'que', 'es', 'en', 'y', 'a',
      'por', 'con', 'para', 'mi', 'tu', 'su', 'más', 'ser', 'hay',
      'todo', 'como', 'pero', 'muy', 'hacer', 'vida', 'no', 'si',
    };
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final matches = words.where(spanishWords.contains).length;
    return matches > words.length * 0.25;
  }

  Future<void> _toggleFavorite(Quote quote, {bool isApi = false}) async {
    final updated = quote.copyWith(isFavorite: !quote.isFavorite);
    await DatabaseHelper.instance.updateQuote(updated);
    setState(() {
      if (isApi) {
        final i = _apiResults.indexWhere((q) => q.id == quote.id);
        if (i != -1) _apiResults[i] = updated;
      } else {
        final i = _localResults.indexWhere((q) => q.id == quote.id);
        if (i != -1) _localResults[i] = updated;
      }
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
              // Header + controles
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
                          hintStyle:
                              TextStyle(color: AppColors.textTertiary),
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
                            _categoryChip(null, 'Todas'),
                            ..._categories
                                .map((c) => _categoryChip(c, c)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Botones de búsqueda
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _search,
                            icon: const Icon(Icons.storage_outlined, size: 16),
                            label: const Text('Buscar local'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _searchController.text.trim().isEmpty ||
                                        _isLoadingApi
                                    ? null
                                    : _searchOnline,
                            icon: _isLoadingApi
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.public, size: 16),
                            label: const Text('Buscar online'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Resultados
              Expanded(
                child: _isLoadingLocal
                    ? Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                    : !_hasSearched
                        ? _emptyState(
                            Icons.search,
                            'Busca frases por texto, autor\no filtra por categoría',
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            children: [
                              // --- Resultados locales ---
                              if (_localResults.isNotEmpty) ...[
                                _sectionHeader(
                                    '${_localResults.length} resultado${_localResults.length == 1 ? '' : 's'} guardados'),
                                ..._localResults.map((q) => _QuoteResultTile(
                                      quote: q,
                                      onFavoriteToggled: (q) =>
                                          _toggleFavorite(q),
                                    )),
                              ] else if (_hasSearched) ...[
                                _emptyState(
                                  Icons.inbox_outlined,
                                  'Sin resultados locales.\nPrueba "Buscar online" para encontrar más.',
                                ),
                              ],

                              // --- Resultados de API ---
                              if (_apiSearched) ...[
                                const SizedBox(height: 16),
                                _sectionHeader('Resultados de internet'),
                                if (_apiResults.isEmpty && !_isLoadingApi)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Center(
                                      child: Text(
                                        'Sin resultados online para ese término',
                                        style: TextStyle(
                                            color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                ..._apiResults.map((q) => _QuoteResultTile(
                                      quote: q,
                                      onFavoriteToggled: (q) =>
                                          _toggleFavorite(q, isApi: true),
                                    )),
                                if (_isLoadingApi)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.accent),
                                    ),
                                  ),
                                if (_apiResults.isNotEmpty &&
                                    _hasMoreApi &&
                                    !_isLoadingApi)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    child: Center(
                                      child: OutlinedButton.icon(
                                        onPressed: _searchOnline,
                                        icon: const Icon(Icons.add),
                                        label: const Text(
                                            'Cargar más resultados'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.accent,
                                          side: BorderSide(
                                              color: AppColors.accent),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],

                              const SizedBox(height: 24),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String? value, String label) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() =>
              _selectedCategory = selected ? null : value);
          if (_hasSearched) _search();
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppColors.surface,
        side: BorderSide(color: AppColors.border),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _emptyState(IconData icon, String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 52, color: AppColors.textTertiary),
            const SizedBox(height: 14),
            Text(
              message,
              style:
                  TextStyle(color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

// ─── Tile de resultado ────────────────────────────────────────────────────────

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
