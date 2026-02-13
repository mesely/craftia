'use client';

import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Star, MapPin, Phone, WhatsappLogo, ShieldCheck, SealCheck } from '@phosphor-icons/react';

interface UstaDetailWidgetProps {
  usta: any;
  isOpen: boolean;
  onClose: () => void;
}

export default function UstaDetailWidget({ usta, isOpen, onClose }: UstaDetailWidgetProps) {
  if (!usta) return null;

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* --- BLUR BACKDROP --- */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 z-[100] bg-slate-500/20 backdrop-blur-sm"
          />

          {/* --- WIDGET PENCERESİ --- */}
          <div className="fixed inset-0 z-[110] flex items-center justify-center pointer-events-none p-6">
            <motion.div
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              transition={{ type: 'spring', damping: 25, stiffness: 300 }}
              className="pointer-events-auto w-full max-w-md bg-white/70 backdrop-blur-3xl border border-white/60 shadow-2xl rounded-[45px] overflow-hidden relative"
            >
              
              {/* Üst Kısım: Fotoğraf ve İsim */}
              <div className="p-8 pb-4 text-center relative">
                <button onClick={onClose} className="absolute top-6 right-6 p-2 bg-white/40 rounded-full hover:bg-white/80 transition-colors">
                  <X size={20} weight="bold" className="text-slate-600" />
                </button>

                <div className="w-24 h-24 bg-gradient-to-br from-indigo-100 to-white rounded-[35px] flex items-center justify-center text-3xl font-black text-indigo-900 mx-auto mb-4 shadow-inner border border-white/50">
                  {usta.first_name?.charAt(0)}{usta.last_name?.charAt(0)}
                </div>
                
                <h2 className="text-2xl font-black text-slate-800 tracking-tight mb-1">
                  {usta.first_name} {usta.last_name}
                </h2>
                
                <div className="flex justify-center gap-2 mb-4">
                  <span className="px-3 py-1 bg-emerald-100/50 text-emerald-700 text-[10px] font-bold uppercase rounded-lg tracking-wider border border-emerald-100 flex items-center gap-1">
                    <SealCheck size={14} weight="fill" /> Onaylı Hesap
                  </span>
                  <span className="px-3 py-1 bg-amber-100/50 text-amber-700 text-[10px] font-bold uppercase rounded-lg tracking-wider border border-amber-100 flex items-center gap-1">
                    <Star size={14} weight="fill" /> 4.9 Puan
                  </span>
                </div>
              </div>

              {/* Detaylar */}
              <div className="px-8 space-y-4">
                <div className="bg-white/40 p-4 rounded-[24px] border border-white/50 flex items-start gap-3">
                  <MapPin size={20} weight="duotone" className="text-slate-500 mt-0.5" />
                  <div>
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Hizmet Bölgesi</span>
                    <p className="text-sm font-bold text-slate-700 leading-snug">
                      {usta.address?.district || 'Merkez'}, {usta.address?.city || 'İstanbul'} (0.8 KM)
                    </p>
                  </div>
                </div>

                <div className="bg-white/40 p-4 rounded-[24px] border border-white/50 flex items-start gap-3">
                  <ShieldCheck size={20} weight="duotone" className="text-slate-500 mt-0.5" />
                  <div>
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Uzmanlık</span>
                    <div className="flex flex-wrap gap-2 mt-1">
                      {['Elektrik', 'Montaj'].map(tag => (
                        <span key={tag} className="text-[10px] font-bold bg-white px-2 py-1 rounded-md text-slate-600 border border-slate-100">#{tag}</span>
                      ))}
                    </div>
                  </div>
                </div>
              </div>

              {/* Alt Butonlar */}
              <div className="p-8 flex gap-3 mt-2">
                <button className="flex-1 py-4 bg-indigo-600 text-white rounded-[24px] font-black text-xs uppercase tracking-widest shadow-lg shadow-indigo-200 active:scale-95 transition-transform flex items-center justify-center gap-2">
                  <Phone size={18} weight="fill" /> Ara
                </button>
                <button className="flex-1 py-4 bg-emerald-500 text-white rounded-[24px] font-black text-xs uppercase tracking-widest shadow-lg shadow-emerald-200 active:scale-95 transition-transform flex items-center justify-center gap-2">
                  <WhatsappLogo size={18} weight="fill" /> Mesaj
                </button>
              </div>

            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}