'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';

/**
 * THEME_MAP: Yükleme ikonunun rengini o anki 
 * kategoriye göre dinamik olarak değiştirir.
 */
const THEME_MAP: any = {
  TECHNICAL: 'border-t-blue-600',
  CONSTRUCTION: 'border-t-purple-600',
  CLIMATE: 'border-t-orange-600',
  TECH: 'border-t-indigo-600',
  LIFE: 'border-t-emerald-600'
};

export default function Loading() {
  const { activeCategory } = useCategory();
  const loaderColor = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  return (
    <div className="fixed inset-0 z-[999] flex flex-col items-center justify-center bg-white/10 backdrop-blur-md">
      
      {/* --- OVAL GLASS KAPSAYICI --- */}
      <motion.div 
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white/40 backdrop-blur-2xl border border-white/60 p-10 rounded-[50px] shadow-2xl flex flex-col items-center gap-6"
      >
        
        {/* --- DİNAMİK SPINNER --- */}
        <div className="relative">
          {/* Sabit Dış Halk (İnce Şeffaf) */}
          <div className="w-16 h-16 border-4 border-slate-200/30 rounded-full" />
          
          {/* Dönen Renkli Halk (Kategori Rengi) */}
          <motion.div 
            animate={{ rotate: 360 }}
            transition={{ repeat: Infinity, duration: 1, ease: "linear" }}
            className={`absolute top-0 left-0 w-16 h-16 border-4 border-transparent ${loaderColor} rounded-full`}
          />
        </div>

        {/* --- LOGO & METİN --- */}
        <div className="text-center">
          <h2 className="text-sm font-black text-slate-800 uppercase tracking-[0.6em] mb-1">USTA</h2>
          <motion.p 
            animate={{ opacity: [0.4, 1, 0.4] }}
            transition={{ repeat: Infinity, duration: 1.5 }}
            className="text-[10px] font-bold text-slate-400 uppercase tracking-widest"
          >
            Hazırlanıyor...
          </motion.p>
        </div>

      </motion.div>

      {/* Arka plan dekoratif parlaması */}
      <div className={`absolute w-64 h-64 blur-[120px] opacity-20 pointer-events-none rounded-full ${loaderColor.replace('border-t-', 'bg-')}`} />
    </div>
  );
}