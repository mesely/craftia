import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { HttpModule } from '@nestjs/axios';
// ✅ Yollar güncellendi (Dosyaların src/provider içindeyse başına /provider/ ekledik)
import { ProviderService } from './provider/provider.service'; 
import { ProviderController } from './provider/provider.controller'; 
import { Provider, ProviderSchema } from './provider/schemas/provider.schema';
import { User, UserSchema } from './provider/schemas/user.schema';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGO_URI'),
      }),
      inject: [ConfigService],
    }),
    MongooseModule.forFeature([
      { name: Provider.name, schema: ProviderSchema },
      { name: User.name, schema: UserSchema },
    ]),
    HttpModule,
  ],
  controllers: [ProviderController],
  providers: [ProviderService],
})
export class AppModule {}