'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  Handshake, Scales, Warning, Gavel, 
  FileText, ShieldCheck, Money, Clock
} from '@phosphor-icons/react';

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', bg: 'bg-blue-600', border: 'border-blue-200', light: 'bg-blue-50/50' },
  CONSTRUCTION: { main: 'text-purple-600', bg: 'bg-purple-600', border: 'border-purple-200', light: 'bg-purple-50/50' },
  CLIMATE: { main: 'text-orange-600', bg: 'bg-orange-600', border: 'border-orange-200', light: 'bg-orange-50/50' },
  TECH: { main: 'text-indigo-600', bg: 'bg-indigo-600', border: 'border-indigo-200', light: 'bg-indigo-50/50' },
  LIFE: { main: 'text-emerald-600', bg: 'bg-emerald-600', border: 'border-emerald-200', light: 'bg-emerald-50/50' }
};

export default function AgreementView() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      className="p-4 space-y-6 pb-24 overflow-x-hidden"
    >
      {/* --- BAŞLIK KARTI --- */}
      <div className={`relative overflow-hidden ${theme.bg} p-8 rounded-[35px] shadow-lg text-center text-white`}>
        <div className="relative z-10">
          <Handshake size={42} weight="duotone" className="mx-auto mb-3 opacity-90" />
          <h1 className="text-xl font-black tracking-tight uppercase">Kullanıcı Sözleşmesi</h1>
          <p className="text-[9px] font-bold opacity-80 uppercase tracking-widest mt-1">Mesafeli Aracılık Sözleşmesi</p>
        </div>
        <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 -rotate-45 translate-x-8 -translate-y-8 rounded-full blur-xl" />
      </div>

      {/* --- SÖZLEŞME İÇERİĞİ (Glassmorphism) --- */}
      <div className="bg-white/40 backdrop-blur-md border border-white/60 p-6 rounded-[40px] space-y-8 shadow-sm">
        
        {/* Madde 1: Statü */}
        <section className="space-y-3">
          <div className="flex items-center gap-3">
            <ShieldCheck size={20} weight="fill" className={theme.main} />
            <h2 className="text-xs font-black text-slate-800 uppercase tracking-tight">1. Aracı Hizmet Statüsü</h2>
          </div>
          <p className="text-[11px] font-bold text-slate-500 leading-relaxed pl-1">
            USTA, <strong>6563 sayılı Kanun</strong> uyarınca bir "Aracı Hizmet Sağlayıcı"dır. Platform, Hizmet Veren (Usta) ile Hizmet Alan'ı buluşturur; ancak sunulan hizmetin tarafı, bayisi veya işvereni değildir.
          </p>
        </section>

        {/* Madde 2: Sorumluluk Sınırı (Kritik) */}
        <section className="bg-red-50/30 p-5 rounded-[25px] border border-red-100/50 space-y-2">
          <div className="flex items-center gap-3 text-red-600">
            <Warning size={20} weight="fill" />
            <h2 className="text-xs font-black uppercase tracking-tight">2. Sorumluluk Sınırı</h2>
          </div>
          <p className="text-[10px] font-bold text-slate-600 leading-relaxed">
            Hizmetin ifası sırasında oluşabilecek maddi zararlar, hatalı işçilik veya gecikmelerden <strong>doğrudan Hizmet Veren (Usta) sorumludur.</strong> USTA, bu uyuşmazlıklarda tazminat yükümlülüğü altında değildir.
          </p>
        </section>

        {/* Madde 3: Ödeme Güvenliği */}
        <section className="space-y-3">
          <div className="flex items-center gap-3">
            <Money size={20} weight="fill" className={theme.main} />
            <h2 className="text-xs font-black text-slate-800 uppercase tracking-tight">3. Ödeme ve Komisyon</h2>
          </div>
          <p className="text-[11px] font-bold text-slate-500 leading-relaxed pl-1">
            Platform üzerinden yapılan ödemeler <strong>6493 sayılı Kanun</strong> lisanslı ödeme kuruluşları aracılığıyla yapılır. Elden yapılan ödemeler USTA güvencesi dışındadır ve takip edilemez.
          </p>
        </section>

        {/* Madde 4: Cayma Hakkı */}
        <section className="space-y-3">
          <div className="flex items-center gap-3">
            <Clock size={20} weight="fill" className={theme.main} />
            <h2 className="text-xs font-black text-slate-800 uppercase tracking-tight">4. İptal ve Cayma</h2>
          </div>
          <p className="text-[11px] font-bold text-slate-500 leading-relaxed pl-1">
            Hizmetin ifasına başlandıktan sonra cayma hakkı kullanılamaz. Randevuya 2 saatten az süre kala yapılan iptallerde "servis çağrı bedeli" iade edilmeyebilir.
          </p>
        </section>

        {/* Madde 5: Yetki */}
        <section className="space-y-2">
          <div className="flex items-center gap-3">
            <Gavel size={20} weight="fill" className={theme.main} />
            <h2 className="text-xs font-black text-slate-800 uppercase tracking-tight">5. Uyuşmazlık</h2>
          </div>
          <p className="text-[11px] font-bold text-slate-500 pl-1">
            Uyuşmazlıklarda her yıl belirlenen parasal sınırlar dahilinde <strong>Tüketici Hakem Heyetleri</strong> ve İstanbul Mahkemeleri yetkilidir.
          </p>
        </section>
      </div>

      {/* --- ONAY BUTONU --- */}
      <div className="pt-2 text-center">
         <p className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] mb-4 px-4">
           Uygulamayı kullanarak yukarıdaki şartları peşinen kabul etmiş sayılırsınız.
         </p>
      </div>

      <div className="text-center opacity-30 pb-4">
         <p className="text-[8px] font-black uppercase tracking-widest">v1.0.2 // Legal Release 2026</p>
      </div>
    </motion.div>
  );
}