<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MoodComment extends Model
{
    use HasFactory;

    protected $fillable = [
        'mood_id',
        'user_id',
        'content',
        'parent_id',
    ];

    public function mood(): BelongsTo
    {
        return $this->belongsTo(Mood::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function parent(): BelongsTo
    {
        return $this->belongsTo(MoodComment::class, 'parent_id');
    }

    public function children(): HasMany
    {
        return $this->hasMany(MoodComment::class, 'parent_id');
    }
}