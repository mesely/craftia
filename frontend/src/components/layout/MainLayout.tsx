'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Gear, UserCircle, Wrench, PaintRoller, 
  Monitor, Sparkle, X 
} from '@phosphor-icons/react';

import LoginView from '../Sidebar/LoginView';
import RegisterView from '../Sidebar/RegisterView';
import MeshBackground from './MeshBackground';
import { useCategory, CategoryType } from '@/context/CategoryContext';

const THEME_COLORS: Record<CategoryType, string> = {
  TECHNICAL: 'text-blue-700',
  CONSTRUCTION: 'text-purple-700',
  CLIMATE: 'text-orange-700', 
  TECH: 'text-indigo-700',
  LIFE: 'text-emerald-700',
};

const THEME_HEADER_BG: Record<string, string> = {
  TECHNICAL: 'bg-blue-500/20 border-blue-500/30',
  CONSTRUCTION: 'bg-purple-500/20 border-purple-500/30',
  TECH: 'bg-indigo-500/20 border-indigo-500/30',
  LIFE: 'bg-emerald-500/20 border-emerald-500/30',
};

const NAV_ITEMS = [
  { id: 'TECHNICAL', icon: Wrench, label: 'Elektrik, Isı & Su' },
  { id: 'CONSTRUCTION', icon: PaintRoller, label: 'Yapı & Dekor' },
  { id: 'TECH', icon: Monitor, label: 'Beyaz Eşya & TV' },
  { id: 'LIFE', icon: Sparkle, label: 'Temizlik & Bakım' },
];

export default function MainLayout({ children }: { children: React.ReactNode }) {
  const { activeCategory, setActiveCategory } = useCategory();
  const router = useRouter();
  const [authModal, setAuthModal] = useState<'login' | 'register' | null>(null);
  const isLoggedIn = false; 

  return (
    <div className="relative min-h-screen w-full font-sans text-slate-800 overflow-x-clip selection:bg-indigo-100">
      <MeshBackground category={activeCategory} />
      
      {/* 📱 HEADER: Üst çentik uyumlu */}
      <header className={`fixed top-0 left-0 right-0 z-[60] flex flex-col ${THEME_HEADER_BG[activeCategory] || 'bg-white/20'} backdrop-blur-3xl border-b border-white/20 shadow-sm transition-all duration-500`}>
        <div className="h-[env(safe-area-inset-top,0px)] w-full" />
        <div className="h-[60px] px-6 flex items-center justify-between">
          <button onClick={() => router.push('/settings')} className="p-3 bg-white/20 hover:bg-white/40 backdrop-blur-md rounded-2xl border border-white/30 active:scale-90 transition-all group">
            <Gear size={26} weight="duotone" className="text-slate-700 group-hover:rotate-90 duration-500" />
          </button>
          <div className="text-[20px] font-black tracking-[0.3em] uppercase text-slate-800/90 select-none">USTA</div>
          <button onClick={() => setAuthModal('login')} className="p-1.5 rounded-full transition-all active:scale-90 hover:bg-white/30">
            <UserCircle size={36} weight="duotone" className="text-slate-700 opacity-80" />
          </button>
        </div>
      </header>

      {/* 🚀 MAIN: Header + Çentik kadar boşluk */}
      <main className="pt-[calc(60px+env(safe-area-inset-top,0px))] pb-[calc(100px+env(safe-area-inset-bottom,0px))] relative z-10 w-full">
        {children}
      </main>

      {/* 📱 BOTTOM NAV: Tam alta dayalı ve üstü kavisli (eğmeli) */}
      <div className="fixed bottom-0 left-0 right-0 z-[50] flex justify-center w-full pointer-events-none">
        <nav className="pointer-events-auto flex items-center justify-between w-full max-w-[500px] h-[calc(80px+env(safe-area-inset-bottom,0px))] bg-white/50 backdrop-blur-3xl border-t border-white/50 rounded-t-[32px] shadow-[0_-10px_40px_rgba(0,0,0,0.1)] px-6 pb-[env(safe-area-inset-bottom,0px)] ring-1 ring-white/30">
          {NAV_ITEMS.map((item) => {
            const isActive = activeCategory === item.id as CategoryType;
            return (
              <button 
                key={item.id} 
                onClick={() => setActiveCategory(item.id as CategoryType)} 
                className={`relative flex flex-col items-center justify-center flex-1 h-full min-w-0 transition-all duration-300 ${isActive ? '-translate-y-1' : 'opacity-70'}`}
              >
                <div className={`p-2.5 rounded-2xl transition-all duration-500 ${isActive ? 'bg-white shadow-xl ring-2 ring-white/50' : ''}`}>
                  <item.icon size={22} weight={isActive ? "fill" : "duotone"} className={`transition-colors duration-300 ${isActive ? THEME_COLORS[item.id as CategoryType] : 'text-slate-700'}`} />
                </div>
                <span className={`text-[10px] font-black uppercase tracking-tighter mt-1 text-center truncate w-full ${isActive ? 'text-slate-900' : 'text-slate-600'}`}>
                  {item.label}
                </span>
                {isActive && (
                  <motion.div layoutId="navDot" className={`absolute -bottom-1 w-1.5 h-1.5 rounded-full ${THEME_COLORS[item.id as CategoryType].replace('text', 'bg')}`} />
                )}
              </button>
            );
          })}
        </nav>
      </div>

      <AnimatePresence>
        {authModal && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setAuthModal(null)} className="absolute inset-0 bg-slate-900/60 backdrop-blur-md" />
            <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.9 }} className="relative w-full max-w-md bg-white/95 backdrop-blur-3xl rounded-[40px] p-8 shadow-2xl border border-white/20">
              <button onClick={() => setAuthModal(null)} className="absolute top-6 right-6 p-2 bg-slate-100 rounded-full text-slate-400 hover:bg-slate-200 transition-colors">
                <X size={20} weight="bold" />
              </button>
              <div className="mt-4">
                {authModal === 'login' ? <LoginView onSwitchToRegister={() => setAuthModal('register')} /> : <RegisterView onSwitchToLogin={() => setAuthModal('login')} />}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}