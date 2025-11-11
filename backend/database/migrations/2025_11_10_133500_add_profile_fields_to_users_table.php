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
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'account_id')) {
                $table->string('account_id')->nullable()->unique();
            }
            if (!Schema::hasColumn('users', 'gender')) {
                $table->string('gender')->nullable();
            }
            if (!Schema::hasColumn('users', 'gender_public')) {
                $table->boolean('gender_public')->default(false);
            }
            if (!Schema::hasColumn('users', 'region')) {
                $table->string('region')->nullable();
            }
            if (!Schema::hasColumn('users', 'region_public')) {
                $table->boolean('region_public')->default(false);
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'account_id')) {
                $table->dropColumn('account_id');
            }
            if (Schema::hasColumn('users', 'gender')) {
                $table->dropColumn('gender');
            }
            if (Schema::hasColumn('users', 'gender_public')) {
                $table->dropColumn('gender_public');
            }
            if (Schema::hasColumn('users', 'region')) {
                $table->dropColumn('region');
            }
            if (Schema::hasColumn('users', 'region_public')) {
                $table->dropColumn('region_public');
            }
        });
    }
};