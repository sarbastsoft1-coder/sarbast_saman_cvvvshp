<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

/**
 * Stores seller product photos / video on the public disk and returns
 * relative paths (resolved to absolute URLs by the Product model).
 */
class ProductMediaService
{
    public const MAX_IMAGES = 5;

    public static function storeImage(UploadedFile $file): string
    {
        return $file->store('products/images', 'public');
    }

    public static function storeVideo(UploadedFile $file): string
    {
        return $file->store('products/videos', 'public');
    }

    /** Turn a stored path or external URL into a browser-ready absolute URL. */
    public static function absoluteUrl(?string $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }
        if (str_starts_with($value, 'http://') || str_starts_with($value, 'https://')) {
            return $value;
        }
        $path = ltrim($value, '/');
        if (str_starts_with($path, 'storage/')) {
            $path = substr($path, strlen('storage/'));
        }

        return rtrim(config('app.url'), '/') . '/storage/' . $path;
    }

    /** @param  list<string|null>  $items */
    public static function absoluteList(array $items): array
    {
        return array_values(array_filter(array_map(
            fn ($item) => self::absoluteUrl(is_string($item) ? $item : null),
            $items,
        )));
    }
}
