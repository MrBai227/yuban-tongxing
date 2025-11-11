<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MoodLike extends Model
{
    use HasFactory;

    protected $fillable = [
        'mood_id',
        'user_id',
    ];

    public function mood(): BelongsTo
    {
        return $this->belongsTo(Mood::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}