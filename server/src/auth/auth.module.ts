import { Global, Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AccountsModule } from '../accounts/accounts.module';
import { ProvidersModule } from '../providers/providers.module';
import { AuthController } from './auth.controller';
import { AuthGuard } from './auth.guard';
import { AuthService } from './auth.service';
import { FirebaseVerifier } from './firebase.verifier';
import { TokenService } from './token.service';

@Global()
@Module({
  imports: [AccountsModule, ProvidersModule.register()],
  controllers: [AuthController],
  providers: [AuthService, TokenService, FirebaseVerifier, { provide: APP_GUARD, useClass: AuthGuard }],
  exports: [TokenService],
})
export class AuthModule {}
