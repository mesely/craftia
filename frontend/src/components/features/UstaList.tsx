'use client';

import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Star, Phone, WhatsappLogo, CircleNotch, NavigationArrow, 
  Receipt, Image as ImageIcon, X, SealCheck, Crown
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

// ✅ Dinamik Renk Paleti (Dolu butonlar ve metinler için)
const THEME_STYLES: Record<string, { text: string; btn: string }> = {
  TECHNICAL: { text: 'text-blue-500', btn: 'bg-blue-500' },
  CONSTRUCTION: { text: 'text-purple-500', btn: 'bg-purple-500' },
  TECH: { text: 'text-indigo-500', btn: 'bg-indigo-500' },
  LIFE: { text: 'text-emerald-500', btn: 'bg-emerald-500' }
};

// --- YARDIMCI FONKSİYONLAR ---
const formatTitle = (name: string) => {
  if (!name) return "";
  // Boşluk, tire ve virgülleri ayırıp ilk 4 kelimeyi alıyoruz
  return name.split(/[\s\-,]+/).slice(0, 4).join(' ');
};

const formatAddress = (addr: string) => {
  if (!addr) return "";
  const words = addr.split(' ');
  if (words.length <= 7) return addr;
  return `${words.slice(0, 5).join(' ')}... ${words.slice(-2).join(' ')}`;
};

