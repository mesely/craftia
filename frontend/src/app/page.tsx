'use client';

import React, { useState } from 'react';
import MainLayout from '@/components/layout/MainLayout';
import AdvancedFilters from '@/components/features/AdvancedFilters';
import UstaList from '@/components/features/UstaList';

export default function Home() {
  // --- MERKEZİ FİLTRE DURUMU ---
  const [filters, setFilters] = useState({
    city: '',          // ✅ Boş = Tüm Türkiye (İzmir hardcode kaldırıldı)
    subType: 'all',
    sortMode: 'nearest',
    distance: 10,
  });

  // --- KULLANICI KONUMU ---
  // Başlangıçta 0,0 — GPS gelince AdvancedFilters → onLocationDetected ile güncellenir
  const [userCoords, setUserCoords] = useState({ lat: 0, lng: 0 });

  const handleFilterChange = (newFilters: any) => {
    setFilters(prev => ({ ...prev, ...newFilters }));
  };

  return (
    <MainLayout>
      <div className="relative w-full flex flex-col">

        {/* AdvancedFilters: GPS'i kendi içinde alır, onLocationDetected ile buraya iletir */}
        <AdvancedFilters
          currentFilters={filters}
          onFilterChange={handleFilterChange}
          onLocationDetected={(coords) => setUserCoords(coords)} // ✅ EKLENDİ
        />

        {/* UstaList: koordinatlar gelince backend'e gönderir, yakına göre sıralar */}
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