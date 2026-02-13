'use client';

import React from 'react';
import { motion } from 'framer-motion';

interface GlassCardProps {
  children: React.ReactNode;
  className?: string;
  onClick?: () => void;
  hoverEffect?: boolean;
}

export default function GlassCard({ children, className = '', onClick, hoverEffect = false }: GlassCardProps) {
  return (
    <motion.div 
      onClick={onClick}
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      whileTap={onClick ? { scale: 0.98 } : undefined}
      className={`
        relative overflow-hidden
        bg-white/30 backdrop-blur-3xl 
        border border-white/40 
        shadow-[0_8px_32px_0_rgba(31,38,135,0.05)]
        ${hoverEffect ? 'hover:bg-white/40 hover:shadow-xl hover:border-white/60 transition-all duration-500' : ''}
        rounded-[45px]
        ${className}
      `}
    >
      {/* İnce Parlama Efekti (Opsiyonel Estetik) */}
      <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-br from-white/20 to-transparent pointer-events-none" />
      
      {/* İçerik */}
      <div className="relative z-10">
        {children}
      </div>
    </motion.div>
  );
}