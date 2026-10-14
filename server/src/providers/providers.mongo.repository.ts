import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, PipelineStage } from 'mongoose';
import { haversineKm, isValidCoordinate } from '../common/geo';
import { Page, toPage } from '../common/pagination';
import { parsePriceList } from '../common/price';
import { ProviderDoc, ProviderDocument } from './provider.schema';
import { ProviderEntity, ProviderQuery, ProviderView } from './provider.types';
import { ProvidersRepository } from './providers.repository';

const KM_PER_DEGREE = 111.32;
const escapeRegex = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

@Injectable()
export class MongoProvidersRepository extends ProvidersRepository {
  constructor(@InjectModel(ProviderDoc.name) private readonly model: Model<ProviderDocument>) {
    super();
  }

  async list(query: ProviderQuery): Promise<Page<ProviderView>> {
    const hasLocation = isValidCoordinate(query.userLat, query.userLng);
    const match: Record<string, unknown> = {};
    // Legacy crawled data used different casing ("elektrikçi" vs "Elektrikçi"): match exactly but ignore case.
    if (query.mainType) match.mainType = { $regex: `^${escapeRegex(query.mainType)}$`, $options: 'i' };
    if (query.subType) match.subType = { $regex: `^${escapeRegex(query.subType)}$`, $options: 'i' };
    if (query.city) match.city = { $regex: `^${escapeRegex(query.city)}$`, $options: 'i' };
    if (query.q) {
      const rx = { $regex: escapeRegex(query.q.trim()), $options: 'i' };
      match.$or = [{ businessName: rx }, { subType: rx }, { district: rx }, { city: rx }];
    }

    const pipeline: PipelineStage[] = [{ $match: match }];
    const sort: Record<string, 1 | -1> = { isPremium: -1 };

    if (hasLocation) {
      const cosLat = Math.cos((query.userLat! * Math.PI) / 180);
      pipeline.push({
        $addFields: {
          distanceKm: {
            $cond: [
              {
                $and: [
                  { $isNumber: '$lat' },
                  { $isNumber: '$lng' },
                  { $not: [{ $and: [{ $eq: ['$lat', 0] }, { $eq: ['$lng', 0] }] }] },
                ],
              },
              {
                $sqrt: {
                  $add: [
                    { $pow: [{ $multiply: [{ $subtract: ['$lat', query.userLat!] }, KM_PER_DEGREE] }, 2] },
                    { $pow: [{ $multiply: [{ $subtract: ['$lng', query.userLng!] }, KM_PER_DEGREE * cosLat] }, 2] },
                  ],
                },
              },
              null,
            ],
          },
        },
      });
      if (query.distance != null) {
        pipeline.push({ $match: { distanceKm: { $ne: null, $lte: query.distance } } });
      }
      if (query.sortMode === 'nearest') {
        pipeline.push({ $addFields: { _nearestKey: { $ifNull: ['$distanceKm', 1e9] } } });
        sort._nearestKey = 1;
      }
    }
    sort.rating = -1;
    sort.reviewCount = -1;
    sort._id = 1;

    pipeline.push(
      { $sort: sort },
      {
        $facet: {
          items: [{ $skip: (query.page - 1) * query.limit }, { $limit: query.limit }],
          total: [{ $count: 'n' }],
        },
      },
    );

    const [res] = await this.model.aggregate(pipeline).exec();
    const total: number = res?.total?.[0]?.n ?? 0;
    const items = (res?.items ?? []).map((d: any) => this.toView(d, hasLocation ? d.distanceKm ?? null : null));
    return toPage(items, total, query.page, query.limit);
  }

  async findById(id: string, userLat?: number, userLng?: number): Promise<ProviderView | null> {
    if (!/^[a-f\d]{24}$/i.test(id)) return null;
    const doc = await this.model.findById(id).lean().exec();
    if (!doc) return null;
    let distance: number | null = null;
    if (isValidCoordinate(userLat, userLng) && isValidCoordinate(doc.lat, doc.lng)) {
      distance = Math.round(haversineKm(userLat!, userLng!, doc.lat, doc.lng) * 10) / 10;
    }
    return this.toView(doc, distance);
  }

  async create(data: Omit<ProviderEntity, 'id'>): Promise<ProviderEntity> {
    const doc = await this.model.create(<any>{
      ...data,
      aiVerified: data.isVerified,
      priceList: Object.fromEntries(
        data.priceList.map((p) => [p.serviceName, `${p.minPrice ?? ''}-${p.maxPrice ?? ''}`]),
      ),
    });
    return this.toEntity((doc as any).toObject());
  }

  async updateReviewStats(id: string, rating: number, reviewCount: number): Promise<void> {
    if (!/^[a-f\d]{24}$/i.test(id)) return;
    await this.model.updateOne({ _id: id }, { $set: { rating, reviewCount } }).exec();
  }

  private toView(doc: any, distanceKm: number | null): ProviderView {
    return {
      ...this.toEntity(doc),
      distanceKm: distanceKm == null ? null : Math.round(distanceKm * 10) / 10,
    };
  }

  private toEntity(doc: any): ProviderEntity {
    const located = isValidCoordinate(doc.lat, doc.lng);
    return {
      id: String(doc._id),
      businessName: doc.businessName ?? '',
      phoneNumber: doc.phoneNumber ?? '',
      mainType: doc.mainType ?? '',
      subType: doc.subType ?? '',
      city: doc.city ?? '',
      district: doc.district ?? '',
      address: doc.address ?? '',
      lat: located ? doc.lat : null,
      lng: located ? doc.lng : null,
      rating: typeof doc.rating === 'number' ? doc.rating : 0,
      reviewCount: typeof doc.reviewCount === 'number' ? doc.reviewCount : 0,
      isPremium: doc.isPremium === true,
      isVerified: doc.aiVerified === true || doc.isPremium === true,
      about: doc.about ?? '',
      profileImage: doc.profileImage || null,
      portfolioImages: Array.isArray(doc.portfolioImages) ? doc.portfolioImages.filter(Boolean) : [],
      priceList: parsePriceList(doc.priceList),
    };
  }
}
