<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Support\Str;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'bio',
        'avatar_url',
        'is_admin',
        'account_id',
        'gender',
        'gender_public',
        'region',
        'region_public',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'is_admin' => 'boolean',
        'gender_public' => 'boolean',
        'region_public' => 'boolean',
    ];

    protected static function boot()
    {
        parent::boot();
        static::creating(function (User $user) {
            if (empty($user->account_id)) {
                $user->account_id = self::generateNumericAccountId(16);
            }
        });
    }

    protected static function generateNumericAccountId(int $length = 16): string
    {
        do {
            $id = '';
            for ($i = 0; $i < $length; $i++) {
                $id .= random_int(0, 9);
            }
        } while (self::query()->where('account_id', $id)->exists());
        return $id;
    }

    // Ensure avatar_url is absolute when serialized
    public function getAvatarUrlAttribute($value)
    {
        if (!$value) return null;
        // Prefer the current request host (includes port), fallback to APP_URL or url('/')
        $requestHost = null;
        try {
            $requestHost = request()->getSchemeAndHttpHost();
        } catch (\Throwable $e) {
            $requestHost = null;
        }
        $base = ($requestHost ?: config('app.url')) ?: rtrim(url('/'), '/');

        // Normalize any storage-based avatar path to CORS-safe streaming route
        $storagePrefix = '/storage/avatars/';
        if (Str::contains($value, $storagePrefix)) {
            // Extract the relative portion after '/storage/'
            $relative = ltrim(Str::after($value, '/storage/'), '/'); // avatars/xxx.jpg
            return rtrim($base, '/') . '/avatar/' . $relative;
        }

        // If already absolute and not storage path, return as-is
        if (Str::startsWith($value, ['http://', 'https://'])) {
            return $value;
        }

        // Otherwise, treat as relative and convert to absolute
        return rtrim($base, '/') . $value;
    }
}
