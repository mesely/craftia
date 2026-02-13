'use client';

import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from '@phosphor-icons/react';

interface GlassModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
}

export default function GlassModal({ isOpen, onClose, title, children }: GlassModalProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center px-6">
          {/* Arka Plan Karartma */}
          <motion.div 
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-slate-900/40 backdrop-blur-[6px]" 
          />

          {/* Modal Penceresi */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 30 }} 
            animate={{ opacity: 1, scale: 1, y: 0 }} 
            exit={{ opacity: 0, scale: 0.9, y: 30 }}
            className="relative w-full max-w-lg bg-white/85 backdrop-blur-3xl border border-white/50 rounded-[45px] shadow-2xl p-8 overflow-hidden"
          >
            {/* Başlık ve Kapat Butonu */}
            <div className="flex justify-between items-center mb-8 pb-6 border-b border-slate-100/30">
              {title && (
                <h3 className="text-xl font-black text-slate-800 uppercase tracking-tighter leading-none">
                  {title}
                </h3>
              )}
              <button 
                onClick={onClose} 
                className="p-3 bg-white/40 rounded-full hover:bg-white/60 transition-colors border border-white/40 ml-auto"
              >
                <X size={24} weight="bold" className="text-slate-600" />
              </button>
            </div>

            {/* İçerik */}
            <div>{children}</div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}