'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { List, UserCircle, Gear } from '@phosphor-icons/react';
import { useCategory } from '@/context/CategoryContext';

// Kategoriye göre dinamik renkler
const THEME_COLORS: Record<string, string> = {
  TECHNICAL: 'text-blue-600',
  CONSTRUCTION: 'text-purple-600',
  TECH: 'text-indigo-600',
  LIFE: 'text-emerald-600',
};

interface HeaderProps {
  onOpenSidebar?: () => void;
  onOpenProfile?: () => void;
}

export default function Header({ onOpenSidebar, onOpenProfile }: HeaderProps) {
  const { activeCategory } = useCategory();
  const router = useRouter();
  const activeColor = THEME_COLORS[activeCategory] || THEME_COLORS.TECHNICAL;

  return (
    // h-16 (64px) yerine h-[58px] yaparak incelettik. 
    // bg-white/40 ile filtrelerden (bg-white/5) daha koyu ve oturaklı yaptık.
    <header className="fixed top-0 left-0 right-0 z-[60] h-[58px] pt-[env(safe-area-inset-top)] flex items-center justify-between px-5 bg-white/40 backdrop-blur-2xl border-b border-white/20 shadow-sm">
      
      {/* SOL: Ayarlar Butonu */}
      <button 
        onClick={() => router.push('/settings')}
        className="p-2 -ml-1 flex items-center justify-center rounded-xl bg-white/10 border border-white/20 hover:bg-white/30 transition-all active:scale-90 outline-none"
        aria-label="Ayarlar"
      >
        <Gear size={22} weight="duotone" className="text-slate-700" />
      </button>

      {/* ORTA: Marka (Daha Kompakt) */}
      <div className="flex flex-col items-center select-none cursor-pointer" onClick={() => router.push('/')}>
        <h1 className="text-[16px] font-black tracking-[0.4em] uppercase text-slate-900 leading-none">
          USTA
        </h1>
        {/* Kategorinin renginde dinamik minik bar */}
        <div className={`w-6 h-[3px] mt-1 rounded-full ${activeColor.replace('text', 'bg')}`} />
      </div>

      {/* SAĞ: Profil Butonu */}
      <button 
        onClick={() => router.push('/settings')} // Şimdilik settings'e yönlendirdik
        className="relative p-1 -mr-1 flex items-center justify-center rounded-full hover:bg-white/20 transition-all active:scale-90 outline-none"
      >
        <UserCircle size={32} weight="duotone" className={`text-slate-700 ${activeColor}`} />
        
        {/* Bildirim Noktası (Dinamik Renk) */}
        <span className={`absolute top-1 right-1 w-2.5 h-2.5 border-2 border-white rounded-full shadow-sm ${activeColor.replace('text', 'bg')}`} />
      </button>

    </header>
  );
}