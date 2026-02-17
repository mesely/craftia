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

  // ✅ GÜNCELLENMİŞ FINDALL: gRPC/Controller'dan gelen Payload (Object) mimarisine uyarlandı.
  // Eskiden parametreler tek tek geliyordu, bu yüzden filtreler DB'ye ulaşmıyordu.
  async findAll(payload: any) {
  const page = Number(payload.page) || 1;
  const limit = Number(payload.limit) || 10;
  const skip = (page - 1) * limit;
  const userLat = parseFloat(payload.userLat);
  const userLng = parseFloat(payload.userLng);
  const sortMode = payload.sortMode || payload.sort;

  // 1. Pipeline Başlangıcı
  const pipeline: any[] = [];

  // 2. MESAFE HESABI (Eğer konum varsa ve mod 'nearest' ise)
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
    // Mesafe modu değilse distance alanını 0 verelim ki hata çıkmasın
    pipeline.push({ $addFields: { distance: 0 } });
  }

  // 3. FİLTRELER (Match)
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

  // 4. SIRALAMA (Önce Premium, Sonra Seçilen Mod)
  // En önemli kural: isPremium hep -1 (en üstte)
  const sortOptions: any = { isPremium: -1 };

  if (sortMode === 'nearest' && !isNaN(userLat)) {
    sortOptions.distance = 1; // En yakın mesafe
  } else if (sortMode === 'rating') {
    sortOptions.rating = -1;
  } else {
    sortOptions.createdAt = -1; // En yeni
  }
  pipeline.push({ $sort: sortOptions });

  // 5. SAYFALAMA
  pipeline.push({ $skip: skip });
  pipeline.push({ $limit: limit });

  // 6. ÇALIŞTIR
  const providers = await this.providerModel.aggregate(pipeline).exec();
  const total = await this.providerModel.countDocuments(matchQuery);

  return {
    providers,
    total,
    page,
    lastPage: Math.ceil(total / limit),
  };
}

  // --- DİĞER METODLAR AYNI --
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
    });
  }

  async findOne(id: string) { return await this.providerModel.findById(id).populate('user').lean().exec(); }
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

  // --- CRAWLER MANTIĞI ---
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
              { headers: { 'Content-Type': 'application/json', 'X-Goog-Api-Key': this.apiKey, 'X-Goog-FieldMask': 'places.displayName,places.nationalPhoneNumber,places.formattedAddress,places.location' }}
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