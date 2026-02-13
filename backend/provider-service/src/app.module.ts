import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { HttpModule } from '@nestjs/axios';
import { ProviderController } from './provider/provider.controller';
import { ProviderService } from './provider/provider.service';
import { Provider, ProviderSchema } from './provider/schemas/provider.schema';
import { User, UserSchema } from './provider/schemas/user.schema';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    HttpModule,
    MongooseModule.forRoot(process.env.MONGO_URI || 'mongodb://localhost:27017/usta_db'),
    MongooseModule.forFeature([
      { name: Provider.name, schema: ProviderSchema },
      { name: User.name, schema: UserSchema },
    ]),
  ],
  controllers: [ProviderController],
  providers: [ProviderService],
})
export class AppModule {}