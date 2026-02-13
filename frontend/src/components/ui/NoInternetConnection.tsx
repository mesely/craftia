'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { WifiSlash, ArrowsClockwise } from '@phosphor-icons/react';

export default function NoInternetConnection() {
  const [isOnline, setIsOnline] = useState(true);

  useEffect(() => {
    // Tarayıcıda çalışıp çalışmadığını kontrol et
    if (typeof window !== 'undefined') {
      setIsOnline(navigator.onLine);

      const handleOnline = () => setIsOnline(true);
      const handleOffline = () => setIsOnline(false);

      window.addEventListener('online', handleOnline);
      window.addEventListener('offline', handleOffline);

      return () => {
        window.removeEventListener('online', handleOnline);
        window.removeEventListener('offline', handleOffline);
      };
    }
  }, []);

  return (
    <AnimatePresence>
      {!isOnline && (
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: 50 }}
          className="fixed inset-0 z-[99999] flex flex-col items-center justify-center bg-slate-900/60 backdrop-blur-xl px-6 text-center"
        >
          <div className="bg-white/10 border border-white/20 p-8 rounded-[40px] shadow-2xl flex flex-col items-center max-w-sm w-full">
            {/* İkon */}
            <div className="w-20 h-20 bg-red-500/20 rounded-full flex items-center justify-center mb-6 shadow-[0_0_30px_rgba(239,68,68,0.4)]">
              <WifiSlash size={40} weight="duotone" className="text-red-500" />
            </div>

            {/* Başlık */}
            <h2 className="text-2xl font-black text-white uppercase tracking-tight mb-2">
              Bağlantı Koptu
            </h2>

            {/* Açıklama */}
            <p className="text-sm text-slate-300 font-medium mb-8 leading-relaxed">
              İnternet bağlantınızı kontrol edip tekrar deneyin. Usta'ya ulaşmak için online olmanız gerekiyor.
            </p>

            {/* Yenile Butonu */}
            <button 
              onClick={() => window.location.reload()}
              className="w-full py-4 rounded-[20px] bg-white text-slate-900 font-black uppercase tracking-widest text-xs flex items-center justify-center gap-2 hover:bg-slate-200 transition-colors active:scale-95"
            >
              <ArrowsClockwise size={18} weight="bold" />
              Sayfayı Yenile
            </button>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}