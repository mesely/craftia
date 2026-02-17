import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.usta.app',
  appName: 'Usta',
  webDir: 'out',
  server: {
    androidScheme: 'https'
  }
};

export default config;