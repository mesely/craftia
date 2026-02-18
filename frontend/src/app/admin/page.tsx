'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Trash, Star, Briefcase, Chats, ShieldWarning, 
  User, CheckCircle, WarningCircle, MagnifyingGlass,
  MapPin, Phone, CaretDown, CaretUp, CheckSquare, Square
} from '@phosphor-icons/react';

// Kategori Renk Temaları
const THEME_MAP: Record<string, { bg: string; text: string; border: string; badge: string }> = {
  TECHNICAL: { bg: 'bg-blue-50', text: 'text-blue-700', border: 'border-blue-100', badge: 'bg-blue-100 text-blue-700 border-blue-200' },
  CONSTRUCTION: { bg: 'bg-purple-50', text: 'text-purple-700', border: 'border-purple-100', badge: 'bg-purple-100 text-purple-700 border-purple-200' },
  CLIMATE: { bg: 'bg-orange-50', text: 'text-orange-700', border: 'border-orange-100', badge: 'bg-orange-100 text-orange-700 border-orange-200' },
  TECH: { bg: 'bg-indigo-50', text: 'text-indigo-700', border: 'border-indigo-100', badge: 'bg-indigo-100 text-indigo-700 border-indigo-200' },
  LIFE: { bg: 'bg-emerald-50', text: 'text-emerald-700', border: 'border-emerald-100', badge: 'bg-emerald-100 text-emerald-700 border-emerald-200' },
  DEFAULT: { bg: 'bg-slate-50', text: 'text-slate-700', border: 'border-slate-100', badge: 'bg-slate-100 text-slate-700 border-slate-200' }
};

type TabType = 'PROVIDERS' | 'REVIEWS' | 'REPORTS';

