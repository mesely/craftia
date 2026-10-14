import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { isPriceRangeValid } from '../common/price';
import { CATEGORIES } from '../categories/categories';
import { CreateProviderDto, ListProvidersDto } from './providers.dto';
import { ProvidersRepository } from './providers.repository';

@Injectable()
export class ProvidersService {
  constructor(private readonly repo: ProvidersRepository) {}

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
      lat: null,
      lng: null,
      rating: 0,
      reviewCount: 0,
      isPremium: false,
      isVerified: false,
      about: dto.about?.trim() ?? '',
      profileImage: null,
      portfolioImages: [],
      priceList: prices.map((p) => ({ serviceName: p.serviceName.trim(), minPrice: p.minPrice, maxPrice: p.maxPrice })),
    });
  }

  updateReviewStats(id: string, rating: number, count: number) {
    return this.repo.updateReviewStats(id, rating, count);
  }
}
