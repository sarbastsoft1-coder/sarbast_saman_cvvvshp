// Data models for the EarthShop Customer App

class Product {
  final int id;
  final String name;
  final double price;
  final String category;
  final String emoji;
  final String seller;
  final String description;
  final double rating;
  final int reviews;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.emoji,
    required this.seller,
    required this.description,
    required this.rating,
    required this.reviews,
  });

  double terraPrice(double rate) => price / rate;
}

class Article {
  final int id;
  final String title;
  final String author;
  final String readTime;
  final String emoji;
  final String tag;
  final String body;

  const Article({
    required this.id,
    required this.title,
    required this.author,
    required this.readTime,
    required this.emoji,
    required this.tag,
    required this.body,
  });
}

class Challenge {
  final int id;
  final String title;
  final String description;
  final String icon;
  final int reward;
  final double progress; // 0.0 - 1.0
  final int target;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.reward,
    required this.progress,
    required this.target,
  });

  bool get isComplete => progress >= 1.0;
}

class Trade {
  final String type; // 'buy' or 'sell'
  final double amount;
  final double usd;
  final String time;

  const Trade({
    required this.type,
    required this.amount,
    required this.usd,
    required this.time,
  });
}

class CartItem {
  final Product product;
  int qty;

  CartItem({required this.product, this.qty = 1});

  double get totalPrice => product.price * qty;
}

class Category {
  final String id;
  final String name;
  final String icon;

  const Category({required this.id, required this.name, required this.icon});
}

// ─── SAMPLE DATA ───

const List<Category> sampleCategories = [
  Category(id: 'all', name: 'All', icon: '✨'),
  Category(id: 'ceramics', name: 'Ceramics', icon: '🏺'),
  Category(id: 'food', name: 'Food', icon: '🍯'),
  Category(id: 'textiles', name: 'Textiles', icon: '🧣'),
  Category(id: 'tea', name: 'Tea', icon: '🍵'),
  Category(id: 'wood', name: 'Wood', icon: '🪵'),
  Category(id: 'soaps', name: 'Soaps', icon: '🧴'),
  Category(id: 'candles', name: 'Candles', icon: '🕯️'),
];

const List<Product> sampleProducts = [
  Product(
    id: 1,
    name: 'Terracotta Pour-Over Set',
    price: 42.00,
    category: 'ceramics',
    emoji: '🏺',
    seller: 'Artisan Clay Studio',
    description:
        'Hand-turned terracotta dripper with matching mug. Fired in a traditional wood kiln using mineral-rich local clays. Each piece is unique with natural variations.',
    rating: 4.8,
    reviews: 124,
  ),
  Product(
    id: 2,
    name: 'Raw Forest Honey',
    price: 24.50,
    category: 'food',
    emoji: '🍯',
    seller: 'Mountain Harvest Co.',
    description:
        'Unfiltered wildflower honey harvested from ancient forest apiaries. Rich amber with notes of chestnut and heather. 100% raw and unpasteurized.',
    rating: 4.9,
    reviews: 89,
  ),
  Product(
    id: 3,
    name: 'Hand-Woven Linen Scarf',
    price: 36.00,
    category: 'textiles',
    emoji: '🧣',
    seller: 'Verdant Weave',
    description:
        'Naturally dyed linen scarf with indigo botanical patterns. Soft, breathable, and sustainable. Woven on traditional handlooms by skilled artisans.',
    rating: 4.7,
    reviews: 67,
  ),
  Product(
    id: 4,
    name: 'Wild Mountain Tea Blend',
    price: 18.00,
    category: 'tea',
    emoji: '🍵',
    seller: 'TeaLeaf Origins',
    description:
        'Loose-leaf blend of high-altitude chamomile, mint, and lavender. Hand-picked at dawn for peak freshness and aroma.',
    rating: 4.6,
    reviews: 203,
  ),
  Product(
    id: 5,
    name: 'Cedarwood Chopping Board',
    price: 55.00,
    category: 'wood',
    emoji: '🪵',
    seller: 'Timber & Grain',
    description:
        'Solid cedarwood board with natural grain patterns. Treated with organic beeswax for lasting beauty and food safety.',
    rating: 4.9,
    reviews: 45,
  ),
  Product(
    id: 6,
    name: 'Goat Milk Soap Set',
    price: 15.00,
    category: 'soaps',
    emoji: '🧴',
    seller: 'Pastoral Suds',
    description:
        'Set of 3 artisan soaps: lavender, rosemary, and oatmeal. Made with fresh goat milk from pasture-raised herds.',
    rating: 4.5,
    reviews: 156,
  ),
  Product(
    id: 7,
    name: 'Beeswax Candle Trio',
    price: 28.00,
    category: 'candles',
    emoji: '🕯️',
    seller: 'Hive & Hearth',
    description:
        'Pure beeswax candles in 3 sizes. Naturally fragrant, long-burning, and hand-poured in small batches.',
    rating: 4.8,
    reviews: 92,
  ),
  Product(
    id: 8,
    name: 'Stoneware Dinner Plate',
    price: 32.00,
    category: 'ceramics',
    emoji: '🍽️',
    seller: 'Artisan Clay Studio',
    description:
        'Handmade stoneware plate with reactive glaze finish. Microwave and dishwasher safe. Each piece is unique.',
    rating: 4.7,
    reviews: 78,
  ),
];

