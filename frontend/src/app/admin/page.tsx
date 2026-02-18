'use client';

import React, { useState, useEffect, useMemo, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Trash, Star, Briefcase, Chats, ShieldWarning, 
  User, CheckCircle, WarningCircle, MapPin, 
  Phone, CaretDown, CheckSquare, Square, 
  PencilSimple, X, Camera, Plus, CurrencyCircleDollar, 
  ShootingStar, Image as ImageIcon, Funnel, Gear, HouseLine, Tag, Crown
} from '@phosphor-icons/react';

// --- TİPLER ---
interface IPriceItem { name: string; min: string; max: string; error: string; }
type TabType = 'PROVIDERS' | 'REVIEWS';

const CATEGORY_STRUCTURE: Record<string, { label: string; subTypes: string[] }> = {
  TECHNICAL: { label: 'Teknik Servis', subTypes: ['Elektrikçi', 'Su Tesisatçısı', 'Çilingir', 'Asansör Tamiri', 'Kamera & Alarm'] },
  CONSTRUCTION: { label: 'Yapı & Dekorasyon', subTypes: ['Boyacı', 'Alçıpancı', 'Parkeci', 'Fayansçı'] },
  CLIMATE: { label: 'İklimlendirme', subTypes: ['Kombi Tamiri', 'Klima Servisi', 'Petek Temizliği'] },
  TECH: { label: 'Teknoloji & Tamir', subTypes: ['Beyaz Eşya', 'TV Tamiri', 'Laptop/PC'] },
  LIFE: { label: 'Yaşam & Temizlik', subTypes: ['Ev Temizliği', 'İlaçlama', 'Koltuk Yıkama'] }
};

const THEME_MAP: Record<string, { badge: string; text: string }> = {
  TECHNICAL: { badge: 'bg-blue-50 text-blue-700 border-blue-100', text: 'text-blue-700' },
  CONSTRUCTION: { badge: 'bg-purple-50 text-purple-700 border-purple-100', text: 'text-purple-700' },
  CLIMATE: { badge: 'bg-orange-50 text-orange-700 border-orange-100', text: 'text-orange-700' },
  TECH: { badge: 'bg-indigo-50 text-indigo-700 border-indigo-100', text: 'text-indigo-700' },
  LIFE: { badge: 'bg-emerald-50 text-emerald-700 border-emerald-100', text: 'text-emerald-700' },
  DEFAULT: { badge: 'bg-slate-50 text-slate-700 border-slate-100', text: 'text-slate-700' }
};

