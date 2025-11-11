<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('practice_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->unsignedInteger('duration_seconds')->default(0);
            $table->unsignedInteger('soft_onset_seconds')->default(0);
            $table->unsignedInteger('prolonged_seconds')->default(0);
            $table->unsignedInteger('reading_seconds')->default(0);
            $table->string('note')->nullable();
            $table->timestamps();

            $table->index('user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('practice_logs');
    }
};