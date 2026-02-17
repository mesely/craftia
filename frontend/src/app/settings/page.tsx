'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  X, House, Receipt, ShieldCheck, 
  Info, ChatCircleDots, UserGear, 
  CaretRight, CaretLeft, User, SignOut, 
  Wrench, PaintRoller, Thermometer, Monitor, Sparkle,
  WarningCircle, UserCircle
} from '@phosphor-icons/react';

// --- ALT GÖRÜNÜMLER ---
import AccountView from '@/components/Sidebar/AccountView';
import LoginView from '@/components/Sidebar/LoginView';
import RegisterView from '@/components/Sidebar/RegisterView';
import OrdersView from '@/components/Sidebar/OrdersView';
import BecomeProviderView from '@/components/Sidebar/BecomeProviderView';
import SupportView from '@/components/Sidebar/SupportView';
import GuideView from '@/components/Sidebar/GuideView';
import AgreementView from '@/components/Sidebar/AgreementView';

type SidebarView = 'menu' | 'account' | 'login' | 'register' | 'orders_full' | 'become-provider' | 'support' | 'contract' | 'guide';

const CATEGORY_ICONS: Record<string, React.ElementType> = {
  TECHNICAL: Wrench, CONSTRUCTION: PaintRoller, CLIMATE: Thermometer, TECH: Monitor, LIFE: Sparkle
};

const THEME_MAP: Record<string, any> = {
  TECHNICAL: { main: 'text-blue-600', bg: 'bg-blue-600', border: 'border-blue-200' },
  CONSTRUCTION: { main: 'text-purple-600', bg: 'bg-purple-600', border: 'border-purple-200' },
  CLIMATE: { main: 'text-orange-600', bg: 'bg-orange-600', border: 'border-orange-200' },
  TECH: { main: 'text-indigo-600', bg: 'bg-indigo-600', border: 'border-indigo-200' },
  LIFE: { main: 'text-emerald-600', bg: 'bg-emerald-600', border: 'border-emerald-200' }
};

