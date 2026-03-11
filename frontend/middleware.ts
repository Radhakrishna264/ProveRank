import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl

  // Block ONLY the exact /admin route — NOT /admin/x7k2p or any sub-routes
  if (pathname === '/admin' || pathname === '/admin/') {
    return NextResponse.rewrite(new URL('/not-found', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: ['/admin', '/admin/'],
}
