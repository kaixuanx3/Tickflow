import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export interface UserRecord {
  id: string;
  email: string;
  passwordHash: string | null;
}

export interface UserRepo {
  findByEmail(email: string): Promise<UserRecord | null>;
  create(email: string, passwordHash: string): Promise<UserRecord>;
}

export class EmailTakenError extends Error {
  constructor() {
    super('email already registered');
    this.name = 'EmailTakenError';
  }
}

export class InvalidCredentialsError extends Error {
  constructor() {
    super('invalid email or password');
    this.name = 'InvalidCredentialsError';
  }
}

export interface AuthResult {
  token: string;
  user: { id: string; email: string };
}

export class AuthService {
  constructor(
    private readonly users: UserRepo,
    private readonly jwtSecret: string,
    private readonly tokenTtl: NonNullable<jwt.SignOptions['expiresIn']> = '7d',
  ) {}

  async register(email: string, password: string): Promise<AuthResult> {
    const normalized = email.trim().toLowerCase();
    if (await this.users.findByEmail(normalized)) throw new EmailTakenError();
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await this.users.create(normalized, passwordHash);
    return this.toResult(user);
  }

  async login(email: string, password: string): Promise<AuthResult> {
    const user = await this.users.findByEmail(email.trim().toLowerCase());
    // passwordHash is null for (future) Google-only accounts
    if (!user?.passwordHash) throw new InvalidCredentialsError();
    if (!(await bcrypt.compare(password, user.passwordHash))) {
      throw new InvalidCredentialsError();
    }
    return this.toResult(user);
  }

  /** Same JWT for REST and the WS auth message. */
  verifyToken(token: string): { userId: string } | null {
    try {
      const payload = jwt.verify(token, this.jwtSecret);
      if (typeof payload === 'string' || typeof payload.sub !== 'string') return null;
      return { userId: payload.sub };
    } catch {
      return null;
    }
  }

  private toResult(user: UserRecord): AuthResult {
    const token = jwt.sign({ sub: user.id }, this.jwtSecret, { expiresIn: this.tokenTtl });
    return { token, user: { id: user.id, email: user.email } };
  }
}
