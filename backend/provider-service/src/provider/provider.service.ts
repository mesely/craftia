import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Provider, ProviderDocument } from './schemas/provider.schema';
import { User, UserDocument } from './schemas/user.schema';
import { TURKEY_DATA } from './turkey_data';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class ProviderService implements OnModuleInit {
  private readonly logger = new Logger(ProviderService.name);
  private readonly apiKey = process.env.GOOGLE_PLACES_API_KEY;
  private readonly GOOGLE_NEW_API_URL = 'https://places.googleapis.com/v1/places:searchText';

  constructor(
    @InjectModel(Provider.name) private providerModel: Model<ProviderDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private readonly httpService: HttpService,
  ) {}

  async onModuleInit() {
    this.logger.log('✅ [Provider Service] Mongoose Modelleri Hazır.');
  }

  async findAll(payload: any) {
    const page = Number(payload.page) || 1;
    const limit = Number(payload.limit) || 10;
    const skip = (page - 1) * limit;
    const userLat = parseFloat(payload.userLat);
    const userLng = parseFloat(payload.userLng);
    const sortMode = payload.sortMode || payload.sort;

    const pipeline: any[] = [];

    if (!isNaN(userLat) && !isNaN(userLng) && sortMode === 'nearest') {
      pipeline.push({
        $addFields: {
          distance: {
            $sqrt: {
              $add: [
                { $pow: [{ $subtract: ['$lat', userLat] }, 2] },
                { $pow: [{ $subtract: ['$lng', userLng] }, 2] }
              ]
            }
          }
        }
      });
    } else {
      pipeline.push({ $addFields: { distance: 0 } });
    }

    const matchQuery: any = {};
    if (payload.mainType && payload.mainType !== 'all') {
      matchQuery.mainType = payload.mainType;
    }
    if (payload.subType && payload.subType !== 'all') {
      matchQuery.subType = payload.subType;
    }
    if (payload.city && payload.city !== 'all') {
      matchQuery.city = { $regex: new RegExp('^' + payload.city + '$', 'i') };
    }
    pipeline.push({ $match: matchQuery });

    const sortOptions: any = { isPremium: -1 };
    if (sortMode === 'nearest' && !isNaN(userLat)) {
      sortOptions.distance = 1; 
    } else if (sortMode === 'rating') {
      sortOptions.rating = -1;
    } else {
      sortOptions.createdAt = -1; 
    }
    pipeline.push({ $sort: sortOptions });

    pipeline.push({ $skip: skip });
    pipeline.push({ $limit: limit });

    const providers = await this.providerModel.aggregate(pipeline).exec();
    const total = await this.providerModel.countDocuments(matchQuery);

    return {
      providers,
      total,
      page,
      lastPage: Math.ceil(total / limit),
    };
  }

  // ✅ GÜNCELLENEN KISIM BURASI
  async create(data: any) {
    const latValue = data.lat ? parseFloat(data.lat.toString()) : 0;
    const lngValue = data.lng ? parseFloat(data.lng.toString()) : 0;
    
    return await this.providerModel.create({
      businessName: data.name || data.businessName,
      phoneNumber: data.phone || data.phoneNumber,
      city: data.city,
      district: data.district || 'Merkez',
      address: data.address || '',
      mainType: data.category || 'TECHNICAL',
      lat: isNaN(latValue) ? 0 : latValue,
      lng: isNaN(lngValue) ? 0 : lngValue,
      user: data.userId ? new Types.ObjectId(data.userId) : new Types.ObjectId(),
      
      // YENİ ALANLARI KAYDET
      profileImage: data.profileImage || '',
      portfolioImages: data.portfolioImages || [],
      priceList: data.priceList || {}, // Sözlük (Map) buraya yerleşiyor
    });
  }

  async findOne(id: string) { return await this.providerModel.findById(id).populate('user').lean().exec(); }
  
  // Güncelleme işlemi objeyi direkt kabul ettiği için priceList ve imagelar otomatik güncellenecek
  async update(id: string, data: any) { return await this.providerModel.findByIdAndUpdate(id, data, { new: true }).exec(); }
  
  async delete(id: string) { const res = await this.providerModel.findByIdAndDelete(id).exec(); return { success: !!res }; }
  
  async getCities() {
    const cities = await this.providerModel.distinct('city').exec();
    return cities.map((c, i) => ({ id: String(i + 1), name: c }));
  }

  async getDistricts(city: string) {
    const districts = await this.providerModel.find({ city }).distinct('district').exec();
    return districts.map((d, i) => ({ id: String(i + 1), name: d }));
  }

  async getCategories() {
    return [{ id: 'TECHNICAL', name: 'Teknik Servis' }, { id: 'CONSTRUCTION', name: 'Yapı & Dekorasyon' }];
  }

  async startTurkeyGeneralCrawl() {
    // ... Crawler kodu aynı ... (Burası değişmedi)
  }

  private async saveToMongoNew(place: any, city: string, district: string, keyword: string) {
    // ... Crawler save mantığı aynı ... (Burası değişmedi)
  }
}