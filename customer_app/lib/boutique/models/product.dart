import '../core/constants/money.dart';
import '../core/shop_department.dart';
import 'package:flutter/material.dart';

/// Product model used across the boutique customer app.
class BoutiqueProduct {
  final int id;
  final String name;
  final double price;
  final double? oldPrice;
  final String currency;
  final String? imageUrl;
  /// Up to five product photos (absolute URLs).
  final List<String> galleryUrls;
  /// Optional product video (absolute URL).
  final String? videoUrl;
  final String category;
  final String description;
  final String seller;
  final double rating;
  final int reviews;
  final String emoji;
  /// Flat illustration key (`pan`, `scarf`, `dress`, …) matching the HTML mock.
  final String art;
  final Color accent;
  final List<String> availableSizes;
  final List<Color> availableColors;
  final ShopAudience audience;

  const BoutiqueProduct({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice,
    this.currency = 'IQD',
    this.imageUrl,
    this.galleryUrls = const [],
    this.videoUrl,
    required this.category,
    required this.description,
    required this.seller,
    required this.rating,
    required this.reviews,
    required this.emoji,
    this.art = 'pan',
    required this.accent,
    this.availableSizes = const ['S', 'M', 'L'],
    this.availableColors = const [
      Color(0xFFDCAE96),
      Color(0xFF333333),
      Color(0xFFF5F5DC),
    ],
    this.audience = ShopAudience.unisex,
  });

  /// The product title split into its Kurdish and Latin halves.
  ///
  /// Seed titles mix both scripts — "دریشی شەمەندەفڕی کۆڵان - Men Trench
  /// Coat". Rendered as a single run, the bidi algorithm reorders the two
  /// halves and a two-line truncation cuts the Latin word in half, which reads
  /// as a broken title. Splitting them lets a card show a clean Kurdish title
  /// with the Latin name as a quiet second line.
  (String, String?) get nameParts {
    for (final separator in const [' - ', ' – ', ' — ']) {
      final index = name.indexOf(separator);
      if (index > 0) {
        return (
          name.substring(0, index).trim(),
          name.substring(index + separator.length).trim(),
        );
      }
    }
    return (name, null);
  }

  /// Formats a monetary amount in this product's currency.
  ///
  /// Routed through [Money] so a price looks identical on the card, the detail
  /// screen, the cart and the order summary.
  String formatAmount(num value) =>
      Money.format(value, currency: currency);

