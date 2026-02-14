'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  X, Star, MapPin, Phone, WhatsappLogo, ShieldCheck, 
  SealCheck, NavigationArrow, Receipt, Image as ImageIcon, 
  Info, Crown 
} from '@phosphor-icons/react';

interface UstaDetailWidgetProps {
  usta: any;
  isOpen: boolean;
  onClose: () => void;
  userCoords?: { lat: number, lng: number }; // Ana sayfadan gelen konum
}

// --- Mesafe Hesaplama (Haversine) ---
function getDistance(lat1: number, lon1: number, lat2: number, lon2: number) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return null;
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return (R * c).toFixed(1);
}

export default function UstaDetailWidget({ usta, isOpen, onClose, userCoords }: UstaDetailWidgetProps) {
  const [activeTab, setActiveTab] = useState<'info' | 'prices' | 'photos'>('info');

  // Her açılışta Info sekmesine dön
  useEffect(() => { if (isOpen) setActiveTab('info'); }, [isOpen]);

  if (!usta) return null;

  const distance = getDistance(userCoords?.lat || 38.4237, userCoords?.lng || 27.1428, usta.lat, usta.lng);
  const isPremium = usta.isPremium;

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* --- ULTRA BLUR BACKDROP --- */}
          <motion.div
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 z-[9998] bg-slate-900/40 backdrop-blur-md"
          />

          {/* --- WIDGET CONTAINER (Her şeyin üstünde) --- */}
          <div className="fixed inset-0 z-[9999] flex items-end sm:items-center justify-center pointer-events-none p-0 sm:p-6">
            <motion.div
              initial={{ y: "100%", opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: "100%", opacity: 0 }}
              transition={{ type: 'spring', damping: 30, stiffness: 300 }}
              className="pointer-events-auto w-full max-w-lg bg-white/80 backdrop-blur-3xl border border-white/60 shadow-[0_-20px_80px_-20px_rgba(0,0,0,0.3)] rounded-t-[50px] sm:rounded-[50px] overflow-hidden relative flex flex-col max-h-[92vh]"
            >
              
              {/* Üst Kısım & Kapatma */}
              <div className="p-8 pb-4 text-center relative shrink-0">
                <button onClick={onClose} className="absolute top-6 right-8 p-3 bg-slate-100/50 hover:bg-slate-200/50 rounded-full transition-colors z-20">
                  <X size={20} weight="bold" className="text-slate-600" />
                </button>

                {/* Avatar / Logo */}
                <div className={`w-28 h-28 rounded-[40px] flex items-center justify-center text-4xl font-black mx-auto mb-6 shadow-2xl relative ${
                  isPremium ? 'bg-amber-400 text-amber-950 ring-4 ring-amber-200/50' : 'bg-slate-800 text-white'
                }`}>
                  {isPremium ? <Crown weight="fill" /> : (usta.businessName?.charAt(0) || 'U')}
                  {isPremium && (
                    <motion.div 
                      animate={{ scale: [1, 1.2, 1] }} 
                      transition={{ repeat: Infinity, duration: 2 }}
                      className="absolute -bottom-2 -right-2 bg-white rounded-full p-1 shadow-lg"
                    >
                      <SealCheck size={28} weight="fill" className="text-amber-500" />
                    </motion.div>
                  )}
                </div>
                
                <h2 className="text-2xl font-black text-slate-800 tracking-tight px-4 leading-tight">
                  {usta.businessName}
                </h2>
                
                <div className="flex flex-wrap justify-center gap-2 mt-4">
                  <div className="px-4 py-2 bg-white/60 border border-white rounded-2xl flex items-center gap-2 shadow-sm">
                    <Star size={18} weight="fill" className="text-amber-500" />
                    <span className="text-sm font-black text-slate-700">4.9</span>
                    <span className="text-xs font-bold text-slate-400">|</span>
                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider truncate max-w-[120px]">
                      {usta.address || usta.district}
                    </span>
                  </div>
                  {distance && (
                    <div className="px-4 py-2 bg-slate-800 text-white rounded-2xl flex items-center gap-2 shadow-lg">
                      <NavigationArrow size={14} weight="fill" className="text-emerald-400" />
                      <span className="text-xs font-black">{distance} KM YAKININDA</span>
                    </div>
                  )}
                </div>
              </div>

              {/* --- TAB SWITCHER (SEKMELER) --- */}
              <div className="px-8 mt-4 shrink-0">
                <div className="flex bg-slate-100/50 p-1.5 rounded-[24px] border border-white/40">
                  <button 
                    onClick={() => setActiveTab('info')}
                    className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-[20px] text-[10px] font-black uppercase transition-all ${activeTab === 'info' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:bg-white/30'}`}
                  >
                    <Info size={18} /> Detay
                  </button>
                  <button 
                    onClick={() => setActiveTab('prices')}
                    className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-[20px] text-[10px] font-black uppercase transition-all ${activeTab === 'prices' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:bg-white/30'}`}
                  >
                    <Receipt size={18} /> Fiyatlar
                  </button>
                  <button 
                    onClick={() => setActiveTab('photos')}
                    className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-[20px] text-[10px] font-black uppercase transition-all ${activeTab === 'photos' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:bg-white/30'}`}
                  >
                    <ImageIcon size={18} /> Galeri
                  </button>
                </div>
              </div>

              {/* --- DİNAMİK İÇERİK ALANI --- */}
              <div className="flex-1 overflow-y-auto p-8 no-scrollbar">
                <AnimatePresence mode="wait">
                  {activeTab === 'info' && (
                    <motion.div 
                      key="info" initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 10 }}
                      className="space-y-4"
                    >
                      <div className="bg-white/50 p-5 rounded-[30px] border border-white shadow-sm flex gap-4">
                        <div className="p-3 bg-blue-50 rounded-2xl text-blue-600"><MapPin size={24} weight="duotone" /></div>
                        <div>
                          <p className="text-[10px] font-black text-slate-400 uppercase">Tam Adres</p>
                          <p className="text-sm font-bold text-slate-700 leading-snug mt-1">{usta.address}</p>
                        </div>
                      </div>
                      <div className="bg-white/50 p-5 rounded-[30px] border border-white shadow-sm flex gap-4">
                        <div className="p-3 bg-emerald-50 rounded-2xl text-emerald-600"><ShieldCheck size={24} weight="duotone" /></div>
                        <div>
                          <p className="text-[10px] font-black text-slate-400 uppercase">Uzmanlık Alanı</p>
                          <p className="text-sm font-bold text-slate-700 mt-1">{usta.subType?.toUpperCase()} Uzmanı</p>
                        </div>
                      </div>
                    </motion.div>
                  )}

                  {activeTab === 'prices' && (
                    <motion.div 
                      key="prices" initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 10 }}
                      className="space-y-3"
                    >
                      {usta.services?.length > 0 ? usta.services.map((s: any, i: number) => (
                        <div key={i} className="flex justify-between items-center p-5 bg-white/50 rounded-[25px] border border-white shadow-sm">
                          <span className="font-bold text-slate-700">{s.name}</span>
                          <span className="font-black text-blue-600">{s.price} ₺</span>
                        </div>
                      )) : (
                        <div className="py-20 text-center opacity-30"><Receipt size={48} className="mx-auto mb-2"/><p className="text-xs font-black uppercase">Fiyat listesi henüz eklenmedi</p></div>
                      )}
                    </motion.div>
                  )}

                  {activeTab === 'photos' && (
                    <motion.div 
                      key="photos" initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 10 }}
                      className="grid grid-cols-2 gap-3"
                    >
                      {usta.gallery?.length > 0 ? usta.gallery.map((img: string, i: number) => (
                        <img key={i} src={img} className="w-full h-36 object-cover rounded-[25px] border-2 border-white shadow-sm" alt="Hizmet" />
                      )) : (
                        <div className="col-span-2 py-20 text-center opacity-30"><ImageIcon size={48} className="mx-auto mb-2"/><p className="text-xs font-black uppercase">Çalışma fotoğrafı bulunamadı</p></div>
                      )}
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>

              {/* Alt Aksiyonlar */}
              <div className="p-8 pt-4 pb-10 bg-white/50 border-t border-white shrink-0 flex gap-4">
                <a href={`tel:${usta.phoneNumber}`} className={`flex-1 py-5 rounded-[28px] font-black text-xs uppercase tracking-[0.2em] flex items-center justify-center gap-3 shadow-xl transition-all active:scale-95 ${
                  isPremium ? 'bg-amber-400 text-amber-950 shadow-amber-200' : 'bg-slate-800 text-white shadow-slate-200'
                }`}>
                  <Phone size={20} weight="fill" /> Hemen Ara
                </a>
                <a href={`https://wa.me/${usta.phoneNumber?.replace(/\D/g, '')}`} className="w-[70px] h-[60px] bg-emerald-500 text-white rounded-[28px] flex items-center justify-center shadow-xl shadow-emerald-100 active:scale-95 transition-transform">
                  <WhatsappLogo size={28} weight="fill" />
                </a>
              </div>

            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}