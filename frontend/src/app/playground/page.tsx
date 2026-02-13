'use client';

import React, { useState } from 'react';
import { 
  Play, Bug, ShieldCheck, Truck, Star, Bell, 
  Trash, MagnifyingGlass, User as UserIcon, Browser 
} from '@phosphor-icons/react';

const GATEWAY_URL = 'http://localhost:3000/api/v1';

export default function ApiPlayground() {
  const [results, setResults] = useState<any[]>([]);
  const [loading, setLoading] = useState<string | null>(null);

  const runTest = async (service: string, action: string, endpoint: string, method = 'GET', body?: any) => {
    const testId = `${service.toUpperCase()}_${action.toUpperCase()}`;
    setLoading(testId);
    
    try {
      const response = await fetch(`${GATEWAY_URL}${endpoint}`, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined
      });

      const data = await response.json();
      
      // HATA TESPİT ETİKETİ (Trace Metadata)
      const traceResult = {
        traceId: testId,
        timestamp: new Date().toLocaleTimeString(),
        status: response.status,
        path: `Gateway(${GATEWAY_URL}) -> ${service}-service -> ${action}`,
        fullUrl: `${GATEWAY_URL}${endpoint}`,
        response: data
      };

      setResults(prev => [traceResult, ...prev]);
    } catch (err: any) {
      setResults(prev => [{
        traceId: testId,
        error: true,
        message: "BAĞLANTI HATASI: Gateway kapalı veya CORS engeli var.",
        details: err.message
      }, ...prev]);
    } finally {
      setLoading(null);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 p-8 font-mono">
      <div className="max-w-6xl mx-auto">
        <header className="mb-10 flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tighter uppercase">Usta API Playground</h1>
            <p className="text-xs text-slate-500 font-bold mt-1 uppercase tracking-widest italic">Hata Dedektörü v1.0</p>
          </div>
          <button onClick={() => setResults([])} className="px-4 py-2 bg-red-500 text-white rounded-xl text-xs font-bold uppercase tracking-widest shadow-lg active:scale-95">
            LOGLARI TEMİZLE
          </button>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* --- KONTROL PANELİ --- */}
          <div className="lg:col-span-1 space-y-6">
            
            {/* PROVIDER SERVICE */}
            <ServiceCard title="Provider Service" icon={<Truck size={20} />} color="blue">
              <TestBtn label="Tümünü Listele" onClick={() => runTest('provider', 'findAll', '/providers')} loading={loading === 'PROVIDER_FINDALL'} />
              <TestBtn label="Şehirleri Getir" onClick={() => runTest('provider', 'getCities', '/providers/cities')} loading={loading === 'PROVIDER_GETCITIES'} />
              <TestBtn label="🔥 Crawler Başlat" color="bg-orange-500" onClick={() => runTest('provider', 'startCrawl', '/providers/crawl', 'POST')} loading={loading === 'PROVIDER_STARTCRAWL'} />
            </ServiceCard>

            {/* USER SERVICE */}
            <ServiceCard title="User Service" icon={<UserIcon size={20} />} color="purple">
              <TestBtn label="Test Kullanıcısı Oluştur" onClick={() => runTest('user', 'create', '/users', 'POST', { firstName: 'Test', lastName: 'User', email: 'test@usta.com' })} loading={loading === 'USER_CREATE'} />
              <TestBtn label="Kullanıcı Getir (ID: 1)" onClick={() => runTest('user', 'findOne', '/users/1')} loading={loading === 'USER_FINDONE'} />
            </ServiceCard>

            {/* ORDER SERVICE */}
            <ServiceCard title="Order Service" icon={<Browser size={20} />} color="emerald">
              <TestBtn label="Yakındaki Siparişler" onClick={() => runTest('order', 'findNearby', '/orders/nearby?lon=28.9&lat=41.0&radius=10')} loading={loading === 'ORDER_FINDNEARBY'} />
            </ServiceCard>

            {/* NOTIFICATION SERVICE */}
            <ServiceCard title="Notification Service" icon={<Bell size={20} />} color="indigo">
              <TestBtn label="Bildirim Geçmişi" onClick={() => runTest('notification', 'getHistory', '/notifications/history/user123')} loading={loading === 'NOTIFICATION_GETHISTORY'} />
              <TestBtn label="Email Gönder (Sim)" onClick={() => runTest('notification', 'sendEmail', '/notifications/email', 'POST', { to: 'test@mail.com', subject: 'Selam', body: 'Playground Test' })} loading={loading === 'NOTIFICATION_SENDEMAIL'} />
            </ServiceCard>

          </div>

          {/* --- ÇIKTI ALANI (HATA BULUCU) --- */}
          <div className="lg:col-span-2 space-y-4">
            <h2 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-4 flex items-center gap-2">
              <Bug weight="fill" /> Canlı İstatistik ve Loglar
            </h2>
            
            {results.length === 0 && (
              <div className="bg-white border-2 border-dashed border-slate-200 rounded-[30px] p-20 text-center text-slate-400">
                Test butonuna bas ve arka plandaki gRPC orkestrasını izle...
              </div>
            )}

            {results.map((res, i) => (
              <div key={i} className={`rounded-[24px] border-l-8 p-6 shadow-sm overflow-hidden animate-in slide-in-from-right duration-300 ${res.error ? 'bg-red-50 border-red-500' : 'bg-white border-slate-900'}`}>
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <span className={`px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-tighter ${res.error ? 'bg-red-500 text-white' : 'bg-slate-900 text-white'}`}>
                      {res.traceId}
                    </span>
                    <p className="text-[10px] text-slate-400 mt-2 font-bold uppercase">{res.timestamp} // {res.path}</p>
                  </div>
                  <span className="text-xs font-black text-slate-600">STATUS: {res.status || 'ERROR'}</span>
                </div>
                
                <pre className="bg-slate-900 text-emerald-400 p-4 rounded-xl text-[11px] overflow-x-auto border border-slate-800 leading-relaxed">
                  {JSON.stringify(res.response || res, null, 2)}
                </pre>

                <div className="mt-3 flex gap-2">
                    <span className="text-[9px] text-slate-400 italic">Endpoint: {res.fullUrl}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

// --- YARDIMCI BİLEŞENLER ---

function ServiceCard({ title, icon, color, children }: any) {
  const colors: any = {
    blue: 'border-blue-200 text-blue-600',
    purple: 'border-purple-200 text-purple-600',
    emerald: 'border-emerald-200 text-emerald-600',
    indigo: 'border-indigo-200 text-indigo-600'
  };
  return (
    <div className={`bg-white border ${colors[color]} rounded-[30px] p-5 shadow-sm`}>
      <div className="flex items-center gap-2 mb-4 opacity-80">
        {icon}
        <span className="text-xs font-black uppercase tracking-widest text-slate-700">{title}</span>
      </div>
      <div className="space-y-2">{children}</div>
    </div>
  );
}

function TestBtn({ label, onClick, loading, color = 'bg-slate-800' }: any) {
  return (
    <button 
      disabled={loading}
      onClick={onClick}
      className={`w-full flex items-center justify-between p-3.5 ${color} text-white rounded-2xl text-[10px] font-black uppercase tracking-widest hover:opacity-90 active:scale-95 transition-all disabled:opacity-50`}
    >
      {loading ? 'İşlem Yapılıyor...' : label}
      {!loading && <Play size={14} weight="fill" />}
    </button>
  );
}