'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { User, Phone, Envelope, LockKey, UserPlus, CheckCircle } from '@phosphor-icons/react';

interface RegisterViewProps {
  onSwitchToLogin: () => void;
}

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-400', bg: 'bg-blue-600' },
  CONSTRUCTION: { main: 'text-purple-400', bg: 'bg-purple-600' },
  TECH: { main: 'text-indigo-400', bg: 'bg-indigo-600' },
  LIFE: { main: 'text-emerald-400', bg: 'bg-emerald-600' }
};

export default function RegisterView({ onSwitchToLogin }: RegisterViewProps) {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const [formData, setFormData] = useState({ name: '', phone: '', email: '', password: '' });
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setTimeout(() => { 
      setLoading(false); 
      alert('Kayıt Başarılı! Şimdi giriş yapabilirsiniz.'); 
      onSwitchToLogin(); 
    }, 1500);
  };

  return (
    <motion.div 
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6"
    >
      <div className="text-center space-y-2">
        <div className={`inline-flex p-5 rounded-[28px] text-white shadow-2xl ${theme.bg} mb-2 ring-4 ring-white/10`}>
          <UserPlus size={32} weight="bold" />
        </div>
        {/* Başlık: Artık Beyaz ve Net */}
        <h1 className="text-3xl font-black text-white tracking-tighter uppercase drop-shadow-sm">Kayıt Ol</h1>
        <p className="text-[11px] font-black text-white/60 uppercase tracking-widest">Usta dünyasına adım at</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-3">
        <GlassInput icon={<User />} placeholder="Ad Soyad" value={formData.name} onChange={(v: string) => setFormData({...formData, name: v})} theme={theme} />
        <GlassInput icon={<Phone />} placeholder="Telefon (05xx...)" value={formData.phone} onChange={(v: string) => setFormData({...formData, phone: v.replace(/[^0-9]/g, '')})} theme={theme} />
        <GlassInput icon={<Envelope />} placeholder="E-posta Adresi" value={formData.email} onChange={(v: string) => setFormData({...formData, email: v})} theme={theme} />
        <GlassInput icon={<LockKey />} type="password" placeholder="Şifre Oluştur" value={formData.password} onChange={(v: string) => setFormData({...formData, password: v})} theme={theme} />
        
        <div className="bg-white/5 p-3 rounded-2xl border border-white/10">
           <p className="text-[9px] text-white/50 font-bold uppercase leading-tight tracking-wide">* Kayıt olarak kullanım koşullarını kabul etmiş sayılırsınız.</p>
        </div>

        <button 
          disabled={loading} 
          className={`w-full py-5 rounded-[25px] text-white font-black text-xs uppercase tracking-[0.2em] shadow-xl active:scale-95 transition-all mt-4 flex items-center justify-center gap-3 ${theme.bg} ${loading ? 'opacity-50' : 'hover:brightness-110'}`}
        >
          {loading ? 'Yükleniyor...' : <>Hesabı Oluştur <CheckCircle size={20} weight="bold" /></>}
        </button>
      </form>

      <div className="text-center pt-4 border-t border-white/10">
        <button 
          onClick={onSwitchToLogin} 
          className={`text-xs font-black uppercase tracking-widest transition-all ${theme.main} hover:text-white hover:scale-105 active:scale-95 flex items-center justify-center gap-2 mx-auto`}
        >
          Zaten üye misin? Giriş Yap
        </button>
      </div>
    </motion.div>
  );
}

function GlassInput({ icon, placeholder, value, onChange, type = 'text', theme }: any) {
  return (
    <div className="relative group">
      <span className={`absolute left-5 top-1/2 -translate-y-1/2 ${theme.main}`}>
        {React.cloneElement(icon, { size: 20, weight: 'bold' })}
      </span>
      {/* Input: text-white ve placeholder-white/40 ile görünürlük artırıldı */}
      <input 
        type={type} 
        placeholder={placeholder} 
        value={value} 
        onChange={(e) => onChange(e.target.value)}
        className="w-full bg-white/10 backdrop-blur-xl border border-white/20 p-5 pl-14 rounded-[22px] text-sm font-bold text-white outline-none focus:bg-white/20 focus:border-white/40 transition-all placeholder:text-white/40 shadow-inner"
      />
    </div>
  );
}