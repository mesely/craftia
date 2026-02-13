'use client';

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';

// 1. Kullanıcı Tipi
interface User {
  id: string;
  name: string;
  phone: string;
  email?: string;
  role: 'USER' | 'USTA';
}

// 2. Context Veri Yapısı
interface AuthContextType {
  user: User | null;
  isLoggedIn: boolean;
  login: (userData: User) => void;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Uygulama ilk açıldığında yerel depolamadan kullanıcıyı kontrol et
  useEffect(() => {
    const savedUser = localStorage.getItem('usta_user');
    if (savedUser) {
      setUser(JSON.parse(savedUser));
    }
    setIsLoading(false);
  }, []);

  // Giriş Yapma Fonksiyonu
  const login = (userData: User) => {
    setUser(userData);
    localStorage.setItem('usta_user', JSON.stringify(userData));
  };

  // Çıkış Yapma Fonksiyonu
  const logout = () => {
    setUser(null);
    localStorage.removeItem('usta_user');
    window.location.href = '/login'; // Çıkış yapınca login sayfasına at
  };

  return (
    <AuthContext.Provider value={{ 
      user, 
      isLoggedIn: !!user, 
      login, 
      logout, 
      isLoading 
    }}>
      {children}
    </AuthContext.Provider>
  );
}

// Hook: Diğer bileşenlerden kolayca erişmek için
export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}