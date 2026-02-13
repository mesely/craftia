'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, UserCircle, Gear, SignOut, CaretLeft } from '@phosphor-icons/react';
import { useCategory } from '@/context/CategoryContext';

// Sidebar bileşenlerini doğru yoldan import ettiğinden emin ol
import LoginView from '../sidebar/LoginView';
import RegisterView from '../sidebar/RegisterView';

interface ProfileWidgetProps {
  isOpen: boolean;
  onClose: () => void;
  isLoggedIn: boolean;
  user: any;
  onLogout: () => void;
  onOpenSidebarAccount: () => void; 
}

const THEME_MAP: any = {
  TECHNICAL: { bg: 'bg-blue-600', text: 'text-blue-700' },
  CONSTRUCTION: { bg: 'bg-purple-600', text: 'text-purple-700' },
  CLIMATE: { bg: 'bg-orange-600', text: 'text-orange-700' },
  TECH: { bg: 'bg-indigo-600', text: 'text-indigo-700' },
  LIFE: { bg: 'bg-emerald-600', text: 'text-emerald-700' }
};

export default function ProfileWidget({ 
  isOpen, onClose, isLoggedIn, user, onLogout, onOpenSidebarAccount 
}: ProfileWidgetProps) {
  
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;
  
  const [view, setView] = useState<'menu' | 'login' | 'register'>('menu');

  const handleClose = () => {
    onClose();
    setTimeout(() => setView('menu'), 300);
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={handleClose}
            className="fixed inset-0 z-[80] bg-slate-500/20 backdrop-blur-sm"
          />

          <div className="fixed inset-0 z-[90] flex items-center justify-center pointer-events-none p-4">
            <motion.div
              initial={{ scale: 0.9, opacity: 0, y: 20 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 20 }}
              transition={{ type: 'spring', damping: 25, stiffness: 300 }}
              className="pointer-events-auto w-full max-w-[380px] bg-white/60 backdrop-blur-3xl border border-white/60 shadow-2xl shadow-indigo-500/10 rounded-[40px] overflow-hidden relative"
            >
              
              <div className="p-5 flex items-center justify-between border-b border-white/40 bg-white/20">
                {view !== 'menu' ? (
                  <button onClick={() => setView('menu')} className={`flex items-center gap-2 text-[10px] font-black uppercase tracking-widest ${theme.text}`}>
                    <CaretLeft size={16} weight="bold" /> Geri
                  </button>
                ) : (
                  <span className="text-[10px] font-black uppercase tracking-[0.2em] text-slate-400">
                    {isLoggedIn ? 'Kullanıcı Paneli' : 'Giriş Yap'}
                  </span>
                )}
                <button onClick={handleClose} className="p-2 bg-white/40 hover:bg-white/80 rounded-full transition-colors">
                  <X size={16} weight="bold" className="text-slate-600" />
                </button>
              </div>

              <div className="p-2 max-h-[60vh] overflow-y-auto scrollbar-hide">
                <AnimatePresence mode="wait">
                  
                  {view === 'menu' && (
                    <motion.div 
                      key="menu"
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      exit={{ opacity: 0, x: -20 }}
                      className="p-4 space-y-3"
                    >
                      {isLoggedIn ? (
                        <>
                          <div className="flex flex-col items-center justify-center py-6">
                            <div className={`w-20 h-20 rounded-full flex items-center justify-center text-white mb-3 shadow-lg ${theme.bg}`}>
                              <UserCircle size={48} weight="duotone" />
                            </div>
                            {/* 🔥 BURASI DÜZELDİ: firstName ve lastName birleştirildi */}
                            <h3 className="text-lg font-black text-slate-700 uppercase">
                              {user?.firstName} {user?.lastName}
                            </h3>
                            <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                              {user?.role === 'PROVIDER' ? 'Usta Hesabı' : 'Standart Üye'}
                            </p>
                          </div>

                          <WidgetBtn icon={<Gear />} label="Hesap Ayarları" onClick={() => { onOpenSidebarAccount(); handleClose(); }} />
                          
                          <button 
                            onClick={onLogout} 
                            className="w-full flex items-center justify-center gap-2 p-4 mt-2 rounded-[24px] bg-red-50 text-red-500 hover:bg-red-100 transition-all font-bold text-xs uppercase tracking-wider"
                          >
                            <SignOut size={18} weight="bold" /> Çıkış Yap
                          </button>
                        </>
                      ) : (
                        <div className="py-4 text-center space-y-6">
                          <div className="px-6">
                            <h2 className="text-xl font-black text-slate-700 uppercase tracking-tight mb-2">Hoşgeldin</h2>
                            <p className="text-xs font-medium text-slate-500 leading-relaxed">
                              Siparişlerini yönetmek ve ustalara ulaşmak için giriş yap.
                            </p>
                          </div>
                          
                          <div className="space-y-3">
                            <button 
                              onClick={() => setView('login')}
                              className={`w-full py-4 rounded-[24px] text-white font-black text-xs uppercase tracking-widest shadow-lg active:scale-95 transition-all ${theme.bg}`}
                            >
                              Giriş Yap
                            </button>
                            <button 
                              onClick={() => setView('register')}
                              className="w-full py-4 rounded-[24px] bg-white/50 border border-white/60 text-slate-700 font-black text-xs uppercase tracking-widest hover:bg-white active:scale-95 transition-all"
                            >
                              Kayıt Ol
                            </button>
                          </div>
                        </div>
                      )}
                    </motion.div>
                  )}

                  {view === 'login' && (
                    <motion.div key="login" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 20 }}>
                      <LoginView onSwitchToRegister={() => setView('register')} />
                    </motion.div>
                  )}

                  {view === 'register' && (
                    <motion.div key="register" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 20 }}>
                      <RegisterView onSwitchToLogin={() => setView('login')} />
                    </motion.div>
                  )}

                </AnimatePresence>
              </div>

            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}

function WidgetBtn({ icon, label, onClick }: any) {
  return (
    <button 
      onClick={onClick}
      className="w-full flex items-center justify-between p-4 rounded-[24px] bg-white/40 hover:bg-white/80 border border-white/50 transition-all group text-slate-700"
    >
      <div className="flex items-center gap-3">
        <span className="text-slate-500 group-hover:text-blue-600 transition-colors">
          {React.cloneElement(icon, { size: 20, weight: 'duotone' })}
        </span>
        <span className="text-xs font-bold uppercase tracking-tight">{label}</span>
      </div>
    </button>
  );
}