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
      <div className="relative w-full flex flex-col">
        
        {/* 1. ADVANCED FILTERS 
            NOT: 'fixed top-[60px]' kaldırıldı. 
            Bileşen kendi içindeki 'sticky' yapısı ile Header'ın tam altına 
            (çentik dahil) otomatik olarak yapışacak.
        */}
        <AdvancedFilters 
          currentFilters={filters} 
          onFilterChange={handleFilterChange} 
        />

        {/* 2. USTA LİSTESİ 
            Filtreler artık akışın (flow) bir parçası olduğu için pt-[90px] 
            fazlalığını kaldırıp, liste ile filtreler arasına makul bir 
            nefes alma boşluğu (py-4) bıraktım.
        */}
        <div className="w-full py-4 pb-36 px-0">
           <UstaList 
             filters={filters} 
             userCoords={userCoords} 
           />
        </div>

      </div>
    </MainLayout>
  );
}