'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  Headset, PaperPlaneRight, Buildings, 
  WarningCircle, CheckCircle, CaretDown,
  ChatText, Gavel, Lifebuoy, Warning,
  UserCircle, Desktop
} from '@phosphor-icons/react';

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', bg: 'bg-blue-600', border: 'border-blue-200', light: 'bg-blue-50/50' },
  CONSTRUCTION: { main: 'text-purple-600', bg: 'bg-purple-600', border: 'border-purple-200', light: 'bg-purple-50/50' },
  CLIMATE: { main: 'text-orange-600', bg: 'bg-orange-600', border: 'border-orange-200', light: 'bg-orange-50/50' },
  TECH: { main: 'text-indigo-600', bg: 'bg-indigo-600', border: 'border-indigo-200', light: 'bg-indigo-50/50' },
  LIFE: { main: 'text-emerald-600', bg: 'bg-emerald-600', border: 'border-emerald-200', light: 'bg-emerald-50/50' }
};

// ŞİKAYET KONULARI
const TOPICS = {
  USTA: [
    { id: 1, title: 'Randevuya Gelmedi' },
    { id: 2, title: 'Fiyat Uyuşmazlığı' },
    { id: 3, title: 'Kötü İşçilik / Eksik Hizmet' },
    { id: 4, title: 'Güvenlik / Kaba Davranış' }
  ],
  APP: [
    { id: 5, title: 'Teknik Hata / Uygulama Çökmesi' },
    { id: 6, title: 'Ödeme / Fatura Sorunu' },
    { id: 7, title: 'Kişisel Veri / Gizlilik Talebi' },
    { id: 8, title: 'Öneri veya Geri Bildirim' }
  ]
};

