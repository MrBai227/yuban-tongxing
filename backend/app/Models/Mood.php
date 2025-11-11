<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Mood extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'content',
        'is_anonymous',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(MoodComment::class);
    }

    public function likes(): HasMany
    {
        return $this->hasMany(MoodLike::class);
    }

    public function views(): HasMany
    {
        return $this->hasMany(MoodView::class);
    }
}