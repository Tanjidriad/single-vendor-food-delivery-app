import { useAuthStore } from "@/store/auth-store"

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1"

interface FetchOptions extends RequestInit {
  requireAuth?: boolean
}

export class ApiError extends Error {
  status: number
  data: any
  constructor(status: number, message: string, data?: any) {
    super(message)
    this.status = status
    this.data = data
  }
}

export async function fetchClient<T>(
  endpoint: string,
  options: FetchOptions = {}
): Promise<T> {
  const { requireAuth = true, ...customOptions } = options
  
  const headers = new Headers(customOptions.headers)
  headers.set("Content-Type", "application/json")

  if (requireAuth) {
    const token = useAuthStore.getState().token
    if (token) {
      headers.set("Authorization", `Bearer ${token}`)
    }
  }

  const config: RequestInit = {
    ...customOptions,
    headers,
  }

  const response = await fetch(`${API_BASE_URL}${endpoint}`, config)
  
  let data
  try {
    data = await response.json()
  } catch (err) {
    data = null
  }

  if (!response.ok) {
    if (response.status === 401) {
      useAuthStore.getState().logout()
    }
    
    throw new ApiError(response.status, data?.message || "API request failed", data)
  }

  return data as T
}
