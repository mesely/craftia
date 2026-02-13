'use client';

import React from 'react';
import { List, UserCircle } from '@phosphor-icons/react';

interface HeaderProps {
  onOpenSidebar: () => void;
  onOpenProfile?: () => void;
}

export default function Header({ onOpenSidebar, onOpenProfile }: HeaderProps) {
  return (
    <header className="fixed top-0 left-0 right-0 z-40 h-16 flex items-center justify-between px-6 bg-white/10 backdrop-blur-md border-b border-white/20">
      
      {/* SOL: Sidebar Menü Butonu */}
      <button 
        onClick={onOpenSidebar}
        className="p-2 -ml-2 flex items-center justify-center rounded-full hover:bg-white/20 transition-all active:scale-90 outline-none"
        aria-label="Menüyü Aç"
      >
        <List size={26} weight="bold" className="text-slate-800" />
      </button>

      {/* ORTA: Marka / Logo */}
      <div className="flex flex-col items-center select-none">
        <h1 className="text-[11px] font-black tracking-[0.3em] uppercase text-slate-900 leading-none">
          Usta Kapımda
        </h1>
        <div className="w-8 h-[2px] bg-blue-600 mt-1.5 rounded-full" />
      </div>

      {/* SAĞ: Profil Butonu (Bildirim Detayıyla) */}
      <button 
        onClick={onOpenProfile}
        className="relative p-1 -mr-1 flex items-center justify-center rounded-full hover:bg-white/20 transition-all active:scale-90 outline-none"
      >
        <UserCircle size={32} weight="duotone" className="text-slate-700" />
        
        {/* Bildirim Noktası - Senin zil fikrini buraya minik bir indikatör olarak ekledim */}
        <span className="absolute top-1.5 right-1.5 w-2.5 h-2.5 bg-blue-600 border-2 border-white/60 rounded-full shadow-sm" />
      </button>

    </header>
  );
}