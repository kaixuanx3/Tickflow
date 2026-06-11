import { OAuth2Client } from 'google-auth-library';
import type { GoogleTokenVerifier } from '../services/auth-service.js';

/** Verifies Google ID tokens (signature, expiry, audience) via Google's public keys. */
export class GoogleAuthLibraryVerifier implements GoogleTokenVerifier {
  private readonly client: OAuth2Client;

  constructor(private readonly clientId: string) {
    this.client = new OAuth2Client(clientId);
  }

  async verify(idToken: string): Promise<{ email: string } | null> {
    try {
      const ticket = await this.client.verifyIdToken({ idToken, audience: this.clientId });
      const payload = ticket.getPayload();
      if (!payload?.email || !payload.email_verified) return null;
      return { email: payload.email };
    } catch {
      return null;
    }
  }
}
