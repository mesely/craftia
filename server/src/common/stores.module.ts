import { Global, Module } from '@nestjs/common';
import { StoreFactory } from './store';

@Global()
@Module({ providers: [StoreFactory], exports: [StoreFactory] })
export class StoresModule {}
