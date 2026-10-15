export type SenderRole = 'customer' | 'provider' | 'system';
export type MessageKind = 'request' | 'text' | 'image' | 'system';

export interface ConversationEntity {
  id: string;
  requestId: string;
  customerId: string;
  customerName: string;
  providerId: string;
  providerName: string;
  /** The usta's app account, or null when the usta (e.g. imported listing) has not joined the app. */
  providerAccountId: string | null;
  /** Service label, e.g. "Elektrikçi". */
  subject: string;
  createdAt: string;
  lastMessageAt: string;
  lastMessageText: string;
  unreadCustomer: number;
  unreadProvider: number;
}

export interface MessageEntity {
  id: string;
  conversationId: string;
  senderId: string;
  senderRole: SenderRole;
  kind: MessageKind;
  text: string;
  attachmentId: string | null;
  replyToId: string | null;
  createdAt: string;
  editedAt: string | null;
  deletedAt: string | null;
}

export interface AttachmentEntity {
  id: string;
  /** Null for photos that belong to an usta's page rather than a chat. */
  conversationId: string | null;
  ownerId: string;
  contentType: string;
  /** Base64. Photos are downscaled on the phone, so this stays small. */
  data: string;
  size: number;
  createdAt: string;
}
