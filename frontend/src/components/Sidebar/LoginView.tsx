'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  SignIn, Phone, LockKey, 
  UserPlus, CheckCircle 
} from '@phosphor-icons/react';

interface LoginViewProps {
  onSwitchToRegister: () => void;
}

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-400', bg: 'bg-blue-600', border: 'border-blue-400/30' },
  CONSTRUCTION: { main: 'text-purple-400', bg: 'bg-purple-600', border: 'border-purple-400/30' },
  TECH: { main: 'text-indigo-400', bg: 'bg-indigo-600', border: 'border-indigo-400/30' },
  LIFE: { main: 'text-emerald-400', bg: 'bg-emerald-600', border: 'border-emerald-400/30' }
};

export default function LoginView({ onSwitchToRegister }: LoginViewProps) {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({ phone: '', password: '' });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setTimeout(() => { setLoading(false); alert('Giriş Başarılı!'); }, 1500);
  };

  return (
    <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-8">
      <div className="text-center space-y-3">
        {/* İkon Konteynırı */}
        <div className={`inline-flex p-5 rounded-[28px] text-white shadow-2xl ${theme.bg} mb-2 ring-4 ring-white/10`}>
          <SignIn size={32} weight="bold" />
        </div>
        {/* Başlık: Artık Beyaz ve Net */}
        <h1 className="text-3xl font-black text-white tracking-tighter uppercase drop-shadow-sm">Hoşgeldin</h1>
        <p className="text-[11px] font-black text-white/60 uppercase tracking-widest">Devam etmek için giriş yap</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <GlassInput 
          icon={<Phone />} type="tel" placeholder="Telefon (05xx...)" 
          value={formData.phone} onChange={(v:any) => setFormData({...formData, phone: v})} 
          theme={theme} 
        />
        <GlassInput 
          icon={<LockKey />} type="password" placeholder="Şifre" 
          value={formData.password} onChange={(v:any) => setFormData({...formData, password: v})} 
          theme={theme} 
        />

        <button disabled={loading} className={`w-full py-5 rounded-[25px] text-white font-black text-sm uppercase tracking-[0.2em] shadow-xl active:scale-95 transition-all mt-6 flex items-center justify-center gap-3 ${theme.bg} ${loading ? 'opacity-50' : 'hover:brightness-110'}`}>
          {loading ? 'Yükleniyor...' : <>Giriş Yap <CheckCircle size={20} weight="bold" /></>}
        </button>
      </form>

      <div className="text-center pt-6 border-t border-white/10">
        <p className="text-[10px] font-bold text-white/40 uppercase tracking-wide mb-3">Hesabın yok mu?</p>
        <button onClick={onSwitchToRegister} className={`group flex items-center justify-center gap-2 mx-auto text-xs font-black uppercase tracking-widest transition-all ${theme.main} hover:text-white`}>
          <UserPlus size={18} weight="bold" /> Kayıt Ol
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
        type={type} placeholder={placeholder} value={value} 
        onChange={(e) => onChange(e.target.value)}
        className="w-full bg-white/10 backdrop-blur-xl border border-white/20 p-5 pl-14 rounded-[22px] text-sm font-bold text-white outline-none focus:bg-white/20 focus:border-white/40 transition-all placeholder:text-white/40 shadow-inner"
      />
    </div>
  );
}