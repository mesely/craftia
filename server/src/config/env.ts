import 'dotenv/config';

export type DataSource = 'mock' | 'mongo';

export interface AppConfig {
  nodeEnv: string;
  port: number;
  dataSource: DataSource;
  mongoUri: string;
  databaseName: string;
}

/** Reads and validates process.env. Secrets only ever come from the environment. */
export function loadConfig(): AppConfig {
  const dataSource = (process.env.DATA_SOURCE ?? 'mock').toLowerCase();
  if (dataSource !== 'mock' && dataSource !== 'mongo') {
    throw new Error(`DATA_SOURCE must be "mock" or "mongo", got "${dataSource}"`);
  }
  const mongoUri = process.env.MONGODB_URI ?? '';
  if (dataSource === 'mongo' && !mongoUri) {
    throw new Error('DATA_SOURCE=mongo requires MONGODB_URI to be set in the environment.');
  }
  return {
    nodeEnv: process.env.NODE_ENV ?? 'development',
    port: Number(process.env.PORT) || 3000,
    dataSource,
    mongoUri,
    databaseName: process.env.DATABASE_NAME || 'usta',
  };
}

export const isMongo = (): boolean => loadConfig().dataSource === 'mongo';
