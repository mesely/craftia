'use client';

import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  X, SlidersHorizontal, CaretDown, MapPin 
} from '@phosphor-icons/react';
import { useCategory } from '@/context/CategoryContext';

interface AdvancedFiltersProps {
  currentFilters: {
    city: string;
    subType: string;
    sortMode: string;
    distance: number;
  };
  onFilterChange: (newFilters: any) => void;
}

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', accent: 'bg-blue-600', border: 'border-blue-200' },
  CONSTRUCTION: { main: 'text-purple-600', accent: 'bg-purple-600', border: 'border-purple-200' },
  TECH: { main: 'text-indigo-600', accent: 'bg-indigo-600', border: 'border-indigo-200' },
  LIFE: { main: 'text-emerald-600', accent: 'bg-emerald-600', border: 'border-emerald-200' }
};

const SUBTYPE_MAP: any = {
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
      <div className="w-full bg-white/5 backdrop-blur-3xl border-b border-white/10 flex flex-col gap-2.5 py-3">
        
        {/* 1. ÜST SATIR: İL + SIRALAMA + AYAR */}
        <div className="w-full px-4 flex items-center gap-2 overflow-hidden">
          
          {/* Şehir Seçimi */}
          <div className="flex items-center gap-1 bg-white/20 border border-white/30 pl-2 pr-1.5 h-[38px] rounded-[16px] shrink-0 shadow-sm">
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
          <div className="flex bg-slate-800/10 rounded-[16px] p-0.5 h-[38px] w-[110px] relative shrink-0">
            <motion.div 
              className={`absolute top-0.5 bottom-0.5 rounded-[14px] shadow-sm ${theme.accent}`}
              animate={{ x: currentFilters.sortMode === 'nearest' ? '0%' : '100%' }}
              style={{ width: '48%' }}
            />
            <button 
              onClick={() => onFilterChange({ sortMode: 'nearest' })} 
              className={`relative z-10 w-1/2 flex items-center justify-center text-[9px] font-black uppercase transition-colors ${currentFilters.sortMode === 'nearest' ? 'text-white' : 'text-slate-500'}`}
            >
               Yakın
            </button>
            <button 
              onClick={() => onFilterChange({ sortMode: 'rating' })} 
              className={`relative z-10 w-1/2 flex items-center justify-center text-[9px] font-black uppercase transition-colors ${currentFilters.sortMode === 'rating' ? 'text-white' : 'text-slate-500'}`}
            >
               Puan
            </button>
          </div>

          {/* Gelişmiş Filtre İkonu (DİNAMİK YAPILDI) */}
          <button 
            onClick={() => setIsModalOpen(true)}
            className={`h-[38px] w-[38px] rounded-[16px] ${theme.accent} text-white flex items-center justify-center shadow-lg active:scale-95 transition-transform shrink-0 ml-auto`}
          >
            <SlidersHorizontal size={18} weight="bold" />
          </button>
        </div>

        {/* 2. ALT SATIR: KATEGORİLER */}
        <div className="w-full px-4 flex items-center gap-2 overflow-x-auto no-scrollbar pb-1">
          {subtypes.map((sub: any) => (
            <button 
              key={sub.value}
              onClick={() => onFilterChange({ subType: sub.value })}
              className={`px-5 h-[36px] rounded-full text-[10px] font-black uppercase whitespace-nowrap transition-all border shrink-0 ${
                currentFilters.subType === sub.value 
                ? `${theme.accent} text-white border-transparent shadow-md scale-105` 
                : 'bg-white/20 text-slate-600 border-white/30 hover:bg-white/40'
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
          <div className="fixed inset-0 z-[9999] flex items-center justify-center px-4">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setIsModalOpen(false)} className="absolute inset-0 bg-slate-900/60 backdrop-blur-md" />
            <motion.div initial={{ opacity: 0, scale: 0.9, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.9, y: 20 }} className="relative w-full max-w-sm bg-white/95 backdrop-blur-3xl rounded-[40px] p-8 shadow-2xl">
              <div className="flex justify-between items-center mb-8">
                <h3 className="text-xl font-black text-slate-800 uppercase tracking-tight">Kriterler</h3>
                <button onClick={() => setIsModalOpen(false)} className="p-2 bg-slate-100 rounded-full text-slate-400"><X size={20} weight="bold"/></button>
              </div>
              <div className="space-y-10">
                <div className="space-y-5">
                  <div className="flex justify-between text-[11px] font-black text-slate-500 uppercase">
                    <span>Arama Mesafesi</span>
                    <span className={`px-3 py-1 rounded-lg text-white ${theme.accent}`}>{currentFilters.distance} KM</span>
                  </div>
                  <input type="range" min="1" max="50" value={currentFilters.distance} onChange={(e) => onFilterChange({ distance: parseInt(e.target.value) })} className="w-full h-1.5 bg-slate-200 rounded-full appearance-none cursor-pointer accent-slate-800" />
                </div>
                <button onClick={() => setIsModalOpen(false)} className={`w-full py-5 rounded-[25px] text-white font-black text-sm uppercase tracking-widest shadow-2xl transition-all active:scale-95 ${theme.accent}`}>Uygula</button>
              </div>
            </motion.div>
          </div>,
          document.body
        )}
      </AnimatePresence>
    </>
  );
}