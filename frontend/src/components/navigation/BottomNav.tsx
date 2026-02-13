'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { 
  Wrench, PaintRoller, Thermometer, Monitor, Sparkle 
} from '@phosphor-icons/react';

const NAV_ITEMS = [
  { id: 'TECHNICAL', icon: Wrench, label: 'Teknik' },
  { id: 'CONSTRUCTION', icon: PaintRoller, label: 'Yapı' },
  { id: 'CLIMATE', icon: Thermometer, label: 'Klima' },
  { id: 'TECH', icon: Monitor, label: 'Cihaz' },
  { id: 'LIFE', icon: Sparkle, label: 'Yaşam' },
];

const COLOR_MAP: any = {
  TECHNICAL: 'text-blue-400', // Daha açık renk (Koyu zemin/blur üstünde parlasın)
  CONSTRUCTION: 'text-purple-400',
  CLIMATE: 'text-orange-400',
  TECH: 'text-indigo-400',
  LIFE: 'text-emerald-400',
};

const DOT_MAP: any = {
  TECHNICAL: 'bg-blue-500',
  CONSTRUCTION: 'bg-purple-500',
  CLIMATE: 'bg-orange-500',
  TECH: 'bg-indigo-500',
  LIFE: 'bg-emerald-500',
};

interface BottomNavProps {
  active: string;
  onChange: (id: string) => void;
}

export default function BottomNav({ active, onChange }: BottomNavProps) {
  return (
    <div className="fixed bottom-6 left-0 right-0 z-50 flex justify-center w-full pointer-events-none pb-[env(safe-area-inset-bottom)]">
      
      {/* NAVBAR CONTAINER 
          - bg-white/5: İŞTE OPAKLIĞI KISAN YER BURASI (Daha şeffaf)
          - backdrop-blur-3xl: Arkası iyice buzlu cam olsun.
          - h-[92px]: İkon zıplayınca taşmasın diye yüksek.
      */}
      <nav className="pointer-events-auto flex items-center justify-between w-[98%] max-w-none h-[92px] bg-white/5 backdrop-blur-3xl border border-white/10 rounded-[46px] shadow-[0_20px_60px_rgba(0,0,0,0.2)] px-2 sm:px-6 ring-1 ring-white/5">
        
        {NAV_ITEMS.map((item) => {
          const isActive = active === item.id;
          const activeColor = COLOR_MAP[item.id];
          const dotColor = DOT_MAP[item.id];

          return (
            <button
              key={item.id}
              onClick={() => onChange(item.id)}
              className={`relative flex flex-col items-center justify-center flex-1 h-full gap-1 transition-all duration-300 outline-none group ${
                isActive ? '' : 'opacity-50 hover:opacity-100'
              }`}
            >
              {/* İKON KUTUSU 
                  - bg-white/10: Aktif olunca arkası çok hafif parlasın (Çok opak olmasın diye 10 yaptık).
                  - shadow-lg: Derinlik katar.
              */}
              <div 
                className={`p-3.5 rounded-[24px] transition-all duration-300 relative z-10 ${
                  isActive 
                    ? 'bg-white/10 shadow-lg ring-1 ring-white/20 -translate-y-2 backdrop-blur-md' 
                    : 'bg-transparent translate-y-0'
                }`}
              >
                <item.icon 
                  size={28} 
                  weight={isActive ? "fill" : "duotone"} 
                  className={`transition-colors duration-300 ${
                    isActive ? activeColor : 'text-slate-300 group-hover:text-white'
                  }`} 
                />
              </div>

              {/* ETİKET */}
              <span className={`text-[10px] font-black uppercase tracking-tight text-center transition-all duration-300 absolute bottom-3.5 ${
                isActive 
                  ? 'opacity-100 text-slate-200 translate-y-0' 
                  : 'opacity-0 text-slate-500 translate-y-2'
              }`}>
                {item.label}
              </span>

              {/* NOKTA */}
              {isActive && (
                <motion.div
                  layoutId="activeDot"
                  className={`absolute bottom-2 w-1.5 h-1.5 rounded-full ${dotColor}`}
                  transition={{ type: "spring", stiffness: 400, damping: 30 }}
                />
              )}
            </button>
          );
        })}
      </nav>
    </div>
  );
}