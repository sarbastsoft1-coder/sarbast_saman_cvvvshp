<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Coupon;

class CouponSeeder extends Seeder
{
    public function run(): void
    {
        $coupons = [
            [
                'code' => 'WELCOME10',
                'type' => 'percent',
                'value' => 10,
                'min_spend' => 0,
                'expires_at' => now()->addMonths(3),
            ],
            [
                'code' => 'SAVE25',
                'type' => 'fixed',
                'value' => 25,
                'min_spend' => 100,
                'expires_at' => now()->addMonths(1),
            ],
            [
                'code' => 'FREESHIP',
                'type' => 'free_shipping',
                'value' => 0,
                'min_spend' => 20,
                'expires_at' => now()->addMonths(2),
            ],
            [
                'code' => 'EXPIRED',
                'type' => 'percent',
                'value' => 50,
                'min_spend' => 0,
                'expires_at' => now()->subDay(),
            ],
        ];

        foreach ($coupons as $coupon) {
            Coupon::updateOrCreate(['code' => $coupon['code']], $coupon);
        }
    }
}
