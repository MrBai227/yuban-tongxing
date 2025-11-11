<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PracticeLog extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'duration_seconds',
        'soft_onset_seconds',
        'prolonged_seconds',
        'reading_seconds',
        'note',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}