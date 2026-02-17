'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  X, House, ShieldCheck, 
  Info, ChatCircleDots, UserGear, 
  CaretRight, CaretLeft, User, SignOut, 
  Wrench, PaintRoller, Monitor, Sparkle,
  WarningCircle, UserCircle, Receipt 
} from '@phosphor-icons/react';

// --- BİLEŞENLER ---
import MeshBackground from '@/components/layout/MeshBackground';
import AccountView from '@/components/Sidebar/AccountView';
import LoginView from '@/components/Sidebar/LoginView';
import RegisterView from '@/components/Sidebar/RegisterView';
import OrdersView from '@/components/Sidebar/OrdersView';
import BecomeProviderView from '@/components/Sidebar/BecomeProviderView';
import SupportView from '@/components/Sidebar/SupportView';
import GuideView from '@/components/Sidebar/GuideView';
import AgreementView from '@/components/Sidebar/AgreementView';

type SidebarView = 'menu' | 'account' | 'login' | 'register' | 'orders_full' | 'become-provider' | 'support' | 'contract' | 'guide';

const THEME_COLORS: Record<string, string> = {
  TECHNICAL: 'text-blue-700',
  CONSTRUCTION: 'text-purple-700',
  TECH: 'text-indigo-700',
  LIFE: 'text-emerald-700',
};

const THEME_BG_TINT: Record<string, string> = {
  TECHNICAL: 'bg-blue-500/10',
  CONSTRUCTION: 'bg-purple-500/10',
  TECH: 'bg-indigo-500/10',
  LIFE: 'bg-emerald-500/10',
};

const THEME_ICON_BG: Record<string, string> = {
  TECHNICAL: 'bg-blue-600',
  CONSTRUCTION: 'bg-purple-600',
  TECH: 'bg-indigo-600',
  LIFE: 'bg-emerald-600',
};

