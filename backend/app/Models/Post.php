<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'title',
        'body',
        'category_key',
    ];

    public function likes()
    {
        return $this->hasMany(\App\Models\PostLike::class);
    }

    public function favorites()
    {
        return $this->hasMany(\App\Models\PostFavorite::class);
    }

    public function comments()
    {
        return $this->hasMany(\App\Models\PostComment::class);
    }

    public function views()
    {
        return $this->hasMany(\App\Models\PostView::class);
    }

    public function user()
    {
        return $this->belongsTo(\App\Models\User::class);
    }
}