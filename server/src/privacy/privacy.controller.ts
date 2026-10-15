import { BadRequestException, Controller, Delete, Get, Query } from '@nestjs/common';
import { AccountsService } from '../accounts/accounts.service';
import { ComplaintsService } from '../complaints/complaints.service';
import { ConversationsService } from '../conversations/conversations.service';
import { OrdersService } from '../orders/orders.service';

/** KVKK data-subject rights: "Verilerimi indir" and "Hesabımı sil". */
@Controller('privacy')
export class PrivacyController {
  constructor(
    private readonly accounts: AccountsService,
    private readonly orders: OrdersService,
    private readonly conversations: ConversationsService,
    private readonly complaints: ComplaintsService,
  ) {}

  @Get('export')
  async export(@Query('accountId') accountId = '') {
    if (!accountId) throw new BadRequestException('accountId gerekli.');
    const account = await this.accounts.get(accountId);
    return {
      exportedAt: new Date().toISOString(),
      notice:
        'Bu dosya Usta uygulamasında hakkında tuttuğumuz tüm verileri içerir: hesap bilgilerin, hizmet taleplerin, mesajların ve şikayet kayıtların.',
      account,
      serviceRequests: await this.orders.exportFor(account.id, account.providerId),
      conversations: await this.conversations.exportFor(account.id, account.providerId),
      complaintsFiledByYou: await this.complaints.listByReporter(account.id),
    };
  }

  @Delete('account')
  async deleteAccount(@Query('accountId') accountId = '') {
    if (!accountId) throw new BadRequestException('accountId gerekli.');
    await this.conversations.anonymizeCustomer(accountId);
    const deleted = await this.accounts.remove(accountId);
    return {
      deleted,
      retained:
        'Anlaşmazlık ve güvenlik süreçleri için mesaj ve şikayet kayıtları, kimliğin kaldırılmış şekilde yasal saklama süresince tutulur.',
    };
  }
}
