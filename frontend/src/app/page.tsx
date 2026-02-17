'use client';

import React, { useState, useEffect } from 'react';
import MainLayout from '@/components/layout/MainLayout';
import AdvancedFilters from '@/components/features/AdvancedFilters';
import UstaList from '@/components/features/UstaList';

export default function Home() {
  // --- MERKEZİ FİLTRE DURUMU (Source of Truth) ---
  const [filters, setFilters] = useState({
    city: 'İzmir',
    subType: 'all',
    sortMode: 'nearest',
    distance: 10,
  });

  // --- KULLANICI KONUMU ---
  // Varsayılan İzmir (Usta'nın kalbi)
  const [userCoords, setUserCoords] = useState({ lat: 38.4237, lng: 27.1428 });

  useEffect(() => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          setUserCoords({ 
            lat: pos.coords.latitude, 
            lng: pos.coords.longitude 
          });
        },
        (err) => {
          console.warn("Konum izni alınamadı, varsayılan İzmir kullanılıyor.");
        },
        { enableHighAccuracy: true }
      );
    }
  }, []);

  // Filtreler değiştikçe tetiklenecek fonksiyon
  const handleFilterChange = (newFilters: any) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
  };

  return (
    <MainLayout>
      <div className="relative w-full">
        
        {/* 1. FIXED FILTER BAR 
            Sticky/Fixed yapısı ile her zaman ulaşılabilir.
        */}
        <div className="fixed top-[88px] left-0 right-0 z-40 w-full">
            <AdvancedFilters 
              currentFilters={filters} 
              onFilterChange={handleFilterChange} 
            />
        </div>

        {/* 2. USTA LİSTESİ 
            Artık 'nearest' (yakındakiler) motoru backend'de hazır olduğu için 
            buradaki userCoords tıkır tıkır çalışacak.
        */}
        <div className="pt-[110px] pb-36 px-0">
           <UstaList 
             filters={filters} 
             userCoords={userCoords} 
           />
        </div>

      </div>
    </MainLayout>
  );
}