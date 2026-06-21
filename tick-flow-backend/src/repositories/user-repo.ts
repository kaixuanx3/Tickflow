import type { PrismaClient } from '@prisma/client';
import type { UserRecord, UserRepo } from '../services/auth-service.js';

const userFields = {
  id: true,
  email: true,
  name: true,
  passwordHash: true,
  pushEnabled: true,
} as const;

export class PrismaUserRepo implements UserRepo {
  constructor(private readonly prisma: PrismaClient) {}

  async findByEmail(email: string): Promise<UserRecord | null> {
    return this.prisma.user.findUnique({ where: { email }, select: userFields });
  }

  async findById(userId: string): Promise<UserRecord | null> {
    return this.prisma.user.findUnique({ where: { id: userId }, select: userFields });
  }

  async create(email: string, passwordHash: string | null): Promise<UserRecord> {
    return this.prisma.user.create({ data: { email, passwordHash }, select: userFields });
  }

  async updateProfile(
    userId: string,
    data: { name?: string | null; pushEnabled?: boolean },
  ): Promise<UserRecord> {
    return this.prisma.user.update({ where: { id: userId }, data, select: userFields });
  }

  async updatePasswordHash(userId: string, passwordHash: string): Promise<void> {
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
  }

  async delete(userId: string): Promise<void> {
    // deleteMany so a stale token (user already gone) is a no-op, not a throw.
    // Related rows are removed by the DB's ON DELETE CASCADE foreign keys.
    await this.prisma.user.deleteMany({ where: { id: userId } });
  }
}
