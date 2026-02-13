'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  Receipt, Wrench, PaintRoller, 
  Thermometer, Monitor, Sparkle, 
  CaretRight, ClockCounterClockwise, CalendarCheck, WarningCircle
} from '@phosphor-icons/react';

// KATEGORİ RENK VE İKON HARİTASI (Kurumsal Tonlar)
const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-700', bg: 'bg-blue-600', border: 'border-blue-200' },
  CONSTRUCTION: { main: 'text-purple-700', bg: 'bg-purple-600', border: 'border-purple-200' },
  CLIMATE: { main: 'text-orange-700', bg: 'bg-orange-600', border: 'border-orange-200' },
  TECH: { main: 'text-indigo-700', bg: 'bg-indigo-600', border: 'border-indigo-200' },
  LIFE: { main: 'text-emerald-700', bg: 'bg-emerald-600', border: 'border-emerald-200' }
};

const CATEGORY_ICONS: any = {
  TECHNICAL: Wrench,
  CONSTRUCTION: PaintRoller,
  CLIMATE: Thermometer,
  TECH: Monitor,
  LIFE: Sparkle
};

export default function OrdersView() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;
  
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
    // GERÇEK BACKEND İSTEĞİ
    const fetchHistory = async () => {
      try {
        // API Gateway üzerinden geçmiş siparişleri çek
        const response = await fetch('/api/user/orders?status=completed');
        
        if (!response.ok) throw new Error('Veri alınamadı');
        
        const data = await response.json();
        
        // Backend'den dizi gelmezse boş diziye eşitle
        if (Array.isArray(data) && data.length > 0) {
          setOrders(data);
        } else {
          setOrders([]); 
        }
      } catch (err) {
        console.error("Geçmiş yüklenirken hata:", err);
        setError(true);
        setOrders([]); // Hata durumunda listeyi temizle
      } finally {
        setLoading(false);
      }
    };

    fetchHistory();
  }, []);

  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      className="p-4 space-y-5 pb-24 overflow-x-hidden font-sans"
    >
      {/* --- BAŞLIK KARTI (Glass Effect) --- */}
      <div className={`${theme.bg} p-8 rounded-[35px] shadow-lg shadow-indigo-500/10 text-center text-white relative overflow-hidden`}>
        <div className="relative z-10">
          <div className="bg-white/20 w-14 h-14 rounded-2xl flex items-center justify-center mx-auto mb-3 backdrop-blur-md border border-white/30">
             <Receipt size={32} weight="duotone" />
          </div>
          <h1 className="text-lg font-black tracking-tight uppercase">Hizmet Geçmişi</h1>
          <p className="text-[10px] font-bold opacity-80 uppercase tracking-widest mt-1">
            Tamamlanan İşlemler
          </p>
        </div>
        
        {/* Dekoratif Işık Efekti */}
        <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 -rotate-45 translate-x-10 -translate-y-10 rounded-full blur-2xl pointer-events-none" />
      </div>

      {/* --- İÇERİK ALANI --- */}
      {loading ? (
        // SKELETON LOADING (Yükleniyor Efekti)
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-24 bg-white/20 animate-pulse rounded-[30px] border border-white/40 shadow-sm" />
          ))}
        </div>
      ) : orders.length > 0 ? (
        // SİPARİŞ LİSTESİ
        <div className="space-y-3">
          {orders.map((order, idx) => {
            const OrderIcon = CATEGORY_ICONS[order.category] || Wrench;
            const orderTheme = THEME_MAP[order.category] || THEME_MAP.TECHNICAL;

            return (
              <motion.div
                key={order.id || idx}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.1 }}
                className="bg-white/40 backdrop-blur-xl border border-white/50 p-5 rounded-[30px] flex items-center gap-4 shadow-sm hover:bg-white/60 transition-all cursor-default group"
              >
                {/* Sol İkon Alanı */}
                <div className={`p-3.5 rounded-2xl bg-white/60 shadow-sm border border-white/60 ${orderTheme.main} group-hover:scale-105 transition-transform`}>
                  <OrderIcon size={22} weight="duotone" />
                </div>

                {/* Detaylar */}
                <div className="flex-1 min-w-0">
                  <div className="flex justify-between items-center mb-1">
                    <h3 className="text-xs font-black text-slate-700 uppercase truncate pr-2">
                      {order.service}
                    </h3>
                    <span className={`text-[11px] font-bold ${orderTheme.main}`}>
                      {order.price} ₺
                    </span>
                  </div>
                  
                  <div className="flex justify-between items-end">
                    <div className="flex items-center gap-1.5 text-slate-500">
                      <CalendarCheck size={14} weight="duotone" />
                      <span className="text-[10px] font-bold uppercase tracking-wider">
                        {order.date}
                      </span>
                    </div>
                    
                    <span className="px-3 py-1 bg-emerald-500/10 text-emerald-700 text-[8px] font-black uppercase rounded-lg tracking-wider border border-emerald-500/20">
                      {order.status}
                    </span>
                  </div>
                </div>

                <CaretRight size={14} weight="bold" className="text-slate-400 group-hover:text-slate-600 transition-colors" />
              </motion.div>
            );
          })}
        </div>
      ) : (
        // BOŞ DURUM (EMPTY STATE - Backend boş döndü)
        <motion.div 
          initial={{ opacity: 0, scale: 0.95 }} 
          animate={{ opacity: 1, scale: 1 }}
          className="py-16 text-center space-y-5 bg-white/20 backdrop-blur-md rounded-[40px] border border-white/40 mx-2 shadow-inner"
        >
          <div className="w-20 h-20 bg-white/40 rounded-full flex items-center justify-center mx-auto mb-2 border border-white/50 shadow-sm">
             <ClockCounterClockwise size={40} weight="duotone" className="text-slate-400 opacity-80" />
          </div>
          <div className="px-8">
             <h3 className="text-sm font-black text-slate-600 uppercase tracking-tight">Kayıt Bulunamadı</h3>
             <p className="text-[10px] font-medium text-slate-500 mt-2 leading-relaxed">
               Sistemimizde tamamlanmış bir hizmet geçmişiniz bulunmuyor.
             </p>
          </div>
        </motion.div>
      )}
      
      {/* Alt Bilgi (Sadece veri varsa göster) */}
      {!loading && orders.length > 0 && (
        <div className="text-center opacity-40 pt-2">
          <p className="text-[8px] font-bold text-slate-600 uppercase tracking-[0.3em]">
            Listelenen İşlem: {orders.length}
          </p>
        </div>
      )}
    </motion.div>
  );
}