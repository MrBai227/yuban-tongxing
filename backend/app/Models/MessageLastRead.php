<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MessageLastRead extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'reactions_last_read_at',
        'follows_last_read_at',
        'comments_last_read_at',
    ];
}