'use client';

import React, { useState, useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Star, Phone, ChatText, CircleNotch, NavigationArrow, 
  Receipt, Image as ImageIcon, X, SealCheck, Crown,
  HouseLine
} from '@phosphor-icons/react';
import { useCategory } from '@/context/CategoryContext';

// ─── Orijinal interface korundu ───────────────────────────────
interface UstaListProps {
  filters: {
    city: string;
    subType: string;
    sortMode: string;
    distance: number;
  };
  userCoords: { lat: number; lng: number };
}

// ─── Tema (orijinal) ────────────────────────────────────────
const THEME_STYLES: Record<string, { text: string; btn: string; light: string }> = {
  TECHNICAL:    { text: 'text-blue-500',    btn: 'bg-blue-500',    light: 'bg-blue-100 text-blue-600' },
  CONSTRUCTION: { text: 'text-purple-500',  btn: 'bg-purple-500',  light: 'bg-purple-100 text-purple-600' },
  CLIMATE:      { text: 'text-orange-500',  btn: 'bg-orange-500',  light: 'bg-orange-100 text-orange-600' },
  TECH:         { text: 'text-indigo-500',  btn: 'bg-indigo-500',  light: 'bg-indigo-100 text-indigo-600' },
  LIFE:         { text: 'text-emerald-500', btn: 'bg-emerald-500', light: 'bg-emerald-100 text-emerald-600' },
};

// ─── Yardımcı fonksiyonlar (orijinal) ────────────────────────
const formatTitle = (name: string) => {
  if (!name) return '';
  return name.split(/[\s\-,]+/).slice(0, 4).join(' ');
};

const formatAddress = (addr: string) => {
  if (!addr) return '';
  const words = addr.split(' ');
  if (words.length <= 7) return addr;
  return `${words.slice(0, 5).join(' ')}... ${words.slice(-2).join(' ')}`;
};

function getDistance(lat1: number, lon1: number, lat2: number, lon2: number) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return '0.0';
  const R = 6371;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) ** 2;
  return (R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))).toFixed(1);
}

