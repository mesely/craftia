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

  // Modal arka planı (Ekran görüntündeki o derin tonu korumak için)
  const currentModalBg = THEME_HEADER_BG[activeCategory] || 'bg-slate-900/40 border-white/20';

  return (
    <div className="relative min-h-screen w-full font-sans text-slate-800 overflow-x-hidden selection:bg-indigo-100">
      <MeshBackground category={activeCategory} />
      
      <header className={`fixed top-0 left-0 right-0 z-[60] h-[60px] pt-[env(safe-area-inset-top)] px-6 flex items-center justify-between ${THEME_HEADER_BG[activeCategory] || 'bg-white/20'} backdrop-blur-3xl border-b border-white/20 shadow-sm transition-colors duration-500`}>
        <button onClick={() => router.push('/settings')} className="p-3 bg-white/20 hover:bg-white/40 backdrop-blur-md rounded-2xl border border-white/30 active:scale-90 transition-all group outline-none">
          <Gear size={26} weight="duotone" className="text-slate-700 group-hover:rotate-90 duration-500" />
        </button>
        <div className="text-[20px] font-black tracking-[0.3em] uppercase text-slate-800/90 select-none drop-shadow-sm">USTA</div>
        <button onClick={() => setAuthModal('login')} className={`p-1.5 rounded-full transition-all active:scale-90 hover:bg-white/30 outline-none ${isLoggedIn ? 'bg-white/20' : ''}`}>
          <UserCircle size={36} weight="duotone" className={isLoggedIn ? THEME_COLORS[activeCategory as CategoryType] : "text-slate-700 opacity-80"} />
        </button>
      </header>

      <main className="pt-[88px] pb-32 px-0 min-h-screen relative z-10 w-full">{children}</main>

      {/* BOTTOM NAV */}
      <div className="fixed bottom-6 left-0 right-0 z-[50] flex justify-center w-full pointer-events-none pb-[env(safe-area-inset-bottom)]">
        <nav className="pointer-events-auto flex items-center justify-between w-[96%] max-w-[480px] h-[85px] bg-white/40 backdrop-blur-3xl border border-white/50 rounded-[32px] shadow-[0_20px_60px_rgba(0,0,0,0.15)] px-1 ring-1 ring-white/40">
          {NAV_ITEMS.map((item) => {
            const isActive = activeCategory === item.id as CategoryType;
            return (
              <button key={item.id} onClick={() => setActiveCategory(item.id as CategoryType)} className={`relative flex flex-col items-center justify-center flex-1 h-full min-w-0 transition-all duration-300 outline-none ${isActive ? '-translate-y-1.5' : 'opacity-70 hover:opacity-100'}`}>
                <div className={`p-2.5 rounded-2xl transition-all duration-500 ${isActive ? 'bg-white shadow-xl ring-2 ring-white/50' : ''}`}>
                  <item.icon size={22} weight={isActive ? "fill" : "duotone"} className={`transition-colors duration-300 ${isActive ? THEME_COLORS[item.id as CategoryType] : 'text-slate-700'}`} />
                </div>
                <span className={`text-[10px] font-black uppercase tracking-tighter mt-1 text-center transition-all duration-300 ${isActive ? 'text-slate-900 scale-105' : 'text-slate-600 opacity-90'}`}>{item.label}</span>
                {isActive && <motion.div layoutId="navDot" className={`absolute -bottom-1 w-1.5 h-1.5 rounded-full ${THEME_COLORS[item.id as CategoryType].replace('text', 'bg')}`} />}
              </button>
            );
          })}
        </nav>
      </div>

      {/* ✅ AUTH PENCERESİ */}
      <AnimatePresence>
        {authModal && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setAuthModal(null)} className="absolute inset-0 bg-slate-900/60 backdrop-blur-md" />
            <motion.div initial={{ opacity: 0, scale: 0.9, y: 20 }} animate={{ opacity: 1, scale: 1, y: 0 }} exit={{ opacity: 0, scale: 0.9, y: 20 }} className={`relative w-full max-w-md ${currentModalBg} backdrop-blur-3xl rounded-[40px] p-8 shadow-2xl border border-white/10`}>
              {/* Kapatma Butonu: Beyaz ve Net */}
              <button onClick={() => setAuthModal(null)} className="absolute top-6 right-6 p-2 bg-white/10 hover:bg-white/20 rounded-full text-white transition-colors">
                <X size={20} weight="bold" />
              </button>
              <div className="mt-4">
                {authModal === 'login' ? (
                  <LoginView onSwitchToRegister={() => setAuthModal('register')} />
                ) : (
                  <RegisterView onSwitchToLogin={() => setAuthModal('login')} />
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}