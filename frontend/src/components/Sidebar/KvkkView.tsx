'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { ShieldCheck, Lock, Eye, IdentificationCard, MapPin, PaperPlaneRight, Warning, CheckCircle } from '@phosphor-icons/react';

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', bg: 'bg-blue-600', border: 'border-blue-200', light: 'bg-blue-50/50' },
  CONSTRUCTION: { main: 'text-purple-600', bg: 'bg-purple-600', border: 'border-purple-200', light: 'bg-purple-50/50' },
  CLIMATE: { main: 'text-orange-600', bg: 'bg-orange-600', border: 'border-orange-200', light: 'bg-orange-50/50' },
  TECH: { main: 'text-indigo-600', bg: 'bg-indigo-600', border: 'border-indigo-200', light: 'bg-indigo-50/50' },
  LIFE: { main: 'text-emerald-600', bg: 'bg-emerald-600', border: 'border-emerald-200', light: 'bg-emerald-50/50' }
};

export default function KvkkView() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      className="p-4 space-y-6 pb-20 overflow-x-hidden"
    >
      {/* Başlık Kartı */}
      <div className={`relative overflow-hidden ${theme.bg} p-8 rounded-[35px] shadow-lg text-center text-white`}>
        <div className="relative z-10">
          <ShieldCheck size={42} weight="duotone" className="mx-auto mb-3 opacity-90" />
          <h1 className="text-xl font-black tracking-tight uppercase">KVKK Aydınlatma</h1>
          <p className="text-[9px] font-bold opacity-80 uppercase tracking-widest mt-1">6698 Sayılı Kanun Kapsamında</p>
        </div>
        <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 -rotate-45 translate-x-8 -translate-y-8 rounded-full blur-xl" />
      </div>

      {/* İçerik Alanı */}
      <div className="bg-white/40 backdrop-blur-md border border-white/60 p-6 rounded-[40px] space-y-8 shadow-sm">
        
        {/* Veri Sorumlusu */}
        <section className="space-y-3">
          <div className="flex items-center gap-3">
            <Lock size={20} weight="fill" className={theme.main} />
            <h2 className="text-xs font-black text-slate-800 uppercase tracking-tight">1. Veri Sorumlusu</h2>
          </div>
          <p className="text-[11px] font-bold text-slate-500 leading-relaxed pl-1">
            Kişisel verileriniz; veri sorumlusu <strong>USTA PLATFORM TEKNOLOJİLERİ A.Ş.</strong> tarafından güvenli altyapımızda işlenmektedir.
          </p>
        </section>

        {/* Veri Kategorileri */}
        <section className="space-y-4">
          <div className="flex items-center gap-3">
            <IdentificationCard size={20} weight="fill" className={theme.main} />
            <h2 className="text-xs font-black text-slate-800 uppercase tracking-tight">2. İşlenen Veriler</h2>
          </div>
          <div className="grid grid-cols-1 gap-2">
            {['Kimlik (Ad, Soyad)', 'İletişim (Telefon)', 'Lokasyon (Hizmet Adresi)', 'Güvenlik (IP, Log)'].map((item, i) => (
              <div key={i} className={`p-3 rounded-2xl border border-white/50 flex items-center gap-3 ${theme.light}`}>
                <CheckCircle size={14} weight="fill" className={theme.main} />
                <span className="text-[10px] font-black text-slate-700 uppercase">{item}</span>
              </div>
            ))}
          </div>
        </section>

        {/* Veri Aktarımı */}
        <section className="space-y-3">
          <div className="flex items-center gap-3">
            <PaperPlaneRight size={20} weight="fill" className={theme.main} />
            <h2 className="text-xs font-black text-slate-800 uppercase tracking-tight">3. Veri Aktarımı</h2>
          </div>
          <p className="text-[11px] font-bold text-slate-500 leading-relaxed pl-1">
            Verileriniz sadece seçtiğiniz <strong>Hizmet Veren (Usta)</strong> ve yasal zorunluluk hallerinde yetkili kamu kurumları ile paylaşılır.
          </p>
        </section>

        {/* Yasal Haklar / İletişim */}
        <div className={`p-5 rounded-[25px] border-2 border-dashed ${theme.border} ${theme.light} text-center`}>
           <div className="flex items-center justify-center gap-2 mb-2 text-amber-600">
             <Warning size={16} weight="bold" />
             <span className="text-[10px] font-black uppercase">Başvuru ve Bilgi</span>
           </div>
           <p className={`text-[11px] font-black uppercase tracking-tighter ${theme.main}`}>hukuk@ustaapp.com</p>
        </div>
      </div>

      <div className="text-center opacity-30">
         <p className="text-[9px] font-black uppercase tracking-widest italic">Son Güncelleme: 12.02.2026</p>
      </div>
    </motion.div>
  );
}