  factory BoutiqueProduct.fromApi(Map<String, dynamic> json) {
    final original = (json['price_fiat'] as num).toDouble();
    final sale = (json['sale_price_fiat'] as num?)?.toDouble() ?? original;
    final category = json['category'];
    final gallery = <String>[];
    final rawGallery = json['gallery'];
    if (rawGallery is List) {
      for (final item in rawGallery) {
        final url = item?.toString() ?? '';
        if (url.isNotEmpty) gallery.add(url);
      }
    }
    final video = json['video']?.toString();
    return BoutiqueProduct(
      id: json['id'] as int,
      name: json['name'] as String,
      price: sale,
      oldPrice: sale < original ? original : null,
      currency: 'USD',
      imageUrl: json['image'] as String?,
      galleryUrls: gallery,
      videoUrl: (video == null || video.isEmpty) ? null : video,
      category: category is Map
          ? category['name']?.toString() ?? 'بەرهەم'
          : category?.toString() ?? 'بەرهەم',
      description: json['description']?.toString() ?? '',
      seller: json['store']?['name']?.toString() ?? '',
      rating: double.tryParse('${json['rating']}') ?? 0,
      reviews: 0,
      emoji: '🛍️',
      art: 'bag',
      accent: const Color(0xFFDCAE96),
      availableSizes: const [],
      availableColors: const [],
      audience: ShopAudienceX.parse(
        json['gender'] ?? json['audience'],
        category: category is Map
            ? category['name']?.toString()
            : category?.toString(),
        name: json['name'] as String?,
        id: json['id'] as int?,
      ),
    );
  }

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'oldPrice': oldPrice,
    'currency': currency,
    'imageUrl': imageUrl,
    'galleryUrls': galleryUrls,
    'videoUrl': videoUrl,
    'category': category,
    'description': description,
    'seller': seller,
    'rating': rating,
    'reviews': reviews,
    'emoji': emoji,
    'art': art,
    'accent': accent.toARGB32(),
    'sizes': availableSizes,
    'colors': availableColors.map((c) => c.toARGB32()).toList(),
    'audience': audience.apiValue,
  };

  factory BoutiqueProduct.fromJson(Map<String, dynamic> json) =>
      BoutiqueProduct(
        id: json['id'] as int,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        oldPrice: (json['oldPrice'] as num?)?.toDouble(),
        currency: json['currency'] as String? ?? 'IQD',
        imageUrl: json['imageUrl'] as String?,
        galleryUrls: (json['galleryUrls'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [],
        videoUrl: json['videoUrl'] as String?,
        category: json['category'] as String,
        description: json['description'] as String,
        seller: json['seller'] as String,
        rating: (json['rating'] as num).toDouble(),
        reviews: json['reviews'] as int,
        emoji: json['emoji'] as String,
        art: json['art'] as String? ?? 'pan',
        accent: Color(json['accent'] as int),
        availableSizes: (json['sizes'] as List).cast<String>(),
        availableColors: (json['colors'] as List)
            .map((c) => Color(c as int))
            .toList(),
        audience: ShopAudienceX.parse(
          json['audience'] ?? json['gender'],
          category: json['category'] as String?,
          name: json['name'] as String?,
          id: json['id'] as int?,
        ),
      );

  int get discountPercent {
    if (!hasDiscount) return 0;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }

  /// A short single-line summary for cards and reels overlays.
  String get shortDescription {
    if (description.length <= 60) return description;
    return '${description.substring(0, 60)}…';
  }
}

/// Demo catalog aligned to the Claude customer HTML (IQD prices, Kurdish names).
final List<BoutiqueProduct> sampleProducts = [
  BoutiqueProduct(
    id: 1,
    name: 'سیتی تاوەی گرانیت، ٣ پارچە',
    price: 35000,
    category: 'ماڵ و چێشتخانە',
    description:
        'تاوەی گرانیت بە ٣ قەبارە: ٢٤، ٢٨ و ٣٢ سم. دەستکی دار. بۆ هەموو جۆرە ئاگرێک. گەرەنتی ٦ مانگ لە فرۆشیارەوە.',
    seller: 'ماڵی ئاسۆ',
    rating: 4.8,
    reviews: 32,
    emoji: '🥘',
    art: 'pan',
    accent: Color(0xFF4A5059),
    availableSizes: ['٢٤ سم', '٢٨ سم', '٣٢ سم'],
    availableColors: [Color(0xFF2B2F36), Color(0xFF4A5059)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 2,
    name: 'لەچکی ئاوریشم',
    price: 15000,
    category: 'جلوبەرگ',
    description: 'لەچکی ئاوریشمی نەرم، چوار ڕەنگ، گونجاو بۆ ڕۆژانە و بۆنە.',
    seller: 'بووتیکی ڕۆژ',
    rating: 4.6,
    reviews: 48,
    emoji: '🧣',
    art: 'scarf',
    accent: Color(0xFF8E5BD0),
    availableSizes: const [],
    availableColors: [
      Color(0xFFC8263A),
      Color(0xFF2B4C8C),
      Color(0xFFD9B46A),
      Color(0xFF2E6B4A),
    ],
    audience: ShopAudience.female,
  ),
  BoutiqueProduct(
    id: 3,
    name: 'کراسی ژنانەی دەستدروو',
    price: 90000,
    category: 'جلوبەرگ',
    description:
        'کراسی کوردیی دەستدوورمان، قوماشی کرێپ، لەگەڵ کەوای هاوڕەنگ. دوورمانی ماڵەوە لە هەولێر.',
    seller: 'دەستکردی شیلان',
    rating: 4.9,
    reviews: 67,
    emoji: '👗',
    art: 'dress',
    accent: Color(0xFFD63447),
    availableSizes: ['S', 'M', 'L', 'XL'],
    availableColors: [Color(0xFFC8263A), Color(0xFF2B4C8C)],
    audience: ShopAudience.female,
  ),
  BoutiqueProduct(
    id: 4,
    name: 'کەتڵی ستێل، ١٫٥ لیتر',
    price: 8000,
    category: 'ماڵ و چێشتخانە',
    description: 'کەتڵی ستێلی ١٫٥ لیتر، گونجاو بۆ چێشتخانەی ماڵەوە.',
    seller: 'بازاڕی ماڵەوە',
    rating: 4.5,
    reviews: 21,
    emoji: '🫖',
    art: 'kettle',
    accent: Color(0xFFC9D1D8),
    availableSizes: const [],
    availableColors: [Color(0xFFC9D1D8)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 5,
    name: 'سۆبەی کارەبایی بچووک',
    price: 45000,
    category: 'ماڵ و چێشتخانە',
    description: 'سۆبەی کارەبایی بچووک بۆ ژوور، گەرمکردنەوەی خێرا.',
    seller: 'ئەلیکترۆنی هەولێر',
    rating: 4.4,
    reviews: 19,
    emoji: '🔌',
    art: 'heater',
    accent: Color(0xFFFF7006),
    availableSizes: const [],
    availableColors: [Color(0xFFE9EBEE)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 6,
    name: 'بەتانیی خوری دەستچن',
    price: 65000,
    category: 'دەستکرد',
    description: 'بەتانیی خوری دەستچن، گەرم و نەرم بۆ زستان.',
    seller: 'دەستکردی ژیان',
    rating: 4.7,
    reviews: 28,
    emoji: '🧶',
    art: 'blanket',
    accent: Color(0xFFB83A3A),
    availableSizes: const [],
    availableColors: [Color(0xFFB83A3A), Color(0xFF2F5D8C)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 7,
    name: 'تاوەی ڕەشی ٢٨ سم',
    price: 18000,
    category: 'ماڵ و چێشتخانە',
    description: 'تاوەی ڕەشی ٢٨ سم، دەستکی دار، بۆ هەموو جۆرە ئاگرێک.',
    seller: 'ماڵی ئاسۆ',
    rating: 4.6,
    reviews: 14,
    emoji: '🍳',
    art: 'pan',
    accent: Color(0xFF2B2F36),
    availableSizes: ['٢٨ سم'],
    availableColors: [Color(0xFF2B2F36)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 8,
    name: 'تاوەی گرانیت ٢٤ سم',
    price: 14000,
    category: 'ماڵ و چێشتخانە',
    description: 'تاوەی گرانیت ٢٤ سم، قەبارەی بچووک بۆ خێزانی بچووک.',
    seller: 'بازاڕی ماڵەوە',
    rating: 4.3,
    reviews: 11,
    emoji: '🥘',
    art: 'pan',
    accent: Color(0xFF4A5059),
    availableSizes: ['٢٤ سم'],
    availableColors: [Color(0xFF4A5059)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 9,
    name: 'جانتای دەستچن',
    price: 35000,
    oldPrice: 42000,
    category: 'پێڵاو و جانتا',
    description: 'جانتای دەستچنی شین، گونجاو بۆ ڕۆژانە.',
    seller: 'بووتیکی ڕۆژ',
    rating: 4.5,
    reviews: 22,
    emoji: '👜',
    art: 'bag',
    accent: Color(0xFF2F7DE1),
    availableSizes: const [],
    availableColors: [Color(0xFF2F7DE1), Color(0xFF1F5FB8)],
    audience: ShopAudience.female,
  ),
  BoutiqueProduct(
    id: 10,
    name: 'کراسی منداڵان',
    price: 30000,
    category: 'منداڵان',
    description: 'کراسی منداڵان، قەبارەی ٤ ساڵ، قوماشی نەرم.',
    seller: 'دەستکردی شیلان',
    rating: 4.8,
    reviews: 16,
    emoji: '🧸',
    art: 'kid',
    accent: Color(0xFFFF8FB1),
    availableSizes: ['٢ ساڵ', '٤ ساڵ', '٦ ساڵ'],
    availableColors: [Color(0xFFFF8FB1), Color(0xFFF8D91A)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 11,
    name: 'جلی کوردیی پیاوانە',
    price: 120000,
    category: 'جلوبەرگ',
    description: 'جلی کوردیی پیاوانە، قەبارە L، دوورمانی دەست.',
    seller: 'بووتیکی ڕۆژ',
    rating: 4.9,
    reviews: 41,
    emoji: '🧥',
    art: 'vest',
    accent: Color(0xFF7A5A3A),
    availableSizes: ['M', 'L', 'XL'],
    availableColors: [Color(0xFFD9C8AC), Color(0xFF7A5A3A)],
    audience: ShopAudience.male,
  ),
  BoutiqueProduct(
    id: 12,
    name: 'سوخمەی کوردی',
    price: 45000,
    category: 'جلوبەرگ',
    description: 'سوخمەی کوردی دەستدوور، قوماشی نەرم.',
    seller: 'دەستکردی ژیان',
    rating: 4.4,
    reviews: 9,
    emoji: '👘',
    art: 'vest',
    accent: Color(0xFFD9C8AC),
    availableSizes: ['S', 'M', 'L'],
    availableColors: [Color(0xFFD9C8AC)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 13,
    name: 'صابوونی سروشتی زەیتوون',
    price: 6000,
    category: 'جوانکاری',
    description: 'صابوونی سروشتی زەیتوون، بێ بۆنی دەستی.',
    seller: 'بازاڕی ماڵەوە',
    rating: 4.7,
    reviews: 55,
    emoji: '🧼',
    art: 'soap',
    accent: Color(0xFF8DB255),
    availableSizes: const [],
    availableColors: [Color(0xFF8DB255)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 14,
    name: 'پێڵاوی کەشی ڕۆژانە',
    price: 55000,
    oldPrice: 68000,
    category: 'پێڵاو و جانتا',
    description: 'پێڵاوی کەشی شیک بۆ ڕۆژانە، قەبارە ٣٦ تا ٤٠.',
    seller: 'پێڵاوی شیرین',
    rating: 4.6,
    reviews: 33,
    emoji: '👟',
    art: 'shoe',
    accent: Color(0xFF8A6A45),
    availableSizes: ['٣٦', '٣٧', '٣٨', '٣٩', '٤٠'],
    availableColors: [Color(0xFFF6F0E4), Color(0xFF8A6A45)],
    audience: ShopAudience.female,
  ),
  BoutiqueProduct(
    id: 15,
    name: 'هەنگوینی سروشتی، ٧٥٠ گرام',
    price: 22000,
    category: 'خۆراک',
    description: 'هەنگوینی سروشتی شاخەکان، بێ شەکر زیادە.',
    seller: 'بازاڕی سروشت',
    rating: 4.9,
    reviews: 74,
    emoji: '🍯',
    art: 'jar',
    accent: Color(0xFFE6B35A),
    availableSizes: const [],
    availableColors: [Color(0xFFE6B35A)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 16,
    name: 'لەچکی مۆر بۆنە',
    price: 18000,
    category: 'جلوبەرگ',
    description: 'لەچکی ئاوریشمی مۆر، گونجاو بۆ بۆنە و میوانداری.',
    seller: 'بووتیکی ڕۆژ',
    rating: 4.7,
    reviews: 29,
    emoji: '🧣',
    art: 'scarf',
    accent: Color(0xFF8E5BD0),
    availableSizes: const [],
    availableColors: [Color(0xFF8E5BD0), Color(0xFF7A45C2)],
    audience: ShopAudience.female,
  ),
  BoutiqueProduct(
    id: 17,
    name: 'کراسی سووری دەستدوور',
    price: 85000,
    oldPrice: 98000,
    category: 'جلوبەرگ',
    description: 'کراسی سووری کوردی، قوماشی کرێپ، دوورمانی دەست.',
    seller: 'دەستکردی شیلان',
    rating: 4.8,
    reviews: 38,
    emoji: '👗',
    art: 'dress',
    accent: Color(0xFFD63447),
    availableSizes: ['S', 'M', 'L'],
    availableColors: [Color(0xFFD63447)],
    audience: ShopAudience.female,
  ),
  BoutiqueProduct(
    id: 18,
    name: 'جانتای شینی ڕۆژانە',
    price: 28000,
    category: 'پێڵاو و جانتا',
    description: 'جانتای شین بە قەفەسی زەرد، سووک و بەهێز.',
    seller: 'پێڵاوی شیرین',
    rating: 4.5,
    reviews: 17,
    emoji: '👜',
    art: 'bag',
    accent: Color(0xFF2F7DE1),
    availableSizes: const [],
    availableColors: [Color(0xFF2F7DE1)],
    audience: ShopAudience.female,
  ),
  BoutiqueProduct(
    id: 19,
    name: 'کراسی منداڵان — ٦ ساڵ',
    price: 32000,
    category: 'منداڵان',
    description: 'کراسی پەمەیی منداڵان، قەبارەی ٦ ساڵ.',
    seller: 'دەستکردی شیلان',
    rating: 4.6,
    reviews: 12,
    emoji: '🧸',
    art: 'kid',
    accent: Color(0xFFFF8FB1),
    availableSizes: ['٤ ساڵ', '٦ ساڵ', '٨ ساڵ'],
    availableColors: [Color(0xFFFF8FB1)],
    audience: ShopAudience.unisex,
  ),
  BoutiqueProduct(
    id: 20,
    name: 'کەتڵی گەورە، ٢ لیتر',
    price: 12000,
    category: 'ماڵ و چێشتخانە',
    description: 'کەتڵی ستێلی ٢ لیتر بۆ خێزانی گەورە.',
    seller: 'ماڵی ئاسۆ',
    rating: 4.4,
    reviews: 8,
    emoji: '🫖',
    art: 'kettle',
    accent: Color(0xFFC9D1D8),
    availableSizes: const [],
    availableColors: [Color(0xFFC9D1D8)],
    audience: ShopAudience.unisex,
  ),
];
