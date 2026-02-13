'use client';

import React from 'react';
import { ArrowsDownUp, Star, MapPinArea, Funnel } from '@phosphor-icons/react';
import { motion } from 'framer-motion';

interface FilterBarProps {
  activeFilter: string;
  onFilterChange: (id: string) => void;
  onOpenAdvanced: () => void;
}

export default function FilterBar({ activeFilter, onFilterChange, onOpenAdvanced }: FilterBarProps) {
  const filters = [
    { id: 'NEARBY', label: 'En Yakın', icon: <MapPinArea size={18} /> },
    { id: 'RATING', label: 'En Yüksek Puan', icon: <Star size={18} /> },
  ];

  return (
    <div className="w-full py-4 flex items-center justify-between gap-3 overflow-x-auto no-scrollbar">
      <div className="flex items-center gap-2">
        {filters.map((filter) => (
          <button
            key={filter.id}
            onClick={() => onFilterChange(filter.id)}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-full border transition-all duration-300 whitespace-nowrap text-xs font-bold uppercase tracking-tight ${
              activeFilter === filter.id
                ? 'bg-slate-900 text-white border-slate-900 shadow-lg'
                : 'bg-white/30 backdrop-blur-md border-white/40 text-slate-700 hover:bg-white/50'
            }`}
          >
            {filter.icon}
            {filter.label}
          </button>
        ))}
      </div>

      {/* Gelişmiş Filtreleme Butonu */}
      <button 
        onClick={onOpenAdvanced}
        className="flex items-center justify-center p-2.5 rounded-full bg-white/30 backdrop-blur-md border border-white/40 text-slate-700 hover:bg-white/50 transition-all active:scale-90"
      >
        <Funnel size={20} weight="bold" />
      </button>
    </div>
  );
}