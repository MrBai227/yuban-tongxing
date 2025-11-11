<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('mood_likes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mood_id')->constrained('moods')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['mood_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mood_likes');
    }
};