function getDistance(lat1: number, lon1: number, lat2: number, lon2: number) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return "0.0";
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
  
  const loaderRef = useRef<HTMLDivElement>(null);
  const theme = THEME_STYLES[activeCategory] || THEME_STYLES.TECHNICAL;

  // ✅ SENİN ÇALIŞAN FETCH MANTIĞIN
  useEffect(() => {
    setProviders([]);
    setPage(1);
    setHasMore(true);
  }, [filters, activeCategory]);

  const fetchProviders = async () => {
    if (loading || !hasMore) return;
    setLoading(true);
    try {
      const url = new URL(`${process.env.NEXT_PUBLIC_BACKEND_URL}/providers`);
      url.searchParams.append('page', page.toString());
      url.searchParams.append('limit', '10');
      if (activeCategory) url.searchParams.append('mainType', activeCategory);
      if (filters.city) url.searchParams.append('city', filters.city);
      if (filters.subType && filters.subType !== 'all') url.searchParams.append('subType', filters.subType);
      if (filters.sortMode) url.searchParams.append('sortMode', filters.sortMode);
      if (userCoords.lat) url.searchParams.append('userLat', userCoords.lat.toString());
      if (userCoords.lng) url.searchParams.append('userLng', userCoords.lng.toString());

      const res = await fetch(url.toString());
      const data = await res.json();
      const newItems = data.providers || [];
      if (newItems.length < 10) setHasMore(false);
      setProviders(prev => [...prev, ...newItems]);
      setPage(prev => prev + 1);
    } catch (err) { console.error(err); } finally { setLoading(false); }
  };

  useEffect(() => {
    const observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting && hasMore && !loading) fetchProviders();
    }, { threshold: 0.1 });
    if (loaderRef.current) observer.observe(loaderRef.current);
    return () => observer.disconnect();
  }, [hasMore, loading, page]);

  return (
    <>
      <div className="space-y-3 pb-32 px-3">
        {providers.map((usta, index) => {
          const distance = getDistance(userCoords.lat, userCoords.lng, usta.lat, usta.lng);
          
          return (
            <motion.div 
              key={usta._id || index}
              initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }}
              className="relative bg-white/10 backdrop-blur-2xl border border-white/20 p-4 rounded-[30px] shadow-lg overflow-hidden"
            >
              <div className="flex items-start gap-3 mb-3 relative z-10">
                <div className={`w-12 h-12 rounded-[16px] flex items-center justify-center text-base font-black shrink-0 bg-white/20 border border-white/20 ${theme.text}`}>
                  {usta.isPremium ? <Crown weight="fill" size={24} /> : usta.businessName?.substring(0, 2).toUpperCase()}
                </div>
                
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1 mb-0.5">
                    {/* Başlık: İlk 4 kelime */}
                    <h3 className="font-black text-slate-800 text-[15px] uppercase truncate">
                      {formatTitle(usta.businessName)}
                    </h3>
                    {usta.isPremium && <SealCheck size={16} weight="fill" className="text-amber-500 shrink-0" />}
                  </div>

                  <div className="flex flex-col gap-0.5">
                    <div className="flex items-center gap-2">
                      <div className="flex items-center gap-0.5">
                        <Star size={12} weight="fill" className={theme.text} />
                        <span className={`text-[11px] font-black ${theme.text}`}>{usta.rating || '4.9'}</span>
                      </div>
                      <span className="text-slate-300">|</span>
                      <div className="flex items-center gap-1">
                        <NavigationArrow size={10} weight="fill" className={theme.text} />
                        <span className={`text-[10px] font-black uppercase ${theme.text}`}>{distance} KM</span>
                      </div>
                    </div>
                    {/* Adres: Akıllı kısaltma */}
                    <p className="text-[10px] font-bold text-slate-500 leading-tight">
                      {formatAddress(usta.address || `${usta.district}, ${usta.city}`)}
                    </p>
                  </div>
                </div>
              </div>

              <div className="flex gap-2 mb-3 relative z-10">
                <button 
                  onClick={() => setActiveModal({ type: 'prices', data: usta })}
                  className={`flex-1 py-2 rounded-xl bg-white/10 border border-white/30 flex items-center justify-center gap-2 text-[9px] font-black uppercase transition-all ${theme.text}`}
                >
                  <Receipt size={14} weight="bold" /> Fiyat
                </button>
                <button 
                  onClick={() => setActiveModal({ type: 'photos', data: usta })}
                  className={`flex-1 py-2 rounded-xl bg-white/10 border border-white/30 flex items-center justify-center gap-2 text-[9px] font-black uppercase transition-all ${theme.text}`}
                >
                  <ImageIcon size={14} weight="bold" /> İşler
                </button>
              </div>

              <div className="flex gap-2 relative z-10">
                {/* ARA Butonu: Dolu ve Dinamik Renk */}
                <a href={`tel:${usta.phoneNumber}`} className={`flex-1 py-3 rounded-[20px] ${theme.btn} text-white font-black text-[11px] uppercase flex items-center justify-center gap-2 shadow-lg active:scale-95 transition-all`}>
                  <Phone size={18} weight="fill" /> ARA
                </a>
                {/* WHATSAPP Butonu: Dolu ve Dinamik Renk */}
                <a 
                  href={`https://wa.me/${usta.phoneNumber?.replace(/\D/g, '')}`} 
                  className={`flex-1 py-3 rounded-[20px] ${theme.btn} text-white font-black text-[11px] uppercase flex items-center justify-center gap-2 shadow-lg active:scale-95 transition-all`}
                >
                  <WhatsappLogo size={18} weight="fill" /> WHATSAPP
                </a>
              </div>
            </motion.div>
          );
        })}
        <div ref={loaderRef} className="h-10 flex justify-center">
          {loading && <CircleNotch size={24} className="animate-spin text-slate-400" />}
        </div>
      </div>

      {/* MODAL TASARIMI */}
      <AnimatePresence>
        {activeModal && (
          <div className="fixed inset-0 z-[9999] flex items-end sm:items-center justify-center p-0 sm:p-4">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setActiveModal(null)} className="absolute inset-0 bg-slate-900/60 backdrop-blur-md" />
            <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} className="relative w-full max-w-lg bg-white/95 backdrop-blur-2xl rounded-t-[40px] sm:rounded-[40px] p-8 max-h-[85vh] overflow-y-auto shadow-2xl">
              <div className="flex justify-between items-center mb-6">
                <div>
                  <h3 className="text-xl font-black text-slate-800 uppercase tracking-tight">{activeModal.type === 'prices' ? 'Fiyat Listesi' : 'Fotoğraflar'}</h3>
                  <p className={`text-[10px] font-bold uppercase ${theme.text}`}>{activeModal.data.businessName}</p>
                </div>
                <button onClick={() => setActiveModal(null)} className="p-2 bg-slate-100 rounded-full text-slate-400"><X size={20} weight="bold"/></button>
              </div>

              {activeModal.type === 'prices' ? (
                <div className="space-y-3">
                  {activeModal.data.services?.map((s: any, i: number) => (
                    <div key={i} className="flex justify-between p-4 bg-white/50 border border-white rounded-2xl">
                      <span className="font-bold text-slate-700 text-sm">{s.name}</span>
                      <span className={`font-black ${theme.text} text-sm`}>{s.price} ₺</span>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="grid grid-cols-2 gap-3">
                  {activeModal.data.gallery?.map((img: string, i: number) => (
                    <img key={i} src={img} className="w-full h-40 object-cover rounded-2xl border border-white" alt="İş" />
                  ))}
                </div>
              )}
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </>
  );
}