export default function SupportView() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const [activeTab, setActiveTab] = useState<'USTA' | 'APP'>('USTA');
  const [selectedTopic, setSelectedTopic] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!message || !selectedTopic) return;
    
    setLoading(true);
    // Backend simülasyonu
    setTimeout(() => {
      setLoading(false);
      setSuccess(true);
      setTimeout(() => {
        setSuccess(false);
        setMessage('');
        setSelectedTopic('');
      }, 4000);
    }, 1500);
  };

  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      className="p-4 space-y-6 pb-24 overflow-x-hidden"
    >
      {/* --- BAŞLIK --- */}
      <div className={`${theme.bg} p-8 rounded-[35px] shadow-lg text-center text-white relative overflow-hidden`}>
        <div className="relative z-10">
          <Headset size={42} weight="duotone" className="mx-auto mb-2 opacity-90" />
          <h1 className="text-xl font-black tracking-tight uppercase">Destek Merkezi</h1>
          <p className="text-[10px] font-bold opacity-70 uppercase tracking-widest">Çözüm İçin Buradayız</p>
        </div>
        <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 -rotate-45 translate-x-8 -translate-y-8 rounded-full blur-xl" />
      </div>

      {/* --- ŞİKAYET TİPİ SEÇİCİ --- */}
      <div className="flex p-1.5 bg-black/5 backdrop-blur-md rounded-[26px]">
        <TabBtn 
          active={activeTab === 'USTA'} 
          onClick={() => setActiveTab('USTA')} 
          icon={<UserCircle size={18} />} 
          label="Usta Şikayeti" 
          theme={theme}
        />
        <TabBtn 
          active={activeTab === 'APP'} 
          onClick={() => setActiveTab('APP')} 
          icon={<Desktop size={18} />} 
          label="Uygulama Şikayeti" 
          theme={theme}
        />
      </div>

      {/* --- FORM ALANI --- */}
      <AnimatePresence mode="wait">
        {success ? (
          <motion.div 
            initial={{ opacity: 0, scale: 0.9 }} 
            animate={{ opacity: 1, scale: 1 }} 
            className="bg-emerald-50 border border-emerald-100 p-10 rounded-[40px] text-center"
          >
            <CheckCircle size={56} weight="duotone" className="text-emerald-500 mx-auto mb-4" />
            <h3 className="text-lg font-black text-emerald-800 uppercase">Talebiniz Alındı</h3>
            <p className="text-[10px] font-bold text-emerald-600 mt-2 uppercase tracking-wide">
              Destek ekibimiz 24 saat içinde dönüş yapacaktır.
            </p>
          </motion.div>
        ) : (
          <motion.form 
            key={activeTab}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            onSubmit={handleSubmit} 
            className="bg-white/40 backdrop-blur-md border border-white/60 p-6 rounded-[40px] shadow-sm space-y-5"
          >
            {/* Konu Seçimi */}
            <div className="space-y-1.5">
              <label className="text-[9px] font-black text-slate-400 uppercase ml-3 tracking-widest">Şikayet Konusu</label>
              <div className="relative">
                <select 
                  value={selectedTopic}
                  onChange={(e) => setSelectedTopic(e.target.value)}
                  className="w-full bg-white/60 border border-white/80 p-4 rounded-[20px] text-xs font-bold text-slate-800 outline-none appearance-none cursor-pointer focus:bg-white transition-all"
                >
                  <option value="">Seçiniz...</option>
                  {TOPICS[activeTab].map(t => <option key={t.id} value={t.title}>{t.title}</option>)}
                </select>
                <CaretDown size={16} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
              </div>
            </div>

            {/* Mesaj Alanı */}
            <div className="space-y-1.5">
              <label className="text-[9px] font-black text-slate-400 uppercase ml-3 tracking-widest">Açıklama</label>
              <textarea 
                rows={5}
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Lütfen sorununuzu detaylandırın..."
                className="w-full bg-white/60 border border-white/80 p-5 rounded-[25px] text-xs font-bold text-slate-800 outline-none focus:bg-white transition-all resize-none placeholder:text-slate-300"
              />
            </div>

            <button 
              disabled={loading || !message || !selectedTopic}
              className={`w-full py-5 rounded-[22px] text-white font-black text-[10px] uppercase tracking-[0.2em] shadow-xl active:scale-95 transition-all flex items-center justify-center gap-3 ${theme.bg} ${loading ? 'opacity-50' : ''}`}
            >
              {loading ? 'Gönderiliyor...' : 'Talebi Gönder'}
              <PaperPlaneRight size={18} weight="bold" />
            </button>
          </motion.form>
        )}
      </AnimatePresence>

      {/* --- YASAL NOTLAR & RESMİ KANALLAR --- */}
      <div className="bg-amber-50/50 border border-amber-100 p-5 rounded-[30px] space-y-3">
        <div className="flex items-center gap-2 text-amber-600">
          <Gavel size={18} weight="duotone" />
          <span className="text-[10px] font-black uppercase tracking-tighter">Yasal Bilgilendirme</span>
        </div>
        <p className="text-[9px] font-bold text-slate-600 leading-snug">
          USTA, bağımsız hizmet verenler ile kullanıcıları buluşturan bir platformdur. Hizmet kusurları durumunda <strong>Tüketici Hakem Heyeti</strong>'ne başvurma hakkınız saklıdır. Uygulamaya dair ciddi sorunlar için: <span className="underline italic">hukuk@ustaapp.com</span>
        </p>
      </div>

      <div className="text-center opacity-30 pt-2">
        <p className="text-[8px] font-black uppercase tracking-[0.3em]">v1.0.2 // Customer Success Integrated</p>
      </div>
    </motion.div>
  );
}

function TabBtn({ active, onClick, icon, label, theme }: any) {
  return (
    <button 
      onClick={onClick}
      className={`flex-1 flex flex-col items-center gap-1 py-3 rounded-[20px] transition-all ${active ? `${theme.bg} text-white shadow-lg` : 'text-slate-400 hover:bg-black/5'}`}
    >
      {icon}
      <span className="text-[8px] font-black uppercase tracking-tighter">{label}</span>
    </button>
  );
}