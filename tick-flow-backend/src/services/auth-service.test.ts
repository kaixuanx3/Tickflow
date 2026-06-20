import { describe, expect, it } from 'vitest';
import {
  AuthService,
  EmailTakenError,
  InvalidCredentialsError,
  type UserRecord,
  type UserRepo,
} from './auth-service.js';

class MemoryUserRepo implements UserRepo {
  users: UserRecord[] = [];
  private nextId = 1;

  async findByEmail(email: string): Promise<UserRecord | null> {
    return this.users.find((u) => u.email === email) ?? null;
  }

  async findById(userId: string): Promise<UserRecord | null> {
    return this.users.find((u) => u.id === userId) ?? null;
  }

  async create(email: string, passwordHash: string | null): Promise<UserRecord> {
    const user = { id: `u${this.nextId++}`, email, name: null, passwordHash };
    this.users.push(user);
    return user;
  }

  async updateProfile(userId: string, data: { name?: string | null }): Promise<UserRecord> {
    const user = this.users.find((u) => u.id === userId);
    if (!user) throw new Error('user not found');
    if (data.name !== undefined) user.name = data.name;
    return user;
  }

  async delete(userId: string): Promise<void> {
    this.users = this.users.filter((u) => u.id !== userId);
  }
}

const makeService = () => {
  const repo = new MemoryUserRepo();
  return { repo, service: new AuthService(repo, 'test-secret') };
};

describe('AuthService', () => {
  it('register returns a token that verifies to the new user id', async () => {
    const { service } = makeService();

    const result = await service.register('kai@example.com', 'password123');

    expect(result.user.email).toBe('kai@example.com');
    expect(service.verifyToken(result.token)).toEqual({ userId: result.user.id });
  });

  it('register stores a bcrypt hash, never the plaintext password', async () => {
    const { repo, service } = makeService();

    await service.register('kai@example.com', 'password123');

    const stored = repo.users[0];
    expect(stored?.passwordHash).not.toContain('password123');
    expect(stored?.passwordHash).toMatch(/^\$2/); // bcrypt prefix
  });

  it('register rejects duplicate emails case-insensitively', async () => {
    const { service } = makeService();
    await service.register('Kai@Example.com', 'password123');

    await expect(service.register('kai@example.com', 'other-password')).rejects.toThrow(
      EmailTakenError,
    );
  });

  it('login succeeds with correct credentials regardless of email casing', async () => {
    const { service } = makeService();
    const registered = await service.register('kai@example.com', 'password123');

    const result = await service.login('KAI@example.com', 'password123');

    expect(result.user.id).toBe(registered.user.id);
    expect(service.verifyToken(result.token)).toEqual({ userId: registered.user.id });
  });

  it('login rejects a wrong password', async () => {
    const { service } = makeService();
    await service.register('kai@example.com', 'password123');

    await expect(service.login('kai@example.com', 'wrong-password')).rejects.toThrow(
      InvalidCredentialsError,
    );
  });

  it('login rejects an unknown email', async () => {
    const { service } = makeService();

    await expect(service.login('nobody@example.com', 'password123')).rejects.toThrow(
      InvalidCredentialsError,
    );
  });

  it('login rejects accounts without a password hash (Google-only)', async () => {
    const { repo, service } = makeService();
    repo.users.push({ id: 'u9', email: 'google@example.com', name: null, passwordHash: null });

    await expect(service.login('google@example.com', 'whatever1')).rejects.toThrow(
      InvalidCredentialsError,
    );
  });

  it('loginWithGoogle creates a passwordless user on first sign-in', async () => {
    const { repo, service } = makeService();
    const verifier = { verify: async () => ({ email: 'Kai@Example.com' }) };

    const result = await service.loginWithGoogle('google-id-token', verifier);

    expect(result.user.email).toBe('kai@example.com');
    expect(repo.users[0]?.passwordHash).toBeNull();
    expect(service.verifyToken(result.token)).toEqual({ userId: result.user.id });
  });

  it('loginWithGoogle links to an existing email/password account', async () => {
    const { service } = makeService();
    const registered = await service.register('kai@example.com', 'password123');
    const verifier = { verify: async () => ({ email: 'kai@example.com' }) };

    const result = await service.loginWithGoogle('google-id-token', verifier);

    expect(result.user.id).toBe(registered.user.id);
  });

  it('loginWithGoogle rejects tokens the verifier turns down', async () => {
    const { service } = makeService();
    const verifier = { verify: async () => null };

    await expect(service.loginWithGoogle('bad-token', verifier)).rejects.toThrow(
      InvalidCredentialsError,
    );
  });

  it('deleteAccount removes the user so the credentials no longer work', async () => {
    const { repo, service } = makeService();
    const registered = await service.register('kai@example.com', 'password123');

    await service.deleteAccount(registered.user.id);

    expect(repo.users).toHaveLength(0);
    await expect(service.login('kai@example.com', 'password123')).rejects.toThrow(
      InvalidCredentialsError,
    );
  });

  it('deleteAccount is idempotent for an unknown id', async () => {
    const { service } = makeService();
    await expect(service.deleteAccount('does-not-exist')).resolves.toBeUndefined();
  });

  it('register starts a new account with no display name', async () => {
    const { service } = makeService();

    const result = await service.register('kai@example.com', 'password123');

    expect(result.user.name).toBeNull();
  });

  it('getProfile returns id/email/name and never the password hash', async () => {
    const { service } = makeService();
    const { user } = await service.register('kai@example.com', 'password123');

    const profile = await service.getProfile(user.id);

    expect(profile).toEqual({ id: user.id, email: 'kai@example.com', name: null });
    expect(profile).not.toHaveProperty('passwordHash');
  });

  it('getProfile returns null when the token names a deleted user', async () => {
    const { service } = makeService();
    await expect(service.getProfile('does-not-exist')).resolves.toBeNull();
  });

  it('updateProfile sets and trims the display name', async () => {
    const { service } = makeService();
    const { user } = await service.register('kai@example.com', 'password123');

    const profile = await service.updateProfile(user.id, { name: '  Kai X  ' });

    expect(profile.name).toBe('Kai X');
    expect((await service.getProfile(user.id))?.name).toBe('Kai X');
  });

  it('updateProfile clears the name when given a blank string', async () => {
    const { service } = makeService();
    const { user } = await service.register('kai@example.com', 'password123');
    await service.updateProfile(user.id, { name: 'Kai' });

    const profile = await service.updateProfile(user.id, { name: '   ' });

    expect(profile.name).toBeNull();
  });

  it('updateProfile leaves the name untouched when name is omitted', async () => {
    const { service } = makeService();
    const { user } = await service.register('kai@example.com', 'password123');
    await service.updateProfile(user.id, { name: 'Kai' });

    const profile = await service.updateProfile(user.id, {});

    expect(profile.name).toBe('Kai');
  });

  it('verifyToken rejects garbage and foreign-signed tokens', async () => {
    const { service } = makeService();
    const other = new AuthService(new MemoryUserRepo(), 'different-secret');
    const foreign = (await other.register('kai@example.com', 'password123')).token;

    expect(service.verifyToken('not-a-jwt')).toBeNull();
    expect(service.verifyToken(foreign)).toBeNull();
  });
});
