<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Store;
use App\Models\Category;
use App\Models\Product;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use App\Models\CurrencyMarketListing;
use App\Models\Challenge;
use App\Models\UserChallenge;
use App\Models\Article;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Delivery;
use App\Models\SystemSetting;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call(CouponSeeder::class);

        // 1. Create Default Core Users
        $admin = User::create([
            'name' => 'Aria Thorne (Admin)',
            'email' => 'admin@earthshop.test',
            'password' => Hash::make('password'),
            'role' => 'admin',
            'phone' => '+1 (555) 019-2831',
            'avatar' => 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
            'status' => 'active',
        ]);

        $sellerUser = User::create([
            'name' => 'Kaito Takahashi',
            'email' => 'seller@earthshop.test',
            'password' => Hash::make('password'),
            'role' => 'seller',
            'phone' => '+1 (555) 014-9922',
            'avatar' => 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
            'status' => 'active',
        ]);

        $customer = User::create([
            'name' => 'Elena Vance',
            'email' => 'customer@earthshop.test',
            'password' => Hash::make('password'),
            'role' => 'customer',
            'phone' => '+1 (555) 018-7711',
            'avatar' => 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
            'status' => 'active',
        ]);

        $driver = User::create([
            'name' => 'Liam Vance (Courier)',
            'email' => 'driver@earthshop.test',
            'password' => Hash::make('password'),
            'role' => 'delivery',
            'phone' => '+1 (555) 012-4433',
            'avatar' => 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
            'status' => 'active',
        ]);

        // 2. Create Wallets
        $customerWallet = Wallet::create([
            'user_id' => $customer->id,
            'fiat_balance' => 480.00,
            'token_balance' => 250.00,
        ]);

        $sellerWallet = Wallet::create([
            'user_id' => $sellerUser->id,
            'fiat_balance' => 1820.00,
            'token_balance' => 1240.00,
        ]);

        $driverWallet = Wallet::create([
            'user_id' => $driver->id,
            'fiat_balance' => 140.00,
            'token_balance' => 85.00,
        ]);

        Wallet::create([
            'user_id' => $admin->id,
            'fiat_balance' => 15400.00,
            'token_balance' => 25000.00,
        ]);

        // 3. Create Categories
        $catCeramics = Category::create([
            'name' => 'Ceramics & Stoneware',
            'slug' => 'ceramics',
            'icon' => '🏺',
            'description' => 'Hand-thrown earthen clay vessels, glazed with natural wood-ash and mineral pigments.',
        ]);

        $catPantry = Category::create([
            'name' => 'Wild Pantry',
            'slug' => 'wild-pantry',
            'icon' => '🍯',
            'description' => 'Raw foraged honey, mountain herbs, and small-batch preserves from certified biodynamic growers.',
        ]);

        $catTextiles = Category::create([
            'name' => 'Heritage Textiles',
            'slug' => 'textiles',
            'icon' => '🧵',
            'description' => 'Organic stone-washed linens and handloom wool dyed with plant barks and indigo.',
        ]);

        $catWoodcraft = Category::create([
            'name' => 'Artisan Woodcraft',
            'slug' => 'woodcraft',
            'icon' => '🪵',
            'description' => 'Sustainable joinery and culinary implements carved from naturally fallen orchard timbers.',
        ]);

        // 4. Create Stores
        $storeKaito = Store::create([
            'user_id' => $sellerUser->id,
            'name' => 'Kaito Pottery Co.',
            'slug' => 'kaito-pottery',
            'tagline' => 'Hand-thrown riverbed terracotta and wood-fired tableware',
            'description' => 'Master artisan studio rooted in ancient Japanese reduction firing techniques using raw wild clay.',
            'craft_category' => 'Ceramics & Stoneware',
            'rating' => 4.95,
            'total_sales' => 142,
            'is_verified' => true,
            'status' => 'active',
        ]);

        $storeWildwood = Store::create([
            'user_id' => $admin->id,
            'name' => 'Wildwood Apiary',
            'slug' => 'wildwood-apiary',
            'tagline' => 'Cold-extracted raw wildflower honey & alpine botanicals',
            'description' => 'Dedicated to wild bee conservation and high-elevation biodynamic flora.',
            'craft_category' => 'Wild Pantry',
            'rating' => 5.00,
            'total_sales' => 89,
            'is_verified' => true,
            'status' => 'active',
        ]);

        // 5. Create Products
        $p1 = Product::create([
            'store_id' => $storeKaito->id,
            'category_id' => $catCeramics->id,
            'name' => 'Handmade Terracotta Pour-Over Vessel',
            'slug' => 'terracotta-pour-over',
            'description' => 'Wheel-thrown raw terracotta brewer with natural unglazed exterior and food-safe matte interior glaze.',
            'price_fiat' => 42.00,
            'price_tokens' => 33.60,
            'stock' => 18,
            'image' => 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=700&q=80',
            'material_provenance' => '100% Wild Riverbed Clay • Fired with fallen orchard wood',
            'rating' => 4.90,
            'is_featured' => true,
            'gender' => 'female',
            'status' => 'active',
        ]);

        $p2 = Product::create([
            'store_id' => $storeWildwood->id,
            'category_id' => $catPantry->id,
            'name' => 'Organic Forest Honey & Meadow Herbs',
            'slug' => 'organic-forest-honey',
            'description' => 'Cold-extracted wildflower raw honey infused with lavender and dried mountain thyme.',
            'price_fiat' => 24.50,
            'price_tokens' => 19.60,
            'stock' => 25,
            'image' => 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&w=700&q=80',
            'material_provenance' => 'Unpasteurized wildflower comb from organic alpine meadows',
            'rating' => 5.00,
            'is_featured' => true,
            'gender' => 'female',
            'status' => 'active',
        ]);

        $p3 = Product::create([
            'store_id' => $storeKaito->id,
            'category_id' => $catTextiles->id,
            'name' => 'Stone-Washed Organic Linen Throw',
            'slug' => 'organic-linen-throw',
            'description' => '100% French flax linen woven on heritage looms, garment-dyed with natural indigo and oak bark.',
            'price_fiat' => 88.00,
            'price_tokens' => 70.40,
            'stock' => 9,
            'image' => 'https://images.unsplash.com/photo-1606744888344-493238955036?auto=format&fit=crop&w=700&q=80',
            'material_provenance' => 'GOTS Certified organic flax • Natural botanical dyes',
            'rating' => 4.85,
            'is_featured' => true,
            'gender' => 'male',
            'status' => 'active',
        ]);

        $p4 = Product::create([
            'store_id' => $storeKaito->id,
            'category_id' => $catWoodcraft->id,
            'name' => 'Hand-Carved Walnut Spoon Set',
            'slug' => 'carved-walnut-spoon-set',
            'description' => 'Set of three kitchen spoons carved from sustainably fallen walnut trees and finished with organic walnut oil.',
            'price_fiat' => 34.00,
            'price_tokens' => 27.20,
            'stock' => 14,
            'image' => 'https://images.unsplash.com/photo-1546554137-f86b9593a222?auto=format&fit=crop&w=700&q=80',
            'material_provenance' => 'Salvaged American Black Walnut • Cold-pressed walnut oil polish',
            'rating' => 4.90,
            'is_featured' => true,
            'gender' => 'male',
            'status' => 'active',
        ]);

        // Men Boutique Products
        Product::create([
            'store_id' => $storeKaito->id,
            'category_id' => $catTextiles->id,
            'name' => 'درێشی شەمەندەفەری کۆتان - Men Trench Coat',
            'slug' => 'men-cotton-trench-coat',
            'description' => 'درێشی کۆتانی ساکتی، فەرشی نەرم، گەرم و ئارام. بۆ وەرزی سەرما زۆر گونجاوە و ستایلی مۆدێرنی هەیە.',
            'price_fiat' => 78.00,
            'price_tokens' => 62.40,
            'stock' => 20,
            'image' => 'https://images.unsplash.com/photo-1544441893-675973e31985?auto=format&fit=crop&w=700&q=80',
            'material_provenance' => '100% Cotton Heritage Looms',
            'rating' => 4.80,
            'is_featured' => true,
            'gender' => 'male',
            'status' => 'active',
        ]);

        Product::create([
            'store_id' => $storeWildwood->id,
            'category_id' => $catWoodcraft->id,
            'name' => 'پێڵاوی کەشی هایکەرتۆن - Men Leather Boots',
            'slug' => 'men-hiking-leather-boots',
            'description' => 'پێڵاویەکی ساکت و شیک بۆ ڕێکردن، بەرزی مامناوەندی و ڕەنگی ساکت. گونجاوە بۆ ڕۆژانە و گەشت.',
            'price_fiat' => 85.00,
            'price_tokens' => 68.00,
            'stock' => 15,
            'image' => 'https://images.unsplash.com/photo-1520639888713-7851133b1ed0?auto=format&fit=crop&w=700&q=80',
            'material_provenance' => 'Natural Full-grain Leather',
            'rating' => 4.70,
            'is_featured' => true,
            'gender' => 'male',
            'status' => 'active',
        ]);

        Product::create([
            'store_id' => $storeKaito->id,
            'category_id' => $catTextiles->id,
            'name' => 'کراسی فەرمی پیاوان - Men Classic Oxford Shirt',
            'slug' => 'men-classic-oxford-shirt',
            'description' => 'کراسی ئۆکسفۆردی فەرمی، قوماشی نەرم و کوالیتی بەرز بۆ کار و بۆنە تایبەتەکان.',
            'price_fiat' => 45.00,
            'price_tokens' => 36.00,
            'stock' => 30,
            'image' => 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?auto=format&fit=crop&w=700&q=80',
            'material_provenance' => 'Organic Egyptian Cotton',
            'rating' => 4.90,
            'is_featured' => true,
            'gender' => 'male',
            'status' => 'active',
        ]);

        // Women Boutique Products
        Product::create([
            'store_id' => $storeKaito->id,
            'category_id' => $catTextiles->id,
            'name' => 'جانتای شێل کلاسیک - Classic Shell Bag',
            'slug' => 'classic-shell-leather-bag',
            'description' => 'جانتایەکی شێلی دەستی بە چەرمی سروشتی، گونجاوە بۆ هەموو دەرفەتێکی ڕۆژانە و ئێوارەییەکان.',
            'price_fiat' => 65.00,
            'price_tokens' => 52.00,
            'stock' => 12,
            'image' => 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=700&q=80',
            'material_provenance' => 'Handcrafted Natural Leather',
            'rating' => 4.90,
            'is_featured' => true,
            'gender' => 'female',
            'status' => 'active',
        ]);

        Product::create([
            'store_id' => $storeWildwood->id,
            'category_id' => $catPantry->id,
            'name' => 'کرێمی ئارای زەری - Rose Facial Cream',
            'slug' => 'rose-facial-cream',
            'description' => 'کرێمی ئارای ڕووی زەری بۆ ڕۆژانە، بۆیەکی درێژخایەن و ڕەنگێکی سروشتی. بۆ هەموو جۆرە پێست.',
            'price_fiat' => 28.00,
            'price_tokens' => 22.40,
            'stock' => 40,
            'image' => 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=700&q=80',
            'material_provenance' => 'Mountain Botanical Extracts',
            'rating' => 4.60,
            'is_featured' => true,
            'gender' => 'female',
            'status' => 'active',
        ]);

        Product::create([
            'store_id' => $storeKaito->id,
            'category_id' => $catCeramics->id,
            'name' => 'گوارەی زێڕین ئەکسسواری - Gold Stud Earrings',
            'slug' => 'gold-stud-earrings',
            'description' => 'گوارەیەکی ناسک بە کۆدی ڕەنگی زێرین، تەواوکەری جلوبەرگی ڕۆژانە و ئێوارەییە.',
            'price_fiat' => 38.00,
            'price_tokens' => 30.40,
            'stock' => 25,
            'image' => 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?auto=format&fit=crop&w=700&q=80',
            'material_provenance' => '18k Gold Plated Artisan Alloy',
            'rating' => 4.50,
            'is_featured' => true,
            'gender' => 'female',
            'status' => 'active',
        ]);

        // 6. Create Articles ("articashin")
        Article::create([
            'author_id' => $admin->id,
            'title' => 'Articashin: The Future of Circular Token Economies in Craft Guilds',
            'slug' => 'articashin-circular-token-economy',
            'category' => 'Ecosystem Economy',
            'read_time' => '4 min read',
            'summary' => 'Discover how regional artisans are leveraging Terra tokens to establish resilient, low-fee exchange markets and reward eco-conscious packaging.',
            'content' => 'The intersection of traditional craftsmanship and decentralized barter networks has given rise to the **Articashin** standard. In our marketplace, every transaction is backed by certified sustainable practices.<br><br>By transacting in Terra tokens, customers receive instant 5% staking rebates, while sellers bypass legacy interchange fees. This creates an authentic closed-loop economy where value stays directly within the artisan ecosystem.',
            'cover_image' => 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=800&q=80',
            'is_published' => true,
            'published_at' => now(),
        ]);

        Article::create([
            'author_id' => $sellerUser->id,
            'title' => 'Clay, Fire & Soil: Tracing the Mineral Origins of Terra Ceramics',
            'slug' => 'clay-fire-soil-origins',
            'category' => 'Artisan Stories',
            'read_time' => '6 min read',
            'summary' => 'A photo essay inside the studio of master potter Kaito, hand-digging wild terracotta clay from riverbeds to craft timeless culinary vessels.',
            'content' => 'Every vessel carries the signature of its geological provenance. Studio Kaito utilizes wood-fired kilns sustained by fallen orchard timber. When you purchase via EarthShop, the carbon offset is directly registered on your profile ledger.',
            'cover_image' => 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?auto=format&fit=crop&w=800&q=80',
            'is_published' => true,
            'published_at' => now()->subDay(),
        ]);

        Article::create([
            'author_id' => $driver->id,
            'title' => 'Zero-Emission Delivery: How Local Hubs Coordinate Last-Mile Drops',
            'slug' => 'zero-emission-delivery-hubs',
            'category' => 'Logistics & Ecology',
            'read_time' => '3 min read',
            'summary' => 'Behind the scenes with our electric cargo fleet and algorithmic route bundling that minimizes transit times while honoring artisan pickup windows.',
            'content' => 'Our delivery partners operate on dynamic clustering nodes. Once a seller prepares an order, nearby couriers receive real-time notifications with optimal pickup windows and optimized battery-friendly routes.',
            'cover_image' => 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?auto=format&fit=crop&w=800&q=80',
            'is_published' => true,
            'published_at' => now()->subDays(2),
        ]);

        // 7. Create Challenges
        $c1 = Challenge::create([
            'title' => 'Green Pioneer',
            'description' => 'Complete your first artisan order with 100% plastic-free packaging.',
            'icon' => '🌱',
            'target_count' => 1,
            'reward_tokens' => 15.00,
            'category' => 'eco',
        ]);

        $c2 = Challenge::create([
            'title' => 'Currency Trader',
            'description' => 'Trade at least 50 Terra tokens in the peer-to-peer Currency Market.',
            'icon' => '🪙',
            'target_count' => 50,
            'reward_tokens' => 25.00,
            'category' => 'market',
        ]);

        $c3 = Challenge::create([
            'title' => 'Patron of Guilds',
            'description' => 'Support 3 distinct artisan workshops across different craft categories.',
            'icon' => '🏺',
            'target_count' => 3,
            'reward_tokens' => 40.00,
            'category' => 'social',
        ]);

        UserChallenge::create([
            'user_id' => $customer->id,
            'challenge_id' => $c1->id,
            'progress' => 1,
            'status' => 'completed',
        ]);

        UserChallenge::create([
            'user_id' => $customer->id,
            'challenge_id' => $c2->id,
            'progress' => 35,
            'status' => 'in_progress',
        ]);

        UserChallenge::create([
            'user_id' => $customer->id,
            'challenge_id' => $c3->id,
            'progress' => 2,
            'status' => 'in_progress',
        ]);

        // 8. Currency Market Listings
        CurrencyMarketListing::create([
            'user_id' => $sellerUser->id,
            'type' => 'sell',
            'token_amount' => 150.00,
            'rate_fiat' => 1.26,
            'status' => 'open',
        ]);

        CurrencyMarketListing::create([
            'user_id' => $customer->id,
            'type' => 'buy',
            'token_amount' => 200.00,
            'rate_fiat' => 1.24,
            'status' => 'open',
        ]);

        // 9. Orders & Deliveries
        $order1 = Order::create([
            'order_number' => 'ORD-9481',
            'customer_id' => $customer->id,
            'store_id' => $storeKaito->id,
            'total_fiat' => 42.00,
            'total_tokens' => 33.60,
            'payment_method' => 'split',
            'status' => 'ready_for_pickup',
            'shipping_address' => '88 Pinecrest Ave, Apt 3',
            'shipping_lat' => 37.7833000,
            'shipping_lng' => -122.4167000,
        ]);

        OrderItem::create([
            'order_id' => $order1->id,
            'product_id' => $p1->id,
            'quantity' => 1,
            'unit_fiat' => 42.00,
            'unit_tokens' => 33.60,
            'total_fiat' => 42.00,
        ]);

        Delivery::create([
            'order_id' => $order1->id,
            'driver_id' => $driver->id,
            'status' => 'ready_for_pickup',
            'pickup_store_name' => 'Kaito Pottery Co.',
            'pickup_address' => '42 Artisan Lane, Studio 4B',
            'estimated_pickup_time' => '11:15 AM (In 15m)',
            'customer_name' => 'Elena Vance',
            'dropoff_address' => '88 Pinecrest Ave, Apt 3',
            'estimated_delivery_time' => '11:45 AM',
            'distance' => '2.4 miles',
            'estimated_payout' => '$9.50 + 4 TERRA',
            'pickup_lat' => 37.7749000,
            'pickup_lng' => -122.4194000,
            'dropoff_lat' => 37.7833000,
            'dropoff_lng' => -122.4167000,
            'current_lat' => 37.7710000,
            'current_lng' => -122.4210000,
            'waypoints' => [
                ['lat' => 37.7710, 'lng' => -122.4210, 'label' => 'Courier'],
                ['lat' => 37.7749, 'lng' => -122.4194, 'label' => 'Pickup: Kaito Pottery'],
                ['lat' => 37.7833, 'lng' => -122.4167, 'label' => 'Dropoff: Elena Vance']
            ],
        ]);

        // 10. System Settings
        SystemSetting::create(['key' => 'token_exchange_rate', 'value' => '1.25', 'group' => 'currency_market']);
        SystemSetting::create(['key' => 'platform_fee_percent', 'value' => '0.0', 'group' => 'currency_market']);
        SystemSetting::create(['key' => 'delivery_base_fee', 'value' => '4.50', 'group' => 'logistics']);
        SystemSetting::create(['key' => 'courier_payout_per_delivery', 'value' => '4.50', 'group' => 'logistics']);
        SystemSetting::create(['key' => 'eco_bonus_token_rate', 'value' => '2.0', 'group' => 'gamification']);
    }
}
