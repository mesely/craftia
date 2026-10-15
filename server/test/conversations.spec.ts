import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { AccountsService } from '../src/accounts/accounts.service';
import { StoreFactory } from '../src/common/store';
import { AttachmentsService } from '../src/attachments/attachments.service';
import { ConversationsService } from '../src/conversations/conversations.service';

function setup() {
  const stores = new StoreFactory(undefined);
  const accounts = new AccountsService(stores);
  const chats = new ConversationsService(stores, accounts, new AttachmentsService(stores));
  return { accounts, chats };
}

async function openChat(env: ReturnType<typeof setup>) {
  await env.accounts.upsert({ id: 'usta-account-1', role: 'provider', name: 'Usta Ali', providerId: 'prov-1' });
  return env.chats.openForRequest({
    requestId: 'req-1',
    customerId: 'customer-1',
    customerName: 'Ayşe',
    providerId: 'prov-1',
    providerName: 'Ali Elektrik',
    subject: 'Elektrikçi',
    description: 'Mutfaktaki priz çalışmıyor.',
  });
}

describe('conversations', () => {
  it('starts with the fixed "Hizmet Talebi:" message and links the usta account', async () => {
    const env = setup();
    const c = await openChat(env);
    expect(c.providerAccountId).toBe('usta-account-1');
    const msgs = await env.chats.list(c.id, 'customer-1');
    expect(msgs).toHaveLength(1);
    expect(msgs[0]).toMatchObject({ kind: 'request', text: 'Hizmet Talebi: Mutfaktaki priz çalışmıyor.' });
  });

  it('lets both sides write, counts unread and clears it on read', async () => {
    const env = setup();
    const c = await openChat(env);
    await env.chats.send(c.id, { senderId: 'usta-account-1', text: 'Yarın 10:00 uygun mu?' });
    await env.chats.send(c.id, { senderId: 'customer-1', text: 'Uygun, bekliyorum.' });
    let v = await env.chats.view(c.id, 'customer-1');
    expect(v.unreadCustomer).toBe(1);
    expect(v.unreadProvider).toBe(2); // request message + customer's reply
    await env.chats.markRead(c.id, 'customer-1');
    v = await env.chats.view(c.id, 'customer-1');
    expect(v.unreadCustomer).toBe(0);
  });

  it('rejects strangers', async () => {
    const env = setup();
    const c = await openChat(env);
    await expect(env.chats.send(c.id, { senderId: 'intruder', text: 'merhaba' })).rejects.toBeInstanceOf(ForbiddenException);
    await expect(env.chats.list(c.id, 'intruder')).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('edits and soft-deletes only own messages, keeping replies intact', async () => {
    const env = setup();
    const c = await openChat(env);
    const first = await env.chats.send(c.id, { senderId: 'customer-1', text: 'Fiyat nedir?' });
    const reply = await env.chats.send(c.id, { senderId: 'usta-account-1', text: '500 TL', replyToId: first.id });
    expect(reply.replyToId).toBe(first.id);

    await expect(env.chats.edit(first.id, { senderId: 'usta-account-1', text: 'x' })).rejects.toBeInstanceOf(ForbiddenException);
    const edited = await env.chats.edit(first.id, { senderId: 'customer-1', text: 'Keşif ücreti nedir?' });
    expect(edited.editedAt).not.toBeNull();

    await env.chats.remove(first.id, 'customer-1');
    const msgs = await env.chats.list(c.id, 'customer-1');
    const gone = msgs.find((m) => m.id === first.id)!;
    expect(gone.text).toBe('');
    expect(gone.deletedAt).not.toBeNull();
    expect(msgs.find((m) => m.id === reply.id)!.replyToId).toBe(first.id);
  });

  it('never lets the request message be deleted', async () => {
    const env = setup();
    const c = await openChat(env);
    const [request] = await env.chats.list(c.id, 'customer-1');
    await expect(env.chats.remove(request.id, 'customer-1')).rejects.toBeInstanceOf(BadRequestException);
  });

  it('polls only what changed after a timestamp', async () => {
    const env = setup();
    const c = await openChat(env);
    const all = await env.chats.list(c.id, 'customer-1');
    const marker = all[all.length - 1].createdAt;
    await new Promise((r) => setTimeout(r, 5));
    await env.chats.send(c.id, { senderId: 'customer-1', text: 'yeni' });
    const news = await env.chats.list(c.id, 'customer-1', marker);
    expect(news.map((m) => m.text)).toEqual(['yeni']);
  });

  it('flags an usta without an app account so the UI can suggest calling', async () => {
    const env = setup();
    const c = await env.chats.openForRequest({
      requestId: 'req-2', customerId: 'customer-2', customerName: 'Can', providerId: 'legacy-9',
      providerName: 'Eski Kayıt', subject: 'Boyacı', description: 'Salon boyanacak, fiyat alabilir miyim?',
    });
    const v = await env.chats.view(c.id, 'customer-2');
    expect(v.providerOnApp).toBe(false);
  });
});
