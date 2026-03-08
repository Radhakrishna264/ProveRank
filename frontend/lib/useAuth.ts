"use client";
import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { getToken, getRole } from "./auth";

export function useAuth(requiredRole?: string | string[]) {
  const router = useRouter();

  useEffect(() => {
    const token = getToken();
    const role = getRole();

    if (!token) {
      if (requiredRole) {
        const isAdmin = Array.isArray(requiredRole)
          ? requiredRole.includes("admin") || requiredRole.includes("superadmin")
          : requiredRole === "admin" || requiredRole === "superadmin";
        router.replace(isAdmin ? "/admin/x7k2p" : "/login");
      }
      return;
    }

    if (requiredRole) {
      const allowed = Array.isArray(requiredRole)
        ? requiredRole.includes(role || "")
        : role === requiredRole;
      if (!allowed) {
        if (role === "student") router.replace("/dashboard");
        else if (role === "admin") router.replace("/admin/x7k2p");
        else if (role === "superadmin") router.replace("/superadmin");
        else router.replace("/login");
      }
    }
  }, [router, requiredRole]);
}
