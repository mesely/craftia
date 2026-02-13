'use client';

import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { User, Phone, Envelope, LockKey, UserPlus, CheckCircle } from '@phosphor-icons/react';

interface RegisterViewProps {
  onSwitchToLogin: () => void;
}

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', bg: 'bg-blue-600', border: 'border-blue-200' },
  CONSTRUCTION: { main: 'text-purple-600', bg: 'bg-purple-600', border: 'border-purple-200' },
  CLIMATE: { main: 'text-orange-600', bg: 'bg-orange-600', border: 'border-orange-200' },
  TECH: { main: 'text-indigo-600', bg: 'bg-indigo-600', border: 'border-indigo-200' },
  LIFE: { main: 'text-emerald-600', bg: 'bg-emerald-600', border: 'border-emerald-200' }
};

export default function RegisterView({ onSwitchToLogin }: RegisterViewProps) {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const [formData, setFormData] = useState({ name: '', phone: '', email: '', password: '' });
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setTimeout(() => { setLoading(false); alert('Kayıt Başarılı!'); onSwitchToLogin(); }, 1500);
  };

  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      className="p-6 space-y-6 pb-20"
    >
      <div className="text-center space-y-2">
        <div className={`inline-flex p-5 rounded-[28px] text-white shadow-xl ${theme.bg} mb-2`}>
          <UserPlus size={32} weight="bold" />
        </div>
        <h1 className="text-2xl font-black text-slate-800 tracking-tighter uppercase">Kayıt Ol</h1>
        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Aramıza Katıl</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-3">
        <SidebarInput icon={<User />} placeholder="Ad Soyad" value={formData.name} onChange={(v: string) => setFormData({...formData, name: v})} theme={theme} />
        <SidebarInput icon={<Phone />} placeholder="Telefon (05xx)" value={formData.phone} onChange={(v: string) => setFormData({...formData, phone: v})} theme={theme} />
        <SidebarInput icon={<Envelope />} placeholder="E-posta" value={formData.email} onChange={(v: string) => setFormData({...formData, email: v})} theme={theme} />
        <SidebarInput icon={<LockKey />} type="password" placeholder="Şifre" value={formData.password} onChange={(v: string) => setFormData({...formData, password: v})} theme={theme} />
        
        <p className="text-[9px] text-slate-400 font-bold px-4">* Şifreniz en az 6 karakter olmalıdır.</p>

        <button disabled={loading} className={`w-full py-5 rounded-[25px] text-white font-black text-xs uppercase tracking-[0.2em] shadow-lg active:scale-95 transition-all mt-4 flex items-center justify-center gap-3 ${theme.bg} ${loading ? 'opacity-50' : ''}`}>
          {loading ? '...' : <>Kaydı Tamamla <CheckCircle size={18} weight="bold" /></>}
        </button>
      </form>

      <div className="text-center pt-4 border-t border-black/5">
        <button onClick={onSwitchToLogin} className={`text-xs font-black uppercase tracking-widest transition-all ${theme.main} hover:underline`}>
          Zaten hesabın var mı? Giriş Yap
        </button>
      </div>
    </motion.div>
  );
}

function SidebarInput({ icon, placeholder, value, onChange, type = 'text', theme }: any) {
  return (
    <div className="relative">
      <span className={`absolute left-5 top-1/2 -translate-y-1/2 ${theme.main}`}>
        {React.cloneElement(icon, { size: 20, weight: 'bold' })}
      </span>
      <input 
        type={type} placeholder={placeholder} value={value} 
        onChange={(e) => onChange(e.target.value)}
        className="w-full bg-white/40 backdrop-blur-md border border-white/60 p-4 pl-14 rounded-[22px] text-sm font-bold text-slate-800 outline-none focus:bg-white transition-all placeholder:text-slate-400"
      />
    </div>
  );
}