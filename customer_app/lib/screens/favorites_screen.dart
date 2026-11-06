import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../utils/animations.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../widgets/glass_container.dart';
import '../models/models.dart';
import 'main_shell.dart';
import 'cart_screen.dart';
import '../utils/responsive.dart';

class FavoritesScreen extends StatefulWidget {
  final AppState appState;

  const FavoritesScreen({super.key, required this.appState});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isLoading = true;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    try {
      final res = await ApiService.get('/favorites');
      if (res['status'] == 'success') {
        final List data = res['data'];
        final products = data.map((p) => Product(
              id: p['id'],
              name: p['name'],
              seller: p['store']?['name'] ?? 'Store',
              price: ((p['sale_price_fiat'] ?? p['price_fiat']) as num).toDouble(),
              emoji: p['emoji'] ?? '📦',
              category: p['category'] ?? 'other',
              description: p['description'] ?? '',
              rating: (p['rating'] as num?)?.toDouble() ?? 4.5,
              reviews: (p['reviews_count'] as num?)?.toInt() ?? 0,
            )).toList();

        setState(() => _products = products);
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EarthTheme.warmSand,
      appBar: AppBar(
        backgroundColor: EarthTheme.warmSand,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const Text(
              'Favorites',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: EarthTheme.forestGreen,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            if (_products.isNotEmpty)
              PillBadge(
                label: '${_products.length}',
                color: EarthTheme.danger,
                textColor: Colors.white,
                icon: Icons.favorite_rounded,
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: EarthTheme.terracotta),
            )
          : _products.isEmpty
              ? _buildEmpty()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            Responsive.getGridCrossAxisCount(context),
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, i) {
                        final p = _products[i];
                        return StaggeredItem(
                          index: i,
                          child: ProductCard(
                            product: p,
                            isFavorite:
                                widget.appState.favorites.contains(p.id),
                            terraRate: widget.appState.terraRate,
                            onToggleFav: () async {
                              await widget.appState.toggleFavorite(p.id);
                              _fetchFavorites();
                            },
                            onAddToCart: () {
                              widget.appState.addToCart(p);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Text('🛒',
                                          style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                            '${p.name} added to cart!'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                          Navigator.of(context).push(
                                            SharedAxisPageRoute(
                                              builder: (_) => CartScreen(
                                                  appState: widget.appState),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'VIEW',
                                          style: TextStyle(
                                            color: EarthTheme.goldenGlow,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            onTap: () {},
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFBEAE6), Color(0xFFF9F7F2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: EarthTheme.danger.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text('💚', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No favorites yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: EarthTheme.forestGreen,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the heart on any product to save it here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: EarthTheme.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
