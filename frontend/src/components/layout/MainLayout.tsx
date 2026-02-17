'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { 
  Gear, UserCircle, Wrench, PaintRoller, 
  Thermometer, Monitor, Sparkle 
} from '@phosphor-icons/react';

import MeshBackground from './MeshBackground';
import { useCategory, CategoryType } from '@/context/CategoryContext';

const THEME_COLORS: Record<CategoryType, string> = {
  TECHNICAL: 'text-blue-700',
  CONSTRUCTION: 'text-purple-700',
  CLIMATE: 'text-orange-700',
  TECH: 'text-indigo-700',
  LIFE: 'text-emerald-700',
};

const NAV_ITEMS = [
  { id: 'TECHNICAL', icon: Wrench, label: 'Teknik' },
  { id: 'CONSTRUCTION', icon: PaintRoller, label: 'Yapı' },
  { id: 'CLIMATE', icon: Thermometer, label: 'Klima' },
  { id: 'TECH', icon: Monitor, label: 'Teknoloji' },
  { id: 'LIFE', icon: Sparkle, label: 'Yaşam' },
];

export default function MainLayout({ children }: { children: React.ReactNode }) {
  const { activeCategory, setActiveCategory } = useCategory();
  const router = useRouter();
  
  // Örn: Gelecekte auth state'den gelecek
  const isLoggedIn = false; 

  return (
    <div className="relative min-h-screen w-full font-sans text-slate-800 overflow-x-hidden selection:bg-indigo-100">
      
      {/* 1. ARKA PLAN */}
      <MeshBackground category={activeCategory} />
      
      {/* 2. HEADER (Üst Bar) 
          Artık Sidebar yerine doğrudan /settings sayfasına yönlendiriyor.
      */}
      <header className="fixed top-0 left-0 right-0 z-[60] h-[88px] pt-[env(safe-area-inset-top)] px-6 flex items-center justify-between bg-white/20 backdrop-blur-3xl border-b border-white/20 shadow-sm">
        
        {/* AYARLAR BUTONU (Eski Hamburger Menü Yerine) */}
        <button 
          onClick={() => router.push('/settings')} 
          className="p-3 bg-white/20 hover:bg-white/40 backdrop-blur-md rounded-2xl border border-white/30 shadow-sm active:scale-90 transition-all group outline-none"
        >
          <Gear size={26} weight="duotone" className="text-slate-700 group-hover:text-slate-900 transition-transform group-hover:rotate-90 duration-500" />
        </button>
        
        <div className="text-[20px] font-black tracking-[0.3em] uppercase text-slate-800/90 select-none drop-shadow-sm">
          USTA
        </div>
        
        {/* PROFİL BUTONU (Eskiden Widget Açardı, Şimdi Profil Sayfasına Veya Girişe Gider) */}
        <button 
          onClick={() => router.push(isLoggedIn ? '/profile' : '/settings')}
          className={`p-1.5 rounded-full transition-all active:scale-90 hover:bg-white/30 outline-none ${isLoggedIn ? 'bg-white/20 backdrop-blur-md border border-white/30 shadow-sm' : ''}`}
        >
          <UserCircle 
            size={36} 
            weight="duotone" 
            className={isLoggedIn ? THEME_COLORS[activeCategory] : "text-slate-700 opacity-80"} 
          />
        </button>
      </header>

      {/* 3. ANA İÇERİK ALANI */}
      <main className="pt-[88px] pb-32 px-0 min-h-screen relative z-10 w-full">
        <div className="w-full">
          {children}
        </div>
      </main>

      {/* 4. BOTTOM NAVIGATION */}
      <div className="fixed bottom-6 left-0 right-0 z-[50] flex justify-center w-full pointer-events-none pb-[env(safe-area-inset-bottom)]">
        <nav className="pointer-events-auto flex items-center justify-between w-[98%] max-w-none h-[90px] bg-white/30 backdrop-blur-3xl border border-white/50 rounded-[35px] shadow-[0_20px_60px_rgba(0,0,0,0.1)] px-4 sm:px-8 ring-1 ring-white/40">
          {NAV_ITEMS.map((item) => {
            const isActive = activeCategory === item.id as CategoryType;
            return (
              <button
                key={item.id}
                onClick={() => setActiveCategory(item.id as CategoryType)}
                className={`relative flex flex-col items-center justify-center flex-1 h-full gap-1.5 transition-all duration-300 outline-none ${
                  isActive ? '-translate-y-2' : 'opacity-60 hover:opacity-100 hover:scale-105'
                }`}
              >
                <div className={`p-2.5 rounded-2xl transition-all duration-500 ${isActive ? 'bg-white shadow-xl ring-2 ring-white/50' : ''}`}>
                  <item.icon 
                    size={24} 
                    weight={isActive ? "fill" : "duotone"} 
                    className={`transition-colors duration-300 ${isActive ? THEME_COLORS[item.id as CategoryType] : 'text-slate-600'}`} 
                  />
                </div>
                
                <span className={`text-[9px] font-black uppercase tracking-tight text-center transition-colors duration-300 hidden sm:block ${isActive ? 'text-slate-800' : 'text-slate-500'}`}>
                  {item.label}
                </span>

                {isActive && (
                  <motion.div 
                    layoutId="navDot" 
                    className={`absolute -bottom-1 w-1.5 h-1.5 rounded-full ${THEME_COLORS[item.id as CategoryType].replace('text', 'bg')}`}
                    transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                  />
                )}
              </button>
            );
          })}
        </nav>
      </div>

    </div>
  );
}