'use client';

import React, { useState, useEffect } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Funnel, Star, MapPin, X, Tag, Check, 
  SlidersHorizontal, SortAscending 
} from '@phosphor-icons/react';
import { useCategory } from '@/context/CategoryContext';

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', accent: 'bg-blue-600', border: 'border-blue-200' },
  CONSTRUCTION: { main: 'text-purple-600', accent: 'bg-purple-600', border: 'border-purple-200' },
  CLIMATE: { main: 'text-orange-600', accent: 'bg-orange-600', border: 'border-orange-200' },
  TECH: { main: 'text-indigo-600', accent: 'bg-indigo-600', border: 'border-indigo-200' },
  LIFE: { main: 'text-emerald-600', accent: 'bg-emerald-600', border: 'border-emerald-200' }
};

const TAGS_LIST = ["Hızlı Servis", "Sertifikalı", "Garantili İşçilik", "7/24 Acil", "Randevulu", "Kurumsal"];

export default function AdvancedFilters() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;
  
  const [mounted, setMounted] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  
  const [filterState, setFilterState] = useState({
    sortMode: 'nearest',
    distance: 10,
    minRating: 4,
    selectedTags: [] as string[]
  });

  useEffect(() => { setMounted(true); }, []);
  
  if (!mounted) return null;

  const toggleTag = (tag: string) => {
    setFilterState(prev => ({
      ...prev,
      selectedTags: prev.selectedTags.includes(tag) 
        ? prev.selectedTags.filter(t => t !== tag) 
        : [...prev.selectedTags, tag]
    }));
  };

  const changeSortMode = (mode: string) => {
    setFilterState(prev => ({ ...prev, sortMode: mode }));
  };

  return (
    <>
      {/* --- FILTER BAR --- 
          Arka plan: bg-white/10 (Şeffaf Cam)
      */}
      <div className="w-full h-[84px] bg-white/10 backdrop-blur-3xl border-b border-white/10 shadow-sm transition-all duration-300">
        <div className="h-full w-full max-w-7xl mx-auto px-4 sm:px-6 flex items-center justify-between gap-4 sm:gap-8">
          
          {/* Sol Yarım: Sıralama */}
          <div className="flex-1 max-w-[320px] h-[56px] bg-white/10 backdrop-blur-md border border-white/20 rounded-[28px] p-1.5 relative flex shadow-inner">
            <motion.div 
              className={`absolute top-1.5 bottom-1.5 rounded-[24px] shadow-md ${theme.accent}`}
              initial={false}
              animate={{
                x: filterState.sortMode === 'nearest' ? '0%' : '100%',
                width: '50%'
              }}
              transition={{ type: "spring", stiffness: 350, damping: 30 }}
            />
            <button 
              onClick={() => changeSortMode('nearest')}
              className={`relative z-10 w-1/2 flex items-center justify-center gap-2 rounded-[24px] transition-colors duration-200 outline-none ${filterState.sortMode === 'nearest' ? 'text-white' : 'text-slate-600 hover:bg-white/10'}`}
            >
              <SortAscending size={20} weight="bold" />
              <span className="text-[11px] font-black uppercase tracking-widest hidden sm:inline">En Yakın</span>
            </button>
            <button 
              onClick={() => changeSortMode('rating')}
              className={`relative z-10 w-1/2 flex items-center justify-center gap-2 rounded-[24px] transition-colors duration-200 outline-none ${filterState.sortMode === 'rating' ? 'text-white' : 'text-slate-600 hover:bg-white/10'}`}
            >
              <Star size={20} weight="bold" />
              <span className="text-[11px] font-black uppercase tracking-widest hidden sm:inline">Puan</span>
            </button>
          </div>

          {/* Sağ Yarım: Gelişmiş Filtre */}
          <div className="flex-1 flex justify-end">
            <button 
              onClick={() => setIsModalOpen(true)}
              className="h-[56px] px-6 sm:px-8 rounded-[28px] bg-white/10 backdrop-blur-md border border-white/20 text-slate-600 hover:bg-white/20 transition-all active:scale-95 flex items-center gap-3 shadow-sm group outline-none relative"
            >
              <span className="text-[11px] font-black uppercase tracking-widest hidden sm:inline text-slate-600">Gelişmiş</span>
              <div className={`p-2 rounded-full bg-white/20 group-hover:bg-white/40 transition-colors ${theme.main}`}>
                <SlidersHorizontal size={22} weight="bold" />
              </div>
              
              {/* ROZET (SAYI) KALDIRILDI - Artık temiz. */}
            </button>
          </div>
        </div>
      </div>

      {/* --- MODAL (PORTAL) --- */}
      {isModalOpen && createPortal(
        <AnimatePresence mode="wait">
          <div className="fixed inset-0 z-[9999] flex items-center justify-center px-4">
            
            {/* Backdrop */}
            <motion.div 
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              onClick={() => setIsModalOpen(false)}
              className="absolute inset-0 bg-slate-900/20 backdrop-blur-sm" 
            />

            {/* Pencere (Glassmorphism Güncellendi) 
                bg-white/15: Çok şeffaf, buzlu cam.
                border-white/20: İnce kenarlık.
            */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }} 
              animate={{ opacity: 1, scale: 1, y: 0 }} 
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              transition={{ type: "spring", damping: 25, stiffness: 300 }}
              className="relative w-full max-w-md bg-white/15 backdrop-blur-3xl border border-white/20 rounded-[40px] shadow-2xl p-8 overflow-hidden"
            >
              <div className="flex justify-between items-center mb-8 pb-4 border-b border-white/10">
                <div className="flex items-center gap-3">
                  <div className={`p-3 rounded-2xl text-white shadow-lg ${theme.accent}`}>
                    <Funnel size={22} weight="duotone" />
                  </div>
                  <div>
                    <h3 className="text-xl font-black text-slate-700 uppercase tracking-tight">Filtrele</h3>
                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Kriter Belirle</span>
                  </div>
                </div>
                <button onClick={() => setIsModalOpen(false)} className="p-2.5 bg-white/10 hover:bg-white/30 rounded-full transition-colors border border-white/20 text-slate-600 outline-none">
                  <X size={20} weight="bold" />
                </button>
              </div>

              {/* İçerik */}
              <div className="space-y-8">
                
                {/* 1. Mesafe Slider (Nokta Görünürlüğü Düzeltildi) */}
                <div className="space-y-4">
                  <div className="flex justify-between text-xs font-bold text-slate-600 uppercase tracking-wide">
                    <span className="flex items-center gap-2"><MapPin size={18} className={theme.main} weight="fill"/> Mesafe Menzili</span>
                    <span className={`text-sm font-black ${theme.main}`}>{filterState.distance} KM</span>
                  </div>
                  
                  <div className="relative w-full h-6 flex items-center">
                    {/* Arka Plan Çubuğu */}
                    <input 
                      type="range" 
                      min="1" 
                      max="50" 
                      value={filterState.distance}
                      onChange={(e) => setFilterState({...filterState, distance: parseInt(e.target.value)})}
                      className="w-full h-2 rounded-full appearance-none bg-white/30 cursor-pointer focus:outline-none relative z-10"
                      style={{
                        // Bu özellik slider'ın sol tarafını (dolu kısmı) ve noktayı boyar
                        accentColor: 'currentColor', 
                        color: theme.main.replace('text-', '') === 'blue-600' ? '#2563eb' : // Tailwind renklerini hex'e çevirmek gerekebilir, burada basit tuttum
                               theme.main.includes('purple') ? '#9333ea' :
                               theme.main.includes('orange') ? '#ea580c' :
                               theme.main.includes('indigo') ? '#4f46e5' : '#059669'
                      }}
                    />
                    {/* Custom Slider Stili (Eğer accent-color yetmezse diye garanti çözüm) */}
                    <style jsx>{`
                      input[type=range]::-webkit-slider-thumb {
                        -webkit-appearance: none;
                        height: 20px;
                        width: 20px;
                        border-radius: 50%;
                        background: currentColor;
                        margin-top: -6px; /* Hizalama */
                        box-shadow: 0 4px 10px rgba(0,0,0,0.2);
                      }
                      input[type=range]::-moz-range-thumb {
                        height: 20px;
                        width: 20px;
                        border-radius: 50%;
                        background: currentColor;
                        border: none;
                        box-shadow: 0 4px 10px rgba(0,0,0,0.2);
                      }
                    `}</style>
                  </div>
                </div>
                
                {/* 2. Puan */}
                <div className="space-y-4">
                  <span className="text-xs font-bold text-slate-600 uppercase tracking-wide flex items-center gap-2">
                    <Star size={18} className="text-amber-500" weight="fill"/> Minimum Puan
                  </span>
                  <div className="flex gap-2">
                    {[3, 4, 4.5, 5].map(rate => (
                      <button 
                        key={rate} 
                        onClick={() => setFilterState({...filterState, minRating: rate})}
                        className={`flex-1 py-3.5 rounded-[20px] text-[11px] font-black transition-all border outline-none ${
                          filterState.minRating === rate 
                            ? `${theme.accent} text-white border-transparent shadow-lg scale-105` 
                            : 'bg-white/5 border-white/20 text-slate-500 hover:bg-white/20'
                        }`}
                      >
                        {rate}+
                      </button>
                    ))}
                  </div>
                </div>

                {/* 3. Etiketler */}
                <div className="space-y-4">
                  <span className="text-xs font-bold text-slate-600 uppercase tracking-wide flex items-center gap-2">
                    <Tag size={18} className={theme.main} weight="fill"/> Özellikler
                  </span>
                  <div className="flex flex-wrap gap-2">
                    {TAGS_LIST.map(tag => {
                      const isSelected = filterState.selectedTags.includes(tag);
                      return (
                        <button 
                          key={tag} 
                          onClick={() => toggleTag(tag)}
                          className={`px-4 py-2.5 rounded-[18px] text-[10px] font-black uppercase transition-all flex items-center gap-2 border outline-none ${
                            isSelected 
                              ? `bg-white/80 border-${theme.main.split('-')[1]}-200 ${theme.main} shadow-sm` 
                              : 'bg-white/5 border-white/20 text-slate-500 hover:bg-white/20'
                          }`}
                        >
                          {isSelected && <Check size={12} weight="bold" />}
                          {tag}
                        </button>
                      );
                    })}
                  </div>
                </div>

                <button 
                  onClick={() => setIsModalOpen(false)}
                  className={`w-full py-5 rounded-[28px] text-white font-black text-xs uppercase tracking-[0.25em] shadow-xl active:scale-95 transition-all mt-4 hover:brightness-110 outline-none ${theme.accent}`}
                >
                  Sonuçları Listele
                </button>
              </div>
            </motion.div>
          </div>
        </AnimatePresence>,
        document.body
      )}
    </>
  );
}