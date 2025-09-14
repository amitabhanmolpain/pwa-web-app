// POST /api/auth/logout
// CONTRACT (backend implementer):
// Invalidate session (clear server-side session or clear cookie).
// Successful response (200): { success: true }
// 500 - server error

export async function POST(req: Request) {
  try {
    // Stub: perform logout (clear cookie / invalidate token)
    const exampleResponse = { message: 'NOT_IMPLEMENTED', hint: 'Invalidate session and clear cookie.' }
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
