'use client';

import React, { useState, useRef, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useCategory } from '@/context/CategoryContext';
import { 
  Briefcase, ShieldCheck, CheckCircle, 
  Info, User, Phone, Envelope, Storefront, Wrench, LockKey, CaretDown, 
  Image as ImageIcon, Plus, Trash, CurrencyCircleDollar, WarningCircle
} from '@phosphor-icons/react';

const THEME_MAP: any = {
  TECHNICAL: { bg: 'bg-blue-600', main: 'text-blue-600', border: 'border-blue-100', light: 'bg-blue-50/50' },
  CONSTRUCTION: { bg: 'bg-purple-600', main: 'text-purple-600', border: 'border-purple-100', light: 'bg-purple-50/50' },
  CLIMATE: { bg: 'bg-orange-600', main: 'text-orange-600', border: 'border-orange-100', light: 'bg-orange-50/50' },
  TECH: { bg: 'bg-indigo-600', main: 'text-indigo-600', border: 'border-indigo-100', light: 'bg-indigo-50/50' },
  LIFE: { bg: 'bg-emerald-600', main: 'text-emerald-600', border: 'border-emerald-100', light: 'bg-emerald-50/50' }
};

const PREDEFINED_SERVICES: Record<string, string[]> = {
  TECHNICAL: [
    "Priz ve Anahtar Montajı (10 Adet)", "Elektrik Tesisatı Yenileme Paketi", 
    "Dükkan/Ofis Elektrik Altyapısı", "Güvenlik Kamerası Elektrik Altyapısı", 
    "Kapı Zili ve İnterkom Kurulum", "Elektrikli Panjur Sistemi", 
    "Havuz Elektrik ve Aydınlatma", "Klima Elektrik Altyapısı", 
    "Kombi Oda Elektrik Bağlantısı", "Ankastre Set Elektrik Kurulumu", 
    "Çamaşır/Bulaşık Makinesi Elektrik Bağlantısı", "Elektrikli Şohben Kurulumu", 
    "Güneş Paneli Elektrik Entegrasyonu", "Topraklama Sistemi Kurulumu", 
    "Kaçak Akım Koruma Sistemi", "Villa Tam Elektrik Bağlantısı", 
    "Daire Elektrik Tesisatı (100m²)", "Elektrik Panosu Kurulumu", 
    "Spot ve LED Aydınlatma Sistemi", "Avize ve Aplik Montajı (5 Nokta)", 
    "Bahçe Aydınlatma Sistemi", "Dış Cephe Led Aydınlatma"
  ]
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
    category: '', phone: '', email: '', password: ''
  });

  const suggestions = useMemo(() => {
    return PREDEFINED_SERVICES[formData.category] || PREDEFINED_SERVICES.TECHNICAL;
  }, [formData.category]);

  const uploadToCloudinary = async (file: File) => {
    const data = new FormData();
    data.append('file', file);
    data.append('upload_preset', 'usta_portfolyo');
    try {
      const res = await fetch(`https://api.cloudinary.com/v1_1/dbgt6dg9n/image/upload`, {
        method: 'POST', body: data,
      });
      const json = await res.json();
      return json.secure_url;
    } catch (err) {
      console.error("Resim yükleme hatası:", err);
      return null;
    }
  };

  const handleServiceChange = (index: number, field: 'name' | 'min' | 'max', value: string) => {
    const newServices = [...services];
    newServices[index][field] = value;

    const minVal = parseFloat(newServices[index].min) || 0;
    const maxVal = parseFloat(newServices[index].max) || 0;

    if (minVal > 0 && maxVal > 0) {
      let maxAllowed = minVal <= 2000 ? minVal * 2 : minVal <= 10000 ? minVal * 1.5 : minVal * 1.3;
      if (maxVal < minVal) {
        newServices[index].error = `Maksimum fiyat, minimumdan küçük olamaz.`;
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

      // Canlı HF Space Backend URL
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
          mainType: formData.category, // Schema için
          category: formData.category, // Proto uyumu için
          subType: 'Elektrikçi', // Varsayılan veya seçimden gelebilir
          city: 'İstanbul',
          district: 'Merkez',
          lat: 41.0082,
          lng: 28.9784,
          profileImage: profileImageUrl,
          portfolioImages: profileImageUrl ? [profileImageUrl] : [],
          priceList: priceMap,
          isPremium: false // Usta kendisini premium yapamaz
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
    <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="p-4 space-y-5 pb-24 overflow-x-hidden">
      
      <div className={`relative overflow-hidden ${theme.bg} p-6 rounded-[35px] shadow-lg text-center text-white`}>
        <div className="relative z-10">
          <div className="bg-white/20 w-12 h-12 rounded-2xl flex items-center justify-center mx-auto mb-2 backdrop-blur-md">
            <Briefcase size={28} weight="duotone" />
          </div>
          <h1 className="text-lg font-black tracking-tight uppercase text-white">Usta Aramıza Katıl</h1>
          <p className="text-[9px] font-bold opacity-80 uppercase tracking-widest text-white">Kendi İşinin Patronu Ol</p>
        </div>
      </div>

      <AnimatePresence mode="wait">
        {success ? (
          <motion.div key="success" initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="bg-emerald-50 border border-emerald-100 p-8 rounded-[40px] text-center space-y-4">
            <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto text-emerald-600">
              <CheckCircle size={48} weight="duotone" />
            </div>
            <div>
              <h3 className="text-lg font-black text-emerald-800 uppercase">Başvuru Başarılı!</h3>
              <p className="text-[10px] font-bold text-emerald-600 mt-2">Profiliniz oluşturuldu. Hoş geldiniz!</p>
            </div>
          </motion.div>
        ) : (
          <motion.div key="form" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-4">
            
            {/* Fotoğraf Yükleme */}
            <div className="bg-white/40 backdrop-blur-xl border border-white/60 p-5 rounded-[35px] shadow-sm flex flex-col items-center justify-center gap-3">
              <input type="file" ref={fileInputRef} className="hidden" accept="image/*" onChange={(e) => setProfilePic(e.target.files?.[0] || null)} />
              <div 
                onClick={() => fileInputRef.current?.click()}
                className={`w-24 h-24 rounded-full border-2 border-dashed flex items-center justify-center cursor-pointer overflow-hidden ${profilePic ? 'border-transparent' : theme.border} ${theme.light}`}
              >
                {profilePic ? (
                  <img src={URL.createObjectURL(profilePic)} alt="Profil" className="w-full h-full object-cover" />
                ) : (
                  <ImageIcon size={32} weight="duotone" className={theme.main} />
                )}
              </div>
              <p className="text-[11px] font-black uppercase text-slate-700">Profil Fotoğrafı</p>
            </div>

            {/* Bilgiler Formu */}
            <div className="bg-white/40 backdrop-blur-xl border border-white/60 p-5 rounded-[35px] shadow-sm relative">
              <div className="flex items-center gap-2 mb-4 px-1 opacity-60">
                  <Info size={14} weight="bold" />
                  <span className="text-[9px] font-black uppercase tracking-widest">Kayıt Bilgileri</span>
              </div>
              <form id="ustaForm" onSubmit={handleSubmit} className="space-y-3">
                <div className="grid grid-cols-2 gap-2">
                  <SidebarInput placeholder="Ad" icon={<User />} value={formData.firstName} onChange={(v: string)=>setFormData({...formData, firstName:v})} theme={theme} />
                  <SidebarInput placeholder="Soyad" value={formData.lastName} onChange={(v: string)=>setFormData({...formData, lastName:v})} theme={theme} />
                </div>
                <SidebarInput placeholder="İşletme Adı" icon={<Storefront />} value={formData.businessName} onChange={(v: string)=>setFormData({...formData, businessName:v})} theme={theme} />
                
                <div className="relative">
                  <span className={`absolute left-4 top-1/2 -translate-y-1/2 ${theme.main}`}><Wrench size={18} weight="bold" /></span>
                  <select 
                    required
                    className="w-full bg-white/50 border border-white/60 p-3.5 pl-12 rounded-[20px] text-xs font-bold text-slate-700 outline-none appearance-none cursor-pointer focus:bg-white transition-all"
                    value={formData.category}
                    onChange={(e) => setFormData({...formData, category: e.target.value})}
                  >
                    <option value="">Uzmanlık Kategorisi...</option>
                    <option value="TECHNICAL">Teknik Servis</option>
                    <option value="CLIMATE">İklimlendirme</option>
                    <option value="CONSTRUCTION">Yapı & Dekorasyon</option>
                    <option value="TECH">Teknoloji & Tamir</option>
                  </select>
                  <CaretDown size={14} weight="bold" className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                </div>

                <SidebarInput placeholder="Telefon" icon={<Phone />} value={formData.phone} onChange={(v: string)=>setFormData({...formData, phone:v})} theme={theme} />
                <SidebarInput placeholder="E-posta" icon={<Envelope />} value={formData.email} onChange={(v: string)=>setFormData({...formData, email:v})} theme={theme} />
                <SidebarInput placeholder="Şifre" type="password" icon={<LockKey />} value={formData.password} onChange={(v: string)=>setFormData({...formData, password:v})} theme={theme} />
              </form>
            </div>

            {/* Fiyat Listesi */}
            <div className="bg-white/40 backdrop-blur-xl border border-white/60 p-5 rounded-[35px] shadow-sm">
               <div className="flex items-center justify-between mb-4 px-1">
                  <div className="flex items-center gap-2 opacity-60 text-slate-900">
                    <CurrencyCircleDollar size={16} weight="bold" />
                    <span className="text-[9px] font-black uppercase tracking-widest">Hizmetler & Fiyatlar (₺)</span>
                  </div>
                  <button type="button" onClick={addService} className={`flex items-center gap-1 text-[9px] font-black uppercase px-3 py-1.5 rounded-full ${theme.bg} text-white`}>
                    <Plus size={10} weight="bold" /> Satır Ekle
                  </button>
              </div>

              <datalist id="reg-suggestions">
                {suggestions.map(s => <option key={s} value={s} />)}
              </datalist>

              <div className="space-y-3">
                {services.map((service, index) => (
                  <div key={index} className="space-y-1.5">
                    <div className="flex items-center gap-2">
                      <input 
                        required form="ustaForm" list="reg-suggestions"
                        placeholder="Hizmet" value={service.name}
                        onChange={(e) => handleServiceChange(index, 'name', e.target.value)}
                        className="flex-1 bg-white/50 border border-white/60 p-3 rounded-[16px] text-xs font-bold text-slate-800 outline-none"
                      />
                      <input 
                        required form="ustaForm" type="number" placeholder="Min" value={service.min}
                        onChange={(e) => handleServiceChange(index, 'min', e.target.value)}
                        className="w-[70px] bg-white/50 border border-white/60 p-3 rounded-[16px] text-xs font-bold text-slate-800 text-center"
                      />
                      <input 
                        required form="ustaForm" type="number" placeholder="Max" value={service.max}
                        onChange={(e) => handleServiceChange(index, 'max', e.target.value)}
                        className={`w-[70px] bg-white/50 border p-3 rounded-[16px] text-xs font-bold text-slate-800 text-center ${service.error ? 'border-red-400 bg-red-50 text-red-600' : 'border-white/60'}`}
                      />
                      <button type="button" onClick={() => removeService(index)} className="p-3 text-red-400"><Trash size={16} weight="bold" /></button>
                    </div>
                    {service.error && <div className="flex items-center gap-1 px-2 text-red-500 text-[8px] font-black uppercase"><WarningCircle size={12}/>{service.error}</div>}
                  </div>
                ))}
              </div>
            </div>

            <button 
              form="ustaForm" type="submit" disabled={loading}
              className={`w-full py-4 rounded-[22px] text-white font-black text-[10px] uppercase tracking-[0.2em] shadow-lg active:scale-95 transition-all mt-4 flex items-center justify-center gap-2 ${theme.bg} ${loading ? 'opacity-60' : ''}`}
            >
              {loading ? 'Kaydediliyor...' : 'Ustayı Kaydet'}
              {!loading && <CheckCircle size={16} weight="bold" />}
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
}

function SidebarInput({ placeholder, icon, value, onChange, type="text", theme }: any) {
  return (
    <div className="relative">
      {icon && <span className={`absolute left-4 top-1/2 -translate-y-1/2 ${theme.main}`}>{React.cloneElement(icon, { size: 18, weight: 'bold' })}</span>}
      <input 
        required type={type} placeholder={placeholder} value={value} onChange={(e) => onChange(e.target.value)}
        className={`w-full bg-white/50 border border-white/60 p-3.5 ${icon ? 'pl-12' : 'pl-4'} rounded-[20px] text-xs font-bold text-slate-800 outline-none focus:bg-white transition-all placeholder:text-slate-400`}
      />
    </div>
  );
}