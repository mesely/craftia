'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Headset } from '@phosphor-icons/react';
import { useCategory } from '@/context/CategoryContext';

const THEME_MAP: any = {
  TECHNICAL: 'bg-blue-600 shadow-blue-500/40',
  CONSTRUCTION: 'bg-purple-600 shadow-purple-500/40',
  CLIMATE: 'bg-orange-600 shadow-orange-500/40',
  TECH: 'bg-indigo-600 shadow-indigo-500/40',
  LIFE: 'bg-emerald-600 shadow-emerald-500/40'
};

export default function SupportButton() {
  const { activeCategory } = useCategory();
  const themeClass = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  return (
    <motion.button
      initial={{ scale: 0 }}
      animate={{ scale: 1 }}
      whileHover={{ scale: 1.1 }}
      whileTap={{ scale: 0.9 }}
      className={`
        fixed bottom-36 right-6 z-40 
        w-14 h-14 rounded-full 
        flex items-center justify-center 
        text-white shadow-xl 
        border-2 border-white/20 
        backdrop-blur-md
        transition-colors duration-500
        ${themeClass}
      `}
    >
      <Headset size={28} weight="fill" />
      
      {/* Bildirim Noktası (Opsiyonel) */}
      <span className="absolute top-0 right-0 w-3.5 h-3.5 bg-red-500 border-2 border-white rounded-full" />
    </motion.button>
  );
}