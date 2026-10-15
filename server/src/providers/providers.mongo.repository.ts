import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, PipelineStage, Types } from 'mongoose';
import { haversineKm, isValidCoordinate } from '../common/geo';
import { Page, toPage } from '../common/pagination';
import { ProviderDoc, ProviderDocument } from './provider.schema';
import { toProviderEntity } from './provider.mapper';
import { ProviderEntity, ProviderQuery, ProviderView } from './provider.types';
import { ProviderProfilePatch, ProvidersRepository } from './providers.repository';

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
    if (query.excludeId && /^[a-f\d]{24}$/i.test(query.excludeId)) match._id = { $ne: new Types.ObjectId(query.excludeId) };
    if (query.q) {
      const rx = { $regex: escapeRegex(query.q.trim()), $options: 'i' };
      match.$or = [{ businessName: rx }, { subType: rx }, { district: rx }, { city: rx }];
    }

    const pipeline: PipelineStage[] = [{ $match: match }];
    // Paid placement first: the legacy flag or a promotion that has not ended yet.
    pipeline.push({
      $addFields: {
        _featured: { $cond: [{ $or: [{ $eq: ['$isPremium', true] }, { $gt: ['$featuredUntil', new Date()] }] }, 1, 0] },
      },
    });
    const sort: Record<string, 1 | -1> = { _featured: -1 };

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
      featuredUntil: undefined,
      priceList: Object.fromEntries(
        data.priceList.map((p) => [p.serviceName, `${p.minPrice ?? ''}-${p.maxPrice ?? ''}`]),
      ),
    });
    return toProviderEntity((doc as any).toObject());
  }

  async update(id: string, patch: ProviderProfilePatch): Promise<ProviderEntity | null> {
    if (!/^[a-f\d]{24}$/i.test(id)) return null;
    const set: Record<string, unknown> = {};
    if (patch.about !== undefined) set.about = patch.about;
    if (patch.address !== undefined) set.address = patch.address;
    if (patch.serviceAreas !== undefined) set.serviceAreas = patch.serviceAreas;
    if (patch.phoneNumber !== undefined) set.phoneNumber = patch.phoneNumber;
    if (patch.portfolioImages !== undefined) set.portfolioImages = patch.portfolioImages;
    if (patch.profileImage !== undefined) set.profileImage = patch.profileImage ?? '';
    if (patch.businessName !== undefined) set.businessName = patch.businessName;
    if (patch.city !== undefined) set.city = patch.city;
    if (patch.district !== undefined) set.district = patch.district;
    if (patch.lat !== undefined && patch.lat !== null) set.lat = patch.lat;
    if (patch.lng !== undefined && patch.lng !== null) set.lng = patch.lng;
    if (patch.featuredUntil !== undefined) set.featuredUntil = patch.featuredUntil ? new Date(patch.featuredUntil) : null;
    if (patch.priceList !== undefined) {
      // Same legacy shape as on create: { "service": "min-max" }.
      set.priceList = Object.fromEntries(patch.priceList.map((p) => [p.serviceName, `${p.minPrice ?? ''}-${p.maxPrice ?? ''}`]));
    }
    const doc = await this.model.findByIdAndUpdate(id, { $set: set }, { new: true }).lean().exec();
    return doc ? toProviderEntity(doc) : null;
  }

  async updateReviewStats(id: string, rating: number, reviewCount: number): Promise<void> {
    if (!/^[a-f\d]{24}$/i.test(id)) return;
    await this.model.updateOne({ _id: id }, { $set: { rating, reviewCount } }).exec();
  }

  private toView(doc: any, distanceKm: number | null): ProviderView {
    return {
      ...toProviderEntity(doc),
      distanceKm: distanceKm == null ? null : Math.round(distanceKm * 10) / 10,
    };
  }
}