export default function AdminDashboard() {
  const [activeTab, setActiveTab] = useState<TabType>('PROVIDERS');
  
  // Veri Stateleri
  const [providers, setProviders] = useState<any[]>([]);
  const [reviews, setReviews] = useState<any[]>([]);
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1';

  // --- FİLTRE & ÇOKLU SEÇİM STATELERİ ---
  const [filterCity, setFilterCity] = useState<string>('');
  const [filterMainType, setFilterMainType] = useState<string>('');
  const [filterSubType, setFilterSubType] = useState<string>('');
  
  const [selectedProviderIds, setSelectedProviderIds] = useState<string[]>([]);
  const [expandedProviderId, setExpandedProviderId] = useState<string | null>(null);

  // Veri Çekme İşlemleri
  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'PROVIDERS') {
        const res = await fetch(`${API_URL}/providers?limit=200`);
        if(res.ok) {
          const data = await res.json();
          setProviders(data.providers || []);
        } else {
          setProviders([]);
        }
      } else if (activeTab === 'REVIEWS') {
        const res = await fetch(`${API_URL}/reviews`); 
        if(res.ok) {
          const data = await res.json();
          setReviews(Array.isArray(data) ? data : []);
        }
      } else if (activeTab === 'REPORTS') {
        setReports([
            { _id: 'r1', type: 'SPAM', description: 'Bu usta sahte yorum atıyor.', targetName: 'Ahmet Elektrik', status: 'PENDING' },
            { _id: 'r2', type: 'INAPPROPRIATE', description: 'Profil fotoğrafı uygunsuz.', targetName: 'Tesisatçı Mehmet', status: 'PENDING' }
        ]);
      }
    } catch (error) {
      console.error("Veri çekme hatası:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    // Tab değiştiğinde seçimleri temizle
    setSelectedProviderIds([]);
    setExpandedProviderId(null);
  }, [activeTab]);

  // --- FİLTRELEME MANTIĞI ---
  const filteredProviders = useMemo(() => {
    return providers.filter(p => {
      if (filterCity && p.city !== filterCity) return false;
      if (filterMainType && p.mainType !== filterMainType) return false;
      if (filterSubType && p.subType !== filterSubType) return false;
      return true;
    });
  }, [providers, filterCity, filterMainType, filterSubType]);

  // Dinamik Filtre Seçenekleri
  const uniqueCities = Array.from(new Set(providers.map(p => p.city).filter(Boolean)));
  const uniqueMainTypes = Array.from(new Set(providers.map(p => p.mainType).filter(Boolean)));
  const uniqueSubTypes = Array.from(new Set(providers.filter(p => filterMainType ? p.mainType === filterMainType : true).map(p => p.subType).filter(Boolean)));

  // --- TEKLİ SİLME İŞLEMLERİ ---
  const handleDeleteProvider = async (e: React.MouseEvent, id: string, name: string) => {
    e.stopPropagation(); // Kartın açılmasını engeller
    if (!window.confirm(`"${name}" adlı ustayı silmek istediğinize emin misiniz?`)) return;
    try {
      await fetch(`${API_URL}/providers/${id}`, { method: 'DELETE' });
      setProviders(providers.filter(p => p._id !== id));
      setSelectedProviderIds(prev => prev.filter(pid => pid !== id));
    } catch (err) { alert('Silme işlemi başarısız.'); }
  };

  const handleDeleteReview = async (id: string) => {
    if (!window.confirm(`Bu yorumu silmek istediğinize emin misiniz?`)) return;
    try {
      await fetch(`${API_URL}/reviews/${id}`, { method: 'DELETE' });
      setReviews(reviews.filter(r => r._id !== id));
    } catch (err) { alert('Silme işlemi başarısız.'); }
  };

  const handleDeleteReport = async (id: string) => {
    if (!window.confirm(`Bu raporu kapatmak istediğinize emin misiniz?`)) return;
    setReports(reports.filter(r => r._id !== id));
  };

  // --- ÇOKLU SEÇİM & TOPLU SİLME ---
  const handleToggleSelect = (e: React.MouseEvent, id: string) => {
    e.stopPropagation(); // Kartın açılmasını engeller
    setSelectedProviderIds(prev => 
      prev.includes(id) ? prev.filter(pid => pid !== id) : [...prev, id]
    );
  };

  const handleSelectAll = () => {
    if (selectedProviderIds.length === filteredProviders.length) {
      setSelectedProviderIds([]); // Hepsini kaldır
    } else {
      setSelectedProviderIds(filteredProviders.map(p => p._id)); // Hepsini seç
    }
  };

  const handleBulkDeleteProviders = async () => {
    if (!window.confirm(`${selectedProviderIds.length} adet ustayı KALICI OLARAK silmek istediğinize emin misiniz?`)) return;
    try {
      // Backend'de toplu silme rotası yoksa, Promise.all ile tek tek siliyoruz
      await Promise.all(selectedProviderIds.map(id => fetch(`${API_URL}/providers/${id}`, { method: 'DELETE' })));
      setProviders(providers.filter(p => !selectedProviderIds.includes(p._id)));
      setSelectedProviderIds([]);
    } catch (err) {
      alert("Toplu silme sırasında bir hata oluştu.");
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 font-sans text-slate-800 pb-20">
      
      {/* Header */}
      <header className="bg-white border-b border-slate-200 sticky top-0 z-50">
        <div className="max-w-5xl mx-auto px-6 h-20 flex items-center justify-between">
          <div>
            <h1 className="text-xl font-black tracking-tight text-slate-900 uppercase">Yönetim Paneli</h1>
            <p className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Sistem Kontrol Merkezi</p>
          </div>
          <div className="w-10 h-10 bg-slate-900 rounded-full flex items-center justify-center text-white shadow-lg">
            <User size={20} weight="duotone" />
          </div>
        </div>

        {/* Tab Menü */}
        <div className="max-w-5xl mx-auto px-6 flex items-center gap-6 overflow-x-auto no-scrollbar">
          <TabButton active={activeTab === 'PROVIDERS'} onClick={() => setActiveTab('PROVIDERS')} icon={Briefcase} label="Ustalar" count={providers.length} />
          <TabButton active={activeTab === 'REVIEWS'} onClick={() => setActiveTab('REVIEWS')} icon={Chats} label="Yorumlar" count={reviews.length} />
          <TabButton active={activeTab === 'REPORTS'} onClick={() => setActiveTab('REPORTS')} icon={ShieldWarning} label="Raporlar" count={reports.length} />
        </div>
      </header>

      {/* Ana İçerik */}
      <main className="max-w-5xl mx-auto px-6 mt-8">
        {loading ? (
          <div className="flex flex-col items-center justify-center py-20 opacity-50">
            <motion.div animate={{ rotate: 360 }} transition={{ repeat: Infinity, duration: 1, ease: "linear" }}>
              <MagnifyingGlass size={32} weight="duotone" className="text-slate-400" />
            </motion.div>
            <p className="text-xs font-bold text-slate-500 uppercase tracking-widest mt-4">Veriler Yükleniyor...</p>
          </div>
        ) : (
          <AnimatePresence mode="wait">
            <motion.div key={activeTab} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -10 }}>
              
              {/* USTALAR SEKMESİ */}
              {activeTab === 'PROVIDERS' && (
                <div className="flex flex-col gap-4">
                  
                  {/* FİLTRE VE ÇOKLU SEÇİM ÇUBUĞU */}
                  <div className="bg-white p-4 rounded-[24px] shadow-sm border border-slate-100 flex flex-wrap items-center justify-between gap-4">
                    
                    {/* Filtreler */}
                    <div className="flex items-center gap-2 flex-wrap">
                      <select value={filterCity} onChange={(e) => setFilterCity(e.target.value)} className="bg-slate-50 border border-slate-200 text-xs font-bold text-slate-700 py-2 px-3 rounded-xl outline-none cursor-pointer">
                        <option value="">Tüm Şehirler</option>
                        {uniqueCities.map(c => <option key={c} value={c}>{c}</option>)}
                      </select>
                      
                      <select value={filterMainType} onChange={(e) => { setFilterMainType(e.target.value); setFilterSubType(''); }} className="bg-slate-50 border border-slate-200 text-xs font-bold text-slate-700 py-2 px-3 rounded-xl outline-none cursor-pointer">
                        <option value="">Tüm Kategoriler</option>
                        {uniqueMainTypes.map(m => <option key={m} value={m}>{m}</option>)}
                      </select>

                      <select value={filterSubType} onChange={(e) => setFilterSubType(e.target.value)} disabled={!filterMainType} className="bg-slate-50 border border-slate-200 text-xs font-bold text-slate-700 py-2 px-3 rounded-xl outline-none cursor-pointer disabled:opacity-50">
                        <option value="">Tüm Alt Hizmetler</option>
                        {uniqueSubTypes.map(s => <option key={s} value={s}>{s}</option>)}
                      </select>
                    </div>

                    {/* Çoklu Seçim Aksiyonları */}
                    <div className="flex items-center gap-3 bg-slate-50 p-1.5 px-3 rounded-xl border border-slate-200">
                      <button onClick={handleSelectAll} className="flex items-center gap-1.5 text-xs font-bold text-slate-600 hover:text-slate-900 transition-colors">
                        {selectedProviderIds.length === filteredProviders.length && filteredProviders.length > 0 ? (
                          <CheckSquare size={18} weight="fill" className="text-indigo-600" />
                        ) : (
                          <Square size={18} weight="bold" />
                        )}
                        Tümünü Seç
                      </button>
                      
                      {selectedProviderIds.length > 0 && (
                        <div className="flex items-center gap-3 pl-3 border-l border-slate-300">
                          <span className="text-xs font-black text-slate-700">{selectedProviderIds.length} Seçili</span>
                          <button onClick={handleBulkDeleteProviders} className="flex items-center gap-1 bg-red-500 text-white text-[10px] font-black uppercase tracking-wider px-3 py-1.5 rounded-lg hover:bg-red-600 transition-colors">
                            <Trash size={14} weight="bold" /> Toplu Sil
                          </button>
                        </div>
                      )}
                    </div>
                  </div>

                  {filteredProviders.length === 0 && <EmptyState message="Filtrelere uygun usta bulunamadı." />}
                  
                  {/* USTA LİSTESİ */}
                  <div className="grid gap-3">
                    {filteredProviders.map((provider) => {
                      const theme = THEME_MAP[provider.mainType] || THEME_MAP.DEFAULT;
                      const isSelected = selectedProviderIds.includes(provider._id);
                      const isExpanded = expandedProviderId === provider._id;

                      return (
                        <div 
                          key={provider._id} 
                          onClick={() => setExpandedProviderId(isExpanded ? null : provider._id)}
                          className={`bg-white rounded-[24px] shadow-sm border transition-all cursor-pointer overflow-hidden ${isSelected ? 'border-indigo-400 ring-2 ring-indigo-50' : 'border-slate-100 hover:shadow-md'}`}
                        >
                          {/* Üst Kısım (Her zaman görünür) */}
                          <div className="p-4 flex items-center justify-between gap-4">
                            
                            {/* Sol: Checkbox + Resim + İsim */}
                            <div className="flex items-center gap-4 flex-1 overflow-hidden">
                              <button onClick={(e) => handleToggleSelect(e, provider._id)} className="text-slate-400 hover:text-indigo-600 transition-colors p-1">
                                {isSelected ? <CheckSquare size={24} weight="fill" className="text-indigo-600" /> : <Square size={24} weight="bold" />}
                              </button>
                              
                              <div className={`w-12 h-12 rounded-[16px] flex items-center justify-center shrink-0 ${theme.bg} ${theme.border} border`}>
                                {provider.profileImage ? (
                                   <img src={provider.profileImage} alt="" className="w-full h-full object-cover rounded-[16px]" />
                                ) : (
                                   <Briefcase size={20} weight="duotone" className={theme.text} />
                                )}
                              </div>
                              <div className="min-w-0">
                                <h3 className="text-sm font-black text-slate-800 truncate">{provider.businessName}</h3>
                                <div className="flex items-center gap-2 mt-1">
                                  <span className={`text-[9px] font-black uppercase tracking-wider px-2 py-0.5 rounded-md border ${theme.badge}`}>
                                    {provider.mainType} {provider.subType && `/ ${provider.subType}`}
                                  </span>
                                  <span className="text-[10px] font-bold text-slate-500 flex items-center gap-0.5">
                                    <Star size={12} weight="fill" className="text-amber-400" /> {provider.rating || 'Yeni'}
                                  </span>
                                </div>
                              </div>
                            </div>

                            {/* Sağ: İkonlar ve Silme */}
                            <div className="flex items-center gap-2 shrink-0">
                              <div className="text-slate-400 mr-2">
                                {isExpanded ? <CaretUp size={20} weight="bold" /> : <CaretDown size={20} weight="bold" />}
                              </div>
                              <button 
                                onClick={(e) => handleDeleteProvider(e, provider._id, provider.businessName)}
                                className="w-9 h-9 rounded-full flex items-center justify-center text-slate-400 hover:bg-red-50 hover:text-red-500 transition-colors"
                              >
                                <Trash size={18} weight="bold" />
                              </button>
                            </div>
                          </div>

                          {/* Alt Kısım (Tıklayınca Açılır Detaylar) */}
                          <AnimatePresence>
                            {isExpanded && (
                              <motion.div 
                                initial={{ height: 0, opacity: 0 }} 
                                animate={{ height: 'auto', opacity: 1 }} 
                                exit={{ height: 0, opacity: 0 }}
                                className="border-t border-slate-100 bg-slate-50/50"
                              >
                                <div className="p-4 px-16 flex flex-col gap-3">
                                  <div className="grid grid-cols-2 gap-4">
                                    <div className="flex items-center gap-2 text-sm font-bold text-slate-600">
                                      <Phone size={18} weight="duotone" className={theme.text} />
                                      {provider.phoneNumber || 'Telefon Yok'}
                                    </div>
                                    <div className="flex items-center gap-2 text-sm font-bold text-slate-600">
                                      <MapPin size={18} weight="duotone" className={theme.text} />
                                      {provider.city} {provider.district && `- ${provider.district}`}
                                    </div>
                                  </div>
                                  {provider.address && (
                                    <div className="text-xs font-semibold text-slate-500 bg-white p-3 rounded-xl border border-slate-100">
                                      <span className="font-black text-slate-700 uppercase tracking-widest text-[9px] block mb-1">Açık Adres</span>
                                      {provider.address}
                                    </div>
                                  )}
                                  <div className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-2">
                                    Sistem ID: {provider._id}
                                  </div>
                                </div>
                              </motion.div>
                            )}
                          </AnimatePresence>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* YORUMLAR LİSTESİ */}
              {activeTab === 'REVIEWS' && (
                <div className="grid gap-4">
                  {reviews.length === 0 && <EmptyState message="Hiç yorum bulunamadı." />}
                  {reviews.map((review) => (
                    <div key={review._id} className="bg-white p-5 rounded-[24px] shadow-sm border border-slate-100 flex flex-col gap-3 group hover:shadow-md transition-all">
                      <div className="flex items-start justify-between">
                        <div>
                          <div className="flex items-center gap-1 mb-1">
                            {[...Array(5)].map((_, i) => (
                              <Star key={i} size={14} weight={i < review.rating ? "fill" : "regular"} className={i < review.rating ? "text-amber-400" : "text-slate-300"} />
                            ))}
                          </div>
                          <p className="text-xs font-bold text-slate-700 leading-relaxed">{review.comment}</p>
                        </div>
                        <button 
                          onClick={() => handleDeleteReview(review._id)}
                          className="w-8 h-8 rounded-full flex items-center justify-center text-slate-400 hover:bg-red-50 hover:text-red-500 transition-colors shrink-0"
                        >
                          <Trash size={16} weight="bold" />
                        </button>
                      </div>
                      <div className="flex items-center justify-between pt-3 border-t border-slate-50">
                        <span className="text-[10px] font-black text-slate-400 uppercase tracking-wider">Usta ID: {review.providerId}</span>
                        <span className="text-[10px] font-black text-slate-400 uppercase tracking-wider">Kullanıcı: {review.userId || 'Anonim'}</span>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* RAPORLAR LİSTESİ */}
              {activeTab === 'REPORTS' && (
                <div className="grid gap-4">
                  {reports.length === 0 && <EmptyState message="Bekleyen rapor bulunmuyor." />}
                  {reports.map((report) => (
                    <div key={report._id} className="bg-white p-5 rounded-[24px] shadow-sm border border-red-100 flex items-center justify-between gap-4 group">
                      <div className="flex items-start gap-4">
                        <div className="w-10 h-10 rounded-full bg-red-50 flex items-center justify-center text-red-500 shrink-0">
                          <WarningCircle size={20} weight="fill" />
                        </div>
                        <div>
                          <h3 className="text-sm font-black text-slate-800">{report.targetName}</h3>
                          <p className="text-xs font-bold text-slate-500 mt-0.5">{report.description}</p>
                          <span className="inline-block mt-2 text-[9px] font-black uppercase tracking-wider px-2 py-0.5 rounded-md bg-slate-100 text-slate-600">
                            Sebep: {report.type}
                          </span>
                        </div>
                      </div>
                      <button 
                        onClick={() => handleDeleteReport(report._id)}
                        className="px-4 py-2 bg-slate-900 text-white text-[10px] font-black uppercase tracking-widest rounded-full hover:bg-slate-800 transition-all shrink-0"
                      >
                        Kapat
                      </button>
                    </div>
                  ))}
                </div>
              )}

            </motion.div>
          </AnimatePresence>
        )}
      </main>
    </div>
  );
}

// Alt Bileşenler
function TabButton({ active, onClick, icon: Icon, label, count }: any) {
  return (
    <button 
      onClick={onClick}
      className={`relative flex items-center gap-2 py-4 border-b-2 transition-all whitespace-nowrap ${
        active ? 'border-slate-900 text-slate-900' : 'border-transparent text-slate-400 hover:text-slate-600'
      }`}
    >
      <Icon size={20} weight={active ? "fill" : "duotone"} />
      <span className="text-[11px] font-black uppercase tracking-widest">{label}</span>
      {count > 0 && (
        <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded-full ${active ? 'bg-slate-900 text-white' : 'bg-slate-100 text-slate-500'}`}>
          {count}
        </span>
      )}
    </button>
  );
}

function EmptyState({ message }: { message: string }) {
  return (
    <div className="text-center py-20 bg-white rounded-[32px] border border-dashed border-slate-200">
      <CheckCircle size={48} weight="duotone" className="text-emerald-400 mx-auto mb-3 opacity-50" />
      <p className="text-xs font-black text-slate-500 uppercase tracking-widest">{message}</p>
    </div>
  );
}