'use client';

import React, { useState, useRef, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  Briefcase, ShieldCheck, CheckCircle, 
  Info, User, Phone, Envelope, Storefront, Wrench, LockKey, CaretDown, 
  Image as ImageIcon, Plus, Trash, CurrencyCircleDollar, WarningCircle, MapPin, HouseLine,
  Tag
} from '@phosphor-icons/react';

// --- SABİTLER ---
const CATEGORY_STRUCTURE: Record<string, { label: string; subTypes: string[] }> = {
  TECHNICAL: { label: 'Teknik Servis', subTypes: ['Elektrikçi', 'Su Tesisatçısı', 'Çilingir', 'Asansör Tamiri', 'Kamera & Alarm'] },
  CONSTRUCTION: { label: 'Yapı & Dekorasyon', subTypes: ['Boyacı', 'Alçıpancı', 'Parkeci', 'Fayansçı', 'Mutfak Dolabı'] },
  CLIMATE: { label: 'İklimlendirme', subTypes: ['Kombi Tamiri', 'Klima Servisi', 'Petek Temizliği', 'Güneş Enerjisi'] },
  TECH: { label: 'Teknoloji & Tamir', subTypes: ['Beyaz Eşya', 'TV Tamiri', 'Laptop/PC', 'Telefon Tamiri'] },
  LIFE: { label: 'Yaşam & Temizlik', subTypes: ['Ev Temizliği', 'İlaçlama', 'Koltuk Yıkama', 'Nakliyat'] }
};

const THEME_MAP: any = {
  TECHNICAL: { bg: 'bg-blue-600', main: 'text-blue-600', border: 'border-blue-100', light: 'bg-blue-50/50' },
  CONSTRUCTION: { bg: 'bg-purple-600', main: 'text-purple-600', border: 'border-purple-100', light: 'bg-purple-50/50' },
  CLIMATE: { bg: 'bg-orange-600', main: 'text-orange-600', border: 'border-orange-100', light: 'bg-orange-50/50' },
  TECH: { bg: 'bg-indigo-600', main: 'text-indigo-600', border: 'border-indigo-100', light: 'bg-indigo-50/50' },
  LIFE: { bg: 'bg-emerald-600', main: 'text-emerald-600', border: 'border-emerald-100', light: 'bg-emerald-50/50' }
};

const PREDEFINED_SERVICES: Record<string, string[]> = {
  TECHNICAL: ["Priz ve Anahtar Montajı (10 Adet)", "Elektrik Tesisatı Yenileme Paketi", "Daire Elektrik Tesisatı (100m²)", "Elektrik Panosu Kurulumu", "Topraklama Sistemi Kurulumu", "Kaçak Akım Koruma Sistemi"],
  CONSTRUCTION: ["Boya Badana (2+1)", "Alçıpan Asma Tavan", "Laminat Parke Döşeme"],
};

