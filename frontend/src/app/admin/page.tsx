'use client';

import React, { useState, useEffect, useMemo, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Trash, Star, Briefcase, Chats, ShieldWarning, 
  User, CheckCircle, WarningCircle, MapPin, 
  Phone, CaretDown, CheckSquare, Square, 
  PencilSimple, X, Camera, Plus, CurrencyCircleDollar, 
  ShootingStar, Image as ImageIcon, Funnel, Gear, HouseLine, Tag
} from '@phosphor-icons/react';

// --- SABİTLER ---
interface IPriceItem {
  name: string;
  min: string;
  max: string;
  error: string;
}

type TabType = 'PROVIDERS' | 'REVIEWS' | 'REPORTS';

const CATEGORY_STRUCTURE: Record<string, { label: string; subTypes: string[] }> = {
  TECHNICAL: { label: 'Teknik Servis', subTypes: ['Elektrikçi', 'Su Tesisatçısı', 'Çilingir', 'Asansör Tamiri'] },
  CONSTRUCTION: { label: 'Yapı & Dekorasyon', subTypes: ['Boyacı', 'Alçıpancı', 'Parkeci', 'Fayansçı'] },
  CLIMATE: { label: 'İklimlendirme', subTypes: ['Kombi Tamiri', 'Klima Servisi', 'Petek Temizliği'] },
  TECH: { label: 'Teknoloji & Tamir', subTypes: ['Beyaz Eşya', 'TV Tamiri', 'Laptop/PC', 'Telefon Tamiri'] },
  LIFE: { label: 'Yaşam & Temizlik', subTypes: ['Ev Temizliği', 'İlaçlama', 'Koltuk Yıkama'] }
};

const THEME_MAP: Record<string, { bg: string; badge: string; text: string }> = {
  TECHNICAL: { bg: 'bg-blue-600', badge: 'bg-blue-50 text-blue-700 border-blue-100', text: 'text-blue-700' },
  CONSTRUCTION: { bg: 'bg-purple-600', badge: 'bg-purple-50 text-purple-700 border-purple-100', text: 'text-purple-700' },
  CLIMATE: { bg: 'bg-orange-600', badge: 'bg-orange-50 text-orange-700 border-orange-100', text: 'text-orange-700' },
  TECH: { bg: 'bg-indigo-600', badge: 'bg-indigo-50 text-indigo-700 border-indigo-100', text: 'text-indigo-700' },
  LIFE: { bg: 'bg-emerald-600', badge: 'bg-emerald-50 text-emerald-700 border-emerald-100', text: 'text-emerald-700' },
  DEFAULT: { bg: 'bg-slate-600', badge: 'bg-slate-50 text-slate-700 border-slate-100', text: 'text-slate-700' }
};

// Görsellerdeki Elektrikçi Hizmetleri
const PREDEFINED_SERVICES: Record<string, string[]> = {
  TECHNICAL: ["Priz ve Anahtar Montajı (10 Adet)", "Elektrik Tesisatı Yenileme Paketi", "Daire Elektrik Tesisatı (100m²)", "Elektrik Panosu Kurulumu", "Topraklama Sistemi Kurulumu", "Kaçak Akım Koruma Sistemi", "Spot ve LED Aydınlatma", "Avize ve Aplik Montajı", "Güvenlik Kamerası Altyapısı"],
  CONSTRUCTION: ["Boya Badana", "Alçıpan", "Parke Döşeme"],
  CLIMATE: ["Kombi Bakımı", "Klima Montajı"],
};