export default function AdminDashboard() {
  const [activeTab, setActiveTab] = useState<TabType>('PROVIDERS');
  const [loading, setLoading] = useState(false);
  const API_URL = 'https://mesely-craftia.hf.space/api/v1';

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
      const res = await fetch(`${API_URL}/${activeTab === 'PROVIDERS' ? 'providers?limit=200' : 'reviews'}`);
      const data = await res.json();
      if (activeTab === 'PROVIDERS') setProviders(data.providers || []);
      else setReviews(Array.isArray(data) ? data : []);
    } catch (err) { console.error(err); }
    finally { setLoading(false); }
  };

  useEffect(() => { fetchData(); setSelectedIds([]); }, [activeTab]);

  const filteredProviders = useMemo(() => providers.filter(p => (!filterCity || p.city === filterCity) && (!filterMainType || p.mainType === filterMainType)), [providers, filterCity, filterMainType]);

  // ✅ ÇOKLU SİLME MANTIĞI
  const handleBulkDelete = async () => {
    if (!window.confirm(`${selectedIds.length} usta silinecek. Emin misiniz?`)) return;
    setLoading(true);
    try {
      await Promise.all(selectedIds.map(id => fetch(`${API_URL}/providers/${id}`, { method: 'DELETE' })));
      setProviders((prev) => prev.filter(p => !selectedIds.includes(p._id)));
      setSelectedIds([]);
      alert("Seçilenlerin tamamı silindi.");
    } finally { setLoading(false); }
  };

  // ✅ TEKLİ SİLME MANTIĞI
  const handleDeleteOne = async (e: React.MouseEvent, id: string) => {
    e.stopPropagation();
    if (!window.confirm("Bu ustayı silmek istediğinize emin misiniz?")) return;
    try {
      const res = await fetch(`${API_URL}/providers/${id}`, { method: 'DELETE' });
      if (res.ok) setProviders((prev) => prev.filter(p => p._id !== id));
    } catch (err) { alert("Bağlantı hatası."); }
  };

  const openEdit = (p: any) => {
    setEditingProvider({ ...p });
    setEditPrices(p.priceList ? Object.entries(p.priceList).map(([name, range]) => ({ name, min: String(range).split('-')[0], max: String(range).split('-')[1] || '', error: '' })) : []);
  };

  const handlePriceChange = (index: number, field: keyof IPriceItem, value: string) => {
    const updated = [...editPrices];
    updated[index] = { ...updated[index], [field]: value };
    const min = parseFloat(updated[index].min) || 0;
    const max = parseFloat(updated[index].max) || 0;
    if (min > 0 && max > 0) {
      const limit = min <= 2000 ? min * 2 : min <= 10000 ? min * 1.5 : min * 1.3;
      updated[index].error = max < min ? "Max < Min olamaz" : max > limit ? `Tavan: ${Math.round(limit)} ₺` : "";
    }
    setEditPrices(updated);
  };

  const saveEdit = async () => {
    if (editPrices.some(p => p.error)) return alert("Fiyat hatalarını düzeltin.");
    const priceMap: Record<string, string> = {};
    editPrices.forEach(p => { if(p.name && p.min) priceMap[p.name] = `${p.min}-${p.max}`; });
    
    // ✅ GÜNCELLEME PAKETİ (PAYLOAD)
    const payload = { 
        ...editingProvider, 
        priceList: priceMap, 
        category: editingProvider.mainType, // Proto eşleşmesi için
        isPremium: editingProvider.isPremium === true // Kesin boolean yolla
    };
    
    try {
      const res = await fetch(`${API_URL}/providers/${editingProvider._id}`, {
        method: 'PUT', 
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      if (res.ok) {
        const updatedData = await res.json();
        // UI tarafında state'i güncelle (Backend'den dönen isPremium false olsa bile UI'da isPremium'u payload'daki gibi yansıt)
        setProviders((prev) => prev.map(p => p._id === payload._id ? { ...p, ...payload } : p));
        setEditingProvider(null);
        alert("Başarıyla kaydedildi.");
      }
    } catch (err) { alert("Güncelleme başarısız."); }
  };

  return (
    <div className="min-h-screen bg-[#FDFDFD] font-sans text-slate-800">
      
      {/* 📱 HEADER (60px) */}
      <header className="fixed top-0 left-0 right-0 z-[60] bg-white/60 backdrop-blur-3xl border-b border-white shadow-sm h-[60px]">
        <div className="max-w-6xl mx-auto px-6 h-full flex items-center justify-between">
          <div className="flex items-center gap-3">
             <div className="p-2 bg-slate-900 rounded-2xl shadow-xl shadow-slate-200"><Gear size={20} weight="fill" className="text-white" /></div>
             <h1 className="text-[16px] font-black uppercase tracking-[0.2em] text-slate-900">Usta Panel</h1>
          </div>
          <div className="flex items-center gap-4">
             <TabLink active={activeTab === 'PROVIDERS'} onClick={() => setActiveTab('PROVIDERS')} label="Ustalar" count={providers.length} />
             <TabLink active={activeTab === 'REVIEWS'} onClick={() => setActiveTab('REVIEWS')} label="Yorumlar" count={reviews.length} />
          </div>
        </div>
      </header>

      <main className="pt-[100px] px-6 pb-32 max-w-6xl mx-auto">
        
        {/* 🔍 FILTER & BULK ACTIONS */}
        <div className="mb-8 flex flex-wrap items-center justify-between gap-4 bg-white/80 p-5 rounded-[35px] border border-white shadow-lg shadow-slate-100/50">
           <div className="flex items-center gap-3">
              <FilterSelect value={filterCity} onChange={setFilterCity} options={Array.from(new Set(providers.map(p => p.city))).filter(Boolean) as string[]} label="Şehirler" />
              <FilterSelect value={filterMainType} onChange={setFilterMainType} options={Object.keys(CATEGORY_STRUCTURE)} label="Kategoriler" />
           </div>
           <div className="flex items-center gap-4">
              <button onClick={() => setSelectedIds(selectedIds.length === filteredProviders.length ? [] : filteredProviders.map(p => p._id))} className="text-[10px] font-black uppercase text-slate-400 flex items-center gap-2 hover:text-indigo-600 transition-colors">
                 {selectedIds.length === filteredProviders.length && selectedIds.length > 0 ? <CheckSquare size={22} weight="fill" className="text-indigo-600" /> : <Square size={22} weight="bold" className="text-slate-100" />}
                 Tümünü Seç
              </button>
              {selectedIds.length > 0 && <button onClick={handleBulkDelete} className="bg-red-500 text-white px-6 py-3 rounded-2xl text-[10px] font-black uppercase shadow-xl active:scale-95 transition-all">Toplu Sil ({selectedIds.length})</button>}
           </div>
        </div>

        {/* 📋 LİSTELEME */}
        <div className="space-y-3">
          {loading ? <div className="flex justify-center py-20 text-slate-300 animate-pulse">Yükleniyor...</div> : 
            filteredProviders.map((p) => (
                <div key={p._id} className={`bg-white rounded-[35px] border transition-all overflow-hidden ${selectedIds.includes(p._id) ? 'border-indigo-400 ring-4 ring-indigo-50 shadow-xl' : 'border-slate-100 shadow-sm hover:shadow-xl'}`}>
                   <div onClick={() => setExpandedId(expandedId === p._id ? null : p._id)} className="p-5 flex items-center justify-between cursor-pointer">
                      <div className="flex items-center gap-5">
                         <div className="w-14 h-14 rounded-[22px] bg-slate-50 border border-slate-100 overflow-hidden shrink-0 relative">
                            {p.profileImage ? <img src={p.profileImage} className="w-full h-full object-cover" /> : <User size={24} className="m-4 text-slate-200" />}
                            {p.isPremium && <div className="absolute top-1 right-1 bg-amber-400 text-white p-0.5 rounded-md"><Crown size={10} weight="fill" /></div>}
                         </div>
                         <div>
                            <h3 className="text-[14px] font-black uppercase text-slate-900 tracking-tight">{p.businessName}</h3>
                            <div className="flex items-center gap-2 mt-1">
                               <span className={`text-[8px] font-black uppercase px-2 py-0.5 rounded-lg border ${THEME_MAP[p.mainType]?.badge || 'bg-slate-50'}`}>{p.mainType}</span>
                               <span className="text-[10px] font-bold text-slate-400 uppercase">{p.city}</span>
                            </div>
                         </div>
                      </div>
                      <div className="flex items-center gap-2">
                         <button onClick={(e) => { e.stopPropagation(); openEdit(p); }} className="p-3 text-slate-300 hover:text-indigo-600 transition-all"><PencilSimple size={20} weight="bold" /></button>
                         <button onClick={(e) => handleDeleteOne(e, p._id)} className="p-3 text-slate-300 hover:text-red-500 transition-all"><Trash size={20} weight="bold" /></button>
                         <div className={`ml-2 text-slate-200 transition-transform duration-300 ${expandedId === p._id ? 'rotate-180' : ''}`}><CaretDown size={20} weight="bold" /></div>
                      </div>
                   </div>

                   {/* ✅ DETAYLAR VE AÇIK ADRES */}
                   <AnimatePresence>
                     {expandedId === p._id && (
                       <motion.div initial={{ height: 0 }} animate={{ height: 'auto' }} exit={{ height: 0 }} className="bg-slate-50/50 border-t p-8 px-24 grid grid-cols-1 md:grid-cols-2 gap-10">
                          <div className="space-y-4">
                            <DetailItem label="İletişim" value={p.phoneNumber} />
                            <DetailItem label="Uzmanlık" value={p.subType} />
                            <DetailItem label="Üyelik Tipi" value={p.isPremium ? '💎 PREMIUM' : 'STANDART'} />
                          </div>
                          <div className="p-6 bg-white rounded-[30px] border border-indigo-100 shadow-sm relative">
                             <div className="text-indigo-500 mb-3 flex items-center gap-2"><HouseLine size={24}/><span className="text-[10px] font-black uppercase">Tam Açık Adres</span></div>
                             <p className="text-[13px] font-bold text-slate-700 italic leading-relaxed">{p.address || 'Adres bilgisi yok.'}</p>
                          </div>
                       </motion.div>
                     )}
                   </AnimatePresence>
                </div>
              )
            )
          }
        </div>
      </main>

      {/* --- 🎨 MODAL --- */}
      <AnimatePresence>
        {editingProvider && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 bg-slate-900/40 backdrop-blur-md" onClick={() => setEditingProvider(null)} />
            <motion.div initial={{ scale: 0.95, y: 30 }} animate={{ scale: 1, y: 0 }} className="relative w-full max-w-3xl bg-white rounded-[45px] p-10 shadow-2xl z-10 max-h-[90vh] overflow-y-auto border border-white/20">
              
              <div className="flex justify-between items-center mb-10">
                <h2 className="text-2xl font-black uppercase text-slate-900 tracking-tighter italic">Kart Düzenle</h2>
                <button onClick={() => setEditingProvider(null)} className="p-3 bg-slate-100 rounded-[20px]"><X size={20} weight="bold" /></button>
              </div>

              <div className="space-y-12">
                {/* 👑 PREMIUM TOGGLE */}
                <div className="flex items-center justify-between bg-amber-50 p-6 rounded-[35px] border border-amber-100 shadow-sm">
                   <div className="flex items-center gap-4">
                      <div className={`p-3 rounded-2xl ${editingProvider.isPremium ? 'bg-amber-400 text-white shadow-lg' : 'bg-white text-slate-300'}`}><Crown size={28} weight="fill" /></div>
                      <div><p className="text-[12px] font-black uppercase text-amber-800">Premium Usta Hesabı</p><p className="text-[9px] font-bold text-amber-600/60 uppercase tracking-widest">Aramalarda her zaman en üstte listelenir.</p></div>
                   </div>
                   <button onClick={() => setEditingProvider({...editingProvider, isPremium: !editingProvider.isPremium})} className={`w-16 h-9 rounded-full flex items-center px-1 transition-all ${editingProvider.isPremium ? 'bg-amber-500 justify-end' : 'bg-slate-200 justify-start'}`}><div className="w-7 h-7 bg-white rounded-full shadow-md" /></button>
                </div>

                {/* 📸 FOTOĞRAFLAR */}
                <section>
                   <div className="flex items-center justify-between mb-6">
                      <label className="text-[11px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-2"><Camera size={18} weight="duotone" /> Hizmet Fotoğrafları</label>
                      <button onClick={() => fileInputRef.current?.click()} className="bg-slate-900 text-white px-5 py-2.5 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-800 transition-all">{uploading ? 'Yükleniyor...' : '+ Fotoğraf Ekle'}</button>
                      <input type="file" ref={fileInputRef} className="hidden" onChange={(e) => {
                        const file = e.target.files?.[0]; if (!file) return;
                        setUploading(true);
                        const data = new FormData(); data.append('file', file); data.append('upload_preset', 'usta_portfolyo');
                        fetch(`https://api.cloudinary.com/v1_1/dbgt6dg9n/image/upload`, { method: 'POST', body: data })
                          .then(r => r.json()).then(json => {
                             setEditingProvider((prev: any) => ({...prev, portfolioImages: [...(prev?.portfolioImages || []), json.secure_url], profileImage: prev?.profileImage || json.secure_url}));
                             setUploading(false);
                          });
                      }} />
                   </div>
                   <div className="grid grid-cols-4 gap-4">
                      {editingProvider.portfolioImages?.map((img: string, idx: number) => (
                        <div key={idx} className="relative aspect-square rounded-[28px] overflow-hidden border-2 border-slate-100 group shadow-sm">
                           <img src={img} className="w-full h-full object-cover" />
                           {editingProvider.profileImage === img && <div className="absolute top-3 left-3 bg-amber-400 text-white p-1.5 rounded-xl shadow-lg"><ShootingStar size={14} weight="fill" /></div>}
                           <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                              <button onClick={() => setEditingProvider({...editingProvider, profileImage: img})} className="p-2.5 bg-white rounded-xl text-indigo-600 shadow-xl" title="Profil Yap"><User size={18} weight="bold" /></button>
                              <button onClick={() => setEditingProvider({...editingProvider, portfolioImages: editingProvider.portfolioImages.filter((i: string) => i !== img)})} className="p-2.5 bg-white rounded-xl text-red-500 shadow-xl"><Trash size={18} weight="bold" /></button>
                           </div>
                        </div>
                      ))}
                   </div>
                </section>

                {/* 📝 KİMLİK & KATEGORİ (DROPDOWN) */}
                <section className="grid grid-cols-1 md:grid-cols-2 gap-6 p-8 bg-slate-50/50 rounded-[40px] border shadow-inner">
                   <EditField label="İşletme Adı" value={editingProvider.businessName} onChange={(v: string) => setEditingProvider({...editingProvider, businessName: v})} />
                   <EditField label="Telefon" value={editingProvider.phoneNumber} onChange={(v: string) => setEditingProvider({...editingProvider, phoneNumber: v})} />
                   <div className="space-y-1.5">
                      <label className="text-[10px] font-black uppercase text-slate-400 ml-2">Ana Kategori</label>
                      <select value={editingProvider.mainType} onChange={(e) => setEditingProvider({...editingProvider, mainType: e.target.value, subType: ''})} className="w-full bg-white border border-slate-200 p-4 rounded-[22px] text-xs font-bold shadow-sm appearance-none cursor-pointer">
                         <option value="">Seçiniz...</option>
                         {Object.entries(CATEGORY_STRUCTURE).map(([key, value]) => <option key={key} value={key}>{value.label}</option>)}
                      </select>
                   </div>
                   <div className="space-y-1.5">
                      <label className="text-[10px] font-black uppercase text-slate-400 ml-2">Uzmanlık Alanı</label>
                      <select value={editingProvider.subType} disabled={!editingProvider.mainType} onChange={(e) => setEditingProvider({...editingProvider, subType: e.target.value})} className="w-full bg-white border border-slate-200 p-4 rounded-[22px] text-xs font-bold shadow-sm">
                         <option value="">Seçiniz...</option>
                         {editingProvider.mainType && CATEGORY_STRUCTURE[editingProvider.mainType]?.subTypes.map(s => <option key={s} value={s}>{s}</option>)}
                      </select>
                   </div>
                </section>

                {/* 📍 ADRES VE KONUM */}
                <section className="p-8 bg-slate-50/50 rounded-[40px] border space-y-6 shadow-inner">
                   <div className="grid grid-cols-2 gap-4">
                      <EditField label="Şehir" value={editingProvider.city} onChange={(v: string) => setEditingProvider({...editingProvider, city: v})} />
                      <EditField label="İlçe" value={editingProvider.district} onChange={(v: string) => setEditingProvider({...editingProvider, district: v})} />
                   </div>
                   <textarea value={editingProvider.address || ''} onChange={(e) => setEditingProvider({...editingProvider, address: e.target.value})} className="w-full bg-white border p-5 rounded-[25px] text-xs font-bold outline-none focus:border-indigo-400 min-h-[120px] shadow-sm" placeholder="Tam açık adres..." />
                </section>

                {/* 💰 FİYAT SİHİRBAZI */}
                <section className="bg-white p-8 rounded-[40px] border border-slate-200 shadow-sm">
                   <div className="flex items-center justify-between mb-8">
                      <label className="text-[11px] font-black uppercase tracking-widest text-slate-500 flex items-center gap-2"><CurrencyCircleDollar size={20} weight="duotone" /> Hizmet & Fiyat Sihirbazı</label>
                      <button onClick={() => setEditPrices([...editPrices, {name: '', min: '', max: '', error: ''}])} className="text-[10px] font-black uppercase text-indigo-600 bg-indigo-50 px-4 py-2 rounded-full hover:bg-indigo-100 transition-all">+ Satır Ekle</button>
                   </div>
                   <div className="space-y-4">
                      {editPrices.map((item, idx) => (
                        <div key={idx} className="flex flex-col gap-2">
                           <div className="flex items-center gap-3">
                              <input placeholder="Hizmet" value={item.name} onChange={(e) => handlePriceChange(idx, 'name', e.target.value)} className="flex-1 bg-slate-50 border border-slate-200 p-4 rounded-[22px] text-xs font-bold outline-none shadow-sm" />
                              <div className="flex items-center gap-2 bg-slate-50 px-4 rounded-[22px] border border-slate-200 shadow-inner">
                                 <input type="number" placeholder="Min" value={item.min} onChange={(e) => handlePriceChange(idx, 'min', e.target.value)} className="w-16 py-4 text-xs font-bold text-center bg-transparent outline-none" />
                                 <span className="text-slate-300">-</span>
                                 <input type="number" placeholder="Max" value={item.max} onChange={(e) => handlePriceChange(idx, 'max', e.target.value)} className={`w-16 py-4 text-xs font-bold text-center bg-transparent outline-none ${item.error ? 'text-red-500' : ''}`} />
                              </div>
                              <button onClick={() => setEditPrices(editPrices.filter((_, i) => i !== idx))} className="p-4 text-red-400 hover:bg-red-50 rounded-2xl transition-all"><Trash size={20} /></button>
                           </div>
                           {item.error && <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="text-red-500 text-[9px] font-black uppercase px-4 leading-tight">{item.error}</motion.div>}
                        </div>
                      ))}
                   </div>
                </section>

                {/* 💾 KAYDET */}
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
function TabLink({ active, onClick, label, count }: any) {
  return (
    <button onClick={onClick} className={`px-5 py-2 rounded-[20px] transition-all ${active ? 'bg-slate-900 text-white shadow-xl shadow-slate-300' : 'text-slate-400 hover:bg-slate-50'}`}>
       <span className="text-[11px] font-black uppercase tracking-widest">{label}</span>
       {count > 0 && <span className={`ml-2 text-[9px] font-bold px-1.5 py-0.5 rounded-full ${active ? 'bg-white/20' : 'bg-slate-100 text-slate-500'}`}>{count}</span>}
    </button>
  );
}

function FilterSelect({ value, onChange, options, label }: any) {
  return (
    <select value={value} onChange={(e) => onChange(e.target.value)} className="bg-white border border-slate-100 px-4 py-2.5 rounded-[22px] shadow-sm text-[10px] font-black uppercase outline-none cursor-pointer">
       <option value="">{label}</option>
       {options.map((o: string) => <option key={o} value={o}>{o}</option>)}
    </select>
  );
}

function DetailItem({ label, value }: any) {
  return (
    <div className="space-y-1">
       <div className="text-[9px] font-black uppercase text-slate-400 tracking-widest">{label}</div>
       <p className="text-xs font-bold text-slate-900 uppercase tracking-tighter">{value}</p>
    </div>
  );
}

function EditField({ label, value, onChange }: any) {
  return (
    <div className="space-y-1.5">
       <label className="text-[10px] font-black uppercase text-slate-400 ml-2 tracking-widest">{label}</label>
       <input value={value || ''} onChange={(e) => onChange(e.target.value)} className="w-full bg-white border border-slate-200 p-4 rounded-[22px] text-xs font-bold outline-none focus:border-indigo-400 transition-all shadow-sm" />
    </div>
  );
}