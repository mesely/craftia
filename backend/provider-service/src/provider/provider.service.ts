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

  async create(data: any) {
    const latValue = data.lat ? parseFloat(data.lat.toString()) : 0;
    const lngValue = data.lng ? parseFloat(data.lng.toString()) : 0;
    
    return await this.providerModel.create({
      businessName: data.name || data.businessName,
      phoneNumber: data.phone || data.phoneNumber,
      city: data.city,
      district: data.district || 'Merkez',
      address: data.address || '',
      // Proto'dan 'category' gelirse 'mainType' olarak kaydet
      mainType: data.category || data.mainType || 'TECHNICAL',
      subType: data.subType || '',
      lat: isNaN(latValue) ? 0 : latValue,
      lng: isNaN(lngValue) ? 0 : lngValue,
      user: data.userId ? new Types.ObjectId(data.userId) : new Types.ObjectId(),
      
      // Premium Durumu
      isPremium: data.isPremium === true || data.isPremium === 'true',

      profileImage: data.profileImage || '',
      portfolioImages: data.portfolioImages || [],
      priceList: data.priceList || {},
    });
  }

  async findOne(id: string) { 
    return await this.providerModel.findById(id).populate('user').lean().exec(); 
  }
  
  // ✅ GÜNCELLEME METODU (Sorunları çözen kısım)
  // provider.service.ts içindeki update metodu
async update(id: string, data: any) {
  const { _id, id: _, ...rest } = data;

  const updatePayload: any = {
    ...rest,
    mainType: data.mainType || data.category,
    isPremium: data.isPremium === true || String(data.isPremium) === 'true'
  };

  // ✅ location'ı da güncelle
  if (data.lat && data.lng) {
    updatePayload.location = {
      type: 'Point',
      coordinates: [parseFloat(data.lng), parseFloat(data.lat)] // GeoJSON: önce lng
    };
  }

  return await this.providerModel.findByIdAndUpdate(
    id,
    { $set: updatePayload },
    { new: true, runValidators: true }
  ).exec();
}
async delete(id: string) {
  const res = await this.providerModel.findByIdAndDelete(id).exec();
  return { success: !!res };
}
  
  async getCities() {
    const cities = await this.providerModel.distinct('city').exec();
    return cities.map((c, i) => ({ id: String(i + 1), name: c }));
  }

  async getDistricts(city: string) {
    const districts = await this.providerModel.find({ city }).distinct('district').exec();
    return districts.map((d, i) => ({ id: String(i + 1), name: d }));
  }

  async getCategories() {
    return [
      { id: 'TECHNICAL', name: 'Teknik Servis' }, 
      { id: 'CONSTRUCTION', name: 'Yapı & Dekorasyon' }
    ];
  }

  async startTurkeyGeneralCrawl() {
    this.logger.log('🚀 [CRAWLER] Operasyon Başlatıldı...');
    const keywords = ['elektrikçi', 'su tesisatçısı', 'kombi tamiri', 'boyacı'];
    for (const region of TURKEY_DATA) {
      for (const keyword of keywords) {
        try {
          const query = `${keyword} ${region.ilce} ${region.il}`;
          const response = await firstValueFrom(
            this.httpService.post(this.GOOGLE_NEW_API_URL, 
              { textQuery: query, languageCode: 'tr' },
              { headers: { 
                'Content-Type': 'application/json', 
                'X-Goog-Api-Key': this.apiKey, 
                'X-Goog-FieldMask': 'places.displayName,places.nationalPhoneNumber,places.formattedAddress,places.location' 
              }}
            )
          );
          const results = response.data.places || [];
          for (const place of results) {
            if (!place.nationalPhoneNumber) continue;
            await this.saveToMongoNew(place, region.il, region.ilce, keyword);
          }
        } catch (e) { this.logger.error(`❌ Hata: ${e.message}`); }
      }
      await new Promise(r => setTimeout(r, 300));
    }
    return { success: true };
  }

  private async saveToMongoNew(place: any, city: string, district: string, keyword: string) {
    try {
      const exists = await this.providerModel.findOne({ phoneNumber: place.nationalPhoneNumber });
      if (exists) return false;
      const newUser = await this.userModel.create({
        email: `u_${Date.now()}@usta.com`,
        password: await bcrypt.hash('Usta2026!', 10),
        role: 'PROVIDER'
      });
      await this.providerModel.create({
        user: newUser._id,
        businessName: place.displayName?.text || 'İsimsiz Usta',
        phoneNumber: place.nationalPhoneNumber,
        city, district, address: place.formattedAddress,
        lat: place.location?.latitude || 0,
        lng: place.location?.longitude || 0,
        mainType: 'TECHNICAL',
        subType: keyword
      });
      return true;
    } catch (e) { return false; }
  }
}