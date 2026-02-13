'use client';
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { UserCircle, Envelope, Phone, User, Camera, FloppyDisk, MapPin, SignIn } from '@phosphor-icons/react';
import { IUser } from '@/app/user.interface';
import { useCategory } from '@/context/CategoryContext';

// Kategori bazlı renk haritası
const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', bg: 'bg-blue-600', border: 'border-blue-200' },
  CONSTRUCTION: { main: 'text-purple-600', bg: 'bg-purple-600', border: 'border-purple-200' },
  CLIMATE: { main: 'text-orange-600', bg: 'bg-orange-600', border: 'border-orange-200' },
  TECH: { main: 'text-indigo-600', bg: 'bg-indigo-600', border: 'border-indigo-200' },
  LIFE: { main: 'text-emerald-600', bg: 'bg-emerald-600', border: 'border-emerald-200' }
};

export default function AccountView() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const [userData, setUserData] = useState<IUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Backend'den kullanıcı verisini çekme simülasyonu / API çağrısı
    const fetchUserProfile = async () => {
      try {
        // Gerçek API endpoint'ini buraya yaz: http://localhost:3000/users/me vb.
        const response = await fetch('/api/user/profile'); 
        if (response.ok) {
          const data = await response.json();
          setUserData(data);
        } else {
          setUserData(null); // Giriş yapılmamışsa null dön
        }
      } catch (error) {
        console.error("Profil yüklenirken hata:", error);
        setUserData(null);
      } finally {
        setLoading(false);
      }
    };

    fetchUserProfile();
  }, []);

  if (loading) {
    return <div className="p-8 text-center animate-pulse text-slate-400 font-bold">Yükleniyor...</div>;
  }

  // GİRİŞ YAPILMAMIŞSA (MİSAFİR GÖRÜNÜMÜ)
  if (!userData) {
    return (
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="p-6 space-y-8 text-center">
        <div className="bg-slate-200 p-8 rounded-[40px] shadow-inner">
          <UserCircle size={64} weight="duotone" className="mx-auto text-slate-400 mb-4" />
          <h2 className="text-xl font-black text-slate-600 uppercase tracking-tighter">Misafir Kullanıcı</h2>
          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-[0.2em] mt-2">Profil özelliklerini kullanmak için giriş yapın</p>
        </div>
        
        <button className={`w-full py-5 rounded-[25px] text-white font-black text-xs uppercase tracking-[0.3em] flex items-center justify-center gap-3 shadow-xl active:scale-95 transition-all ${theme.bg}`}>
          <SignIn size={20} weight="bold" />
          Giriş Yap / Kayıt Ol
        </button>
      </motion.div>
    );
  }

  // GİRİŞ YAPILMIŞSA (PROFİL GÖRÜNÜMÜ)
  return (
    <motion.div 
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      className="p-4 space-y-6 overflow-x-hidden"
    >
      <div className={`${theme.bg} p-6 rounded-[35px] text-center text-white shadow-lg relative overflow-hidden`}>
        <UserCircle size={44} weight="duotone" className="mx-auto mb-2 relative z-10" />
        <h2 className="text-lg font-black uppercase tracking-tight relative z-10">Hesap Ayarları</h2>
        <div className="absolute inset-0 bg-white/10 -skew-x-12 translate-x-20" />
      </div>

      <div className="flex justify-center">
        <div className="relative group">
          <div className={`w-28 h-28 rounded-[30px] bg-white border-4 ${theme.border} shadow-xl flex items-center justify-center overflow-hidden`}>
             {userData.profilePictureUrl ? (
               <img src={userData.profilePictureUrl} alt="Profil" className="w-full h-full object-cover" />
             ) : (
               <User size={60} weight="duotone" className="text-slate-200" />
             )}
          </div>
          <div className={`absolute -bottom-2 -right-2 p-2.5 rounded-xl text-white shadow-lg border-2 border-white ${theme.bg}`}>
            <Camera size={18} weight="fill" />
          </div>
        </div>
      </div>

      <div className="space-y-4">
        <SidebarInput label="Ad" icon={<User size={18} />} value={userData.firstName} theme={theme} />
        <SidebarInput label="Soyad" icon={<User size={18} />} value={userData.lastName} theme={theme} />
        <SidebarInput label="Telefon" icon={<Phone size={18} />} value={userData.phone} theme={theme} />
        <SidebarInput label="E-posta" icon={<Envelope size={18} />} value={userData.email} theme={theme} />
        
        <div className="p-5 bg-black/5 rounded-[30px] space-y-4 border border-black/[0.02]">
          <span className="text-[9px] font-black text-slate-400 uppercase ml-2 tracking-widest flex items-center gap-2">
            <MapPin size={14} weight="duotone" /> Adres Bilgileri
          </span>
          <SidebarInput label="Şehir" value={userData.address.city} theme={theme} plain />
          <SidebarInput label="İlçe" value={userData.address.district} theme={theme} plain />
        </div>
      </div>

      <button className={`w-full py-5 rounded-[26px] text-white font-black text-[10px] uppercase tracking-[0.2em] shadow-xl active:scale-95 transition-all hover:brightness-110 ${theme.bg}`}>
        <FloppyDisk size={20} weight="fill" className="inline mr-2" />
        Değişiklikleri Kaydet
      </button>
    </motion.div>
  );
}

function SidebarInput({ label, icon, value, theme, plain = false }: any) {
  return (
    <div className="space-y-1 text-left">
      <label className="text-[9px] font-black text-slate-400 uppercase ml-3 tracking-widest">{label}</label>
      <div className="relative">
        {icon && <span className={`absolute left-5 top-1/2 -translate-y-1/2 ${theme.main}`}>{icon}</span>}
        <input 
          readOnly 
          value={value || ''}
          className={`w-full bg-white/60 border border-white/80 p-4 ${icon ? 'pl-14' : 'pl-5'} rounded-[20px] text-xs font-bold text-slate-800 outline-none focus:bg-white transition-all`}
        />
      </div>
    </div>
  );
}