import { Worker } from 'bullmq';
import type { Redis } from 'ioredis';
import type { NotificationJob } from '../services/alert-engine.js';
import type { NotificationDelivery } from '../services/notifications.js';
import { NOTIFICATIONS_QUEUE } from './notification-queue.js';

export function startNotificationWorker(
  connection: Redis,
  delivery: NotificationDelivery,
): Worker<NotificationJob> {
  const worker = new Worker<NotificationJob>(
    NOTIFICATIONS_QUEUE,
    async (job) => delivery.deliver(job.data),
    { connection },
  );
  worker.on('failed', (job, err) => {
    console.error(`[notifications] job ${job?.id} failed:`, err.message);
  });
  return worker;
}
