import type { PrismaClient } from '@prisma/client';
import type { UserRecord, UserRepo } from '../services/auth-service.js';

export class PrismaUserRepo implements UserRepo {
  constructor(private readonly prisma: PrismaClient) {}

  async findByEmail(email: string): Promise<UserRecord | null> {
    return this.prisma.user.findUnique({
      where: { email },
      select: { id: true, email: true, passwordHash: true },
    });
  }

  async create(email: string, passwordHash: string | null): Promise<UserRecord> {
    return this.prisma.user.create({
      data: { email, passwordHash },
      select: { id: true, email: true, passwordHash: true },
    });
  }
}
