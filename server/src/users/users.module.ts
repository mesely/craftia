import { DynamicModule, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { isMongo } from '../config/env';
import { UserDoc, UserSchema } from './user.schema';
import { UsersController } from './users.controller';
import { MockUsersRepository, MongoUsersRepository, UsersRepository } from './users.repository';

@Module({})
export class UsersModule {
  static register(): DynamicModule {
    const mongo = isMongo();
    return {
      module: UsersModule,
      imports: mongo ? [MongooseModule.forFeature([{ name: UserDoc.name, schema: UserSchema }])] : [],
      controllers: [UsersController],
      providers: [{ provide: UsersRepository, useClass: mongo ? MongoUsersRepository : MockUsersRepository }],
    };
  }
}
