import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import type { Request } from 'express';
import { FirebaseLoginDto, LoginDto, RegisterDto, UpgradeDto } from './auth.dto';
import { AuthService } from './auth.service';

type Authed = Request & { accountId?: string };

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  register(@Body() body: RegisterDto) {
    return this.auth.register(body);
  }

  @Post('login')
  login(@Body() body: LoginDto) {
    return this.auth.login(body);
  }

  @Get('methods')
  methods() {
    return this.auth.methods();
  }

  @Post('firebase')
  firebase(@Body() body: FirebaseLoginDto) {
    return this.auth.loginWithFirebase(body);
  }

  @Post('upgrade')
  upgrade(@Req() req: Authed, @Body() body: UpgradeDto) {
    return this.auth.upgrade(req.accountId!, body.provider);
  }

  @Get('me')
  me(@Req() req: Authed) {
    return this.auth.me(req.accountId!);
  }
}
