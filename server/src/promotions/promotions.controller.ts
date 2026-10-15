import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { PromotionsService, PurchasePromotionDto } from './promotions.service';

@Controller()
export class PromotionsController {
  constructor(private readonly promotions: PromotionsService) {}

  @Get('promotions/plans')
  plans() {
    return this.promotions.plans();
  }

  @Post('providers/:id/promotions')
  purchase(@Param('id') id: string, @Body() body: PurchasePromotionDto) {
    return this.promotions.purchase(id, body);
  }
}
