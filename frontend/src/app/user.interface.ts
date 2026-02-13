import { Observable } from 'rxjs';

export interface IAddress {
  city: string;
  district: string;
  street: string;
  zipCode: string;
}

export interface IUser {
  id?: string; 
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: IAddress;
  profilePictureUrl?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface IUserList {
  users: IUser[];
}

export interface CreateUserDto {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: IAddress;
  profilePictureUrl?: string;
}

export interface UpdateUserDto extends CreateUserDto {
  id: string;
}

export interface UserIdRequest {
  id: string;
}

// --- gRPC Client Servis Tanımı ---
export interface UserGrpcService {
  createUser(data: CreateUserDto): Observable<IUser>;
  findAll(data: any): Observable<IUserList>;
  findOne(data: UserIdRequest): Observable<IUser>;
  updateUser(data: UpdateUserDto): Observable<IUser>;
  deleteUser(data: UserIdRequest): Observable<{ success: boolean }>;
}