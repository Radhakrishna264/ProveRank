"use client";
import { useEffect } from "react";
import { isLoggedIn, getRole } from "@/lib/auth";
interface Props { children: React.ReactNode; allowedRoles?: string[]; }
export default function ProtectedRoute({ children, allowedRoles }: Props) {
  useEffect(()=>{
    if (!isLoggedIn()){ window.location.href="/login"; return; }
    if (allowedRoles&&!allowedRoles.includes(getRole()||"")) window.location.href="/login";
  },[allowedRoles]);
  return <>{children}</>;
}
