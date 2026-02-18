'use client';

import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  X, SlidersHorizontal, CaretDown, MapPin 
} from '@phosphor-icons/react';
import { useCategory, CategoryType } from '@/context/CategoryContext';

interface AdvancedFiltersProps {
  currentFilters: {
    city: string;
    subType: string;
    sortMode: string;
    distance: number;
  };
  onFilterChange: (newFilters: any) => void;
}
const THEME_BG: Record<string, string> = {
  TECHNICAL: 'bg-blue-500/10 border-blue-500/20',
  CONSTRUCTION: 'bg-purple-500/10 border-purple-500/20',
  TECH: 'bg-indigo-500/10 border-indigo-500/20',
  LIFE: 'bg-emerald-500/10 border-emerald-500/20',
  CLIMATE: 'bg-orange-500/10 border-orange-500/20',
};

const THEME_MAP: Record<CategoryType, { main: string; accent: string; border: string }> = {
  TECHNICAL: { main: 'text-blue-700', accent: 'bg-blue-600', border: 'border-blue-200' },
  CONSTRUCTION: { main: 'text-purple-700', accent: 'bg-purple-600', border: 'border-purple-200' },
  TECH: { main: 'text-indigo-700', accent: 'bg-indigo-600', border: 'border-indigo-200' },
  LIFE: { main: 'text-emerald-700', accent: 'bg-emerald-600', border: 'border-emerald-200' },
  CLIMATE: { main: 'text-orange-700', accent: 'bg-orange-600', border: 'border-orange-200' }
};

const SUBTYPE_MAP: Record<string, { label: string; value: string }[]> = {
  TECHNICAL: [
    { label: "Tümü", value: "all" },
    { label: "Elektrik", value: "elektrikçi" },
    { label: "Su Tesisat", value: "su tesisatçısı" },
    { label: "Klima & Kombi", value: "klima ve kombi servisi" }
  ],
  CONSTRUCTION: [
    { label: "Tümü", value: "all" },
    { label: "Boyacı", value: "boyacı" },
    { label: "Dekorasyon", value: "dekorasyon" },
    { label: "Marangoz", value: "marangoz" }
  ],
  TECH: [
    { label: "Tümü", value: "all" },
    { label: "Beyaz Eşya", value: "beyaz eşya tamiri" },
    { label: "Elektronik", value: "elektronik tamiri" }
  ],
  LIFE: [
    { label: "Tümü", value: "all" },
    { label: "Ev Temizliği", value: "ev temizliği" }
  ]
};

const CITIES = ["İzmir", "İstanbul", "Ankara", "Adana", "Bursa", "Antalya"];

