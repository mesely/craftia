import { Injectable, Optional } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import { ObjectId } from 'mongodb';
import { Connection } from 'mongoose';

/** A tiny Mongo-style filter: equality plus `$in`, `$ne`, `$gt`, `$lt`, `$exists`. */
export type Filter = Record<string, unknown>;

export interface FindOptions {
  sort?: Record<string, 1 | -1>;
  limit?: number;
}

/** Persistence port for the newer collections. One memory and one MongoDB implementation. */
export interface Store<T extends { id: string }> {
  insert(doc: Omit<T, 'id'> & { id?: string }): Promise<T>;
  get(id: string): Promise<T | null>;
  find(filter?: Filter, options?: FindOptions): Promise<T[]>;
  update(id: string, patch: Partial<Omit<T, 'id'>>): Promise<T | null>;
  remove(id: string): Promise<boolean>;
  removeWhere(filter: Filter): Promise<number>;
}

export const newId = (): string => new ObjectId().toHexString();

function matches(doc: Record<string, unknown>, filter: Filter): boolean {
  return Object.entries(filter).every(([key, cond]) => {
    const value = doc[key];
    if (cond !== null && typeof cond === 'object' && !Array.isArray(cond)) {
      const ops = cond as Record<string, unknown>;
      if ('$in' in ops && !(ops.$in as unknown[]).includes(value)) return false;
      if ('$ne' in ops && value === ops.$ne) return false;
      if ('$gt' in ops && !((value as string | number) > (ops.$gt as string | number))) return false;
      if ('$lt' in ops && !((value as string | number) < (ops.$lt as string | number))) return false;
      if ('$exists' in ops && (value !== undefined) !== ops.$exists) return false;
      return true;
    }
    return value === cond;
  });
}

export class MemoryStore<T extends { id: string }> implements Store<T> {
  private readonly docs = new Map<string, T>();

  async insert(doc: Omit<T, 'id'> & { id?: string }): Promise<T> {
    const item = { ...doc, id: doc.id ?? newId() } as T;
    this.docs.set(item.id, item);
    return { ...item };
  }

  async get(id: string): Promise<T | null> {
    const d = this.docs.get(id);
    return d ? { ...d } : null;
  }

  async find(filter: Filter = {}, options: FindOptions = {}): Promise<T[]> {
    let rows = [...this.docs.values()].filter((d) => matches(d as Record<string, unknown>, filter));
    const sort = Object.entries(options.sort ?? {});
    if (sort.length) {
      rows.sort((a, b) => {
        for (const [key, dir] of sort) {
          const av = (a as Record<string, unknown>)[key] as string | number;
          const bv = (b as Record<string, unknown>)[key] as string | number;
          if (av !== bv) return (av > bv ? 1 : -1) * dir;
        }
        return 0;
      });
    }
    if (options.limit) rows = rows.slice(0, options.limit);
    return rows.map((d) => ({ ...d }));
  }

  async update(id: string, patch: Partial<Omit<T, 'id'>>): Promise<T | null> {
    const d = this.docs.get(id);
    if (!d) return null;
    Object.assign(d, patch);
    return { ...d };
  }

  async remove(id: string): Promise<boolean> {
    return this.docs.delete(id);
  }

  async removeWhere(filter: Filter): Promise<number> {
    let n = 0;
    for (const [id, d] of this.docs) {
      if (matches(d as Record<string, unknown>, filter)) {
        this.docs.delete(id);
        n++;
      }
    }
    return n;
  }
}

/** Uses the native driver collection of the shared Mongoose connection. `_id` is the string id. */
export class MongoStore<T extends { id: string }> implements Store<T> {
  constructor(private readonly connection: Connection, private readonly name: string) {}

  private get col() {
    return this.connection.collection(this.name);
  }

  private out(d: Record<string, unknown> | null): T | null {
    if (!d) return null;
    const { _id, ...rest } = d;
    return { ...rest, id: String(_id) } as unknown as T;
  }

  async insert(doc: Omit<T, 'id'> & { id?: string }): Promise<T> {
    const { id: given, ...rest } = doc as Record<string, unknown>;
    const id = (given as string | undefined) ?? newId();
    await this.col.insertOne({ _id: id, ...rest } as never);
    return { ...rest, id } as unknown as T;
  }

  async get(id: string): Promise<T | null> {
    return this.out((await this.col.findOne({ _id: id } as never)) as Record<string, unknown> | null);
  }

  async find(filter: Filter = {}, options: FindOptions = {}): Promise<T[]> {
    let cursor = this.col.find(filter as never);
    if (options.sort) cursor = cursor.sort(options.sort as never);
    if (options.limit) cursor = cursor.limit(options.limit);
    return (await cursor.toArray()).map((d) => this.out(d as Record<string, unknown>)!);
  }

  async update(id: string, patch: Partial<Omit<T, 'id'>>): Promise<T | null> {
    await this.col.updateOne({ _id: id } as never, { $set: patch } as never);
    return this.get(id);
  }

  async remove(id: string): Promise<boolean> {
    return (await this.col.deleteOne({ _id: id } as never)).deletedCount === 1;
  }

  async removeWhere(filter: Filter): Promise<number> {
    return (await this.col.deleteMany(filter as never)).deletedCount;
  }
}

@Injectable()
export class StoreFactory {
  private readonly memory = new Map<string, MemoryStore<never>>();

  constructor(@Optional() @InjectConnection() private readonly connection?: Connection) {}

  collection<T extends { id: string }>(name: string): Store<T> {
    if (this.connection) return new MongoStore<T>(this.connection, name);
    if (!this.memory.has(name)) this.memory.set(name, new MemoryStore<never>());
    return this.memory.get(name) as unknown as Store<T>;
  }
}
