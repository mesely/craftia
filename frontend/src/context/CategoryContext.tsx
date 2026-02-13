'use client';

import React, { createContext, useContext, useState, ReactNode } from 'react';

// Senin projenin orijinal kategorileri
export type CategoryType = 
  | 'TECHNICAL'    // Teknik Destek (Mavi)
  | 'CONSTRUCTION' // Yapı & Dekor (Mor)
  | 'CLIMATE'      // İklimlendirme (Turuncu)
  | 'TECH'         // Cihaz & Teknoloji (İndigo)
  | 'LIFE';        // Yaşam & Temizlik (Yeşil)

interface CategoryContextType {
  activeCategory: CategoryType;
  setActiveCategory: (category: CategoryType) => void;
}

const CategoryContext = createContext<CategoryContextType | undefined>(undefined);

export function CategoryProvider({ children }: { children: ReactNode }) {
  // Varsayılan kategori senin ilk kodundaki gibi TECHNICAL
  const [activeCategory, setActiveCategory] = useState<CategoryType>('TECHNICAL');

  return (
    <CategoryContext.Provider value={{ activeCategory, setActiveCategory }}>
      {children}
    </CategoryContext.Provider>
  );
}

export function useCategory() {
  const context = useContext(CategoryContext);
  if (context === undefined) {
    throw new Error('useCategory must be used within a CategoryProvider');
  }
  return context;
}