import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // /admin → 404 (Secret URL protection - R1 rule)
  if (pathname === '/admin') {
    return NextResponse.rewrite(new URL('/not-found', request.url));
  }

  // Baaki sab client-side handle karega
  return NextResponse.next();
}

export const config = {
  matcher: ['/admin'],
};
