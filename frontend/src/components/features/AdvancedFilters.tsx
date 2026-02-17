'use client';

import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Star, MapPin, X, SlidersHorizontal, SortAscending, 
  CaretDown, Funnel 
} from '@phosphor-icons/react';
import { useCategory } from '@/context/CategoryContext';

// ✅ TypeScript Arabirimi: page.tsx'den gelen verileri karşılar
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

// SADECE VERİTABANINDA OLAN ANA VE ALT KATEGORİLER
const SUBTYPE_MAP: any = {
  TECHNICAL: [
    { label: "Tümü", value: "all" },
    { label: "Elektrikçi", value: "elektrikçi" },
    { label: "Su Tesisatçısı", value: "su tesisatçısı" },
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
      <div className="w-full bg-white/10 backdrop-blur-3xl border-b border-white/10 shadow-sm py-3 overflow-hidden">
        {/* TEK SATIR KONTEYNER: Yatay kaydırma aktif, alt satıra geçmez */}
        <div className="max-w-7xl mx-auto px-4 flex items-center gap-3 overflow-x-auto no-scrollbar flex-nowrap">
          
          {/* 1. Hızlı İl Seçimi */}
          <div className="flex items-center gap-1.5 bg-white/20 border border-white/30 px-3 h-[42px] rounded-[18px] shrink-0">
            <MapPin size={16} weight="fill" className={theme.main} />
            <select 
              value={currentFilters.city}
              onChange={(e) => onFilterChange({ city: e.target.value })}
              className="bg-transparent text-[11px] font-black text-slate-700 uppercase outline-none cursor-pointer appearance-none"
            >
              {CITIES.map(city => <option key={city} value={city} className="text-slate-800">{city}</option>)}
            </select>
            <CaretDown size={10} weight="bold" className="text-slate-400" />
          </div>

          {/* 2. Sıralama Switcher */}
          <div className="flex bg-slate-800/10 rounded-[18px] p-0.5 h-[42px] w-[130px] relative shrink-0">
            <motion.div 
              className={`absolute top-0.5 bottom-0.5 rounded-[16px] shadow-sm ${theme.accent}`}
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

          {/* 3. Dikey Ayraç */}
          <div className="w-[1px] h-6 bg-white/20 shrink-0 mx-1" />

          {/* 4. Alt Kategoriler (Yatay Çipler) */}
          <div className="flex items-center gap-2 flex-nowrap shrink-0">
            {subtypes.map((sub: any) => (
              <button 
                key={sub.value}
                onClick={() => onFilterChange({ subType: sub.value })}
                className={`px-4 h-[38px] rounded-full text-[10px] font-black uppercase whitespace-nowrap transition-all border shrink-0 ${
                  currentFilters.subType === sub.value 
                  ? `${theme.accent} text-white border-transparent shadow-md` 
                  : 'bg-white/20 text-slate-500 border-white/30 hover:bg-white/40'
                }`}
              >
                {sub.label}
              </button>
            ))}
          </div>

          {/* 5. Gelişmiş Filtre Butonu (En Sağda) */}
          <button 
            onClick={() => setIsModalOpen(true)}
            className="h-[42px] w-[42px] rounded-[18px] bg-slate-800 text-white flex items-center justify-center shadow-lg shrink-0 ml-auto"
          >
            <SlidersHorizontal size={18} weight="bold" />
          </button>
        </div>
      </div>

      {/* --- MODAL (Gelişmiş Kriterler) --- */}
      <AnimatePresence>
        {isModalOpen && createPortal(
          <div className="fixed inset-0 z-[9999] flex items-center justify-center px-4">
            <motion.div 
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} 
              onClick={() => setIsModalOpen(false)} 
              className="absolute inset-0 bg-slate-900/40 backdrop-blur-md" 
            />
            <motion.div 
              initial={{ opacity: 0, scale: 0.9, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.9, y: 20 }} 
              className="relative w-full max-w-sm bg-white/90 backdrop-blur-2xl rounded-[40px] p-8 shadow-2xl"
            >
              <div className="flex justify-between items-center mb-8">
                <h3 className="text-xl font-black text-slate-800 uppercase tracking-tight">Kriterler</h3>
                <button onClick={() => setIsModalOpen(false)} className="p-2 bg-slate-100 rounded-full text-slate-400">
                  <X size={20} weight="bold"/>
                </button>
              </div>

              <div className="space-y-8">
                {/* Mesafe Slider */}
                <div className="space-y-4">
                  <div className="flex justify-between text-[10px] font-black text-slate-500 uppercase">
                    <span>Arama Mesafesi</span>
                    <span className={theme.main}>{currentFilters.distance} KM</span>
                  </div>
                  <input 
                    type="range" min="1" max="50" 
                    value={currentFilters.distance} 
                    onChange={(e) => onFilterChange({ distance: parseInt(e.target.value) })} 
                    className="w-full accent-slate-800 h-1 bg-slate-100 rounded-full appearance-none cursor-pointer" 
                  />
                </div>

                <button 
                  onClick={() => setIsModalOpen(false)} 
                  className={`w-full py-5 rounded-[25px] text-white font-black text-xs uppercase tracking-widest shadow-xl transition-all active:scale-95 ${theme.accent}`}
                >
                  Filtreleri Uygula
                </button>
              </div>
            </motion.div>
          </div>,
          document.body
        )}
      </AnimatePresence>
    </>
  );
}