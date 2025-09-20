"use client"

import type React from "react"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { Loader2 } from "lucide-react"

interface AuthGuardProps {
  children: React.ReactNode
}

export function AuthGuard({ children }: AuthGuardProps) {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null)
  const router = useRouter()

  useEffect(() => {
    const checkAuth = async () => {
      try {
        // First attempt to validate via API (session cookie)
        const response = await fetch('/api/auth/validate', {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
        });

        const data = await response.json();
        
        if (response.ok && data.valid) {
          setIsAuthenticated(true);
          return;
        }
        
        // Fallback to localStorage during transition to API auth
        const user = localStorage.getItem("user");
        if (user) {
          const userData = JSON.parse(user);
          setIsAuthenticated(userData.isAuthenticated || false);
        } else {
          setIsAuthenticated(false);
        }
      } catch {
        // If API fails, fallback to localStorage
        try {
          const user = localStorage.getItem("user");
          if (user) {
            const userData = JSON.parse(user);
            setIsAuthenticated(userData.isAuthenticated || false);
          } else {
            setIsAuthenticated(false);
          }
        } catch {
          setIsAuthenticated(false);
        }
      }
    };

    checkAuth();
  }, [])

  useEffect(() => {
    if (isAuthenticated === false) {
      router.push("/login")
    }
  }, [isAuthenticated, router])

  if (isAuthenticated === null) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    )
  }

  if (!isAuthenticated) {
    return null
  }

  return <>{children}</>
}
