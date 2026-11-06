<?php

namespace App\Models;

use App\Services\ProductMediaService;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'store_id',
        'category_id',
        'name',
        'slug',
        'description',
        'price_fiat',
        'price_tokens',
        'discount_percent',
        'stock',
        'image',
        'gallery',
        'video',
        'material_provenance',
        'rating',
        'is_featured',
        'gender',
        'status',
    ];

    protected $casts = [
        'discount_percent' => 'integer',
        'gallery' => 'array',
        'is_featured' => 'boolean',
        'price_fiat' => 'float',
        'price_tokens' => 'float',
    ];

    protected $appends = [
        'sale_price_fiat',
        'sale_price_tokens',
        'image_url',
        'video_url',
        'gallery_urls',
    ];

    /** Cover image as an absolute URL (keeps raw `image` path in DB). */
    public function getImageUrlAttribute(): ?string
    {
        return ProductMediaService::absoluteUrl($this->attributes['image'] ?? null);
    }

    public function getVideoUrlAttribute(): ?string
    {
        return ProductMediaService::absoluteUrl($this->attributes['video'] ?? null);
    }

    public function getGalleryUrlsAttribute(): array
    {
        $raw = $this->attributes['gallery'] ?? null;
        if (is_string($raw)) {
            $decoded = json_decode($raw, true);
            $raw = is_array($decoded) ? $decoded : [];
        }
        if (!is_array($raw)) {
            $raw = $this->gallery ?? [];
        }

        return ProductMediaService::absoluteList($raw);
    }

    public function toArray(): array
    {
        $array = parent::toArray();
        // Clients always receive absolute media URLs.
        $array['image'] = $this->image_url;
        $array['video'] = $this->video_url;
        $array['gallery'] = $this->gallery_urls;

        return $array;
    }

    public function getSalePriceFiatAttribute(): float
    {
        return round($this->price_fiat * (100 - $this->discount_percent) / 100, 2);
    }

    public function getSalePriceTokensAttribute(): float
    {
        return round($this->price_tokens * (100 - $this->discount_percent) / 100, 2);
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }
}
