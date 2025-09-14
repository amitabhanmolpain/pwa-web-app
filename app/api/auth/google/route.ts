// POST /api/auth/google
// CONTRACT (backend implementer):
// Description: Endpoint to initiate or complete Google OAuth authentication.
// When called directly: Redirect to Google OAuth consent screen.
// When called with token from OAuth callback: validate with Google and create/login user.
// Request body (for callback): { token: string, code: string }
// Successful response: { user: { id: string, email: string, name: string } }
// Error responses: 400, 401, 500

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}))
    
    // This route can be called in two ways:
    // 1. Direct browser redirect to start OAuth (no body needed)
    // 2. With Google auth code/token to complete authentication
    
    if (body.token || body.code) {
      // Phase 2: Complete authentication with Google token/code
      const exampleResponse = {
        message: 'NOT_IMPLEMENTED',
        hint: 'Validate token with Google, find or create user, and set auth cookie.'
      }
      
      return new Response(JSON.stringify(exampleResponse), {
        status: 501,
        headers: { 'Content-Type': 'application/json' },
      })
    } else {
      // Phase 1: Initiate OAuth flow
      // In production: Generate OAuth URL with proper scopes and state
      const exampleResponse = {
        message: 'NOT_IMPLEMENTED',
        hint: 'Redirect to Google OAuth URL with proper scopes, state, and redirect URI.'
      }
      
      return new Response(JSON.stringify(exampleResponse), {
        status: 501,
        headers: { 'Content-Type': 'application/json' },
      })
    }
  } catch (err) {
    console.error('Google auth error:', err)
    return new Response(JSON.stringify({ error: 'internal_server_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
}