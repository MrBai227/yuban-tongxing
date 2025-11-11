<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('account_id')->nullable()->unique();
            $table->string('gender')->nullable();
            $table->boolean('gender_public')->default(false);
            $table->string('region')->nullable();
            $table->boolean('region_public')->default(false);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['account_id', 'gender', 'gender_public', 'region', 'region_public']);
        });
    }
};