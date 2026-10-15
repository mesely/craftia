import { Body, Controller, Get, Param, Put } from '@nestjs/common';
import { UpsertAccountDto } from './accounts.dto';
import { AccountsService } from './accounts.service';

@Controller('accounts')
export class AccountsController {
  constructor(private readonly accounts: AccountsService) {}

  /** Creates or updates the profile of the signed-in person. */
  @Put()
  upsert(@Body() body: UpsertAccountDto) {
    return this.accounts.upsert(body);
  }

  @Get(':id')
  get(@Param('id') id: string) {
    return this.accounts.get(id);
  }
}
