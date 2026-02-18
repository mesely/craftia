import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // ✅ Capacitor için statik çıktı üretilmesini sağlar
  output: 'export', 
  
  // ✅ Statik export modunda resim optimizasyonu için sunucu gerekmez
  images: {
    unoptimized: true,
  },

  eslint: {
    // ✅ Build sırasında lint hatalarını görmezden gelir
    ignoreDuringBuilds: true,
  },

  typescript: {
    // ✅ Build sırasında TypeScript hatalarını görmezden gelir
    ignoreBuildErrors: true,
  },

  // İhtiyacın olursa diğer Next.js ayarlarını buraya ekleyebilirsin
};

export default nextConfig;