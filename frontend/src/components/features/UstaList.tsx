'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Star, MapPin, Phone, WhatsappLogo, CaretRight, Ghost, Wrench } from '@phosphor-icons/react';
import { useCategory } from '@/context/CategoryContext';
import UstaDetailWidget from './UstaDetailWidget'; // Widget'ı buraya çağırıyoruz

export default function UstaList() {
  const { activeCategory } = useCategory();
  
  // State Yönetimi
  const [providers, setProviders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUsta, setSelectedUsta] = useState<any>(null); // Widget kontrolü burada!

  // Backend'den Veri Çekme
  useEffect(() => {
    const fetchProviders = async () => {
      setLoading(true);
      try {
        // Gerçek API İsteği
        const response = await fetch(`/api/providers?category=${activeCategory}`);
        
        // --- Backend Bağlanamazsa Hata Vermemesi İçin Kontrol ---
        if (!response.ok) {
            // Eğer backend yoksa boş dizi dön (Hata patlatma)
            console.warn("Backend bağlantısı sağlanamadı, boş liste gösteriliyor.");
            setProviders([]); 
        } else {
            const data = await response.json();
            setProviders(Array.isArray(data) ? data : []);
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
          // SKELETON LOADING
          [1, 2, 3].map(i => (
            <div key={i} className="h-36 bg-white/20 animate-pulse rounded-[35px] border border-white/40" />
          ))
        ) : providers.length > 0 ? (
          // LİSTELEME
          providers.map((usta, index) => (
            <motion.div 
              key={usta.id || index}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => setSelectedUsta(usta)} // TIKLAYINCA WIDGET AÇ
              className="group relative bg-white/40 backdrop-blur-md border border-white/50 p-5 rounded-[35px] shadow-sm hover:shadow-xl hover:bg-white/60 transition-all duration-300 cursor-pointer active:scale-[0.98]"
            >
              {/* Üst Kısım */}
              <div className="flex items-center gap-4 mb-5">
                <div className="w-14 h-14 bg-white/60 rounded-[20px] flex items-center justify-center text-slate-600 text-lg font-black shadow-sm border border-white">
                  {usta.first_name?.[0]}{usta.last_name?.[0]}
                </div>
                <div>
                  <h3 className="font-black text-slate-800 text-base uppercase tracking-tight">
                    {usta.first_name} {usta.last_name}
                  </h3>
                  <div className="flex items-center gap-2 mt-0.5">
                    <Star size={14} weight="fill" className="text-amber-500" />
                    <span className="text-xs font-bold text-slate-600">{usta.rating || 'Yeni'}</span>
                  </div>
                </div>
                
                {/* Mesafe */}
                <div className="ml-auto flex items-center gap-1 px-3 py-1.5 rounded-full bg-white/40 border border-white/60">
                  <MapPin size={12} weight="fill" className="text-slate-400" />
                  <span className="text-[9px] font-black text-slate-500 uppercase">{usta.dist || '? KM'}</span>
                </div>
              </div>

              {/* Butonlar */}
              <div className="flex gap-2">
                <button 
                  onClick={(e) => { e.stopPropagation(); }}
                  className="flex-[1.2] py-3.5 rounded-[20px] bg-slate-700 text-white font-black text-[9px] uppercase tracking-widest flex items-center justify-center gap-2 shadow-md active:scale-95 transition-transform"
                >
                  <Phone size={16} weight="fill" /> Ara
                </button>
                <button 
                  onClick={(e) => { e.stopPropagation(); }}
                  className="flex-1 py-3.5 rounded-[20px] bg-emerald-50 text-emerald-700 border border-emerald-100 font-black text-[9px] uppercase tracking-widest flex items-center justify-center gap-2 active:scale-95 transition-transform"
                >
                  <WhatsappLogo size={18} weight="fill" /> Yaz
                </button>
              </div>

              <div className="absolute bottom-5 right-5 opacity-0 group-hover:opacity-100 transition-opacity">
                <CaretRight size={18} weight="bold" className="text-slate-400" />
              </div>
            </motion.div>
          ))
        ) : (
          // BOŞ DURUM (Veri Yoksa)
          <motion.div 
            initial={{ opacity: 0 }} 
            animate={{ opacity: 1 }}
            className="py-16 text-center flex flex-col items-center justify-center opacity-60"
          >
            <div className="w-20 h-20 bg-white/30 rounded-full flex items-center justify-center mb-3 border border-white/40">
               <Ghost size={40} weight="duotone" className="text-slate-400" />
            </div>
            <h3 className="text-sm font-black text-slate-600 uppercase tracking-tight">Kayıt Bulunamadı</h3>
            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">
              Bölgenizde aktif hizmet veren bulunamadı.
            </p>
          </motion.div>
        )}
      </div>

      {/* --- DETAY WIDGET (Burada Çağırıyoruz) --- */}
      <UstaDetailWidget 
        usta={selectedUsta} 
        isOpen={!!selectedUsta} 
        onClose={() => setSelectedUsta(null)} 
      />
    </>
  );
}