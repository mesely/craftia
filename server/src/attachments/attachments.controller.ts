import { Controller, Get, Param, Res } from '@nestjs/common';
import type { Response } from 'express';
import { AttachmentsService } from './attachments.service';

@Controller('attachments')
export class AttachmentsController {
  constructor(private readonly attachments: AttachmentsService) {}

  /** Ids are unguessable; photos are served with a day of private caching. */
  @Get(':id')
  async get(@Param('id') id: string, @Res() res: Response) {
    const { contentType, buffer } = await this.attachments.binary(id);
    res.setHeader('Cache-Control', 'private, max-age=86400');
    res.type(contentType).send(buffer);
  }
}
