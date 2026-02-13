'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  SignIn, Phone, LockKey, 
  UserPlus, CheckCircle 
} from '@phosphor-icons/react';

// Props Tanımı (Geçiş Fonksiyonu İçin)
interface LoginViewProps {
  onSwitchToRegister: () => void;
}

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', bg: 'bg-blue-600', border: 'border-blue-200' },
  CONSTRUCTION: { main: 'text-purple-600', bg: 'bg-purple-600', border: 'border-purple-200' },
  CLIMATE: { main: 'text-orange-600', bg: 'bg-orange-600', border: 'border-orange-200' },
  TECH: { main: 'text-indigo-600', bg: 'bg-indigo-600', border: 'border-indigo-200' },
  LIFE: { main: 'text-emerald-600', bg: 'bg-emerald-600', border: 'border-emerald-200' }
};

export default function LoginView({ onSwitchToRegister }: LoginViewProps) {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({ phone: '', password: '' });
  const [errors, setErrors] = useState({ phone: '', password: '' });

  const validate = () => {
    let isValid = true;
    let newErrors = { phone: '', password: '' };

    if (!/^0\d{10}$/.test(formData.phone)) {
      newErrors.phone = 'Telefon (05xx) formatında olmalı';
      isValid = false;
    }
    if (formData.password.length < 6) {
      newErrors.password = 'Şifre en az 6 karakter olmalı';
      isValid = false;
    }
    setErrors(newErrors);
    return isValid;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    setLoading(true);
    setTimeout(() => { setLoading(false); alert('Giriş Başarılı!'); }, 1500);
  };

  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      className="p-6 space-y-8"
    >
      <div className="text-center space-y-3">
        <div className={`inline-flex p-5 rounded-[28px] text-white shadow-xl ${theme.bg} mb-2`}>
          <SignIn size={32} weight="bold" />
        </div>
        <h1 className="text-2xl font-black text-slate-800 tracking-tighter uppercase">Hoşgeldin</h1>
        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Hesabına Giriş Yap</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-1">
          <div className="relative">
            <span className={`absolute left-5 top-1/2 -translate-y-1/2 ${errors.phone ? 'text-red-500' : theme.main}`}><Phone size={20} weight="bold" /></span>
            <input 
              type="tel" placeholder="05xx..." 
              value={formData.phone}
              onChange={(e) => setFormData({...formData, phone: e.target.value.replace(/[^0-9]/g, '')})}
              className={`w-full bg-white/40 backdrop-blur-md border ${errors.phone ? 'border-red-300' : 'border-white/60'} p-4 pl-14 rounded-[22px] text-sm font-bold text-slate-800 outline-none focus:bg-white transition-all`}
            />
          </div>
          {errors.phone && <p className="text-[9px] text-red-500 font-bold ml-4">{errors.phone}</p>}
        </div>

        <div className="space-y-1">
          <div className="relative">
            <span className={`absolute left-5 top-1/2 -translate-y-1/2 ${errors.password ? 'text-red-500' : theme.main}`}><LockKey size={20} weight="bold" /></span>
            <input 
              type="password" placeholder="Şifre" 
              value={formData.password}
              onChange={(e) => setFormData({...formData, password: e.target.value})}
              className={`w-full bg-white/40 backdrop-blur-md border ${errors.password ? 'border-red-300' : 'border-white/60'} p-4 pl-14 rounded-[22px] text-sm font-bold text-slate-800 outline-none focus:bg-white transition-all`}
            />
          </div>
          {errors.password && <p className="text-[9px] text-red-500 font-bold ml-4">{errors.password}</p>}
        </div>

        <button disabled={loading} className={`w-full py-5 rounded-[25px] text-white font-black text-xs uppercase tracking-[0.2em] shadow-xl active:scale-95 transition-all mt-4 flex items-center justify-center gap-3 ${theme.bg} ${loading ? 'opacity-50' : ''}`}>
          {loading ? '...' : <>Giriş Yap <CheckCircle size={18} weight="bold" /></>}
        </button>
      </form>

      <div className="text-center pt-4 border-t border-black/5">
        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wide mb-2">Hesabın yok mu?</p>
        <button onClick={onSwitchToRegister} className={`text-xs font-black uppercase tracking-widest transition-all ${theme.main} hover:underline flex items-center justify-center gap-2`}>
          <UserPlus size={16} weight="bold" /> Kayıt Ol
        </button>
      </div>
    </motion.div>
  );
}