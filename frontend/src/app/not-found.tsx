'use client';

import React from 'react';
import { motion } from 'framer-motion';
import Link from 'next/link';
import MainLayout from '@/components/layout/MainLayout';
import { useCategory } from '@/context/CategoryContext';
import { MagnifyingGlass, House, WarningCircle, ArrowLeft } from '@phosphor-icons/react';

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', bg: 'bg-blue-600' },
  CONSTRUCTION: { main: 'text-purple-600', bg: 'bg-purple-600' },
  CLIMATE: { main: 'text-orange-600', bg: 'bg-orange-600' },
  TECH: { main: 'text-indigo-600', bg: 'bg-indigo-600' },
  LIFE: { main: 'text-emerald-600', bg: 'bg-emerald-600' }
};

export default function NotFound() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  return (
    <MainLayout>
      <div className="min-h-[70vh] flex flex-col items-center justify-center px-6">
        
        {/* --- ANA GLASS KART --- */}
        <motion.div 
          initial={{ opacity: 0, scale: 0.9, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          className="w-full max-w-lg bg-white/40 backdrop-blur-3xl border border-white/60 p-12 rounded-[50px] shadow-2xl text-center relative overflow-hidden"
        >
          {/* Arka Plan Dekoratif Blur */}
          <div className={`absolute -top-20 -right-20 w-40 h-40 rounded-full blur-[80px] opacity-20 ${theme.bg}`} />
          
          {/* İKON ALANI */}
          <div className="relative mb-8">
            <div className="flex justify-center">
              <div className={`p-8 rounded-[35px] bg-white shadow-xl border-4 border-white/40 ${theme.main}`}>
                <MagnifyingGlass size={64} weight="duotone" />
              </div>
            </div>
            {/* Küçük Uyarı Balonu */}
            <motion.div 
              animate={{ y: [0, -5, 0] }}
              transition={{ repeat: Infinity, duration: 2 }}
              className="absolute top-0 right-1/4 p-2 bg-red-500 rounded-full text-white shadow-lg border-2 border-white"
            >
              <WarningCircle size={20} weight="fill" />
            </motion.div>
          </div>

          {/* METİN ALANI */}
          <div className="space-y-4 mb-10">
            <h1 className="text-5xl font-black text-slate-800 tracking-tighter italic">404</h1>
            <h2 className="text-lg font-black text-slate-700 uppercase tracking-widest leading-tight">
              Aradığın Usta <br /> Burada Değil!
            </h2>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-widest max-w-[250px] mx-auto leading-relaxed">
              Görünen o ki bu sayfa tadilatta veya hiç var olmadı.
            </p>
          </div>

          {/* AKSİYON BUTONU */}
          <Link href="/">
            <button className={`w-full py-5 rounded-[26px] text-white font-black text-xs uppercase tracking-[0.2em] shadow-xl active:scale-[0.98] transition-all hover:brightness-110 flex items-center justify-center gap-3 ${theme.bg}`}>
              <House size={20} weight="fill" />
              Ana Sayfaya Dön
            </button>
          </Link>

          {/* Geri Gitme Linki */}
          <button 
            onClick={() => window.history.back()}
            className="mt-6 text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] hover:text-slate-600 transition-colors flex items-center justify-center gap-2 mx-auto"
          >
            <ArrowLeft size={14} weight="bold" /> Geri Git
          </button>

        </motion.div>
      </div>
    </MainLayout>
  );
}