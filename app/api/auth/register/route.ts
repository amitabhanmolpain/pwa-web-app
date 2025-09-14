// POST /api/auth/register
// CONTRACT (backend implementer):
// Request JSON body: { name: string, email: string, phone?: string, password: string }
// Successful response (201): { id: string, email: string, name?: string }
// Error responses:
// 400 - missing fields or validation error
// 409 - email already exists
// 500 - server error

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}))

    if (!body.name || !body.email || !body.password) {
      return new Response(JSON.stringify({ error: 'name, email and password are required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const exampleResponse = {
      message: 'NOT_IMPLEMENTED',
      hint: 'Replace with real registration logic: validate, hash password, create user in DB, and return created user id.',
      received: { name: body.name, email: body.email },
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
