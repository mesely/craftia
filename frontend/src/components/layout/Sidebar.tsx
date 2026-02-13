'use client';

import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  X, House, Receipt, ShieldCheck, 
  Info, ChatCircleDots, UserGear, 
  CaretRight, CaretLeft, User, SignIn, SignOut, 
  Wrench, PaintRoller, Thermometer, Monitor, Sparkle,
  WarningCircle, UserCircle
} from '@phosphor-icons/react';

// --- ALT GÖRÜNÜMLER ---
import AccountView from '../Sidebar/AccountView';
import LoginView from '../Sidebar/LoginView';
import RegisterView from '../Sidebar/RegisterView';
import OrdersView from '../Sidebar/OrdersView';
import BecomeProviderView from '../Sidebar/BecomeProviderView';
import SupportView from '../Sidebar/SupportView';
import GuideView from '../Sidebar/GuideView';
import AgreementView from '../Sidebar/AgreementView';

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
  onOpenComplaint: () => void;
}

type SidebarView = 'menu' | 'account' | 'login' | 'register' | 'orders_full' | 'become-provider' | 'support' | 'contract' | 'guide';

const CATEGORY_ICONS: any = {
  TECHNICAL: Wrench, CONSTRUCTION: PaintRoller, CLIMATE: Thermometer, TECH: Monitor, LIFE: Sparkle
};

const THEME_MAP: any = {
  TECHNICAL: { main: 'text-blue-600', bg: 'bg-blue-600', border: 'border-blue-200' },
  CONSTRUCTION: { main: 'text-purple-600', bg: 'bg-purple-600', border: 'border-purple-200' },
  CLIMATE: { main: 'text-orange-600', bg: 'bg-orange-600', border: 'border-orange-200' },
  TECH: { main: 'text-indigo-600', bg: 'bg-indigo-600', border: 'border-indigo-200' },
  LIFE: { main: 'text-emerald-600', bg: 'bg-emerald-600', border: 'border-emerald-200' }
};

