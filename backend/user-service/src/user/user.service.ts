import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User, UserDocument } from './schemas/user.schema';
import * as bcrypt from 'bcryptjs'; // Şifreleme için

@Injectable()
export class UserService {
  private readonly logger = new Logger(UserService.name);

  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  // 1. Kullanıcı Oluşturma
  async createUser(data: any) {
    try {
      // Şifreyi hashleyelim
      const hashedPassword = await bcrypt.hash(data.password, 10);
      
      const newUser = new this.userModel({
        email: data.email,
        password: hashedPassword,
        firstName: data.first_name, // Proto snake_case -> Schema camelCase
        lastName: data.last_name,   // Proto snake_case -> Schema camelCase
        phone: data.phone,
      });

      const savedUser = await newUser.save();
      return this.mapToProto(savedUser);
    } catch (error) {
      this.logger.error(`Kullanıcı oluşturma hatası: ${error.message}`);
      throw error;
    }
  }

  // 2. Kullanıcı Getirme
  async getUser(id: string) {
    const user = await this.userModel.findById(id).exec();
    if (!user) {
      this.logger.warn(`Kullanıcı bulunamadı: ${id}`);
      // gRPC için boş dönmek yerine hata fırlatabiliriz veya null dönebiliriz.
      // Proto yapısı null desteklemez, boş obje dönebiliriz ama genelde hata fırlatılır.
      throw new NotFoundException('Kullanıcı bulunamadı');
    }
    return this.mapToProto(user);
  }

  // 3. Kullanıcı Güncelleme
  async updateUser(data: any) {
    const { id, ...updateData } = data;
    
    // Proto'dan gelen snake_case veriyi camelCase'e çeviriyoruz
    const formattedUpdate = {};
    if (updateData.first_name) formattedUpdate['firstName'] = updateData.first_name;
    if (updateData.last_name) formattedUpdate['lastName'] = updateData.last_name;
    if (updateData.phone) formattedUpdate['phone'] = updateData.phone;

    const updatedUser = await this.userModel
      .findByIdAndUpdate(id, formattedUpdate, { new: true })
      .exec();

    if (!updatedUser) throw new NotFoundException('Kullanıcı bulunamadı');

    return this.mapToProto(updatedUser);
  }

  // 4. Kullanıcı Silme
  async deleteUser(id: string) {
    const result = await this.userModel.findByIdAndDelete(id).exec();
    return { success: !!result };
  }

  // Helper: DB Objesini Proto Response formatına çevirir
  private mapToProto(user: UserDocument) {
    return {
      id: user._id.toString(),
      email: user.email,
      first_name: user.firstName, // Schema camelCase -> Proto snake_case
      last_name: user.lastName,   // Schema camelCase -> Proto snake_case
      phone: user.phone,
    };
  }
}