import { Body, Controller, Delete, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { EditMessageDto, SendMessageDto, UploadAttachmentDto } from './conversations.dto';
import { ConversationsService } from './conversations.service';

@Controller()
export class ConversationsController {
  constructor(private readonly conversations: ConversationsService) {}

  @Get('conversations/:id')
  get(@Param('id') id: string, @Query('viewerId') viewerId = '') {
    return this.conversations.view(id, viewerId);
  }

  @Get('conversations/:id/messages')
  messages(@Param('id') id: string, @Query('viewerId') viewerId = '', @Query('after') after?: string) {
    return this.conversations.list(id, viewerId, after);
  }

  @Post('conversations/:id/messages')
  send(@Param('id') id: string, @Body() body: SendMessageDto) {
    return this.conversations.send(id, body);
  }

  @Post('conversations/:id/read')
  async read(@Param('id') id: string, @Body('viewerId') viewerId: string) {
    await this.conversations.markRead(id, viewerId);
    return { ok: true };
  }

  @Post('conversations/:id/attachments')
  upload(@Param('id') id: string, @Body() body: UploadAttachmentDto) {
    return this.conversations.upload(id, body);
  }

  @Patch('messages/:id')
  edit(@Param('id') id: string, @Body() body: EditMessageDto) {
    return this.conversations.edit(id, body);
  }

  @Delete('messages/:id')
  remove(@Param('id') id: string, @Query('senderId') senderId = '') {
    return this.conversations.remove(id, senderId);
  }
}
