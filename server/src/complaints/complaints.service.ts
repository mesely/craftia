import { Injectable } from '@nestjs/common';
import { randomBytes } from 'crypto';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { Store, StoreFactory } from '../common/store';

export const COMPLAINT_REASONS = ['fraud', 'abusive', 'no_show', 'price_dispute', 'fake_info', 'other'] as const;
export const COMPLAINT_TARGETS = ['provider', 'customer', 'conversation', 'message'] as const;

export interface ComplaintEntity {
  id: string;
  reference: string;
  reporterId: string;
  targetType: (typeof COMPLAINT_TARGETS)[number];
  targetId: string;
  targetName: string;
  conversationId: string | null;
  reason: (typeof COMPLAINT_REASONS)[number];
  details: string;
  status: 'received';
  createdAt: string;
}

export class CreateComplaintDto {
  @IsString() @MaxLength(64) reporterId: string;
  @IsIn(COMPLAINT_TARGETS as unknown as string[]) targetType: ComplaintEntity['targetType'];
  @IsString() @MaxLength(64) targetId: string;
  @IsString() @MaxLength(120) @IsOptional() targetName?: string;
  @IsString() @MaxLength(64) @IsOptional() conversationId?: string;
  @IsIn(COMPLAINT_REASONS as unknown as string[]) reason: ComplaintEntity['reason'];
  @IsString() @MaxLength(1000) @IsOptional() details?: string;
}

@Injectable()
export class ComplaintsService {
  private readonly store: Store<ComplaintEntity>;

  constructor(stores: StoreFactory) {
    this.store = stores.collection<ComplaintEntity>('complaints');
  }

  /** Complaints are recorded, never auto-resolved: the app is an intermediary (see Sorumluluk Reddi). */
  create(dto: CreateComplaintDto): Promise<ComplaintEntity> {
    const reference = `SK-${new Date().getFullYear()}-${randomBytes(3).toString('hex').toUpperCase()}`;
    return this.store.insert({
      reference,
      reporterId: dto.reporterId,
      targetType: dto.targetType,
      targetId: dto.targetId,
      targetName: dto.targetName?.trim() ?? '',
      conversationId: dto.conversationId ?? null,
      reason: dto.reason,
      details: dto.details?.trim() ?? '',
      status: 'received',
      createdAt: new Date().toISOString(),
    });
  }

  listByReporter(reporterId: string): Promise<ComplaintEntity[]> {
    return this.store.find({ reporterId }, { sort: { createdAt: -1 } });
  }
}