export default function AdvancedFilters({ currentFilters, onFilterChange }: AdvancedFiltersProps) {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;
  const [mounted, setMounted] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  
  useEffect(() => { setMounted(true); }, []);
  if (!mounted) return null;

  const subtypes = SUBTYPE_MAP[activeCategory] || [{ label: "Tümü", value: "all" }];

  return (
    <>
      {/* 📱 STICKY FIX: Header'ın (60px + Safe Area) bittiği yere milimetrik yapışma */}
     <div className={`sticky top-[calc(60px+env(safe-area-inset-top,0px))] z-[50] w-full ${THEME_BG[activeCategory] || 'bg-white/10'} backdrop-blur-3xl border-b flex flex-col gap-2.5 py-3 shadow-sm transition-all duration-500`}> 
        
        {/* 1. ÜST SATIR: İL + SIRALAMA + AYAR (Giden tabaka burasıydı, artık görünür) */}
        <div className="w-full px-4 flex items-center gap-2 overflow-hidden">
          
          {/* Şehir Seçimi */}
          <div className="flex items-center gap-1 bg-white/40 border border-white/50 pl-2 pr-1.5 h-[38px] rounded-[16px] shrink-0 shadow-sm">
            <MapPin size={16} weight="fill" className={theme.main} />
            <select 
              value={currentFilters.city}
              onChange={(e) => onFilterChange({ city: e.target.value })}
              className="bg-transparent text-[11px] font-black text-slate-800 uppercase outline-none appearance-none cursor-pointer"
            >
              {CITIES.map(city => <option key={city} value={city}>{city}</option>)}
            </select>
            <CaretDown size={10} weight="bold" className="text-slate-400" />
          </div>

          {/* Yakın/Puan Switcher */}
          <div className="flex bg-slate-900/10 rounded-[16px] p-0.5 h-[38px] w-[110px] relative shrink-0">
            <motion.div 
              className={`absolute top-0.5 bottom-0.5 rounded-[14px] shadow-sm ${theme.accent}`}
              animate={{ x: currentFilters.sortMode === 'nearest' ? '0%' : '100%' }}
              style={{ width: '48%' }}
            />
            <button 
              onClick={() => onFilterChange({ sortMode: 'nearest' })} 
              className={`relative z-10 w-1/2 flex items-center justify-center text-[9px] font-black uppercase transition-colors ${currentFilters.sortMode === 'nearest' ? 'text-white' : 'text-slate-600'}`}
            >
               Yakın
            </button>
            <button 
              onClick={() => onFilterChange({ sortMode: 'rating' })} 
              className={`relative z-10 w-1/2 flex items-center justify-center text-[9px] font-black uppercase transition-colors ${currentFilters.sortMode === 'rating' ? 'text-white' : 'text-slate-600'}`}
            >
               Puan
            </button>
          </div>

          {/* Gelişmiş Filtre İkonu */}
          <button 
            onClick={() => setIsModalOpen(true)}
            className={`h-[38px] w-[38px] rounded-[16px] ${theme.accent} text-white flex items-center justify-center shadow-lg active:scale-95 transition-transform shrink-0 ml-auto ring-2 ring-white/20`}
          >
            <SlidersHorizontal size={18} weight="bold" />
          </button>
        </div>

        {/* 2. ALT SATIR: KATEGORİLER */}
        <div className="w-full px-4 flex items-center gap-2 overflow-x-auto no-scrollbar pb-1">
          {subtypes.map((sub) => (
            <button 
              key={sub.value}
              onClick={() => onFilterChange({ subType: sub.value })}
              className={`px-5 h-[36px] rounded-full text-[10px] font-black uppercase whitespace-nowrap transition-all border shrink-0 ${
                currentFilters.subType === sub.value 
                ? `${theme.accent} text-white border-transparent shadow-md scale-105` 
                : 'bg-white/30 text-slate-700 border-white/40 hover:bg-white/50'
              }`}
            >
              {sub.label}
            </button>
          ))}
        </div>

      </div>

      {/* --- MODAL --- */}
      <AnimatePresence>
        {isModalOpen && createPortal(
          <div className="fixed inset-0 z-[100] flex items-center justify-center px-4">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setIsModalOpen(false)} className="absolute inset-0 bg-slate-900/60 backdrop-blur-md" />
            <motion.div initial={{ opacity: 0, scale: 0.9, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.9, y: 20 }} className="relative w-full max-w-sm bg-white/90 backdrop-blur-3xl rounded-[40px] p-8 shadow-2xl border border-white/40">
              <div className="flex justify-between items-center mb-8">
                <h3 className="text-xl font-black text-slate-800 uppercase tracking-tight">Kriterler</h3>
                <button onClick={() => setIsModalOpen(false)} className="p-2 bg-slate-100/50 rounded-full text-slate-500 hover:bg-slate-200"><X size={20} weight="bold"/></button>
              </div>
              <div className="space-y-10">
                <div className="space-y-5">
                  <div className="flex justify-between text-[11px] font-black text-slate-600 uppercase">
                    <span>Arama Mesafesi</span>
                    <span className={`px-3 py-1 rounded-lg text-white ${theme.accent}`}>{currentFilters.distance} KM</span>
                  </div>
                  <input type="range" min="1" max="50" value={currentFilters.distance} onChange={(e) => onFilterChange({ distance: parseInt(e.target.value) })} className="w-full h-2 bg-slate-200 rounded-full appearance-none cursor-pointer accent-slate-800" />
                </div>
                <button onClick={() => setIsModalOpen(false)} className={`w-full py-5 rounded-[25px] text-white font-black text-sm uppercase tracking-widest shadow-2xl transition-all active:scale-95 ${theme.accent} hover:brightness-110`}>Uygula</button>
              </div>
            </motion.div>
          </div>,
          document.body
        )}
      </AnimatePresence>
    </>
  );
}