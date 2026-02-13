'use client';

import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const THEMES = {
  TECHNICAL: ['#00d2ff', '#3a7bd5', '#1CB5E0'],
  CONSTRUCTION: ['#8e2de2', '#4a00e0', '#6a11cb'],
  CLIMATE: ['#f95738', '#ee964b', '#f4d35e'],
  TECH: ['#1e1b4b', '#1e3a8a', '#60a5fa'], // Lacivert & Safir Mavi
  LIFE: ['#00b09b', '#96c93d', '#56ab2f'],
};

interface MeshBackgroundProps {
  category: string;
}

const MeshBackground: React.FC<MeshBackgroundProps> = ({ category }) => {
  const colors = THEMES[category as keyof typeof THEMES] || THEMES.TECHNICAL;

  return (
    <div className="fixed inset-0 -z-10 overflow-hidden transition-colors duration-700 bg-slate-50">
      <AnimatePresence mode="wait">
        <motion.div
          key={category}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.8 }} // Hızlandırılmış geçiş
          className="absolute inset-0"
        >
          {/* Merkezi Ana Leke */}
          <motion.div
            animate={{ scale: [1, 1.3, 1], opacity: [0.3, 0.5, 0.3] }}
            transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[85%] h-[85%] rounded-full blur-[140px]"
            style={{ backgroundColor: colors[1] }}
          />
          
          {/* Sağ Üst Leke */}
          <motion.div
            animate={{ x: [0, -50, 0], y: [0, 50, 0] }}
            transition={{ duration: 12, repeat: Infinity, ease: "linear" }}
            className="absolute -top-[15%] -right-[15%] w-[65%] h-[65%] rounded-full blur-[120px] opacity-40"
            style={{ backgroundColor: colors[0] }}
          />

          {/* Sol Alt Leke */}
          <motion.div
            animate={{ x: [0, 70, 0], y: [0, -70, 0] }}
            transition={{ duration: 15, repeat: Infinity, ease: "linear" }}
            className="absolute -bottom-[15%] -left-[15%] w-[65%] h-[65%] rounded-full blur-[120px] opacity-30"
            style={{ backgroundColor: colors[2] }}
          />

          {/* Tech Izgara Efekti */}
          {category === 'TECH' && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 0.15 }}
              className="absolute inset-0 bg-[linear-gradient(to_right,#3b82f610_1px,transparent_1px),linear-gradient(to_bottom,#3b82f610_1px,transparent_1px)] bg-[size:32px_32px]"
            />
          )}
        </motion.div>
      </AnimatePresence>
      <div className="absolute inset-0 opacity-[0.03] pointer-events-none mix-blend-overlay bg-[url('https://grainy-gradients.vercel.app/noise.svg')]" />
    </div>
  );
};

export default MeshBackground;