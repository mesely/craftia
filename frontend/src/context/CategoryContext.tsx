'use client';

import React, { createContext, useContext, useState, ReactNode } from 'react';

// 1. Kategori Tipleri (Tip Güvenliği İçin)
export type CategoryType = 
  | 'TECHNICAL'    // Teknik Destek (Mavi)
  | 'CONSTRUCTION' // Yapı & Dekor (Mor)
  | 'CLIMATE'      // İklimlendirme (Turuncu)
  | 'TECH'         // Cihaz & Teknoloji (İndigo)
  | 'LIFE';        // Yaşam & Temizlik (Yeşil)

// 2. Context Veri Yapısı
interface CategoryContextType {
  activeCategory: CategoryType;
  setActiveCategory: (category: CategoryType) => void;
}

// 3. Context Oluşturma
const CategoryContext = createContext<CategoryContextType | undefined>(undefined);

// 4. Provider Bileşeni (Uygulamayı Saracak)
export function CategoryProvider({ children }: { children: ReactNode }) {
  const [activeCategory, setActiveCategory] = useState<CategoryType>('TECHNICAL');

  return (
    <CategoryContext.Provider value={{ activeCategory, setActiveCategory }}>
      {children}
    </CategoryContext.Provider>
  );
}

// 5. Hook (Kolay Kullanım İçin)
export function useCategory() {
  const context = useContext(CategoryContext);
  if (context === undefined) {
    throw new Error('useCategory must be used within a CategoryProvider');
  }
  return context;
}