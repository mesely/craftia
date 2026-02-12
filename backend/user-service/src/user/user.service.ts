import { Injectable, OnModuleInit } from '@nestjs/common';
import { MongoClient, ObjectId, Collection } from 'mongodb';
import { CreateUserDto, UpdateUserDto, IUser } from './user.interface';


@Injectable()
export class UserService implements OnModuleInit {
  private client: MongoClient;
  private collection: Collection<any>;

  async onModuleInit() {
    try {
      // Atlas bağlantı dizesi (morinyo1907 şifresiyle)
      const url = process.env.DATABASE_URL || 'mongodb+srv://selmanyilmaz:morinyo1907@cs306cluster.h6hnm1n.mongodb.net/usta_db?retryWrites=true&w=majority';
      this.client = new MongoClient(url);
      await this.client.connect();
      
      const db = this.client.db('usta_db');
      this.collection = db.collection('users');
      
      console.log('✅ User Service: MongoDB Atlas bağlantısı başarılı!');
    } catch (error) {
      console.error('❌ User Service: MongoDB bağlantı hatası:', error);
    }
  }

  async create(data: CreateUserDto) {
    const newUser = {
      ...data,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const res = await this.collection.insertOne(newUser);
    return { id: res.insertedId.toString(), ...newUser };
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

  async update(id: string, data: UpdateUserDto) {
    if (!ObjectId.isValid(id)) return null;
    const { id: _, ...updateData } = data;
    const updateBody = {
      ...updateData,
      updatedAt: new Date(),
    };
    await this.collection.updateOne(
      { _id: new ObjectId(id) },
      { $set: updateBody }
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