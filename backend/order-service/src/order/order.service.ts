import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Order, OrderDocument } from './schemas/order.schema';

@Injectable()
export class OrderService {
  private readonly logger = new Logger(OrderService.name);

  constructor(@InjectModel(Order.name) private orderModel: Model<OrderDocument>) {}

  async create(data: any) {
    try {
      const newOrder = new this.orderModel({
        userId: data.userId,
        categoryId: data.categoryId,
        cityId: data.cityId,
        description: data.description,
        status: 'PENDING',
        // Koordinatları GeoJSON formatına çeviriyoruz
        location: {
          type: 'Point',
          coordinates: [data.longitude, data.latitude], // [Boylam, Enlem]
        },
      });

      const savedOrder = await newOrder.save();
      return this.mapToProto(savedOrder);
    } catch (error) {
      this.logger.error(`Sipariş oluşturma hatası: ${error.message}`);
      throw error;
    }
  }

  async findOne(id: string) {
    const order = await this.orderModel.findById(id).exec();
    if (!order) throw new NotFoundException('Sipariş bulunamadı');
    return this.mapToProto(order);
  }

  async findByUser(userId: string) {
    const orders = await this.orderModel.find({ userId }).sort({ createdAt: -1 }).exec();
    return orders.map(this.mapToProto);
  }

  async updateStatus(id: string, status: string) {
    const updatedOrder = await this.orderModel
      .findByIdAndUpdate(id, { status }, { new: true })
      .exec();
    
    if (!updatedOrder) throw new NotFoundException('Sipariş bulunamadı');
    return this.mapToProto(updatedOrder);
  }

  // 🌍 Yakındaki Siparişleri Bul
  async findNearby(longitude: number, latitude: number, radiusKm: number) {
    try {
      const orders = await this.orderModel.find({
        location: {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [longitude, latitude],
            },
            $maxDistance: radiusKm * 1000, // Metre cinsinden
          },
        },
      }).exec();

      return orders.map(this.mapToProto);
    } catch (error) {
      this.logger.error(`Konum arama hatası: ${error.message}`);
      return [];
    }
  }

  // Helper: DB Objesini Proto formatına çevirir
  private mapToProto(order: OrderDocument) {
    return {
      id: order._id.toString(),
      userId: order.userId,
      categoryId: order.categoryId,
      cityId: order.cityId,
      description: order.description,
      status: order.status,
      // GeoJSON'dan koordinatları çıkarıp düz olarak dönüyoruz
      longitude: order.location.coordinates[0],
      latitude: order.location.coordinates[1],
      createdAt: (order as any).createdAt.toISOString(),
    };
  }
}