export default function SettingsPage() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const [view, setView] = useState<SidebarView>('menu');
  const [isLoggedIn, setIsLoggedIn] = useState(false); 
  const [recentOrders, setRecentOrders] = useState<any[]>([]); 
  const [loadingOrders, setLoadingOrders] = useState(false);

  // Tanımlama sıralaması hatasını (ESLint) önlemek için fonksiyonu yukarı aldık
  const checkAuthAndFetch = async () => {
    const isAuth = false; 
    setIsLoggedIn(isAuth);
    setRecentOrders([]); 
    setLoadingOrders(false);
  };

  useEffect(() => {
    checkAuthAndFetch();
  }, []);

  const slideVariants = {
    enter: (direction: number) => ({ x: direction > 0 ? 50 : -50, opacity: 0 }),
    center: { x: 0, opacity: 1 },
    exit: (direction: number) => ({ x: direction < 0 ? 50 : -50, opacity: 0 }),
  };

  const handleLogout = () => {
    if(confirm('Oturumu sonlandırmak istediğinize emin misiniz?')) {
      setIsLoggedIn(false);
      setRecentOrders([]);
      setView('menu');
    }
  };

  return (
    <main className="min-h-screen bg-slate-50 flex items-center justify-center p-0 sm:p-4 font-sans">
      {/* --- AYARLAR PANELİ (Sidebar içeriği artık tam sayfa) --- */}
      <div className="relative h-screen sm:h-[850px] w-full sm:w-[500px] bg-white/40 backdrop-blur-3xl border border-white/20 shadow-2xl sm:rounded-[40px] flex flex-col overflow-hidden ring-1 ring-black/5">
        
        {/* --- HEADER (Daha Geniş P-8) --- */}
        <div className="p-8 flex items-center justify-between border-b border-white/10 bg-white/30 shrink-0">
          {view === 'menu' ? (
            <div className="flex flex-col">
                <span className="font-bold text-[11px] uppercase tracking-[0.4em] text-slate-400">AYARLAR</span>
                <span className={`text-xl font-black uppercase tracking-tight ${theme.main}`}>Menü</span>
            </div>
          ) : (
            <button 
              onClick={() => setView('menu')}
              className={`flex items-center gap-2 ${theme.main} hover:opacity-70 transition-all outline-none`}
            >
              <CaretLeft size={24} weight="bold" />
              <span className="text-sm font-black uppercase tracking-widest">Geri Dön</span>
            </button>
          )}
          
          <button onClick={() => window.history.back()} className="p-3 bg-white/20 hover:bg-white/40 rounded-full transition-colors border border-white/20 text-slate-500 outline-none">
            <X size={20} weight="bold" />
          </button>
        </div>

        {/* --- İÇERİK ALANI --- */}
        <div className="flex-1 overflow-y-auto relative scrollbar-hide">
          <AnimatePresence initial={false} mode="wait">
            
            {view === 'menu' && (
              <motion.nav
                key="menu"
                variants={slideVariants}
                initial="enter" animate="center" exit="exit"
                className="p-8 space-y-6"
              >
                {/* --- KULLANICI KARTI (Daha Büyük) --- */}
                <div 
                  onClick={() => setView(isLoggedIn ? 'account' : 'login')} 
                  className="flex items-center gap-5 p-6 rounded-[35px] bg-white/30 border border-white/30 shadow-sm cursor-pointer hover:scale-[1.02] transition-all group"
                >
                    <div className={`p-4 rounded-2xl text-white shadow-lg ${isLoggedIn ? theme.bg : 'bg-slate-400/80'}`}>
                      {isLoggedIn ? <User size={28} weight="duotone" /> : <UserCircle size={28} weight="duotone" />}
                    </div>
                    
                    <div>
                        <div className="text-base font-black text-slate-700 uppercase">
                          {isLoggedIn ? 'Ahmet Yılmaz' : 'Misafir Kullanıcı'}
                        </div>
                        <div className={`text-xs font-bold uppercase tracking-widest mt-1 ${isLoggedIn ? 'text-slate-500' : theme.main}`}>
                          {isLoggedIn ? 'Hesap Ayarları' : 'Giriş Yap / Kayıt Ol'}
                        </div>
                    </div>
                    
                    <CaretRight size={20} className="ml-auto text-slate-400" />
                </div>

                {/* --- SİPARİŞ GEÇMİŞİ --- */}
                <div className="py-2">
                  <div className="flex items-center justify-between px-2 mb-4">
                    <span className="text-xs font-black uppercase text-slate-400 tracking-[0.2em] flex items-center gap-2">
                      <Receipt size={16} weight="bold" /> Son İşlemler
                    </span>
                  </div>

                  {loadingOrders ? (
                    <div className="h-20 bg-white/20 animate-pulse rounded-[30px]" />
                  ) : recentOrders.length > 0 ? (
                    <div className="space-y-3">
                      {recentOrders.map((order: any) => {
                        const Icon = CATEGORY_ICONS[order.category] || Wrench;
                        return (
                          <div key={order.id} className="bg-white/20 p-5 rounded-[30px] flex items-center gap-4 border border-white/20">
                            <div className={`p-3 rounded-xl bg-white/40 shadow-sm text-slate-600`}>
                              <Icon size={20} weight="duotone" />
                            </div>
                            <div className="flex-1">
                              <span className="text-xs font-black text-slate-700 uppercase block">{order.service}</span>
                              <span className="text-[11px] font-bold text-slate-500">{order.price}</span>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  ) : (
                    <div className="p-10 text-center border border-dashed border-slate-400/20 rounded-[30px] bg-white/10">
                      <span className="text-xs font-bold text-slate-400 uppercase">Henüz işlem geçmişi yok.</span>
                    </div>
                  )}
                </div>

                {/* Navigasyon Butonları */}
                <div className="space-y-3">
                  <MenuButton icon={<House />} label="Ana Sayfa" onClick={() => window.location.href = '/'} />
                  <MenuButton icon={<UserGear />} label="Hizmet Veren Ol" onClick={() => setView('become-provider')} showCaret />
                  <MenuButton icon={<ChatCircleDots />} label="Çözüm Merkezi" onClick={() => setView('support')} showCaret />
                  <MenuButton icon={<ShieldCheck />} label="Yasal Metinler" onClick={() => setView('contract')} showCaret />
                  <MenuButton icon={<Info />} label="Uygulama Rehberi" onClick={() => setView('guide')} showCaret />
                </div>

                {/* Şikayet Butonu */}
                <div className="pt-4">
                  <button className="w-full flex items-center justify-center gap-3 p-5 rounded-[30px] bg-red-50/40 text-red-500 border border-red-100 hover:bg-red-100 transition-all font-black text-xs uppercase tracking-widest shadow-sm outline-none active:scale-95">
                      <WarningCircle size={22} weight="duotone" /> 
                      Şikayet Bildir
                  </button>
                </div>
              </motion.nav>
            )}

            {/* ALT GÖRÜNÜMLER */}
            {view === 'account' && <AccountView />}
            {view === 'login' && <LoginView onSwitchToRegister={() => setView('register')} />}
            {view === 'register' && <RegisterView onSwitchToLogin={() => setView('login')} />}
            {view === 'orders_full' && <OrdersView />} 
            {view === 'become-provider' && <BecomeProviderView />}
            {view === 'support' && <SupportView />}
            {view === 'guide' && <GuideView />}
            {view === 'contract' && <AgreementView />}

          </AnimatePresence>
        </div>

        {/* --- FOOTER --- */}
        <div className="p-8 border-t border-white/10 bg-white/30 flex justify-between items-center shrink-0">
          <div className="text-[10px] font-black text-slate-400 uppercase tracking-[0.4em]">v1.0.2</div>
          {isLoggedIn && (
              <button 
                onClick={handleLogout}
                className="flex items-center gap-2 text-[10px] font-black text-red-400 uppercase tracking-widest hover:text-red-600 outline-none"
              >
                  <SignOut size={18} weight="bold" /> Çıkış Yap
              </button>
          )}
        </div>
      </div>
    </main>
  );
}

function MenuButton({ icon, label, onClick, showCaret = false }: any) {
  return (
    <button 
      onClick={onClick}
      className="w-full flex items-center justify-between p-5 rounded-[30px] bg-white/20 hover:bg-white/40 border border-white/20 transition-all group active:scale-[0.98] text-slate-700 shadow-sm outline-none"
    >
      <div className="flex items-center gap-4">
        <span className="text-slate-500 group-hover:text-indigo-600">
          {React.cloneElement(icon, { size: 24, weight: 'duotone' })}
        </span>
        <span className="text-sm font-bold tracking-tight uppercase text-slate-600 group-hover:text-slate-800">{label}</span>
      </div>
      {showCaret && <CaretRight size={18} weight="bold" className="text-slate-300 group-hover:text-indigo-400" />}
    </button>
  );
}