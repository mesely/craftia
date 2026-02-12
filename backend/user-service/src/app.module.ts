import { Module } from '@nestjs/common';
import { UserController } from './user/user.controller';
import { UserService } from './user/user.service';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true, // .env dosyasındaki DATABASE_URL'i her yerden okuyabilmek için
    }),
  ],
  controllers: [UserController],
  providers: [UserService],
})
export class AppModule {}

