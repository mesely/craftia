'use client';

import React from 'react';
import MainLayout from '@/components/layout/MainLayout';
import AdvancedFilters from '@/components/features/AdvancedFilters';
import UstaList from '@/components/features/UstaList';

export default function Home() {
  return (
    <MainLayout>
      {/* Container: relative
        Bu kapsayıcı, içindeki fixed elemanların sayfaya göre hizalanmasını sağlar.
      */}
      <div className="relative w-full">
        
        {/* 1. FIXED FILTER BAR (ÇAKILI FİLTRE)
            - fixed: Asla kımıldamaz, Header gibi sabit kalır.
            - top-[88px]: MainLayout'taki Header'ın (88px) tam bittiği yerden başlar.
            - left-0 right-0: Ekranın solundan sağına tam oturur.
            - z-40: Listenin üstünde kalır, Header'ın (z-60) altında kalır.
        */}
        <div className="fixed top-[88px] left-0 right-0 z-40 w-full">
            <AdvancedFilters />
        </div>

        {/* 2. USTA LİSTESİ 
            - pt-[100px]: Üstten 100px boşluk bırakıyoruz.
              Neden? Çünkü Filtre Barı (yaklaşık 84px) artık "fixed" olduğu için yer kaplamıyor.
              Listeyi elle aşağı itmezsek filtrenin altında kalır.
            - pb-36: Alt menü (BottomNav) için güvenli boşluk.
        */}
        <div className="pt-[100px] pb-36 px-0">
           <UstaList />
        </div>

      </div>
    </MainLayout>
  );
}