export default function AdminDashboard() {
  const [activeTab, setActiveTab] = useState<TabType>('PROVIDERS');
  const [loading, setLoading] = useState(false);
  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1';

  const [providers, setProviders] = useState<any[]>([]);
  const [reviews, setReviews] = useState<any[]>([]);
  
  const [filterCity, setFilterCity] = useState<string>('');
  const [filterMainType, setFilterMainType] = useState<string>('');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const [editingProvider, setEditingProvider] = useState<any | null>(null);
  const [editPrices, setEditPrices] = useState<IPriceItem[]>([]);
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'PROVIDERS') {
        const res = await fetch(`${API_URL}/providers?limit=200`);
        const data = await res.json();
        setProviders(data.providers || []);
      } else if (activeTab === 'REVIEWS') {
        const res = await fetch(`${API_URL}/reviews`);
        const data = await res.json();
        setReviews(Array.isArray(data) ? data : []);
      }
    } catch (err) { console.error(err); }
    finally { setLoading(false); }
  };

  useEffect(() => { fetchData(); setSelectedIds([]); setExpandedId(null); }, [activeTab]);

  const filteredProviders = useMemo(() => {
    return providers.filter(p => {
      const cityMatch = !filterCity || p.city === filterCity;
      const typeMatch = !filterMainType || p.mainType === filterMainType;
      return cityMatch && typeMatch;
    });
  }, [providers, filterCity, filterMainType]);

  const uniqueCities = useMemo(() => Array.from(new Set(providers.map(p => p.city))).filter(Boolean), [providers]);

  // --- AKSİYONLAR ---
  const handleBulkDelete = async () => {
    if (!window.confirm(`${selectedIds.length} kayıt silinecek. Emin misiniz?`)) return;
    setLoading(true);
    try {
      await Promise.all(selectedIds.map(id => fetch(`${API_URL}/providers/${id}`, { method: 'DELETE' })));
      setProviders((prev: any[]) => prev.filter(p => !selectedIds.includes(p._id)));
      setSelectedIds([]);
    } finally { setLoading(false); }
  };

  const handlePriceChange = (index: number, field: keyof IPriceItem, value: string) => {
    const updated = [...editPrices];
    updated[index] = { ...updated[index], [field]: value };
    const min = parseFloat(updated[index].min) || 0;
    const max = parseFloat(updated[index].max) || 0;

    if (min > 0 && max > 0) {
      let maxAllowed = min <= 2000 ? min * 2 : min <= 10000 ? min * 1.5 : min * 1.3;
      if (max < min) updated[index].error = "Max, Min'den küçük olamaz.";
      else if (max > maxAllowed) updated[index].error = `Tavan: ${Math.round(maxAllowed)} ₺`;
      else updated[index].error = "";
    } else updated[index].error = "";
    setEditPrices(updated);
  };

  const openEdit = (provider: any) => {
    setEditingProvider({ ...provider });
    const prices = provider.priceList ? Object.entries(provider.priceList).map(([name, range]) => {
      const [min, max] = String(range).split('-');
      return { name, min: min || '', max: max || '', error: '' };
    }) : [];
    setEditPrices(prices);
  };

  const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    const data = new FormData();
    data.append('file', file);
    data.append('upload_preset', 'usta_portfolyo');
    try {
      const res = await fetch(`https://api.cloudinary.com/v1_1/dbgt6dg9n/image/upload`, { method: 'POST', body: data });
      const json = await res.json();
      setEditingProvider((prev: any) => ({
        ...prev,
        portfolioImages: [...(prev?.portfolioImages || []), json.secure_url],
        profileImage: prev?.profileImage || json.secure_url
      }));
    } finally { setUploading(false); }
  };

  const saveEdit = async () => {
    if (editPrices.some(p => p.error)) return alert("Lütfen hataları düzeltin.");
    const priceMap: Record<string, string> = {};
    editPrices.forEach(p => { if(p.name) priceMap[p.name] = `${p.min}-${p.max}`; });
    const payload = { ...editingProvider, priceList: priceMap };
    
    try {
      const res = await fetch(`${API_URL}/providers/${editingProvider._id}`, {
        method: 'PUT', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      if (res.ok) {
        setProviders((prev: any[]) => prev.map(p => p._id === payload._id ? payload : p));
        setEditingProvider(null);
      }
    } catch (err) { alert("Hata oluştu."); }
  };

  return (
    <div className="min-h-screen bg-[#FDFDFD] font-sans text-slate-800">
      
      {/* 📱 HEADER */}
      <header className="fixed top-0 left-0 right-0 z-[60] bg-white/60 backdrop-blur-2xl border-b border-white shadow-sm h-[60px]">
        <div className="max-w-6xl mx-auto px-6 h-full flex items-center justify-between">
          <div className="flex items-center gap-3">
             <div className="p-2 bg-slate-900 rounded-2xl shadow-xl">
                <Gear size={20} weight="fill" className="text-white" />
             </div>
             <h1 className="text-[16px] font-black tracking-[0.2em] uppercase text-slate-900">Usta Panel</h1>
          </div>
          <div className="flex items-center gap-2">
             <TabLink active={activeTab === 'PROVIDERS'} onClick={() => setActiveTab('PROVIDERS')} label="Ustalar" count={providers.length} icon={Briefcase} />
             <TabLink active={activeTab === 'REVIEWS'} onClick={() => setActiveTab('REVIEWS')} label="Yorumlar" count={reviews.length} icon={Chats} />
          </div>
        </div>
      </header>

      <main className="pt-[100px] px-6 pb-32 max-w-6xl mx-auto">
        
        {/* 🔍 FİLTRELER */}
        <AnimatePresence>
          {activeTab === 'PROVIDERS' && (
            <motion.div initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} className="mb-8 flex flex-wrap items-center justify-between gap-4 bg-white/80 backdrop-blur-xl p-5 rounded-[35px] border border-white shadow-lg shadow-slate-100/50">
               <div className="flex items-center gap-3">
                  <FilterSelect icon={MapPin} value={filterCity} onChange={setFilterCity} options={uniqueCities as string[]} label="Tüm Şehirler" />
                  <FilterSelect icon={Funnel} value={filterMainType} onChange={setFilterMainType} options={Object.keys(CATEGORY_STRUCTURE)} label="Tüm Kategoriler" />
               </div>
               <div className="flex items-center gap-4">
                  <button onClick={() => setSelectedIds(selectedIds.length === filteredProviders.length ? [] : filteredProviders.map(p => p._id))} className="text-[10px] font-black uppercase text-slate-400 flex items-center gap-2 hover:text-indigo-600 transition-colors">
                     {selectedIds.length === filteredProviders.length && selectedIds.length > 0 ? <CheckSquare size={22} weight="fill" className="text-indigo-600" /> : <Square size={22} weight="bold" className="text-slate-100" />}
                     Tümünü Seç
                  </button>
                  {selectedIds.length > 0 && (
                    <button onClick={handleBulkDelete} className="bg-red-500 text-white px-6 py-3 rounded-2xl text-[10px] font-black uppercase shadow-xl active:scale-95 transition-all">Toplu Sil ({selectedIds.length})</button>
                  )}
               </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* 📋 LİSTELEME */}
        <div className="space-y-3">
          {loading ? (
             <div className="flex justify-center py-20 opacity-20"><ImageIcon size={60} className="animate-pulse" /></div>
          ) : (
            filteredProviders.map((p) => {
              const theme = THEME_MAP[p.mainType] || THEME_MAP.DEFAULT;
              const isSel = selectedIds.includes(p._id);
              const isExp = expandedId === p._id;

              return (
                <div key={p._id} className={`bg-white rounded-[35px] border transition-all overflow-hidden ${isSel ? 'border-indigo-400 ring-4 ring-indigo-50' : 'border-slate-100 shadow-sm hover:shadow-xl hover:shadow-slate-200/40'}`}>
                   <div onClick={() => setExpandedId(isExp ? null : p._id)} className="p-5 flex items-center justify-between cursor-pointer">
                      <div className="flex items-center gap-5">
                         <button onClick={(e) => { e.stopPropagation(); setSelectedIds((prev: string[]) => prev.includes(p._id) ? prev.filter(id => id !== p._id) : [...prev, p._id]); }}>
                            {isSel ? <CheckSquare size={24} weight="fill" className="text-indigo-600" /> : <Square size={24} weight="bold" className="text-slate-100" />}
                         </button>
                         <div className="w-14 h-14 rounded-[22px] bg-slate-50 border border-slate-100 overflow-hidden shrink-0">
                            {p.profileImage ? <img src={p.profileImage} className="w-full h-full object-cover" /> : <User size={24} className="m-4 text-slate-200" />}
                         </div>
                         <div>
                            <h3 className="text-[14px] font-black text-slate-900 uppercase tracking-tight">{p.businessName}</h3>
                            <div className="flex items-center gap-2 mt-1">
                               <span className={`text-[8px] font-black uppercase px-2 py-0.5 rounded-lg border ${theme.badge}`}>{p.mainType}</span>
                               <span className="text-[10px] font-bold text-slate-400 uppercase">{p.city} - {p.district}</span>
                            </div>
                         </div>
                      </div>
                      <div className="flex items-center gap-2">
                         <button onClick={(e) => { e.stopPropagation(); openEdit(p); }} className="p-3 text-slate-300 hover:text-indigo-600 transition-all"><PencilSimple size={20} weight="bold" /></button>
                         <div className={`ml-2 text-slate-200 transition-transform ${isExp ? 'rotate-180' : ''}`}><CaretDown size={20} weight="bold" /></div>
                      </div>
                   </div>
                   <AnimatePresence>
                     {isExp && (
                       <motion.div initial={{ height: 0 }} animate={{ height: 'auto' }} exit={{ height: 0 }} className="bg-slate-50/50 border-t border-slate-100 p-8 px-24">
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
                             <div className="space-y-4">
                               <DetailItem icon={Phone} label="İletişim" value={p.phoneNumber} color={theme.text} />
                               <DetailItem icon={Briefcase} label="Uzmanlık" value={p.subType} color={theme.text} />
                             </div>
                             <div className="p-5 bg-white rounded-[25px] border border-slate-200 shadow-sm relative overflow-hidden">
                                <div className="flex items-center gap-2 text-indigo-500 mb-3">
                                   <HouseLine size={20} weight="duotone" />
                                   <span className="text-[10px] font-black uppercase tracking-[0.1em]">Tam Açık Adres</span>
                                </div>
                                <p className="text-xs font-bold text-slate-600 leading-relaxed italic">{p.address || 'Adres bilgisi girilmemiş.'}</p>
                                <div className="absolute top-0 right-0 w-24 h-24 bg-indigo-50 -rotate-45 translate-x-12 -translate-y-12 rounded-full opacity-40" />
                             </div>
                          </div>
                       </motion.div>
                     )}
                   </AnimatePresence>
                </div>
              )
            })
          )}
        </div>
      </main>

      {/* --- 🎨 MODAL --- */}
      <AnimatePresence>
        {editingProvider && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 bg-slate-900/40 backdrop-blur-md" onClick={() => setEditingProvider(null)} />
            <motion.div initial={{ scale: 0.95, y: 30, opacity: 0 }} animate={{ scale: 1, y: 0, opacity: 1 }} className="relative w-full max-w-3xl bg-white rounded-[45px] p-10 shadow-2xl z-10 max-h-[90vh] overflow-y-auto no-scrollbar border border-white/20">
              
              <div className="flex justify-between items-center mb-10">
                <div>
                  <h2 className="text-2xl font-black uppercase text-slate-900 tracking-tighter">Usta Düzenle</h2>
                  <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">Sistem ID: {editingProvider._id}</p>
                </div>
                <button onClick={() => setEditingProvider(null)} className="p-3 bg-slate-100 rounded-[20px] hover:bg-slate-200 transition-colors"><X size={20} weight="bold" /></button>
              </div>

              <div className="space-y-12">
                {/* 📸 FOTOĞRAFLAR */}
                <section>
                   <div className="flex items-center justify-between mb-6">
                      <label className="text-[11px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2"><Camera size={18} weight="duotone" /> Hizmet Görselleri</label>
                      <button onClick={() => fileInputRef.current?.click()} className="bg-slate-900 text-white px-5 py-2.5 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-800 transition-all">
                        {uploading ? 'Yükleniyor...' : '+ Fotoğraf Ekle'}
                      </button>
                      <input type="file" ref={fileInputRef} className="hidden" onChange={handleImageUpload} />
                   </div>
                   <div className="grid grid-cols-4 gap-4">
                      {editingProvider.portfolioImages?.map((img: string, idx: number) => (
                        <div key={idx} className="relative aspect-square rounded-[28px] overflow-hidden border-2 border-slate-100 group">
                           <img src={img} className="w-full h-full object-cover" />
                           {editingProvider.profileImage === img && <div className="absolute top-3 left-3 bg-amber-400 text-white p-1.5 rounded-xl shadow-lg"><ShootingStar size={14} weight="fill" /></div>}
                           <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                              <button onClick={() => setEditingProvider({...editingProvider, profileImage: img})} className="p-2 bg-white rounded-xl text-indigo-600 shadow-xl"><User size={18} weight="bold" /></button>
                              <button onClick={() => setEditingProvider({...editingProvider, portfolioImages: editingProvider.portfolioImages.filter((i: string) => i !== img)})} className="p-2 bg-white rounded-xl text-red-500 shadow-xl"><Trash size={18} weight="bold" /></button>
                           </div>
                        </div>
                      ))}
                   </div>
                </section>

                {/* 📝 KATEGORİ & BİLGİLER (DROPDOWN SİSTEMİ) */}
                <section className="grid grid-cols-1 md:grid-cols-2 gap-6 p-8 bg-slate-50/50 rounded-[40px] border border-slate-100 shadow-inner">
                   <EditField icon={User} label="İşletme Adı" value={editingProvider.businessName} onChange={(v) => setEditingProvider({...editingProvider, businessName: v})} />
                   <EditField icon={Phone} label="Telefon" value={editingProvider.phoneNumber} onChange={(v) => setEditingProvider({...editingProvider, phoneNumber: v})} />
                   
                   {/* Ana Kategori Dropdown */}
                   <div className="space-y-1.5">
                      <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-2 flex items-center gap-2"><Tag size={14}/> Ana Kategori</label>
                      <select 
                        value={editingProvider.mainType} 
                        onChange={(e) => setEditingProvider({...editingProvider, mainType: e.target.value, subType: ''})}
                        className="w-full bg-white border border-slate-200 p-4 rounded-[22px] text-xs font-bold text-slate-800 outline-none focus:border-indigo-400 transition-all appearance-none cursor-pointer"
                      >
                         <option value="">Seçiniz...</option>
                         {Object.entries(CATEGORY_STRUCTURE).map(([key, value]) => <option key={key} value={key}>{value.label}</option>)}
                      </select>
                   </div>

                   {/* Alt Uzmanlık Dropdown */}
                   <div className="space-y-1.5">
                      <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-2 flex items-center gap-2"><Briefcase size={14}/> Uzmanlık Alanı</label>
                      <select 
                        value={editingProvider.subType} 
                        disabled={!editingProvider.mainType}
                        onChange={(e) => setEditingProvider({...editingProvider, subType: e.target.value})}
                        className="w-full bg-white border border-slate-200 p-4 rounded-[22px] text-xs font-bold text-slate-800 outline-none focus:border-indigo-400 transition-all appearance-none cursor-pointer disabled:opacity-50"
                      >
                         <option value="">Seçiniz...</option>
                         {editingProvider.mainType && CATEGORY_STRUCTURE[editingProvider.mainType]?.subTypes.map(s => <option key={s} value={s}>{s}</option>)}
                      </select>
                   </div>
                </section>

                {/* 📍 KONUM & ADRES */}
                <section className="grid grid-cols-1 md:grid-cols-2 gap-6 p-8 bg-slate-50/50 rounded-[40px] border border-slate-100 shadow-inner">
                   <EditField icon={MapPin} label="Şehir" value={editingProvider.city} onChange={(v) => setEditingProvider({...editingProvider, city: v})} />
                   <EditField icon={MapPin} label="İlçe" value={editingProvider.district} onChange={(v) => setEditingProvider({...editingProvider, district: v})} />
                   <div className="md:col-span-2 space-y-1.5">
                      <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-2 flex items-center gap-2"><HouseLine size={14}/> Açık Adres</label>
                      <textarea 
                        value={editingProvider.address || ''} 
                        onChange={(e) => setEditingProvider({...editingProvider, address: e.target.value})} 
                        className="w-full bg-white border border-slate-200 p-5 rounded-[25px] text-xs font-bold text-slate-800 outline-none focus:border-indigo-400 transition-all min-h-[100px] shadow-sm" 
                        placeholder="Ustanın tam açık adresini buraya giriniz..."
                      />
                   </div>
                </section>

                {/* 💰 FİYATLAR */}
                <section className="bg-white p-8 rounded-[40px] border border-slate-200 shadow-sm">
                   <div className="flex items-center justify-between mb-8">
                      <label className="text-[11px] font-black uppercase tracking-widest text-slate-500 flex items-center gap-2"><CurrencyCircleDollar size={20} weight="duotone" /> Hizmet & Fiyat Listesi</label>
                      <button onClick={() => setEditPrices([...editPrices, {name: '', min: '', max: '', error: ''}])} className="text-[10px] font-black uppercase text-indigo-600 bg-indigo-50 px-4 py-2 rounded-full">+ Satır Ekle</button>
                   </div>
                   <datalist id="admin-sug">{(PREDEFINED_SERVICES[editingProvider.mainType] || []).map(s => <option key={s} value={s} />)}</datalist>
                   <div className="space-y-4">
                      {editPrices.map((item, idx) => (
                        <div key={idx} className="flex flex-col gap-2">
                           <div className="flex items-center gap-3">
                              <input list="admin-sug" placeholder="Hizmet Adı" value={item.name} onChange={(e) => handlePriceChange(idx, 'name', e.target.value)} className="flex-1 bg-white border border-slate-200 p-4 rounded-[22px] text-xs font-bold outline-none shadow-sm" />
                              <div className="flex items-center gap-2 bg-slate-50 px-4 rounded-[22px] border border-slate-200">
                                 <input type="number" placeholder="Min" value={item.min} onChange={(e) => handlePriceChange(idx, 'min', e.target.value)} className="w-16 py-4 text-xs font-bold outline-none text-center bg-transparent" />
                                 <span className="text-slate-200">-</span>
                                 <input type="number" placeholder="Max" value={item.max} onChange={(e) => handlePriceChange(idx, 'max', e.target.value)} className={`w-16 py-4 text-xs font-bold outline-none text-center bg-transparent ${item.error ? 'text-red-500' : ''}`} />
                              </div>
                              <button onClick={() => setEditPrices(editPrices.filter((_, i) => i !== idx))} className="p-4 text-red-400 hover:bg-red-50 rounded-2xl"><Trash size={20} /></button>
                           </div>
                           {item.error && <div className="flex items-center gap-1.5 px-4 text-red-500 text-[9px] font-black uppercase tracking-widest"><WarningCircle size={14} weight="fill" />{item.error}</div>}
                        </div>
                      ))}
                   </div>
                </section>

                <div className="flex gap-4 pt-6">
                   <button onClick={() => setEditingProvider(null)} className="flex-1 py-5 bg-slate-100 text-slate-500 font-black text-[11px] uppercase tracking-widest rounded-[28px]">İptal</button>
                   <button onClick={saveEdit} className="flex-[2] py-5 bg-slate-900 text-white font-black text-[11px] uppercase tracking-[0.2em] rounded-[28px] shadow-2xl active:scale-95 transition-all">Değişiklikleri Kaydet</button>
                </div>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </div>
  );
}

// --- ALT BİLEŞENLER ---
function TabLink({ active, onClick, icon: Icon, label, count }: any) {
  return (
    <button onClick={onClick} className={`flex items-center gap-2 px-5 py-2 rounded-[20px] transition-all ${active ? 'bg-slate-900 text-white shadow-xl shadow-slate-300' : 'text-slate-400 hover:bg-slate-50'}`}>
       <Icon size={18} weight={active ? "fill" : "duotone"} />
       <span className="text-[11px] font-black uppercase tracking-widest">{label}</span>
       {count > 0 && <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded-full ${active ? 'bg-white/20' : 'bg-slate-100 text-slate-500'}`}>{count}</span>}
    </button>
  );
}

function FilterSelect({ icon: Icon, value, onChange, options, label }: any) {
  return (
    <div className="flex items-center gap-2 bg-white border border-slate-100 px-4 py-2.5 rounded-[22px] shadow-sm">
       <Icon size={18} weight="fill" className="text-slate-300" />
       <select value={value} onChange={(e) => onChange(e.target.value)} className="bg-transparent text-[10px] font-black uppercase outline-none cursor-pointer text-slate-700">
          <option value="">{label}</option>
          {options.map((o: string) => <option key={o} value={o}>{o}</option>)}
       </select>
    </div>
  );
}

function DetailItem({ icon: Icon, label, value, color }: any) {
  return (
    <div className="space-y-1">
       <div className="flex items-center gap-2 text-slate-400"><Icon size={16} weight="duotone" className={color} /><span className="text-[9px] font-black uppercase tracking-widest">{label}</span></div>
       <p className="text-xs font-bold text-slate-800 uppercase tracking-tighter">{value}</p>
    </div>
  );
}

function EditField({ label, value, onChange, icon: Icon }: { label: string, value: string, onChange: (v: string) => void, icon?: any }) {
  return (
    <div className="space-y-1.5">
       <label className="text-[10px] font-black uppercase tracking-widest text-slate-400 ml-2 flex items-center gap-2">
          {Icon && <Icon size={14}/>} {label}
       </label>
       <input value={value || ''} onChange={(e) => onChange(e.target.value)} className="w-full bg-white border border-slate-200 p-4 rounded-[20px] text-xs font-bold text-slate-800 outline-none focus:border-indigo-400 transition-all" />
    </div>
  );
}