// POST /api/auth/register
// CONTRACT (backend implementer):
// Request JSON body: { name: string, email: string, phone?: string, password: string }
// Successful response (201): { id: string, email: string, name?: string }
// Error responses:
// 400 - missing fields or validation error
// 409 - email already exists
// 500 - server error

// app/api/auth/register/route.ts

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}))

    if (!body.name || !body.email || !body.password) {
      return new Response(JSON.stringify({ error: 'name, email and password are required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Forward request to Spring Boot backend
    const backendResponse = await fetch("${BASE_URL}/auth/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    })

    const data = await backendResponse.json()

    return new Response(JSON.stringify(data), {
      status: backendResponse.status,
      headers: { "Content-Type": "application/json" },
    })
  } catch (err) {
    console.error("Proxy error:", err)
    return new Response(JSON.stringify({ error: "internal_server_error" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    })
  }
}
