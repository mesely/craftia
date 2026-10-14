import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { UserDoc, UserDocument } from './user.schema';

export interface UserEntity {
  id: string;
  firstName: string;
  lastName: string;
  phone: string;
  email: string;
}

export abstract class UsersRepository {
  abstract findById(id: string): Promise<UserEntity | null>;
}

/** Mock mode has no accounts: every id resolves to an anonymous guest profile. */
@Injectable()
export class MockUsersRepository extends UsersRepository {
  async findById(id: string): Promise<UserEntity> {
    return { id, firstName: 'Misafir', lastName: '', phone: '', email: '' };
  }
}

@Injectable()
export class MongoUsersRepository extends UsersRepository {
  constructor(@InjectModel(UserDoc.name) private readonly model: Model<UserDocument>) {
    super();
  }

  async findById(id: string): Promise<UserEntity | null> {
    if (!/^[a-f\d]{24}$/i.test(id)) return null;
    const d = await this.model.findById(id, { email: 1, firstName: 1, lastName: 1, phone: 1 }).lean().exec();
    return d
      ? { id: String(d._id), firstName: d.firstName ?? '', lastName: d.lastName ?? '', phone: d.phone ?? '', email: d.email ?? '' }
      : null;
  }
}
