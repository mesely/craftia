'use client';

import React from 'react';

export default function SkeletonCard() {
  return (
    <div className="relative bg-white/20 backdrop-blur-md border border-white/30 p-6 rounded-[45px] shadow-sm animate-pulse">
      {/* Üst Kısım: Avatar ve İsim */}
      <div className="flex items-start justify-between mb-6">
        <div className="flex items-center gap-4">
          {/* Avatar Skeleton */}
          <div className="w-16 h-16 bg-white/40 rounded-[26px]" />
          <div className="space-y-2">
            {/* İsim Satırı */}
            <div className="w-32 h-4 bg-white/40 rounded-full" />
            {/* Puan Satırı */}
            <div className="w-20 h-3 bg-white/30 rounded-full" />
          </div>
        </div>
        {/* KM Pill Skeleton */}
        <div className="w-16 h-8 bg-white/40 rounded-full" />
      </div>

      {/* Etiketler */}
      <div className="flex gap-2 mb-8 ml-1">
        <div className="w-20 h-6 bg-white/30 rounded-lg" />
        <div className="w-24 h-6 bg-white/30 rounded-lg" />
      </div>

      {/* Butonlar */}
      <div className="flex gap-3">
        <div className="flex-[1.2] h-14 bg-white/40 rounded-[28px]" />
        <div className="flex-1 h-14 bg-white/30 rounded-[28px]" />
      </div>
    </div>
  );
}