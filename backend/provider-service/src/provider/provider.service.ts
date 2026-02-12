import { Injectable, OnModuleInit } from '@nestjs/common';
import { MongoClient, ObjectId, Collection } from 'mongodb';
import { CreateProviderRequest } from './provider.interface';

@Injectable()
export class ProviderService implements OnModuleInit {
  private client: MongoClient;
  private collection: Collection<any>;

  async onModuleInit() {
    try {
  
const url = process.env.DATABASE_URL || "mongodb+srv://selmanyilmaz:morinyo1907@cs306cluster.h6hnm1n.mongodb.net/usta_db?retryWrites=true&w=majority";
      this.client = new MongoClient(url);
      await this.client.connect();
      
      const db = this.client.db('usta_db');
      this.collection = db.collection('providers');
      
      console.log('✅ MongoDB bağlantısı başarılı (Native Driver)');
    } catch (error) {
      console.error('❌ MongoDB bağlantı hatası:', error);
    }
  }

  async create(data: CreateProviderRequest) {
    const res = await this.collection.insertOne({ ...data });
    return { id: res.insertedId.toString(), ...data };
  }

  async findAll() {
    const docs = await this.collection.find({}).toArray();
    return docs.map(doc => ({
      id: doc._id.toString(),
      ...doc,
      _id: undefined,
    }));
  }

  async findOne(id: string) {
    if (!ObjectId.isValid(id)) return null;
    const doc = await this.collection.findOne({ _id: new ObjectId(id) });
    if (!doc) return null;
    return { id: doc._id.toString(), ...doc, _id: undefined };
  }

  async update(id: string, data: any) {
    if (!ObjectId.isValid(id)) return null;
    const { id: _, ...updateData } = data;
    await this.collection.updateOne(
      { _id: new ObjectId(id) },
      { $set: updateData }
    );
    return this.findOne(id);
  }

  async delete(id: string) {
    if (!ObjectId.isValid(id)) return null;
    const doc = await this.findOne(id);
    if (!doc) return null;
    await this.collection.deleteOne({ _id: new ObjectId(id) });
    return doc;
  }
}