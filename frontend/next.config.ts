const nextConfig = {
  eslint: {
    // Build sırasında lint hatalarını görmezden gel
    ignoreDuringBuilds: true,
  },
  typescript: {
    // Build sırasında TS hatalarını görmezden gel
    ignoreBuildErrors: true,
  },
};

export default nextConfig;