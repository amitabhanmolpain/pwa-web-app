Auth API contract (server stub)

This folder contains stub API routes to guide backend implementation for authentication. Each route currently returns 501 and a small hint. Backend engineers should replace the stubs with real logic and adhere to the contract described below.

Endpoints

1) POST /api/auth/login
   - Request: JSON { email: string, password: string }
   - Success (200): { token: string, user: { id: string, email: string, name?: string } }
   - Errors: 400 (bad request), 401 (invalid credentials), 500
   - Notes: Prefer returning HTTP-only secure cookies for session tokens. If returning bearer tokens, follow best practices (refresh token, expiry).

2) POST /api/auth/register
   - Request: JSON { name: string, email: string, phone?: string, password: string }
   - Success (201): { id: string, email: string, name?: string }
   - Errors: 400 (validation), 409 (email exists), 500

3) GET /api/auth/validate
   - Description: Validate the current request's session/cookie/token.
   - Success (200): { valid: true, user: { id: string, email: string, name?: string } }
   - Unauthorized (401): { valid: false }

4) POST /api/auth/logout
   - Description: Invalidate session (server-side) and clear cookie.
   - Success (200): { success: true }

5) POST /api/auth/google
   - Description: Handle Google OAuth authentication flow.
   - Direct access: Redirects user to Google OAuth consent screen.
   - Callback: Accepts Google token/code to validate and authenticate user.
   - Success (200): { user: { id: string, email: string, name: string } }
   - Errors: 400, 401, 500

Implementation notes
- Prefer HTTP-only, Secure cookies for session. If using JWT, set access token in cookie and issue refresh token (rotate on refresh).
- Return consistent error shapes: { error: string, details?: object }
- Add rate-limiting and brute-force protections on login/register endpoints.
- Validate input and enforce password strength requirements.
- Consider email verification for register flow.

Testing
- Provide example requests in Postman/Insomnia or automated integration tests.