const List<Article> sampleArticles = [
  Article(
    id: 1,
    title: 'The Future of Circular Token Economies',
    author: 'Eleni Vance',
    readTime: '4 min',
    emoji: '🌍',
    tag: 'Economics',
    body:
        'Circular token economies represent a paradigm shift in how we think about value exchange. By creating closed-loop systems where tokens flow between producers, consumers, and the ecosystem itself, we can reduce waste and incentivize sustainable behavior.\n\nTerra tokens are at the forefront of this movement, enabling direct peer-to-peer trade without traditional financial intermediaries. The result is a more equitable, transparent marketplace where every transaction supports the artisan community.',
  ),
  Article(
    id: 2,
    title: 'Clay, Fire & Soil: Tracing Mineral Origins',
    author: 'Master Potter Kaito',
    readTime: '6 min',
    emoji: '🏺',
    tag: 'Craft',
    body:
        'Every piece of pottery tells the story of the earth it came from. The mineral composition of clay determines its color, texture, and firing properties.\n\nIn our studio, we source clay from three distinct geological formations, each yielding unique characteristics. The red terracotta comes from iron-rich alluvial deposits, while our stoneware uses kaolin from ancient granite decomposition.',
  ),
  Article(
    id: 3,
    title: 'Zero-Waste Artisan Shipping',
    author: 'Eco Logistics Team',
    readTime: '3 min',
    emoji: '📦',
    tag: 'Sustainability',
    body:
        'Our commitment to sustainability extends beyond our products to how we ship them. Every package uses biodegradable materials: mushroom-based foam, recycled paper padding, and plant-based inks.\n\nOur delivery partners use electric vehicles for last-mile delivery, reducing carbon emissions by 78% compared to conventional shipping.',
  ),
];

const List<Challenge> sampleChallenges = [
  Challenge(
    id: 1,
    title: 'Green Pioneer',
    description: 'Make your first eco-certified purchase.',
    icon: '🌱',
    reward: 15,
    progress: 1.0,
    target: 1,
  ),
  Challenge(
    id: 2,
    title: 'Artisan Supporter',
    description: 'Purchase from 3 different artisan stores.',
    icon: '🎨',
    reward: 25,
    progress: 0.66,
    target: 3,
  ),
  Challenge(
    id: 3,
    title: 'Token Trader',
    description: 'Complete 5 token trades on the Terra market.',
    icon: '🪙',
    reward: 30,
    progress: 0.4,
    target: 5,
  ),
  Challenge(
    id: 4,
    title: 'Eco Reviewer',
    description: 'Write 3 honest product reviews.',
    icon: '⭐',
    reward: 20,
    progress: 0.0,
    target: 3,
  ),
  Challenge(
    id: 5,
    title: 'Zero-Waste Hero',
    description: 'Choose plastic-free packaging on 5 orders.',
    icon: '♻️',
    reward: 50,
    progress: 0.2,
    target: 5,
  ),
];

const List<Trade> sampleTrades = [
  Trade(type: 'buy', amount: 50.0, usd: 62.50, time: '14:32'),
  Trade(type: 'sell', amount: 20.0, usd: 25.00, time: '12:15'),
  Trade(type: 'buy', amount: 100.0, usd: 125.00, time: '09:40'),
];

