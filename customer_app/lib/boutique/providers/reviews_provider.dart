import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_store.dart';

import '../core/constants/boutique_constants.dart';
import '../models/product.dart';

/// One submitted customer review.
class BoutiqueReview {
  final String name;
  final double rating;
  final String date;
  final String comment;
  final bool isUserSubmitted;

  const BoutiqueReview({
    required this.name,
    required this.rating,
    required this.date,
    required this.comment,
    this.isUserSubmitted = false,
  });
}

/// Holds reviews grouped by product id. Seeded with the static reviews from
/// [BoutiqueConstants.reviews] so the product details screen stays populated
/// until real data arrives.
class ReviewsProvider extends LocalStoreNotifier {
  final Map<int, List<BoutiqueReview>> _byProduct =
      <int, List<BoutiqueReview>>{};

  ReviewsProvider({SharedPreferences? preferences})
    : super(preferences, 'boutique.reviews.v1') {
    // Seed: attach the first sample review to product id 1 so the demo data
    // flows through the same provider the UI consumes.
    if (sampleProducts.isNotEmpty && BoutiqueConstants.reviews.isNotEmpty) {
      _byProduct[sampleProducts.first.id] = BoutiqueConstants.reviews
          .map(
            (m) => BoutiqueReview(
              name: m['name'] as String,
              rating: (m['rating'] as num).toDouble(),
              date: m['date'] as String,
              comment: m['comment'] as String,
            ),
          )
          .toList();
    }
    final saved = readData();
    if (saved is Map) {
      for (final entry in saved.entries) {
        final id = int.tryParse(entry.key.toString());
        if (id == null || entry.value is! List) continue;
        final restored = <BoutiqueReview>[];
        for (final row in entry.value as List) {
          try {
            restored.add(
              BoutiqueReview(
                name: row['name'] as String,
                rating: (row['rating'] as num).toDouble(),
                date: row['date'] as String,
                comment: row['comment'] as String,
                isUserSubmitted: true,
              ),
            );
          } catch (_) {
            /* Skip damaged review. */
          }
        }
        _byProduct.putIfAbsent(id, () => []).insertAll(0, restored);
      }
    }
  }

  /// All reviews for a product. Returns an empty list when none exist.
  List<BoutiqueReview> forProduct(int productId) {
    return List.unmodifiable(_byProduct[productId] ?? const []);
  }

  /// Average rating for a product, or 0 when no reviews exist.
  double averageFor(int productId) {
    final reviews = _byProduct[productId];
    if (reviews == null || reviews.isEmpty) return 0;
    final total = reviews.fold<double>(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  /// Total review count for a product.
  int countFor(int productId) => _byProduct[productId]?.length ?? 0;

  /// Submit a new review. The newly submitted review is added to the top.
  void submit({
    required int productId,
    required String name,
    required double rating,
    required String comment,
  }) {
    final review = BoutiqueReview(
      name: name.trim().isEmpty ? 'هاوڕێی نەناسراو' : name.trim(),
      rating: rating.clamp(1, 5).toDouble(),
      date: DateTime.now().toIso8601String().substring(0, 10),
      comment: comment.trim(),
      isUserSubmitted: true,
    );
    final list = _byProduct.putIfAbsent(productId, () => <BoutiqueReview>[]);
    list.insert(0, review);
    saveData(
      _byProduct.map(
        (id, rows) => MapEntry(
          id.toString(),
          rows
              .where((r) => r.isUserSubmitted)
              .map(
                (r) => {
                  'name': r.name,
                  'rating': r.rating,
                  'date': r.date,
                  'comment': r.comment,
                },
              )
              .toList(),
        ),
      ),
    );
    notifyListeners();
  }
}