export default function SettingsPage() {
  const { activeCategory } = useCategory();
  const accentColor = THEME_COLORS[activeCategory] || THEME_COLORS.TECHNICAL;
  const bgTint = THEME_BG_TINT[activeCategory] || THEME_BG_TINT.TECHNICAL;
  const iconBg = THEME_ICON_BG[activeCategory] || THEME_ICON_BG.TECHNICAL;

  const router = useRouter();
  const [view, setView] = useState<SidebarView>('menu');
  const [isLoggedIn] = useState(false); // Bu state'i ileride auth logic ile bağlayacağız

  const slideVariants = {
    enter: (direction: number) => ({ x: direction > 0 ? 50 : -50, opacity: 0 }),
    center: { x: 0, opacity: 1 },
    exit: (direction: number) => ({ x: direction < 0 ? 50 : -50, opacity: 0 }),
  };

  return (
    <main className="relative min-h-screen w-full font-sans overflow-hidden bg-slate-50">
      <MeshBackground category={activeCategory} />

      <div className={`absolute inset-0 z-10 flex flex-col ${bgTint} backdrop-blur-3xl transition-colors duration-700`}>
        
        {/* --- HEADER (60px) --- */}
        <header className="p-8 pt-[env(safe-area-inset-top,2rem)] flex items-center justify-between border-b border-slate-200/50 shrink-0 bg-white/20">
          {view === 'menu' ? (
            <div className="flex flex-col">
                <span className="font-bold text-[10px] uppercase tracking-[0.4em] text-slate-500">AYARLAR</span>
                <span className="text-3xl font-black uppercase tracking-tighter text-slate-800">MENÜ</span>
            </div>
          ) : (
            <button 
              onClick={() => setView('menu')}
              className={`flex items-center gap-2 ${accentColor} hover:opacity-80 transition-all outline-none`}
            >
              <CaretLeft size={28} weight="bold" />
              <span className="text-sm font-black uppercase tracking-widest text-slate-800">Geri Dön</span>
            </button>
          )}
          
          <button 
            onClick={() => router.push('/')} 
            className="p-3 bg-white/40 hover:bg-white/60 rounded-full transition-all border border-white/50 text-slate-700 shadow-sm active:scale-90"
          >
            <X size={24} weight="bold" />
          </button>
        </header>

        <div className="flex-1 overflow-y-auto relative scrollbar-hide">
          <AnimatePresence initial={false} mode="wait">
            
            {view === 'menu' && (
              <motion.nav
                key="menu" variants={slideVariants} initial="enter" animate="center" exit="exit"
                className="p-8 max-w-2xl mx-auto w-full space-y-8"
              >
                {/* --- KULLANICI KARTI --- */}
                <div 
                  onClick={() => setView(isLoggedIn ? 'account' : 'login')} 
                  className="flex items-center gap-5 p-7 rounded-[40px] bg-white/40 border border-white/60 shadow-xl backdrop-blur-md cursor-pointer hover:bg-white/60 transition-all group"
                >
                    <div className={`p-4 rounded-3xl text-white shadow-lg transition-colors duration-500 ${iconBg}`}>
                      {isLoggedIn ? <User size={32} weight="duotone" /> : <UserCircle size={32} weight="duotone" />}
                    </div>
                    
                    <div>
                        <div className="text-xl font-black text-slate-800 uppercase tracking-tight">
                          {isLoggedIn ? 'Ahmet Yılmaz' : 'Misafir Kullanıcı'}
                        </div>
                        <div className={`text-[10px] font-black uppercase tracking-widest mt-1 ${accentColor}`}>
                          {isLoggedIn ? 'Hesabı Yönet' : 'Giriş Yap / Kayıt Ol'}
                        </div>
                    </div>
                    
                    <CaretRight size={24} className="ml-auto text-slate-400 group-hover:text-slate-600 transition-colors" />
                </div>

                {/* Navigasyon Butonları */}
                <div className="space-y-4">
                  <MenuButton icon={<House />} label="Ana Sayfa" onClick={() => router.push('/')} accentColor={accentColor} />
                  
                  {/* ✅ İŞLEM GEÇMİŞİ BUTONU (Yeni Eklendi) */}
                  <MenuButton 
                    icon={<Receipt />} 
                    label="İşlem Geçmişi" 
                    onClick={() => setView('orders_full')} 
                    showCaret 
                    accentColor={accentColor} 
                  />

                  <MenuButton icon={<UserGear />} label="Hizmet Veren Ol" onClick={() => setView('become-provider')} showCaret accentColor={accentColor} />
                  <MenuButton icon={<ChatCircleDots />} label="Çözüm Merkezi" onClick={() => setView('support')} showCaret accentColor={accentColor} />
                  <MenuButton icon={<ShieldCheck />} label="Yasal Metinler" onClick={() => setView('contract')} showCaret accentColor={accentColor} />
                  <MenuButton icon={<Info />} label="Uygulama Rehberi" onClick={() => setView('guide')} showCaret accentColor={accentColor} />
                </div>

                <div className="pt-6">
                  <button className="w-full flex items-center justify-center gap-3 p-6 rounded-[35px] bg-red-500/10 text-red-600 border border-red-500/20 backdrop-blur-md hover:bg-red-500/20 transition-all font-black text-xs uppercase tracking-widest shadow-lg active:scale-95 outline-none">
                      <WarningCircle size={22} weight="duotone" /> 
                      Şikayet Bildir
                  </button>
                </div>
              </motion.nav>
            )}

            <div className="max-w-2xl mx-auto w-full">
              {view === 'account' && <AccountView />}
              {view === 'login' && <LoginView onSwitchToRegister={() => setView('register')} />}
              {view === 'register' && <RegisterView onSwitchToLogin={() => setView('login')} />}
              {view === 'orders_full' && <OrdersView />} 
              {view === 'become-provider' && <BecomeProviderView />}
              {view === 'support' && <SupportView />}
              {view === 'guide' && <GuideView />}
              {view === 'contract' && <AgreementView />}
            </div>

          </AnimatePresence>
        </div>

        <footer className="p-8 border-t border-slate-200/50 flex justify-between items-center backdrop-blur-md shrink-0 bg-white/20">
          <div className="text-[10px] font-black text-slate-400 uppercase tracking-[0.4em]">v1.0.2</div>
        </footer>
      </div>
    </main>
  );
}

function MenuButton({ icon, label, onClick, showCaret = false, accentColor }: any) {
  return (
    <button 
      onClick={onClick}
      className="w-full flex items-center justify-between p-6 rounded-[35px] bg-white/40 hover:bg-white/60 border border-white/50 shadow-lg backdrop-blur-md transition-all group active:scale-[0.98] outline-none"
    >
      <div className="flex items-center gap-5">
        <span className={`${accentColor} group-hover:scale-110 transition-transform`}>
          {React.cloneElement(icon, { size: 28, weight: 'duotone' })}
        </span>
        <span className="text-[15px] font-black tracking-tight uppercase text-slate-800 group-hover:text-slate-900">{label}</span>
      </div>
      {showCaret && <CaretRight size={20} weight="bold" className="text-slate-400 group-hover:text-slate-600 transition-all" />}
    </button>
  );
}