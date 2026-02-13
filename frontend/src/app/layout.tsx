import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

// --- SAĞLAYICILAR (CONTEXTS) ---
import { CategoryProvider } from "@/context/CategoryContext"; 
import { AuthProvider } from "@/context/AuthContext";

// --- YENİ BİLEŞENLER ---
import SplashScreen from "@/components/ui/SplashScreen";
import NoInternetConnection from "@/components/ui/NoInternetConnection";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "USTA | Profesyonel Hizmetler",
  description: "En yakın profesyonel ustalar kapında.",
  manifest: "/manifest.json", // PWA Manifest
};

// Mobil cihazlarda çentik ve zoom ayarları için kritik
export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: "cover", // iPhone çentik (Notch) tam ekran
  themeColor: "#f8fafc",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased bg-slate-50 text-slate-900 selection:bg-indigo-100 selection:text-indigo-900`}
      >
        {/* ZİNCİRLEME SARMALAMA:
            1. CategoryProvider: Tema rengini yönetir.
            2. AuthProvider: Kullanıcıyı yönetir.
        */}
        <CategoryProvider>
          <AuthProvider>
            
            {/* 1. AÇILIŞ EKRANI (En üstte çıkar, sonra kaybolur) */}
            <SplashScreen />

            {/* 2. İNTERNET KONTROLÜ (İnternet giderse tüm ekranı kaplar) */}
            <NoInternetConnection />

            {/* 3. UYGULAMANIN KENDİSİ */}
            {children}

          </AuthProvider>
        </CategoryProvider>
      </body>
    </html>
  );
}