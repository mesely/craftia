'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Star, MapPin, Phone, WhatsappLogo, CaretRight, Ghost } from '@phosphor-icons/react';
import { useCategory } from '@/context/CategoryContext';
import UstaDetailWidget from './UstaDetailWidget';

export default function UstaList() {
  const { activeCategory } = useCategory();
  const [providers, setProviders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUsta, setSelectedUsta] = useState<any>(null);

  useEffect(() => {
    const fetchProviders = async () => {
      setLoading(true);
      try {
        // 1. API Gateway URL ve Endpoint düzeltildi
        const response = await fetch(`http://localhost:3000/api/v1/providers?category=${activeCategory}`);
        
        if (!response.ok) {
            console.warn("Backend bağlantısı sağlanamadı.");
            setProviders([]); 
        } else {
            const data = await response.json();
            // 2. DİKKAT: Backend veri yapısı { providers: [...] } şeklinde geliyor
            setProviders(data.providers || []);
        }
      } catch (err) {
        console.error("Veri hatası:", err);
        setProviders([]);
      } finally {
        setLoading(false);
      }
    };

    fetchProviders();
  }, [activeCategory]);

  return (
    <>
      <div className="space-y-4 pb-32 px-1">
        {loading ? (
          [1, 2, 3].map(i => (
            <div key={i} className="h-36 bg-white/20 animate-pulse rounded-[35px] border border-white/40" />
          ))
        ) : providers.length > 0 ? (
          providers.map((usta, index) => (
            <motion.div 
              key={usta.id || index}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => setSelectedUsta(usta)}
              className="group relative bg-white/40 backdrop-blur-md border border-white/50 p-5 rounded-[35px] shadow-sm hover:shadow-xl hover:bg-white/60 transition-all duration-300 cursor-pointer active:scale-[0.98]"
            >
              <div className="flex items-center gap-4 mb-5">
                {/* 3. İSİM LOGİĞİ: businessName'in ilk iki harfi */}
                <div className="w-14 h-14 bg-white/60 rounded-[20px] flex items-center justify-center text-slate-600 text-lg font-black shadow-sm border border-white">
                  {usta.businessName?.substring(0, 2).toUpperCase() || 'UP'}
                </div>
                <div>
                  {/* 4. ALAN ADI: Crawler'dan gelen businessName */}
                  <h3 className="font-black text-slate-800 text-base uppercase tracking-tight">
                    {usta.businessName || 'İsimsiz İşletme'}
                  </h3>
                  <div className="flex items-center gap-2 mt-0.5">
                    <Star size={14} weight="fill" className="text-amber-500" />
                    <span className="text-xs font-bold text-slate-600">{usta.rating || '4.8'}</span>
                  </div>
                </div>
                
                <div className="ml-auto flex items-center gap-1 px-3 py-1.5 rounded-full bg-white/40 border border-white/60">
                  <MapPin size={12} weight="fill" className="text-slate-400" />
                  <span className="text-[9px] font-black text-slate-500 uppercase">{usta.district || 'Merkez'}</span>
                </div>
              </div>

              <div className="flex gap-2">
                {/* 5. TELEFON: usta.phoneNumber üzerinden arama */}
                <a 
                  href={`tel:${usta.phoneNumber}`}
                  onClick={(e) => { e.stopPropagation(); }}
                  className="flex-[1.2] py-3.5 rounded-[20px] bg-slate-700 text-white font-black text-[9px] uppercase tracking-widest flex items-center justify-center gap-2 shadow-md active:scale-95 transition-transform"
                >
                  <Phone size={16} weight="fill" /> Ara
                </a>
                <a 
                  href={`https://wa.me/${usta.phoneNumber?.replace(/\D/g, '')}`}
                  onClick={(e) => { e.stopPropagation(); }}
                  className="flex-1 py-3.5 rounded-[20px] bg-emerald-50 text-emerald-700 border border-emerald-100 font-black text-[9px] uppercase tracking-widest flex items-center justify-center gap-2 active:scale-95 transition-transform"
                >
                  <WhatsappLogo size={18} weight="fill" /> Yaz
                </a>
              </div>

              <div className="absolute bottom-5 right-5 opacity-0 group-hover:opacity-100 transition-opacity">
                <CaretRight size={18} weight="bold" className="text-slate-400" />
              </div>
            </motion.div>
          ))
        ) : (
          <motion.div 
            initial={{ opacity: 0 }} animate={{ opacity: 1 }}
            className="py-16 text-center flex flex-col items-center justify-center opacity-60"
          >
            <Ghost size={40} className="text-slate-400 mb-3" />
            <h3 className="text-sm font-black text-slate-600 uppercase">Kayıt Bulunamadı</h3>
          </motion.div>
        )}
      </div>

      <UstaDetailWidget usta={selectedUsta} isOpen={!!selectedUsta} onClose={() => setSelectedUsta(null)} />
    </>
  );
}