import { BadRequestException, Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ComplaintsService, CreateComplaintDto } from './complaints.service';

@Controller('complaints')
export class ComplaintsController {
  constructor(private readonly complaints: ComplaintsService) {}

  @Post()
  create(@Body() body: CreateComplaintDto) {
    if (body.reason === 'other' && (body.details ?? '').trim().length < 10) {
      throw new BadRequestException('Lütfen şikayetini birkaç cümleyle anlat.');
    }
    return this.complaints.create(body);
  }

  @Get()
  list(@Query('reporterId') reporterId = '') {
    return this.complaints.listByReporter(reporterId);
  }
}