// ─── Ana bileşen ─────────────────────────────────────────────
export default function UstaList({ filters, userCoords }: UstaListProps) {
  const { activeCategory } = useCategory();
  const [providers, setProviders] = useState<any[]>([]);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);
  const [hasMore, setHasMore] = useState(true);
  const [activeModal, setActiveModal] = useState<{ type: 'prices' | 'photos'; data: any } | null>(null);
  const [mounted, setMounted] = useState(false);

  const loaderRef = useRef<HTMLDivElement>(null);
  const theme = THEME_STYLES[activeCategory] || THEME_STYLES.TECHNICAL;

  // createPortal için mount kontrolü
  useEffect(() => { setMounted(true); }, []);

  // Filtre/kategori değişince listeyi sıfırla
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
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => { if (entries[0].isIntersecting && hasMore && !loading) fetchProviders(); },
      { threshold: 0.1 }
    );
    if (loaderRef.current) observer.observe(loaderRef.current);
    return () => observer.disconnect();
  }, [hasMore, loading, page]);

  // ─── Modal içeriği (createPortal ile body'e mount edilir) ──
  const modalContent = activeModal && (
    <div className="fixed inset-0 z-[99999] flex items-end sm:items-center justify-center p-0 sm:p-4">
      {/* Glassmorphism backdrop */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={() => setActiveModal(null)}
        className="absolute inset-0 bg-slate-900/60 backdrop-blur-md"
      />

      {/* Glassmorphism panel — orijinal tasarım */}
      <motion.div
        initial={{ y: '100%' }}
        animate={{ y: 0 }}
        exit={{ y: '100%' }}
        transition={{ type: 'spring', damping: 28, stiffness: 280 }}
        className="relative w-full max-w-lg bg-white/95 backdrop-blur-2xl rounded-t-[40px] sm:rounded-[40px] p-8 max-h-[85vh] overflow-y-auto shadow-2xl"
      >
        {/* Başlık */}
        <div className="flex justify-between items-start mb-6">
          <div>
            <h3 className="text-xl font-black text-slate-800 uppercase tracking-tight">
              {activeModal.type === 'prices' ? 'Fiyat Listesi' : 'Fotoğraflar'}
            </h3>
            <p className={`text-[10px] font-bold uppercase ${theme.text} mt-0.5`}>
              {activeModal.data.businessName}
            </p>
          </div>
          <button
            onClick={() => setActiveModal(null)}
            className="p-2.5 bg-slate-100 rounded-2xl text-slate-400 hover:bg-slate-200 transition-colors"
          >
            <X size={20} weight="bold" />
          </button>
        </div>

        {/* Fiyatlar — backend priceList nesnesi */}
        {activeModal.type === 'prices' ? (
          <div className="space-y-3">
            {activeModal.data.priceList && Object.keys(activeModal.data.priceList).length > 0 ? (
              Object.entries(activeModal.data.priceList).map(
                ([serviceName, priceRange]: [string, any], i) => {
                  const parts = String(priceRange).split('-');
                  const minVal = parseInt(parts[0]) || 0;
                  const maxVal = parseInt(parts[1]) || 0;
                  return (
                    <div
                      key={i}
                      className="flex justify-between items-start p-4 bg-white/60 border border-white/80 rounded-[22px] hover:bg-white hover:shadow-sm transition-all backdrop-blur-sm"
                    >
                      <span className="font-bold text-slate-700 text-[13px] leading-snug flex-1 pr-3">
                        {serviceName}
                      </span>
                      <div className="text-right shrink-0">
                        <div className="flex items-baseline gap-1">
                          <span className="text-[11px] font-bold text-slate-400">
                            {minVal.toLocaleString('tr-TR')}
                          </span>
                          <span className="text-slate-300 text-[10px]">—</span>
                          <span className={`text-[15px] font-black ${theme.text}`}>
                            {maxVal.toLocaleString('tr-TR')}
                          </span>
                          <span className="text-[10px] font-black text-slate-400">₺</span>
                        </div>
                        <p className="text-[8px] font-black text-slate-300 uppercase mt-0.5">
                          Min — Maks
                        </p>
                      </div>
                    </div>
                  );
                }
              )
            ) : (
              <div className="py-16 text-center opacity-40">
                <Receipt size={40} className="mx-auto mb-3 text-slate-300" />
                <p className="font-black uppercase text-xs tracking-widest text-slate-400">
                  Fiyat listesi henüz eklenmemiş.
                </p>
              </div>
            )}
          </div>
        ) : (
          /* Portfolyo — backend portfolioImages dizisi */
          <div className="grid grid-cols-2 gap-3">
            {activeModal.data.portfolioImages && activeModal.data.portfolioImages.length > 0 ? (
              activeModal.data.portfolioImages.map((img: string, i: number) => (
                <div
                  key={i}
                  className="relative aspect-square rounded-[28px] overflow-hidden border-2 border-white/50 shadow-sm"
                >
                  <img
                    src={img}
                    className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                    alt={`İş görseli ${i + 1}`}
                  />
                </div>
              ))
            ) : (
              <div className="col-span-2 py-16 text-center opacity-40">
                <ImageIcon size={40} className="mx-auto mb-3 text-slate-300" />
                <p className="font-black uppercase text-xs tracking-widest text-slate-400">
                  Henüz fotoğraf yüklenmemiş.
                </p>
              </div>
            )}
          </div>
        )}

        {/* Modal altı: adres + butonlar */}
        <div className="mt-6 pt-5 border-t border-slate-100 space-y-4">
          {activeModal.data.address && (
            <div className="flex items-start gap-2">
              <HouseLine size={18} className="text-slate-300 shrink-0 mt-0.5" />
              <p className="text-[11px] font-bold text-slate-400 leading-relaxed">
                {activeModal.data.address}
              </p>
            </div>
          )}
          <div className="flex gap-2">
            <a
              href={`tel:${activeModal.data.phoneNumber}`}
              className={`flex-1 py-4 rounded-[20px] ${theme.btn} text-white font-black text-[11px] uppercase flex items-center justify-center gap-2 shadow-md active:scale-95 transition-all`}
            >
              <Phone size={18} weight="fill" /> ARA
            </a>
            <a
              href={`sms:${activeModal.data.phoneNumber}`}
              className="flex-1 py-4 rounded-[20px] bg-slate-900 text-white font-black text-[11px] uppercase flex items-center justify-center gap-2 shadow-md active:scale-95 transition-all"
            >
              <ChatText size={18} weight="fill" /> MESAJ
            </a>
          </div>
        </div>
      </motion.div>
    </div>
  );

  return (
    <>
      <div className="space-y-3 pb-32 px-3">
        {providers.map((usta, index) => {
          const distance = getDistance(userCoords.lat, userCoords.lng, usta.lat, usta.lng);
          const priceCount = usta.priceList ? Object.keys(usta.priceList).length : 0;
          const photoCount = usta.portfolioImages?.length || 0;

          return (
            <motion.div
              key={usta._id || index}
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              className="relative bg-white/10 backdrop-blur-2xl border border-white/20 p-4 rounded-[30px] shadow-lg overflow-hidden"
            >
              {/* ── Usta Başlık ── */}
              <div className="flex items-start gap-3 mb-3 relative z-10">
                <div className={`w-12 h-12 rounded-[16px] flex items-center justify-center text-base font-black shrink-0 overflow-hidden bg-white/20 border border-white/20 ${theme.text}`}>
                  {usta.profileImage
                    ? <img src={usta.profileImage} alt="Usta" className="w-full h-full object-cover" />
                    : usta.isPremium
                      ? <Crown weight="fill" size={24} className="text-amber-400" />
                      : usta.businessName?.substring(0, 2).toUpperCase()
                  }
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1 mb-0.5">
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
                    <p className="text-[10px] font-bold text-slate-500 leading-tight">
                      {formatAddress(usta.address || `${usta.district}, ${usta.city}`)}
                    </p>
                  </div>
                </div>
              </div>

              {/* ── Fiyat & Portfolyo Butonları ── */}
              <div className="flex gap-2 mb-3 relative z-10">
                <button
                  onClick={() => setActiveModal({ type: 'prices', data: usta })}
                  className={`flex-1 py-2 rounded-xl bg-white/10 border border-white/30 flex items-center justify-center gap-1.5 text-[9px] font-black uppercase transition-all ${theme.text}`}
                >
                  <Receipt size={14} weight="bold" />
                  Fiyat
                  {/* Dinamik renkli rozet — artık cırtlak beyaz değil */}
                  {priceCount > 0 && (
                    <span className={`px-1.5 py-0.5 rounded-full text-[8px] font-black ${theme.light}`}>
                      {priceCount}
                    </span>
                  )}
                </button>
                <button
                  onClick={() => setActiveModal({ type: 'photos', data: usta })}
                  className={`flex-1 py-2 rounded-xl bg-white/10 border border-white/30 flex items-center justify-center gap-1.5 text-[9px] font-black uppercase transition-all ${theme.text}`}
                >
                  <ImageIcon size={14} weight="bold" />
                  İşler
                  {photoCount > 0 && (
                    <span className={`px-1.5 py-0.5 rounded-full text-[8px] font-black ${theme.light}`}>
                      {photoCount}
                    </span>
                  )}
                </button>
              </div>

              {/* ── ARA & MESAJ ── */}
              <div className="flex gap-2 relative z-10">
                <a
                  href={`tel:${usta.phoneNumber}`}
                  className={`flex-1 py-3 rounded-[20px] ${theme.btn} text-white font-black text-[11px] uppercase flex items-center justify-center gap-2 shadow-lg active:scale-95 transition-all`}
                >
                  <Phone size={18} weight="fill" /> ARA
                </a>
                <a
                  href={`sms:${usta.phoneNumber}`}
                  className="flex-1 py-3 rounded-[20px] bg-slate-900 text-white font-black text-[11px] uppercase flex items-center justify-center gap-2 shadow-lg active:scale-95 transition-all"
                >
                  <ChatText size={18} weight="fill" /> MESAJ
                </a>
              </div>
            </motion.div>
          );
        })}

        <div ref={loaderRef} className="h-10 flex justify-center">
          {loading && <CircleNotch size={24} className="animate-spin text-slate-400" />}
          {!loading && !hasMore && providers.length > 0 && (
            <p className="text-[9px] font-black uppercase text-slate-300 tracking-widest py-2">
              Tüm Ustalar Gösterildi
            </p>
          )}
        </div>
      </div>

      {/* Modal: createPortal ile body'e mount (navbar stack'inin dışına çıkar) */}
      <AnimatePresence>
        {activeModal && mounted && createPortal(modalContent, document.body)}
      </AnimatePresence>
    </>
  );
}