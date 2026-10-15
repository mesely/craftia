import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { AccountsService } from '../accounts/accounts.service';
import { AttachmentsService } from '../attachments/attachments.service';
import { isValidCoordinate } from '../common/geo';
import { isPriceRangeValid } from '../common/price';
import { CATEGORIES } from '../categories/categories';
import { CreateProviderDto, ListProvidersDto, ProviderPhotoDto, UpdateProviderDto } from './providers.dto';
import { ProvidersRepository } from './providers.repository';

@Injectable()
export class ProvidersService {
  constructor(
    private readonly repo: ProvidersRepository,
    private readonly accounts: AccountsService,
    private readonly attachments: AttachmentsService,
  ) {}

  list(dto: ListProvidersDto) {
    return this.repo.list({ ...dto, sortMode: dto.sortMode });
  }

  async get(id: string, userLat?: number, userLng?: number) {
    const provider = await this.repo.findById(id, userLat, userLng);
    if (!provider) throw new NotFoundException('Usta bulunamadı.');
    return provider;
  }

  create(dto: CreateProviderDto) {
    const category = CATEGORIES.find((c) => c.id === dto.mainType);
    if (!category || !category.subTypes.some((s) => s.value === dto.subType)) {
      throw new BadRequestException('Geçersiz hizmet kategorisi.');
    }
    const prices = dto.priceList ?? [];
    for (const p of prices) {
      if (!isPriceRangeValid(p.minPrice, p.maxPrice)) {
        throw new BadRequestException(`"${p.serviceName}" için fiyat aralığı geçersiz.`);
      }
    }
    return this.repo.create({
      businessName: dto.businessName.trim(),
      phoneNumber: dto.phoneNumber.replace(/[^\d+]/g, ''),
      mainType: dto.mainType,
      subType: dto.subType,
      city: dto.city.trim(),
      district: dto.district.trim(),
      address: dto.address?.trim() ?? '',
      lat: isValidCoordinate(dto.lat, dto.lng) ? dto.lat! : null,
      lng: isValidCoordinate(dto.lat, dto.lng) ? dto.lng! : null,
      rating: 0,
      reviewCount: 0,
      isPremium: false,
      featuredUntil: null,
      isVerified: false,
      about: dto.about?.trim() ?? '',
      profileImage: null,
      portfolioImages: [],
      serviceAreas: (dto.serviceAreas ?? []).map((a) => a.trim()).filter(Boolean),
      ...(dto.demo && process.env.NODE_ENV !== 'production' ? { isDemo: true } : {}),
      priceList: prices.map((p) => ({ serviceName: p.serviceName.trim(), minPrice: p.minPrice, maxPrice: p.maxPrice })),
    });
  }

  updateReviewStats(id: string, rating: number, count: number) {
    return this.repo.updateReviewStats(id, rating, count);
  }

  /** Only the account that manages a listing may change it. */
  private async assertOwner(providerId: string, actorId: string) {
    const account = await this.accounts.find(actorId);
    if (!account || account.providerId !== providerId) throw new ForbiddenException('Bu sayfayı değiştirme yetkin yok.');
  }

  async update(id: string, dto: UpdateProviderDto) {
    await this.assertOwner(id, dto.actorId);
    const prices = dto.priceList;
    for (const p of prices ?? []) {
      if (!isPriceRangeValid(p.minPrice, p.maxPrice)) {
        throw new BadRequestException(`"${p.serviceName}" için fiyat aralığı geçersiz.`);
      }
    }
    const updated = await this.repo.update(id, {
      ...(dto.about !== undefined ? { about: dto.about.trim() } : {}),
      ...(dto.businessName !== undefined ? { businessName: dto.businessName.trim() } : {}),
      ...(dto.city !== undefined ? { city: dto.city.trim() } : {}),
      ...(dto.district !== undefined ? { district: dto.district.trim() } : {}),
      ...(isValidCoordinate(dto.lat, dto.lng) ? { lat: dto.lat!, lng: dto.lng! } : {}),
      ...(dto.address !== undefined ? { address: dto.address.trim() } : {}),
      ...(dto.serviceAreas !== undefined ? { serviceAreas: dto.serviceAreas.map((a) => a.trim()).filter(Boolean) } : {}),
      ...(dto.phoneNumber !== undefined ? { phoneNumber: dto.phoneNumber.replace(/[^\d+]/g, '') } : {}),
      ...(prices !== undefined
        ? { priceList: prices.map((p) => ({ serviceName: p.serviceName.trim(), minPrice: p.minPrice, maxPrice: p.maxPrice })) }
        : {}),
    });
    if (!updated) throw new NotFoundException('Usta bulunamadı.');
    return updated;
  }

  /** Work photos: stored as attachments and listed on the page by their relative URL. */
  async addPhoto(id: string, dto: ProviderPhotoDto) {
    await this.assertOwner(id, dto.actorId);
    const current = await this.get(id);
    if (current.portfolioImages.length >= 12) throw new BadRequestException('En fazla 12 fotoğraf ekleyebilirsin.');
    const photoId = await this.attachments.save({ ownerId: dto.actorId, conversationId: null, contentType: dto.contentType, data: dto.data });
    return (await this.repo.update(id, { portfolioImages: [...current.portfolioImages, `/attachments/${photoId}`] }))!;
  }

  /** The face of the listing (profile photo). Replaces the previous one. */
  async setProfilePhoto(id: string, dto: ProviderPhotoDto) {
    await this.assertOwner(id, dto.actorId);
    const current = await this.get(id);
    const photoId = await this.attachments.save({ ownerId: dto.actorId, conversationId: null, contentType: dto.contentType, data: dto.data });
    const updated = (await this.repo.update(id, { profileImage: `/attachments/${photoId}` }))!;
    const old = /^\/attachments\/([a-f\d]{24})$/i.exec(current.profileImage ?? '');
    if (old) await this.attachments.remove(old[1]);
    return updated;
  }

  /** Runs a paid promotion until [until]; used by the promotions module after a purchase. */
  setFeaturedUntil(id: string, until: Date) {
    return this.repo.update(id, { featuredUntil: until.toISOString() });
  }

  async removePhoto(id: string, actorId: string, path: string) {
    await this.assertOwner(id, actorId);
    const current = await this.get(id);
    const remaining = current.portfolioImages.filter((p) => p !== path);
    if (remaining.length === current.portfolioImages.length) throw new NotFoundException('Fotoğraf bulunamadı.');
    const updated = (await this.repo.update(id, { portfolioImages: remaining }))!;
    const match = /^\/attachments\/([a-f\d]{24})$/i.exec(path);
    if (match) await this.attachments.remove(match[1]);
    return updated;
  }
}
