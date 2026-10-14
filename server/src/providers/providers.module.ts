import { DynamicModule, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { isMongo } from '../config/env';
import { ProviderDoc, ProviderSchema } from './provider.schema';
import { ProvidersController } from './providers.controller';
import { MockProvidersRepository } from './providers.mock.repository';
import { MongoProvidersRepository } from './providers.mongo.repository';
import { ProvidersRepository } from './providers.repository';
import { ProvidersService } from './providers.service';

@Module({})
export class ProvidersModule {
  private static cached?: DynamicModule;

  /** Memoised so every importer shares one instance (and one in-memory store in mock mode). */
  static register(): DynamicModule {
    if (ProvidersModule.cached) return ProvidersModule.cached;
    const mongo = isMongo();
    return (ProvidersModule.cached = {
      module: ProvidersModule,
      imports: mongo ? [MongooseModule.forFeature([{ name: ProviderDoc.name, schema: ProviderSchema }])] : [],
      controllers: [ProvidersController],
      providers: [
        ProvidersService,
        { provide: ProvidersRepository, useClass: mongo ? MongoProvidersRepository : MockProvidersRepository },
      ],
      exports: [ProvidersService],
    });
  }
}
