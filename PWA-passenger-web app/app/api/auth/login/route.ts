// POST /api/auth/login
// CONTRACT (backend implementer):
// Request JSON body: { email: string, password: string }
// Successful response (200): { token: string, user: { id: string, email: string, name?: string } }
// Error responses:
// 400 - missing fields or validation error
// 401 - invalid credentials
// 500 - server error

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}))

    // Basic shape check (frontend may already do validation).
    if (!body.email || !body.password) {
      return new Response(JSON.stringify({ error: 'email and password are required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // This is a stub. Replace with real authentication (DB lookup + password verify).
    // Example successful response shape shown below.
    const exampleResponse = {
      message: 'NOT_IMPLEMENTED',
      hint: 'Replace this handler with real auth logic: verify credentials and return a signed token (HTTP-only cookie or bearer token).',
      received: { email: body.email },
    }

    return new Response(JSON.stringify(exampleResponse), {
      status: 501,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: 'internal_server_error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
}
