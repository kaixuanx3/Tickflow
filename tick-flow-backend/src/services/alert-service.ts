export type AlertRuleType = 'price_above' | 'price_below';
export type AlertKind = 'one_shot' | 're_arm';
export type AlertStatus = 'active' | 'cooldown' | 'done' | 'paused';

export interface Alert {
  id: string;
  userId: string;
  symbol: string;
  ruleType: AlertRuleType;
  threshold: number;
  kind: AlertKind;
  status: AlertStatus;
  triggerCount: number;
  lastTriggeredAt: Date | null;
  createdAt: Date;
}

export interface AlertInput {
  symbol: string;
  ruleType: AlertRuleType;
  threshold: number;
  kind: AlertKind;
}

// undefined = leave unchanged. Clients may set status to 'active' (re-arm a
// done/cooldown alert, or resume a paused one) or 'paused' (pause an active
// alert). The engine owns every other transition.
export interface AlertPatch {
  threshold?: number | undefined;
  kind?: AlertKind | undefined;
  status?: 'active' | 'paused' | undefined;
}

export interface AlertRepo {
  list(userId: string): Promise<Alert[]>;
  create(userId: string, data: AlertInput): Promise<Alert>;
  /** null when the alert doesn't exist or belongs to another user */
  update(userId: string, id: string, patch: AlertPatch): Promise<Alert | null>;
  /** the removed alert, or null when not found / not owned */
  remove(userId: string, id: string): Promise<Alert | null>;
}

export class AlertService {
  constructor(
    private readonly repo: AlertRepo,
    /** notified whenever a symbol's set of live alerts may have changed */
    private readonly onSymbolTouched: (symbol: string) => void = () => {},
  ) {}

  list(userId: string): Promise<Alert[]> {
    return this.repo.list(userId);
  }

  async create(userId: string, data: AlertInput): Promise<Alert> {
    const alert = await this.repo.create(userId, {
      ...data,
      symbol: data.symbol.toUpperCase(),
    });
    this.onSymbolTouched(alert.symbol);
    return alert;
  }

  async update(userId: string, id: string, patch: AlertPatch): Promise<Alert | null> {
    const alert = await this.repo.update(userId, id, patch);
    if (alert) this.onSymbolTouched(alert.symbol);
    return alert;
  }

  async remove(userId: string, id: string): Promise<boolean> {
    const alert = await this.repo.remove(userId, id);
    if (alert) this.onSymbolTouched(alert.symbol);
    return alert !== null;
  }
}
