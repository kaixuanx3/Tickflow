import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export interface UserRecord {
  id: string;
  email: string;
  name: string | null;
  passwordHash: string | null;
}

export interface UserRepo {
  findByEmail(email: string): Promise<UserRecord | null>;
  findById(userId: string): Promise<UserRecord | null>;
  create(email: string, passwordHash: string | null): Promise<UserRecord>;
  updateProfile(userId: string, data: { name?: string | null }): Promise<UserRecord>;
  /** Idempotent; related rows cascade via the schema's onDelete: Cascade. */
  delete(userId: string): Promise<void>;
}

/** Account info served by GET /auth/me — never includes the password hash. */
export interface UserProfile {
  id: string;
  email: string;
  name: string | null;
}

/** Implemented by infrastructure (google-auth-library); null = token rejected. */
export interface GoogleTokenVerifier {
  verify(idToken: string): Promise<{ email: string } | null>;
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
  user: { id: string; email: string; name: string | null };
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

  /** Verified Google ID token → find-or-create user by email → our JWT. */
  async loginWithGoogle(
    idToken: string,
    verifier: GoogleTokenVerifier,
  ): Promise<AuthResult> {
    const google = await verifier.verify(idToken);
    if (!google) throw new InvalidCredentialsError();
    const email = google.email.trim().toLowerCase();
    const user = (await this.users.findByEmail(email)) ?? (await this.users.create(email, null));
    return this.toResult(user);
  }

  /** Deletes the account and all its data (cascade). Idempotent. */
  async deleteAccount(userId: string): Promise<void> {
    await this.users.delete(userId);
  }

  /** Current account info, or null if the (still-valid) token names a deleted user. */
  async getProfile(userId: string): Promise<UserProfile | null> {
    const user = await this.users.findById(userId);
    return user ? this.toProfile(user) : null;
  }

  /** Partial update: only fields present in `patch` change. Blank name clears it to null. */
  async updateProfile(userId: string, patch: { name?: string | undefined }): Promise<UserProfile> {
    const data: { name?: string | null } = {};
    if (patch.name !== undefined) {
      const trimmed = patch.name.trim();
      data.name = trimmed === '' ? null : trimmed;
    }
    const user = await this.users.updateProfile(userId, data);
    return this.toProfile(user);
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
    return { token, user: this.toProfile(user) };
  }

  private toProfile(user: UserRecord): UserProfile {
    return { id: user.id, email: user.email, name: user.name };
  }
}
