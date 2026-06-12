import { Queue } from 'bullmq';
import type { Redis } from 'ioredis';
import type { NotificationEnqueuer, NotificationJob } from '../services/alert-engine.js';

export const NOTIFICATIONS_QUEUE = 'notifications';

export class BullMqNotificationEnqueuer implements NotificationEnqueuer {
  private readonly queue: Queue;

  constructor(connection: Redis) {
    this.queue = new Queue(NOTIFICATIONS_QUEUE, {
      connection,
      defaultJobOptions: {
        removeOnComplete: 1000,
        removeOnFail: 1000,
        attempts: 3,
        backoff: { type: 'exponential', delay: 2000 },
      },
    });
  }

  async enqueue(jobId: string, job: NotificationJob): Promise<void> {
    // BullMQ dedupes on jobId → duplicate evaluation can't double-send
    await this.queue.add('alert-triggered', job, { jobId });
  }

  async close(): Promise<void> {
    await this.queue.close();
  }
}
