import type { PrismaClient } from '@prisma/client';
import type {
  Holding,
  HoldingInput,
  HoldingPatch,
  HoldingRepo,
} from '../services/portfolio-service.js';

const fields = {
  id: true,
  symbol: true,
  qty: true,
  buyPrice: true,
  assetType: true,
  createdAt: true,
} as const;

export class PrismaHoldingRepo implements HoldingRepo {
  constructor(private readonly prisma: PrismaClient) {}

  async list(userId: string): Promise<Holding[]> {
    return this.prisma.holding.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: fields,
    });
  }

  async create(userId: string, data: HoldingInput): Promise<Holding> {
    return this.prisma.holding.create({ data: { userId, ...data }, select: fields });
  }

  async update(userId: string, id: string, patch: HoldingPatch): Promise<Holding | null> {
    // exactOptionalPropertyTypes: drop undefined entries before handing to Prisma
    const data = Object.fromEntries(
      Object.entries(patch).filter(([, v]) => v !== undefined),
    );
    // updateMany so the WHERE can include userId — no cross-user edits
    const { count } = await this.prisma.holding.updateMany({
      where: { id, userId },
      data,
    });
    if (count === 0) return null;
    return this.prisma.holding.findUnique({ where: { id }, select: fields });
  }

  async remove(userId: string, id: string): Promise<boolean> {
    const { count } = await this.prisma.holding.deleteMany({ where: { id, userId } });
    return count > 0;
  }
}
