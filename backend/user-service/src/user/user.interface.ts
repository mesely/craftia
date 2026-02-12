export interface IAddress {
  city: string;
  district: string;
  street: string;
  zipCode: string;
}

export interface IUser {
  id?: string; // MongoDB'den gelince string'e çevireceğiz
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: IAddress;
  profilePictureUrl?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

// gRPC'den gelen Create isteği için (ID henüz yok)
export interface CreateUserDto {
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  address: IAddress;
  profilePictureUrl?: string;
}

// gRPC'den gelen Update isteği için (ID zorunlu)
export interface UpdateUserDto extends CreateUserDto {
  id: string;
}