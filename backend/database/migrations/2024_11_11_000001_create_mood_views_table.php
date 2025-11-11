<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('mood_views', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('mood_id');
            $table->unsignedBigInteger('user_id')->nullable();
            $table->timestamps();

            $table->foreign('mood_id')->references('id')->on('moods')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('set null');
            $table->unique(['mood_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mood_views');
    }
};