export default function BecomeProviderView() {
  const { activeCategory } = useCategory();
  const theme = THEME_MAP[activeCategory] || THEME_MAP.TECHNICAL;

  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [profilePic, setProfilePic] = useState<File | null>(null);
  const [services, setServices] = useState([{ name: '', min: '', max: '', error: '' }]);

  const [formData, setFormData] = useState({
    firstName: '', lastName: '', businessName: '',
    category: '', subType: '', phone: '', email: '', password: '',
    city: '', district: '', address: ''
  });

  // Seçilen kategoriye göre hizmet önerileri
  const suggestions = useMemo(() => {
    return PREDEFINED_SERVICES[formData.category] || PREDEFINED_SERVICES.TECHNICAL;
  }, [formData.category]);

  // Cloudinary Yükleme
  const uploadToCloudinary = async (file: File) => {
    const data = new FormData();
    data.append('file', file);
    data.append('upload_preset', 'usta_portfolyo');
    try {
      const res = await fetch(`https://api.cloudinary.com/v1_1/dbgt6dg9n/image/upload`, { method: 'POST', body: data });
      const json = await res.json();
      return json.secure_url;
    } catch (err) { return null; }
  };

  // 🔥 FİYAT ALGORİTMASI (%100 - %50 - %30 Kuralı)
  const handleServiceChange = (index: number, field: 'name' | 'min' | 'max', value: string) => {
    const newServices = [...services];
    newServices[index][field] = value;

    const minVal = parseFloat(newServices[index].min) || 0;
    const maxVal = parseFloat(newServices[index].max) || 0;

    if (minVal > 0 && maxVal > 0) {
      let maxAllowed = minVal <= 2000 ? minVal * 2 : minVal <= 10000 ? minVal * 1.5 : minVal * 1.3;
      if (maxVal < minVal) {
        newServices[index].error = `Max fiyat, Min fiyattan küçük olamaz.`;
      } else if (maxVal > maxAllowed) {
        newServices[index].error = `Tavan fiyat ${Math.round(maxAllowed)} ₺'dir.`;
      } else {
        newServices[index].error = '';
      }
    } else {
      newServices[index].error = '';
    }
    setServices(newServices);
  };

  const addService = () => setServices([...services, { name: '', min: '', max: '', error: '' }]);
  const removeService = (index: number) => setServices(services.filter((_, i) => i !== index));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (services.some(s => s.error !== '')) {
      alert("Lütfen fiyat listesindeki kırmızı uyarıları düzeltin.");
      return;
    }

    setLoading(true);

    try {
      let profileImageUrl = '';
      if (profilePic) {
        profileImageUrl = await uploadToCloudinary(profilePic);
      }

      const priceMap: Record<string, string> = {};
      services.forEach(s => {
        if (s.name.trim() && s.min && s.max) {
          priceMap[s.name] = `${s.min}-${s.max}`;
        }
      });

      const response = await fetch('https://mesely-craftia.hf.space/api/v1/providers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          firstName: formData.firstName,
          lastName: formData.lastName,
          email: formData.email,
          password: formData.password,
          businessName: formData.businessName,
          phoneNumber: formData.phone,
          mainType: formData.category, // Schema uyumu
          category: formData.category, // Proto uyumu
          subType: formData.subType,
          city: formData.city,
          district: formData.district,
          address: formData.address,
          lat: 41.0082, lng: 28.9784, // Mock GPS
          profileImage: profileImageUrl,
          portfolioImages: profileImageUrl ? [profileImageUrl] : [],
          priceList: priceMap,
          isPremium: false // Güvenlik: Usta kendisini premium yapamaz
        }),
      });

      if (response.ok) {
        setSuccess(true);
      } else {
        const error = await response.json();
        alert(`Hata: ${error.message || 'Kayıt başarısız.'}`);
      }
    } catch (err) {
      alert("Sunucuya bağlanılamadı.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="p-4 space-y-5 pb-24 overflow-x-hidden max-w-xl mx-auto">
      
      {/* Header */}
      <div className={`relative overflow-hidden ${theme.bg} p-8 rounded-[40px] shadow-lg text-center text-white`}>
        <div className="relative z-10">
          <div className="bg-white/20 w-14 h-14 rounded-2xl flex items-center justify-center mx-auto mb-3 backdrop-blur-md">
            <Briefcase size={32} weight="duotone" />
          </div>
          <h1 className="text-xl font-black tracking-tight uppercase">Usta Aramıza Katıl</h1>
          <p className="text-[10px] font-bold opacity-80 uppercase tracking-widest">Kendi İşinin Patronu Ol</p>
        </div>
        <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 -rotate-45 translate-x-10 -translate-y-10 rounded-full blur-2xl" />
      </div>

      <AnimatePresence mode="wait">
        {success ? (
          <motion.div key="success" initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="bg-emerald-50 border border-emerald-100 p-10 rounded-[45px] text-center space-y-5 shadow-inner">
            <div className="w-24 h-24 bg-emerald-100 rounded-full flex items-center justify-center mx-auto text-emerald-600 shadow-lg shadow-emerald-200/50">
              <CheckCircle size={56} weight="duotone" />
            </div>
            <div>
              <h3 className="text-xl font-black text-emerald-800 uppercase tracking-tighter">Başvuru Tamamlandı!</h3>
              <p className="text-[11px] font-bold text-emerald-600 mt-2 leading-relaxed">Usta profiliniz oluşturuldu. Aramıza hoş geldiniz!</p>
            </div>
          </motion.div>
        ) : (
          <motion.div key="form" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-4">
            
            {/* Fotoğraf Yükleme */}
            <div className="bg-white/60 backdrop-blur-xl border border-white/80 p-6 rounded-[40px] shadow-sm flex flex-col items-center justify-center gap-4">
              <input type="file" ref={fileInputRef} className="hidden" accept="image/*" onChange={(e) => setProfilePic(e.target.files?.[0] || null)} />
              <div 
                onClick={() => fileInputRef.current?.click()}
                className={`w-28 h-28 rounded-full border-4 border-dashed flex items-center justify-center cursor-pointer transition-all overflow-hidden shadow-inner ${profilePic ? 'border-transparent' : 'border-slate-200 bg-slate-50'}`}
              >
                {profilePic ? (
                  <img src={URL.createObjectURL(profilePic)} alt="Profil" className="w-full h-full object-cover" />
                ) : (
                  <ImageIcon size={40} weight="duotone" className="text-slate-300" />
                )}
              </div>
              <div className="text-center">
                <p className="text-[12px] font-black uppercase text-slate-700">Profil Fotoğrafı</p>
                <p className="text-[10px] font-bold text-slate-400 uppercase mt-0.5">{profilePic ? profilePic.name : 'Seçmek için dokun'}</p>
              </div>
            </div>

            {/* Bilgiler Formu */}
            <div className="bg-white/60 backdrop-blur-xl border border-white/80 p-6 rounded-[40px] shadow-sm space-y-4">
              <div className="flex items-center gap-2 px-1 opacity-50">
                  <Info size={16} weight="bold" />
                  <span className="text-[10px] font-black uppercase tracking-widest">Kayıt Bilgileri</span>
              </div>
              <form id="ustaForm" onSubmit={handleSubmit} className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <SidebarInput placeholder="Ad" icon={<User />} value={formData.firstName} onChange={(v: string)=>setFormData({...formData, firstName:v})} theme={theme} />
                  <SidebarInput placeholder="Soyad" value={formData.lastName} onChange={(v: string)=>setFormData({...formData, lastName:v})} theme={theme} />
                </div>
                <SidebarInput placeholder="İşletme Adı" icon={<Storefront />} value={formData.businessName} onChange={(v: string)=>setFormData({...formData, businessName:v})} theme={theme} />
                
                {/* Ana Kategori Dropdown */}
                <div className="relative">
                  <span className={`absolute left-4 top-1/2 -translate-y-1/2 ${theme.main}`}><Tag size={18} weight="bold" /></span>
                  <select 
                    required
                    className="w-full bg-white/80 border border-slate-100 p-4 pl-12 rounded-[22px] text-xs font-bold text-slate-700 outline-none appearance-none cursor-pointer focus:bg-white transition-all shadow-sm"
                    value={formData.category}
                    onChange={(e) => setFormData({...formData, category: e.target.value, subType: ''})}
                  >
                    <option value="">Kategori Seç...</option>
                    {Object.entries(CATEGORY_STRUCTURE).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
                  </select>
                  <CaretDown size={14} weight="bold" className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                </div>

                {/* Alt Uzmanlık Dropdown */}
                <div className="relative">
                  <span className={`absolute left-4 top-1/2 -translate-y-1/2 ${theme.main}`}><Wrench size={18} weight="bold" /></span>
                  <select 
                    required
                    disabled={!formData.category}
                    className="w-full bg-white/80 border border-slate-100 p-4 pl-12 rounded-[22px] text-xs font-bold text-slate-700 outline-none appearance-none cursor-pointer focus:bg-white transition-all shadow-sm disabled:opacity-50"
                    value={formData.subType}
                    onChange={(e) => setFormData({...formData, subType: e.target.value})}
                  >
                    <option value="">Uzmanlık Alanı...</option>
                    {formData.category && CATEGORY_STRUCTURE[formData.category].subTypes.map(s => <option key={s} value={s}>{s}</option>)}
                  </select>
                  <CaretDown size={14} weight="bold" className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                </div>

                <SidebarInput placeholder="Telefon" icon={<Phone />} value={formData.phone} onChange={(v: string)=>setFormData({...formData, phone:v})} theme={theme} />
                <SidebarInput placeholder="E-posta" icon={<Envelope />} value={formData.email} onChange={(v: string)=>setFormData({...formData, email:v})} theme={theme} />
                <SidebarInput placeholder="Şifre" type="password" icon={<LockKey />} value={formData.password} onChange={(v: string)=>setFormData({...formData, password:v})} theme={theme} />
              </form>
            </div>

            {/* Konum Formu */}
            <div className="bg-white/60 backdrop-blur-xl border border-white/80 p-6 rounded-[40px] shadow-sm space-y-4">
               <div className="flex items-center gap-2 px-1 opacity-50">
                  <MapPin size={16} weight="bold" />
                  <span className="text-[10px] font-black uppercase tracking-widest">Konum Bilgileri</span>
               </div>
               <div className="grid grid-cols-2 gap-3">
                  <SidebarInput placeholder="Şehir" value={formData.city} onChange={(v: string)=>setFormData({...formData, city:v})} theme={theme} />
                  <SidebarInput placeholder="İlçe" value={formData.district} onChange={(v: string)=>setFormData({...formData, district:v})} theme={theme} />
               </div>
               <textarea 
                  required
                  placeholder="Tam Açık Adres (Sokak, Bina No, Kat...)"
                  className="w-full bg-white/80 border border-slate-100 p-4 rounded-[22px] text-xs font-bold text-slate-700 outline-none focus:bg-white transition-all shadow-sm min-h-[100px] resize-none"
                  value={formData.address}
                  onChange={(e) => setFormData({...formData, address: e.target.value})}
               />
            </div>

            {/* Fiyat Listesi */}
            <div className="bg-white/60 backdrop-blur-xl border border-white/80 p-6 rounded-[40px] shadow-sm">
               <div className="flex items-center justify-between mb-5 px-1">
                  <div className="flex items-center gap-2 opacity-50">
                    <CurrencyCircleDollar size={18} weight="bold" />
                    <span className="text-[10px] font-black uppercase tracking-widest">Hizmet & Fiyat Listesi</span>
                  </div>
                  <button type="button" onClick={addService} className={`flex items-center gap-1 text-[10px] font-black uppercase px-4 py-2 rounded-full ${theme.bg} text-white shadow-lg active:scale-90 transition-all`}>
                    <Plus size={12} weight="bold" /> Ekle
                  </button>
              </div>

              <datalist id="service-sug">
                {suggestions.map(s => <option key={s} value={s} />)}
              </datalist>

              <div className="space-y-4">
                {services.map((service, index) => (
                  <div key={index} className="space-y-2">
                    <div className="flex items-center gap-2">
                      <input 
                        required form="ustaForm" list="service-sug"
                        placeholder="Hizmet Adı" value={service.name}
                        onChange={(e) => handleServiceChange(index, 'name', e.target.value)}
                        className="flex-1 bg-white border border-slate-100 p-4 rounded-[22px] text-xs font-bold text-slate-800 outline-none shadow-sm"
                      />
                      <div className="flex items-center gap-2 bg-white/80 px-3 rounded-[22px] border border-slate-100 shadow-inner">
                         <input required form="ustaForm" type="number" placeholder="Min" value={service.min} onChange={(e) => handleServiceChange(index, 'min', e.target.value)} className="w-14 py-4 text-xs font-bold text-center bg-transparent outline-none" />
                         <span className="text-slate-300">-</span>
                         <input required form="ustaForm" type="number" placeholder="Max" value={service.max} onChange={(e) => handleServiceChange(index, 'max', e.target.value)} className={`w-14 py-4 text-xs font-bold text-center bg-transparent outline-none ${service.error ? 'text-red-500' : ''}`} />
                      </div>
                      {services.length > 1 && (
                        <button type="button" onClick={() => removeService(index)} className="p-4 text-red-400 hover:bg-red-50 rounded-2xl transition-all"><Trash size={20} weight="bold" /></button>
                      )}
                    </div>
                    {service.error && (
                      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex items-center gap-1.5 px-4 text-red-500">
                        <WarningCircle size={14} weight="fill" />
                        <span className="text-[9px] font-black uppercase tracking-widest">{service.error}</span>
                      </motion.div>
                    )}
                  </div>
                ))}
              </div>
            </div>

            <button 
              form="ustaForm" type="submit" disabled={loading}
              className={`w-full py-5 rounded-[26px] text-white font-black text-[11px] uppercase tracking-[0.2em] shadow-xl active:scale-95 transition-all mt-6 flex items-center justify-center gap-2 ${theme.bg} ${loading ? 'opacity-60' : ''}`}
            >
              {loading ? 'Kayıt Yapılıyor...' : 'Ustayı Sisteme Kaydet'}
              {!loading && <RocketLaunch size={20} weight="bold" />}
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}

// SidebarInput Helper Component
function SidebarInput({ placeholder, icon, value, onChange, type="text", theme }: any) {
  return (
    <div className="relative w-full">
      {icon && <span className={`absolute left-4 top-1/2 -translate-y-1/2 ${theme.main}`}>{React.cloneElement(icon, { size: 18, weight: 'bold' })}</span>}
      <input 
        required type={type} placeholder={placeholder} value={value} onChange={(e) => onChange(e.target.value)}
        className={`w-full bg-white/80 border border-slate-100 p-4 ${icon ? 'pl-12' : 'pl-4'} rounded-[22px] text-xs font-bold text-slate-800 outline-none focus:bg-white transition-all placeholder:text-slate-400 shadow-sm`}
      />
    </div>
  );
}

const RocketLaunch = ({size, weight}: any) => (
    <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} fill="currentColor" viewBox="0 0 256 256">
        <path d="M213.66,42.34a8,8,0,0,0-11.32,0L135.06,109.62A48,48,0,1,0,109.62,135.06l-67.28,67.28a8,8,0,0,0,0,11.32l30,30a8,8,0,0,0,11.32,0l67.28-67.28A48,48,0,1,0,176.38,151l67.28-67.28a8,8,0,0,0,0-11.32ZM128,160a32,32,0,1,1,32-32A32,32,0,0,1,128,160Z" opacity="0.2"></path>
        <path d="M219.31,36.69a16,16,0,0,0-22.62,0l-71,71a56.06,56.06,0,0,0-63.59,12.73l-19.41,19.4a16,16,0,0,0,0,22.63l12.44,12.44L31,203a16,16,0,0,0,0,22.63l1.37,1.37a16,16,0,0,0,22.63,0l28.05-28.05,12.44,12.44a16,16,0,0,0,22.63,0l19.4-19.41a56.06,56.06,0,0,0,12.73-63.59l71-71A16,16,0,0,0,219.31,36.69ZM109.66,193.66l-12.44-12.44a8,8,0,0,0-11.32,0L57.85,209.27,46.73,198.15l28.05-28.05a8,8,0,0,0,0-11.32L62.34,146.34a40,40,0,0,1,53.49-53.49l11.32,11.32a8,8,0,0,0,11.32,0l15.19-15.19A40.06,40.06,0,0,1,200.15,142.49ZM208,48l-71,71-11.32-11.32,71-71Z"></path>
    </svg>
)