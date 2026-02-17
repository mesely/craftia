'use client';

import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Star, Phone, WhatsappLogo, CircleNotch, NavigationArrow, Receipt, Image as ImageIcon, X, SealCheck, Crown
} from '@phosphor-icons/react';
import { useCategory } from '@/context/CategoryContext';

interface UstaListProps {
  filters: {
    city: string;
    subType: string;
    sortMode: string;
    distance: number;
  };
  userCoords: { lat: number; lng: number };
}

function getDistance(lat1: number, lon1: number, lat2: number, lon2: number) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return null;
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return (R * c).toFixed(1);
}

export default function UstaList({ filters, userCoords }: UstaListProps) {
  const { activeCategory } = useCategory();
  const [providers, setProviders] = useState<any[]>([]);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [activeModal, setActiveModal] = useState<{ type: 'prices' | 'photos'; data: any } | null>(null);
  const [error, setError] = useState<string | null>(null);
  
  const loaderRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setProviders([]);
    setPage(1);
    setHasMore(true);
    setError(null);
  }, [filters.city, filters.subType, filters.sortMode, activeCategory]);

  const fetchProviders = async () => {
    if (loading || !hasMore) return;
    setLoading(true);
    setError(null);

    try {
      const url = new URL(`${process.env.NEXT_PUBLIC_BACKEND_URL}/providers`);
      url.searchParams.append('page', page.toString());
      url.searchParams.append('limit', '10');
      if (activeCategory) url.searchParams.append('mainType', activeCategory);
      if (filters.city) url.searchParams.append('city', filters.city);
      if (filters.subType) url.searchParams.append('subType', filters.subType);
      if (filters.sortMode) url.searchParams.append('sort', filters.sortMode);
      if (userCoords.lat && userCoords.lng) {
          url.searchParams.append('userLat', userCoords.lat.toString());
          url.searchParams.append('userLng', userCoords.lng.toString());
      }

      const res = await fetch(url.toString(), {
        headers: {
            'Accept': 'application/json'
        }
      });
      
      if (!res.ok) {
        throw new Error(`HTTP error! status: ${res.status}`);
      }

      const data = await res.json();
      const newItems = data.providers || [];

      if (newItems.length < 10) setHasMore(false);
      setProviders(prev => [...prev, ...newItems]);
      setPage(prev => prev + 1);

    } catch (err) {
      console.error("Veri çekme hatası:", err);
      setError("Bağlantı kurulamadı. Lütfen internetinizi kontrol edip tekrar deneyin.");
      setHasMore(false);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting && hasMore && !loading) {
        fetchProviders();
      }
    }, { threshold: 0.1 });

    const currentLoader = loaderRef.current;
    if (currentLoader) observer.observe(currentLoader);

    return () => {
      if (currentLoader) observer.unobserve(currentLoader);
    };
  }, [hasMore, loading, page, filters, activeCategory, userCoords]);

  return (
    <>
      <div className="space-y-4 pb-32 px-1">
        {providers.map((usta, index) => {
          const distance = getDistance(userCoords.lat, userCoords.lng, usta.lat, usta.lng);
          const isPremium = usta.isPremium;
          
          return (
            <motion.div 
              key={usta._id || index}
              initial={{ opacity: 0, y: 20 }} 
              animate={{ opacity: 1, y: 0 }}
              className={`relative bg-white/40 backdrop-blur-md border p-5 rounded-[35px] shadow-sm transition-all duration-300 group overflow-hidden ${
                isPremium ? 'border-amber-200/60 bg-gradient-to-br from-amber-50/30 to-white/40' : 'border-white/50'
              }`}
            >
              {isPremium && <div className="absolute -top-10 -right-10 w-32 h-32 bg-amber-200/20 blur-3xl rounded-full" />}

              <div className="flex items-start gap-4 mb-4 relative z-10">
                <div className={`w-14 h-14 rounded-[20px] flex items-center justify-center text-lg font-black shrink-0 shadow-sm ${
                  isPremium ? 'bg-amber-400 text-amber-900' : 'bg-slate-800 text-white'
                }`}>
                  {isPremium ? <Crown weight="fill" size={24} /> : usta.businessName?.substring(0, 2).toUpperCase()}
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5">
                    <h3 className="font-black text-slate-800 text-base uppercase truncate">{usta.businessName}</h3>
                    {isPremium && <SealCheck size={18} weight="fill" className="text-amber-500 shrink-0" />}
                  </div>

                  <div className="flex items-center gap-2 mt-1 overflow-hidden">
                    <div className="flex items-center gap-0.5 shrink-0">
                      <Star size={12} weight="fill" className="text-amber-500" />
                      <span className="text-[11px] font-bold text-slate-600">{usta.rating || '4.9'}</span>
                    </div>
                    <span className="text-slate-300">|</span>
                    <span className="text-[10px] font-medium text-slate-500 truncate">
                      {usta.address || `${usta.district}, ${usta.city}`}
                    </span>
                  </div>
                </div>

                <div className="flex flex-col items-end gap-2 shrink-0">
                  {distance && (
                    <div className="px-2.5 py-1.5 rounded-full bg-slate-800 text-white flex items-center gap-1 shadow-md">
                      <NavigationArrow size={10} weight="fill" className="text-emerald-400" />
                      <span className="text-[9px] font-black uppercase">{distance} KM</span>
                    </div>
                  )}
                </div>
              </div>

              <div className="flex gap-2 mb-4 relative z-10">
                <button onClick={() => setActiveModal({ type: 'prices', data: usta })} className="flex-1 py-2.5 rounded-xl bg-white/60 border border-white flex items-center justify-center gap-2 text-[10px] font-black text-slate-600 uppercase transition-all hover:bg-white">
                  <Receipt size={16} /> Fiyat Listesi
                </button>
                <button onClick={() => setActiveModal({ type: 'photos', data: usta })} className="flex-1 py-2.5 rounded-xl bg-white/60 border border-white flex items-center justify-center gap-2 text-[10px] font-black text-slate-600 uppercase transition-all hover:bg-white">
                  <ImageIcon size={16} /> Çalışmalar
                </button>
              </div>

              <div className="flex gap-2 relative z-10">
                <a href={`tel:${usta.phoneNumber}`} className={`flex-[1.2] py-3.5 rounded-[20px] font-black text-[10px] uppercase flex items-center justify-center gap-2 shadow-lg active:scale-95 transition-transform ${
                  isPremium ? 'bg-amber-500 text-amber-950' : 'bg-slate-800 text-white'
                }`}>
                  <Phone size={18} weight="fill" /> ARA
                </a>
                <a href={`https://wa.me/${usta.phoneNumber?.replace(/\D/g, '')}`} className="flex-1 py-3.5 rounded-[20px] bg-emerald-500 text-white font-black text-[10px] uppercase flex items-center justify-center gap-2 shadow-lg active:scale-95 transition-transform">
                  <WhatsappLogo size={18} weight="fill" /> YAZ
                </a>
              </div>
            </motion.div>
          );
        })}

        <div ref={loaderRef} className="py-10 flex flex-col items-center justify-center text-center">
          {loading ? (
            <CircleNotch size={32} className="animate-spin text-slate-400" />
          ) : error ? (
            <p className="text-xs font-bold text-red-500">{error}</p>
          ) : !hasMore && providers.length > 0 ? (
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">Tüm ustalar yüklendi</p>
          ) : null}
        </div>
      </div>

      <AnimatePresence>
        {activeModal && (
          <div className="fixed inset-0 z-[9999] flex items-end sm:items-center justify-center p-0 sm:p-4">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setActiveModal(null)} className="absolute inset-0 bg-slate-900/60 backdrop-blur-md" />
            <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} className="relative w-full max-w-lg bg-white rounded-t-[40px] sm:rounded-[40px] p-8 max-h-[80vh] overflow-y-auto shadow-2xl">
              <div className="flex justify-between items-center mb-6">
                <div>
                  <h3 className="text-xl font-black text-slate-800 uppercase tracking-tight">{activeModal.type === 'prices' ? 'Fiyat Listesi' : 'Hizmet Fotoğrafları'}</h3>
                  <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">{activeModal.data.businessName}</p>
                </div>
                <button onClick={() => setActiveModal(null)} className="p-2 bg-slate-100 rounded-full"><X size={20} weight="bold"/></button>
              </div>

              {activeModal.type === 'prices' ? (
                <div className="space-y-3">
                  {activeModal.data.services?.length > 0 ? activeModal.data.services.map((s: any, i: number) => (
                    <div key={i} className="flex justify-between p-4 bg-slate-50 rounded-2xl border border-slate-100">
                      <span className="font-bold text-slate-700 text-sm">{s.name}</span>
                      <span className="font-black text-blue-600 text-sm">{s.price} ₺</span>
                    </div>
                  )) : <div className="py-10 text-center opacity-40 italic text-sm">Veri henüz eklenmemiş.</div>}
                </div>
              ) : (
                <div className="grid grid-cols-2 gap-3">
                  {activeModal.data.gallery?.length > 0 ? activeModal.data.gallery.map((img: string, i: number) => (
                    <img key={i} src={img} className="w-full h-40 object-cover rounded-2xl" alt="Hizmet" />
                  )) : <div className="col-span-2 py-10 text-center opacity-40 italic text-sm">Fotoğraf henüz eklenmemiş.</div>}
                </div>
              )}
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </>
  );
}