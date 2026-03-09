import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const token = request.cookies.get("pr_token")?.value;
  const role = request.cookies.get("pr_role")?.value;

  // /admin → 404 (Secret URL protection - R1 rule)
  if (pathname === "/admin") {
    return NextResponse.rewrite(new URL("/not-found", request.url));
  }

  // Protected: /dashboard → student only
  if (pathname.startsWith("/dashboard")) {
    if (!token || role !== "student") {
      return NextResponse.redirect(new URL("/login", request.url));
    }
  }

  // Protected: /admin/x7k2p → admin/superadmin only
  if (pathname.startsWith("/admin/x7k2p")) {
    if (!token || (role !== "admin" && role !== "superadmin")) {
      return NextResponse.redirect(new URL("/login", request.url));
    }
  }

  // Protected: /superadmin → superadmin only
  if (pathname.startsWith("/superadmin")) {
    if (!token || role !== "superadmin") {
      return NextResponse.redirect(new URL("/login", request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/dashboard/:path*", "/admin/:path*", "/superadmin/:path*"],
};
