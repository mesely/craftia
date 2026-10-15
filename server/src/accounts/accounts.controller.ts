import { Body, Controller, Get, Param, Patch } from '@nestjs/common';
import { UpdateProfileDto } from './accounts.dto';
import { AccountsService } from './accounts.service';

/** The auth guard only lets a person reach their own account (`:id` must match the session). */
@Controller('accounts')
export class AccountsController {
  constructor(private readonly accounts: AccountsService) {}

  @Get(':id')
  get(@Param('id') id: string) {
    return this.accounts.get(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() body: UpdateProfileDto) {
    return this.accounts.updateProfile(id, body);
  }
}
