import { DynamicModule, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { loadConfig } from './env';

/** Connects to MongoDB only when DATA_SOURCE=mongo. Mock mode needs no database. */
@Module({})
export class DatabaseModule {
  static register(): DynamicModule {
    const config = loadConfig();
    return {
      module: DatabaseModule,
      imports:
        config.dataSource === 'mongo'
          ? [MongooseModule.forRoot(config.mongoUri, { dbName: config.databaseName })]
          : [],
    };
  }
}