export default function Sidebar({ isOpen, onClose, onOpenComplaint }: SidebarProps) {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const [view, setView] = useState<SidebarView>('menu');
  const [isLoggedIn, setIsLoggedIn] = useState(false); 
  const [recentOrders, setRecentOrders] = useState<any[]>([]); 
  const [loadingOrders, setLoadingOrders] = useState(false);

  // Sidebar kapandığında görünümü sıfırla
  useEffect(() => {
    if (!isOpen) {
      const timer = setTimeout(() => setView('menu'), 400); 
      return () => clearTimeout(timer);
    } else {
      checkAuthAndFetch();
    }
  }, [isOpen]);

  const checkAuthAndFetch = async () => {
    // MOCK DATA YOK - BACKEND HAZIRLIK
    const isAuth = false; 
    setIsLoggedIn(isAuth);
    setRecentOrders([]); 
    setLoadingOrders(false);
  };

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
    <AnimatePresence mode="wait">
      {isOpen && (
        <>
          {/* --- BLUR OVERLAY (Daha hafif bir karartma) --- */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 z-[100] bg-slate-900/10 backdrop-blur-[4px]"
          />

          {/* --- SIDEBAR GÖVDESİ (GERÇEK GLASS EFFECT) --- 
              - bg-white/10: ÇOK ŞEFFAF. Arkadaki renkleri gösterir.
              - backdrop-blur-3xl: GÜÇLÜ BLUR. Buzlu cam etkisi yaratır.
              - border-white/10: Çok ince, zarif sınır.
          */}
          <motion.aside
            initial={{ x: '-100%' }}
            animate={{ x: 0 }}
            exit={{ x: '-100%' }}
            transition={{ type: 'spring', damping: 30, stiffness: 300 }}
            className="fixed top-0 left-0 z-[110] h-full w-full sm:w-[420px] bg-white/20 backdrop-blur-3xl border-r border-white/10 shadow-2xl ring-1 ring-white/5 flex flex-col overflow-hidden font-sans"
          >
            {/* --- HEADER --- */}
            <div className="p-6 flex items-center justify-between border-b border-white/10 bg-white/20 shrink-0">
              {view === 'menu' ? (
                <div className="flex flex-col">
                    <span className="font-bold text-[10px] uppercase tracking-[0.3em] text-slate-400">USTA</span>
                    <span className={`text-[16px] font-black uppercase tracking-tight ${theme.main}`}>Menü</span>
                </div>
              ) : (
                <button 
                  onClick={() => setView('menu')}
                  className={`flex items-center gap-2 ${theme.main} hover:opacity-70 transition-all outline-none`}
                >
                  <CaretLeft size={20} weight="bold" />
                  <span className="text-xs font-black uppercase tracking-widest">Geri Dön</span>
                </button>
              )}
              
              <button onClick={onClose} className="p-2.5 bg-white/20 hover:bg-white/30 rounded-full transition-colors border border-white/20 text-slate-500 outline-none">
                <X size={18} weight="bold" />
              </button>
            </div>

            {/* --- İÇERİK ALANI --- */}
            <div className="flex-1 overflow-y-auto relative scrollbar-hide">
              <AnimatePresence initial={false} mode="wait">
                
                {/* 1. ANA MENÜ */}
                {view === 'menu' && (
                  <motion.nav
                    key="menu"
                    variants={slideVariants}
                    initial="enter" animate="center" exit="exit"
                    className="p-5 space-y-4"
                  >
                    {/* --- KULLANICI KARTI (Ultra Şeffaf) --- */}
                    <div 
                      onClick={() => setView(isLoggedIn ? 'account' : 'login')} 
                      className="flex items-center gap-4 p-5 rounded-[30px] bg-white/20 border border-white/20 shadow-sm cursor-pointer hover:bg-white/20 transition-all group"
                    >
                        <div className={`p-3.5 rounded-2xl text-white shadow-lg transition-transform group-hover:scale-105 ${isLoggedIn ? theme.bg : 'bg-slate-400/80'}`}>
                          {isLoggedIn ? <User size={24} weight="duotone" /> : <UserCircle size={24} weight="duotone" />}
                        </div>
                        
                        <div>
                            <div className="text-sm font-black text-slate-700 uppercase">
                              {isLoggedIn ? 'Ahmet Yılmaz' : 'Misafir Kullanıcı'}
                            </div>
                            <div className={`text-[10px] font-bold uppercase tracking-widest mt-0.5 ${isLoggedIn ? 'text-slate-500' : theme.main}`}>
                              {isLoggedIn ? 'Hesap Ayarları' : 'Giriş Yap / Kayıt Ol'}
                            </div>
                        </div>
                        
                        <CaretRight size={16} className="ml-auto text-slate-400 group-hover:text-slate-600" />
                    </div>

                    {/* --- SİPARİŞ GEÇMİŞİ (Ultra Şeffaf) --- */}
                    <div className="py-2">
                      <div className="flex items-center justify-between px-2 mb-3">
                        <span className="text-[10px] font-black uppercase text-slate-400 tracking-[0.2em] flex items-center gap-2">
                          <Receipt size={14} weight="bold" /> Son İşlemler
                        </span>
                        {recentOrders.length > 0 && (
                          <button onClick={() => setView('orders_full')} className={`text-[9px] font-bold uppercase tracking-wide ${theme.main} hover:underline`}>
                            Tümünü Gör
                          </button>
                        )}
                      </div>

                      {loadingOrders ? (
                        <div className="h-16 bg-white/20 animate-pulse rounded-[25px] border border-white/10" />
                      ) : recentOrders.length > 0 ? (
                        <div className="space-y-2">
                          {recentOrders.map((order) => {
                            const Icon = CATEGORY_ICONS[order.category] || Wrench;
                            return (
                              <div key={order.id} className="bg-white/20 p-4 rounded-[26px] flex items-center gap-4 border border-white/20">
                                <div className={`p-2 rounded-xl bg-white/40 shadow-sm text-slate-600`}>
                                  <Icon size={18} weight="duotone" />
                                </div>
                                <div className="flex-1">
                                  <span className="text-[11px] font-black text-slate-700 uppercase block">{order.service}</span>
                                  <span className="text-[10px] font-bold text-slate-500">{order.price}</span>
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      ) : (
                        // BOŞ DURUM (MOCK DATA YOKKEN BURASI GÖRÜNÜR)
                        <div className="p-6 text-center border border-dashed border-slate-400/20 rounded-[25px] bg-white/20">
                          <span className="text-[10px] font-bold text-slate-400 uppercase">Henüz işlem geçmişi yok.</span>
                        </div>
                      )}
                    </div>

                    {/* Navigasyon Butonları */}
                    <div className="space-y-2">
                      <MenuButton 
                        icon={<House />} 
                        label="Ana Sayfa" 
                        onClick={onClose} 
                      />
                      <MenuButton 
                        icon={<UserGear />} 
                        label="Hizmet Veren Ol" 
                        onClick={() => setView('become-provider')} 
                        showCaret 
                      />
                      <MenuButton 
                        icon={<ChatCircleDots />} 
                        label="Çözüm Merkezi" 
                        onClick={() => setView('support')} 
                        showCaret 
                      />
                      <MenuButton 
                        icon={<ShieldCheck />} 
                        label="Yasal Metinler" 
                        onClick={() => setView('contract')} 
                        showCaret 
                      />
                      <MenuButton 
                        icon={<Info />} 
                        label="Uygulama Rehberi" 
                        onClick={() => setView('guide')} 
                        showCaret 
                      />
                    </div>

                    {/* Şikayet Butonu */}
                    <div className="pt-4">
                      <button 
                        onClick={() => { onOpenComplaint(); onClose(); }} 
                        className="w-full flex items-center justify-center gap-3 p-4 rounded-[24px] bg-red-50/30 text-red-500/80 border border-red-100/30 hover:bg-red-100/40 transition-all font-black text-[10px] uppercase tracking-widest active:scale-95 shadow-sm outline-none"
                      >
                          <WarningCircle size={18} weight="duotone" /> 
                          Şikayet Bildir
                      </button>
                    </div>
                  </motion.nav>
                )}

                {/* 2. ALT GÖRÜNÜMLER */}
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
            <div className="p-6 border-t border-white/10 bg-white/20 flex justify-between items-center backdrop-blur-sm shrink-0">
              <div className="text-[9px] font-black text-slate-400 uppercase tracking-[0.3em]">v1.0.2</div>
              {isLoggedIn && (
                  <button 
                    onClick={handleLogout}
                    className="flex items-center gap-2 text-[9px] font-black text-red-400 uppercase tracking-widest hover:text-red-600 transition-colors outline-none"
                  >
                      <SignOut size={14} weight="bold" /> Çıkış Yap
                  </button>
              )}
            </div>
          </motion.aside>
        </>
      )}
    </AnimatePresence>
  );
}

// --- GLASSY MENU BUTONU (Ultra Şeffaf) ---
function MenuButton({ icon, label, onClick, showCaret = false }: any) {
  return (
    <button 
      onClick={onClick}
      className="w-full flex items-center justify-between p-4 rounded-[24px] bg-white/20 hover:bg-white/30 border border-white/20 hover:border-white/40 transition-all group active:scale-[0.98] text-slate-700 shadow-sm outline-none"
    >
      <div className="flex items-center gap-4">
        <span className="text-slate-500 group-hover:text-indigo-600 transition-colors">
          {React.cloneElement(icon, { size: 20, weight: 'duotone' })}
        </span>
        <span className="text-xs font-bold tracking-tight uppercase text-slate-600 group-hover:text-slate-800">{label}</span>
      </div>
      {showCaret && <CaretRight size={14} weight="bold" className="text-slate-300 group-hover:text-indigo-400 transition-colors" />}
    </button>
  );
}