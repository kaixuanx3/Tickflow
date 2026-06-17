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
  position: true,
  createdAt: true,
} as const;

export class PrismaHoldingRepo implements HoldingRepo {
  constructor(private readonly prisma: PrismaClient) {}

  async list(userId: string): Promise<Holding[]> {
    return this.prisma.holding.findMany({
      where: { userId },
      // position is the user's manual order; createdAt breaks ties (and orders
      // pre-migration rows that all share position 0) oldest-first.
      orderBy: [{ position: 'asc' }, { createdAt: 'asc' }],
      select: fields,
    });
  }

  async create(userId: string, data: HoldingInput): Promise<Holding> {
    // New holdings go to the bottom: one past the user's current max position.
    const { _max } = await this.prisma.holding.aggregate({
      where: { userId },
      _max: { position: true },
    });
    const position = (_max.position ?? -1) + 1;
    return this.prisma.holding.create({
      data: { userId, ...data, position },
      select: fields,
    });
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

  async reorder(userId: string, orderedIds: string[]): Promise<void> {
    // Set each holding's position to its index. updateMany scopes to userId so
    // ids that aren't the caller's are silently skipped.
    await this.prisma.$transaction(
      orderedIds.map((id, index) =>
        this.prisma.holding.updateMany({ where: { id, userId }, data: { position: index } }),
      ),
    );
  }
}
