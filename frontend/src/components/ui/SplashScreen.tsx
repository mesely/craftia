'use client';

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Image from 'next/image';

export default function SplashScreen() {
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    // 2.8 saniye sonra (animasyonun bitişiyle uyumlu) ekranı kaldır
    const timer = setTimeout(() => {
      setIsVisible(false);
    }, 2800);

    return () => clearTimeout(timer);
  }, []);

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          initial={{ opacity: 1 }}
          exit={{ 
            opacity: 0, 
            filter: 'blur(20px)',
            transition: { duration: 0.8, ease: "easeInOut" }
          }}
          className="fixed inset-0 z-[99999] flex flex-col items-center justify-center bg-[#fcfcfc]"
        >
          <div className="relative flex flex-col items-center">
            
            {/* Logo Konteynırı */}
            <motion.div
              initial={{ scale: 0.7, opacity: 0, rotate: -10 }}
              animate={{ scale: 1, opacity: 1, rotate: 0 }}
              transition={{ 
                duration: 1.2, 
                type: "spring", 
                stiffness: 100 
              }}
              className="relative w-40 h-40 mb-8"
            >
              {/* Ortadaki Vida Dönüş Efekti (Arka Planda Hafif) */}
              <motion.div 
                animate={{ rotate: 360 }}
                transition={{ duration: 8, repeat: Infinity, ease: "linear" }}
                className="absolute inset-0 opacity-10"
              >
                <div className="w-full h-full border-[2px] border-dashed border-slate-900 rounded-full" />
              </motion.div>

              {/* Ana Logo */}
              <Image
                src="/apicon.png"
                alt="Usta Logo"
                fill
                className="object-contain drop-shadow-2xl"
                priority
              />
            </motion.div>

            {/* Metin Alanı */}
            <motion.div
              initial={{ y: 20, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              transition={{ delay: 0.5, duration: 0.8 }}
              className="text-center"
            >
              <h1 className="text-4xl font-black tracking-[0.4em] text-slate-900 uppercase">
                USTA
              </h1>
              
              {/* Minimalist Yükleme Barı */}
              <div className="mt-6 w-48 h-[3px] bg-slate-100 rounded-full overflow-hidden relative mx-auto">
                <motion.div 
                  initial={{ width: 0 }}
                  animate={{ width: "100%" }}
                  transition={{ duration: 2.2, ease: "easeInOut" }}
                  className="absolute top-0 left-0 h-full bg-gradient-to-r from-blue-500 via-purple-500 to-orange-500 shadow-[0_0_8px_rgba(99,102,241,0.5)]"
                />
              </div>

              <motion.p 
                animate={{ opacity: [0.4, 1, 0.4] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="mt-4 text-[9px] font-bold text-slate-400 uppercase tracking-[0.6em]"
              >
                Sistem Hazırlanıyor
              </motion.p>
            </motion.div>
          </div>

          {/* Hafif "Dust" / Gren Efekti (Zemin Derinliği İçin) */}
          <div className="absolute inset-0 pointer-events-none opacity-[0.03] bg-[url('https://www.transparenttextures.com/patterns/p6.png')]" />
        </motion.div>
      )}
    </AnimatePresence>
  );
}