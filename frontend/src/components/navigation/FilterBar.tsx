'use client';

import React from 'react';
import { Star, MapPinArea, Funnel } from '@phosphor-icons/react';

interface FilterBarProps {
  activeFilter: string;
  onFilterChange: (id: string) => void;
  onOpenAdvanced: () => void;
}

export default function FilterBar({ activeFilter, onFilterChange, onOpenAdvanced }: FilterBarProps) {
  const filters = [
    { id: 'NEARBY', label: 'En Yakın', icon: <MapPinArea size={16} weight="duotone" /> },
    { id: 'RATING', label: 'En Yüksek Puan', icon: <Star size={16} weight="duotone" /> },
  ];

  return (
    <div className="w-full px-4 py-3 flex items-center justify-between gap-3 overflow-x-auto no-scrollbar relative z-[30]">
      <div className="flex items-center gap-2 shrink-0">
        {filters.map((filter) => (
          <button
            key={filter.id}
            onClick={() => onFilterChange(filter.id)}
            className={`flex items-center gap-1.5 px-4 py-2.5 rounded-full border transition-all duration-300 whitespace-nowrap text-[10px] font-black uppercase tracking-tighter shadow-sm ${
              activeFilter === filter.id
                ? 'bg-slate-900 text-white border-slate-900 shadow-md scale-105'
                : 'bg-white/40 backdrop-blur-md border-white/50 text-slate-700 hover:bg-white/60'
            }`}
          >
            {filter.icon}
            {filter.label}
          </button>
        ))}
      </div>

      <button 
        onClick={onOpenAdvanced}
        className="flex items-center justify-center p-2.5 rounded-2xl bg-white/40 backdrop-blur-md border border-white/50 text-slate-700 hover:bg-white/60 transition-all active:scale-90 shadow-sm shrink-0"
      >
        <Funnel size={18} weight="bold" />
      </button>
    </div>
  );
}