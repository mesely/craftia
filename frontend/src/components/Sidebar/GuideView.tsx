'use client';

import React from 'react';
import { motion } from 'framer-motion'; // Next 15 uyumlu
import { useCategory } from '@/context/CategoryContext';
import { 
  Info, MapPin, Funnel, Phone, 
  UserCircle, CheckCircle, Wrench, 
  PaintRoller, Thermometer, Monitor, Sparkle,
  ShieldWarning, Handshake, Gavel
} from '@phosphor-icons/react';

// KATEGORİ RENK VE İKON HARİTASI
const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', bg: 'bg-blue-600', border: 'border-blue-200', light: 'bg-blue-50' },
  CONSTRUCTION: { main: 'text-purple-600', bg: 'bg-purple-600', border: 'border-purple-200', light: 'bg-purple-50' },
  CLIMATE: { main: 'text-orange-600', bg: 'bg-orange-600', border: 'border-orange-200', light: 'bg-orange-50' },
  TECH: { main: 'text-indigo-600', bg: 'bg-indigo-600', border: 'border-indigo-200', light: 'bg-indigo-50' },
  LIFE: { main: 'text-emerald-600', bg: 'bg-emerald-600', border: 'border-emerald-200', light: 'bg-emerald-50' }
};

export default function GuideView() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const SECTIONS = [
    {
      id: 1,
      title: "Konum Bazlı Eşleşme",
      icon: <MapPin size={22} weight="duotone" />,
      content: "USTA, en yakınındaki profesyonelleri KM bazlı listeler. Konum izni vererek sana en hızlı ulaşacak ustaları görebilirsin."
    },
    {
      id: 2,
      title: "Akıllı Filtreleme",
      icon: <Funnel size={22} weight="duotone" />,
      content: "Puan, yorum sayısı ve uzmanlık alanına göre filtreleme yaparak, işin için en doğru ustayı saniyeler içinde bulabilirsin."
    },
    {
      id: 3,
      title: "Doğrudan İletişim",
      icon: <Phone size={22} weight="duotone" />,
      content: "Usta kartlarındaki butonlarla direkt arama yapabilir veya WhatsApp üzerinden yazışabilirsin. Arada komisyoncu veya çağrı merkezi yoktur."
    }
  ];

  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      className="p-4 space-y-6 pb-20"
    >
      {/* --- BAŞLIK KARTI --- */}
      <div className={`relative overflow-hidden ${theme.bg} p-8 rounded-[35px] shadow-lg text-center text-white`}>
        <div className="relative z-10">
            <div className="bg-white/20 w-16 h-16 rounded-2xl flex items-center justify-center mx-auto mb-3 backdrop-blur-md">
                <Info size={32} weight="duotone" />
            </div>
            <h1 className="text-xl font-black tracking-tight uppercase">Uygulama Rehberi</h1>
            <p className="text-[10px] font-bold opacity-80 uppercase tracking-widest">USTA Platformunu Tanıyın</p>
        </div>
        {/* Dekoratif Cam Efekti */}
        <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 -rotate-45 translate-x-10 -translate-y-10 rounded-full blur-2xl" />
      </div>

      {/* --- KULLANIM ADIMLARI --- */}
      <div className="space-y-3">
        {SECTIONS.map((section) => (
          <div key={section.id} className="bg-white/40 backdrop-blur-md border border-white/60 p-5 rounded-[28px] shadow-sm">
            <div className="flex items-center gap-4 mb-2">
              <div className={`${theme.main} bg-white p-2.5 rounded-xl shadow-sm`}>
                {section.icon}
              </div>
              <h3 className="text-xs font-black text-slate-800 uppercase tracking-tight">{section.title}</h3>
            </div>
            <p className="text-[11px] font-bold text-slate-500 leading-relaxed pl-1">
              {section.content}
            </p>
          </div>
        ))}
      </div>

      {/* --- ⚠️ YASAL UYARI VE GÜVENLİK (Kritik Bölüm) --- */}
      <div className="bg-amber-50/50 backdrop-blur-sm border border-amber-100 p-6 rounded-[30px] space-y-4">
        <div className="flex items-center gap-2 text-amber-600">
          <ShieldWarning size={20} weight="duotone" />
          <h4 className="text-[11px] font-black uppercase tracking-widest">Güvenlik ve Sorumluluk</h4>
        </div>
        
        <div className="space-y-3">
          <LegalItem 
            icon={<Handshake size={14} />} 
            text="Ödemeler doğrudan usta ve müşteri arasında yapılır. USTA, ödeme süreçlerine müdahil olmaz ve sorumluluk kabul etmez." 
          />
          <LegalItem 
            icon={<Gavel size={14} />} 
            text="USTA bir işveren değildir; sadece bağımsız profesyoneller ile kullanıcıları buluşturan bir ilan platformudur." 
          />
          <LegalItem 
            icon={<CheckCircle size={14} />} 
            text="Hizmet almadan önce ustanın kimlik bilgilerini ve yetki belgelerini kontrol etmeniz güvenliğiniz için önerilir." 
          />
        </div>
      </div>

      {/* --- KATEGORİ ÖZETLERİ --- */}
      <div className="bg-white/20 backdrop-blur-md border border-white/40 p-5 rounded-[30px]">
        <h3 className="text-[10px] font-black uppercase text-slate-400 tracking-widest text-center mb-4">Uzmanlık Alanları</h3>
        <div className="grid grid-cols-2 gap-2">
            <MiniCat label="Tesisat" icon={Wrench} color="text-blue-500" />
            <MiniCat label="Boya" icon={PaintRoller} color="text-purple-500" />
            <MiniCat label="Klima" icon={Thermometer} color="text-orange-500" />
            <MiniCat label="Tamir" icon={Monitor} color="text-indigo-500" />
        </div>
      </div>

      <div className="text-center opacity-30 pt-4">
        <p className="text-[8px] font-black uppercase tracking-[0.3em]">Hukuki Sorular İçin: destek@usta.app</p>
      </div>
    </motion.div>
  );
}

// Yardımcı Bileşenler
function LegalItem({ icon, text }: { icon: any, text: string }) {
  return (
    <div className="flex gap-3 items-start opacity-80">
      <div className="mt-0.5 text-amber-600">{icon}</div>
      <p className="text-[9px] font-bold text-slate-600 leading-snug">{text}</p>
    </div>
  );
}

function MiniCat({ label, icon: Icon, color }: any) {
  return (
    <div className="bg-white/60 p-3 rounded-2xl flex items-center gap-3 border border-white/50 shadow-sm">
      <Icon size={16} weight="fill" className={color} />
      <span className="text-[10px] font-black text-slate-700 uppercase">{label}</span>
    </div>
  );
}