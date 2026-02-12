import { Module } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { join } from 'path';
import { ProviderController } from './provider/provider.controller';
import { ProviderService } from './provider/provider.service';
import { UserController } from './user/user.controller';
import { UserService } from './user/user.service';

@Module({
  imports: [
    ClientsModule.register([
      {
        name: 'PROVIDER_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'provider',
          // Proto dosyalarını ortak /backend/proto klasörüne taşıyacağımız için yol güncellendi
          protoPath: join(process.cwd(), '../proto/provider.proto'),
          url: 'localhost:50051',
          loader: {
            keepCase: true,
            longs: String,
            enums: String,
            defaults: true,
            oneofs: true,
          },
        },
      },
      {
        name: 'USER_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'user',
          protoPath: join(process.cwd(), '../proto/user.proto'),
          url: 'localhost:50052',
          loader: {
            keepCase: true,
            longs: String,
            enums: String,
            defaults: true,
            oneofs: true,
          },
        },
      },
    ]),
  ],
  controllers: [ProviderController, UserController],
  providers: [ProviderService, UserService],
})
export class AppModule {}