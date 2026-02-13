'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  Briefcase, ShieldCheck, RocketLaunch, CheckCircle, 
  Info, User, Phone, Envelope, Storefront, Wrench, LockKey, CaretDown 
} from '@phosphor-icons/react';

const THEME_MAP: any = {
  TECHNICAL: { bg: 'bg-blue-600', main: 'text-blue-600', border: 'border-blue-100', light: 'bg-blue-50/50' },
  CONSTRUCTION: { bg: 'bg-purple-600', main: 'text-purple-600', border: 'border-purple-100', light: 'bg-purple-50/50' },
  CLIMATE: { bg: 'bg-orange-600', main: 'text-orange-600', border: 'border-orange-100', light: 'bg-orange-50/50' },
  TECH: { bg: 'bg-indigo-600', main: 'text-indigo-600', border: 'border-indigo-100', light: 'bg-indigo-50/50' },
  LIFE: { bg: 'bg-emerald-600', main: 'text-emerald-600', border: 'border-emerald-100', light: 'bg-emerald-50/50' }
};

export default function BecomeProviderView() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  
  // Form Verileri
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    businessName: '',
    category: '',
    phone: '',
    email: '',
    password: ''
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    // Backend Simülasyonu
    setTimeout(() => {
      setLoading(false);
      setSuccess(true); // Başarılı ekranını tetikle
    }, 2000);
  };

  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      className="p-4 space-y-5 pb-24 overflow-x-hidden"
    >
      {/* --- ÜST TANITIM KARTI --- */}
      <div className={`relative overflow-hidden ${theme.bg} p-6 rounded-[35px] shadow-lg text-center text-white`}>
        <div className="relative z-10">
          <div className="bg-white/20 w-12 h-12 rounded-2xl flex items-center justify-center mx-auto mb-2 backdrop-blur-md">
            <Briefcase size={28} weight="duotone" />
          </div>
          <h1 className="text-lg font-black tracking-tight uppercase">Usta Aramıza Katıl</h1>
          <p className="text-[9px] font-bold opacity-80 uppercase tracking-widest">Kendi İşinin Patronu Ol</p>
        </div>
        <div className="absolute top-0 right-0 w-24 h-24 bg-white/10 -rotate-45 translate-x-8 -translate-y-8 rounded-full blur-xl" />
      </div>

      <AnimatePresence mode="wait">
        {success ? (
          // --- BAŞARILI KAYIT EKRANI ---
          <motion.div 
            key="success"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="bg-emerald-50 border border-emerald-100 p-8 rounded-[40px] text-center space-y-4"
          >
            <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto text-emerald-600">
              <CheckCircle size={48} weight="duotone" />
            </div>
            <div>
              <h3 className="text-lg font-black text-emerald-800 uppercase">Başvuru Alındı!</h3>
              <p className="text-[10px] font-bold text-emerald-600 mt-2 leading-relaxed">
                Usta profiliniz incelemeye alınmıştır. En kısa sürede sizinle iletişime geçeceğiz.
              </p>
            </div>
          </motion.div>
        ) : (
          // --- KAYIT FORMU ---
          <motion.div key="form" initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
            
            {/* Avantajlar */}
            <div className="grid grid-cols-2 gap-2 mb-5">
              <AdvantageItem icon={ShieldCheck} label="Onaylı Profil" theme={theme} />
              <AdvantageItem icon={RocketLaunch} label="Hızlı İş Alımı" theme={theme} />
            </div>

            <div className="bg-white/40 backdrop-blur-xl border border-white/60 p-5 rounded-[35px] shadow-sm relative">
              <div className="flex items-center gap-2 mb-4 px-1 opacity-60">
                  <Info size={14} weight="bold" />
                  <span className="text-[9px] font-black uppercase tracking-widest">Başvuru Formu</span>
              </div>
              
              <form onSubmit={handleSubmit} className="space-y-3">
                {/* Ad & Soyad */}
                <div className="grid grid-cols-2 gap-2">
                  <SidebarInput placeholder="Ad" icon={<User />} value={formData.firstName} onChange={(v: string)=>setFormData({...formData, firstName:v})} theme={theme} />
                  <SidebarInput placeholder="Soyad" value={formData.lastName} onChange={(v: string)=>setFormData({...formData, lastName:v})} theme={theme} />
                </div>

                {/* İşletme Adı */}
                <SidebarInput placeholder="İşletme Adı (Opsiyonel)" icon={<Storefront />} value={formData.businessName} onChange={(v: string)=>setFormData({...formData, businessName:v})} theme={theme} />

                {/* Kategori Seçimi */}
                <div className="relative">
                  <span className={`absolute left-4 top-1/2 -translate-y-1/2 ${theme.main}`}><Wrench size={18} weight="bold" /></span>
                  <select 
                    className="w-full bg-white/50 border border-white/60 p-3.5 pl-12 rounded-[20px] text-xs font-bold text-slate-700 outline-none appearance-none cursor-pointer focus:bg-white transition-all"
                    value={formData.category}
                    onChange={(e) => setFormData({...formData, category: e.target.value})}
                  >
                    <option value="">Uzmanlık Alanı Seç...</option>
                    <option value="TECHNICAL">Teknik Servis</option>
                    <option value="CLIMATE">İklimlendirme (Klima/Kombi)</option>
                    <option value="CONSTRUCTION">Yapı & Dekorasyon</option>
                    <option value="TECH">Teknoloji & Tamir</option>
                  </select>
                  <CaretDown size={14} weight="bold" className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                </div>

                {/* İletişim */}
                <SidebarInput placeholder="Telefon (05xx)" icon={<Phone />} value={formData.phone} onChange={(v: string)=>setFormData({...formData, phone:v})} theme={theme} />
                <SidebarInput placeholder="E-posta" icon={<Envelope />} value={formData.email} onChange={(v: string)=>setFormData({...formData, email:v})} theme={theme} />
                
                {/* Şifre */}
                <SidebarInput placeholder="Şifre Oluştur" type="password" icon={<LockKey />} value={formData.password} onChange={(v: string)=>setFormData({...formData, password:v})} theme={theme} />

                <button 
                  type="submit"
                  disabled={loading}
                  className={`w-full py-4 rounded-[22px] text-white font-black text-[10px] uppercase tracking-[0.2em] shadow-lg active:scale-95 transition-all mt-2 flex items-center justify-center gap-2 ${theme.bg} ${loading ? 'opacity-60' : ''}`}
                >
                  {loading ? 'İşleniyor...' : 'Başvuruyu Tamamla'}
                  {!loading && <CheckCircle size={16} weight="bold" />}
                </button>
              </form>
            </div>

            {/* Yasal Uyarı */}
            <div className={`mt-4 p-4 rounded-[25px] border border-dashed ${theme.border} ${theme.light}`}>
              <div className="flex gap-2">
                <CheckCircle size={16} weight="fill" className={theme.main} />
                <p className="text-[8px] font-bold text-slate-600 leading-relaxed uppercase tracking-tighter">
                  Başvurarak <span className="underline cursor-pointer">Hizmet Veren Sözleşmesini</span> kabul etmiş sayılırsınız.
                </p>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      <div className="text-center opacity-30">
        <p className="text-[8px] font-black uppercase tracking-[0.3em]">v1.0.2 // Provider Operations</p>
      </div>
    </motion.div>
  );
}

// --- YARDIMCI BİLEŞENLER ---

function AdvantageItem({ icon: Icon, label, theme }: any) {
  return (
    <div className="bg-white/40 backdrop-blur-md border border-white/60 p-2.5 rounded-2xl flex flex-col items-center text-center gap-1 shadow-sm">
      <Icon size={18} className={theme.main} weight="fill" />
      <span className="text-[8px] font-black uppercase text-slate-600 tracking-tighter">{label}</span>
    </div>
  );
}

function SidebarInput({ placeholder, icon, value, onChange, type="text", theme }: any) {
  return (
    <div className="relative">
      {icon && <span className={`absolute left-4 top-1/2 -translate-y-1/2 ${theme.main}`}>{React.cloneElement(icon, { size: 18, weight: 'bold' })}</span>}
      <input 
        type={type}
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className={`w-full bg-white/50 border border-white/60 p-3.5 ${icon ? 'pl-12' : 'pl-4'} rounded-[20px] text-xs font-bold text-slate-800 outline-none focus:bg-white transition-all placeholder:text-slate-400`}
      />
    </div>
  );
}