import axios from 'axios'

const TOKEN_KEY = 'ebook_token'
const REFRESH_KEY = 'ebook_refresh_token'
const DEVICE_ID_KEY = 'ebook_device_id'
const LOGGED_OUT_KEY = 'ebook_logged_out'

export const AUTH_BASE = import.meta.env.VITE_AUTH_BASE || 'https://device-api.expotoworld.com'

// ── Device ID ───────────────────────────────────────────────────────────────
// A persistent, client-generated UUID stored in localStorage.
// Much more stable than IP+UA hashing because it survives network changes,
// VPN toggling, and ISP rotations — only lost on explicit storage clear.

function generateUUID(): string {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) return crypto.randomUUID()
  // Fallback for older browsers
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
    const r = (Math.random() * 16) | 0
    return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16)
  })
}

export function getDeviceId(): string {
  let id = localStorage.getItem(DEVICE_ID_KEY)
  if (!id) {
    id = generateUUID()
    localStorage.setItem(DEVICE_ID_KEY, id)
  }
  return id
}

// ── Token storage (localStorage as fallback alongside httpOnly cookies) ──────

export function getAccessToken(): string | null {
  try { return JSON.parse(localStorage.getItem(TOKEN_KEY) || 'null')?.token || null } catch { return null }
}
export function setAccessToken(token: string, expires_at?: string) {
  localStorage.setItem(TOKEN_KEY, JSON.stringify({ token, expires_at }))
  axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
}
export function getAccessTokenExp(): number | null {
  try { return new Date(JSON.parse(localStorage.getItem(TOKEN_KEY) || 'null')?.expires_at).getTime() || null } catch { return null }
}
export function getRefreshToken(): string | null {
  try { return JSON.parse(localStorage.getItem(REFRESH_KEY) || 'null')?.refresh_token || null } catch { return null }
}
export function getRefreshTokenExp(): number | null {
  try { return new Date(JSON.parse(localStorage.getItem(REFRESH_KEY) || 'null')?.refresh_expires_at).getTime() || null } catch { return null }
}
export function setRefreshToken(refresh_token: string, refresh_expires_at?: string) {
  localStorage.setItem(REFRESH_KEY, JSON.stringify({ refresh_token, refresh_expires_at }))
}
export function clearTokens() {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(REFRESH_KEY)
  // NOTE: Device ID is intentionally NOT cleared — it identifies the device across sessions
}

// ── Explicit-logout flag ────────────────────────────────────────────────────
// Prevents the visibilitychange listener from resurrecting a session via the
// httpOnly cookie after the user intentionally logged out.

export function setLoggedOut() { localStorage.setItem(LOGGED_OUT_KEY, '1') }
export function wasExplicitlyLoggedOut(): boolean { return localStorage.getItem(LOGGED_OUT_KEY) === '1' }
export function clearLoggedOutFlag() { localStorage.removeItem(LOGGED_OUT_KEY) }

/**
 * Full logout: revoke refresh token on backend, clear httpOnly cookie,
 * clear localStorage tokens, and set the explicit-logout flag.
 */
export async function logout(): Promise<void> {
  const rt = getRefreshToken()
  try {
    await axios.post(
      `${AUTH_BASE}/api/v1/auth/logout`,
      rt ? { refresh_token: rt } : {},
      {
        withCredentials: true, // ensures httpOnly cookie is sent & cleared by backend
        headers: { 'X-Device-Id': getDeviceId() },
      }
    )
  } catch {
    // Best-effort: even if the backend call fails, proceed with client-side cleanup
  }
  // Ensure ALL cleanup steps run even if one fails (e.g. storage quota error)
  try { clearTokens() } catch {}
  try { setLoggedOut() } catch {}
  try { delete axios.defaults.headers.common['Authorization'] } catch {}
}

let isRefreshing = false
let waiters: { resolve: (t: string)=>void; reject: (e:any)=>void }[] = []

/**
 * Refresh access token with mutex protection.
 * Dual-source strategy:
 *   1. Sends refresh_token in JSON body (backward compatible, from localStorage)
 *   2. Browser also sends httpOnly cookie automatically (withCredentials: true)
 *   3. Backend checks body first, cookie second — whichever is present wins.
 *
 * This ensures session survives even if one storage mechanism is cleared.
 */
export async function refreshOnce(): Promise<string> {
  // Nuclear guard: never attempt refresh after explicit logout.
  // Without this, interceptors or auth-boot could resurrect a session via the httpOnly cookie.
  if (wasExplicitlyLoggedOut()) throw new Error('Session ended by user')

  if (isRefreshing) return new Promise((resolve,reject)=>waiters.push({resolve,reject}))
  isRefreshing = true
  try {
    const rt = getRefreshToken()

    // Check if the locally-stored refresh token is known-expired before network call
    const rtExp = getRefreshTokenExp()
    if (!rt && !rtExp) {
      // No localStorage token at all — still attempt refresh via cookie only
    } else if (rt && rtExp && rtExp < Date.now()) {
      // Locally stored token is expired — clear it, but still try cookie-based refresh
      clearTokens()
    }

    // Build request: include body token if available, always send cookie via withCredentials
    const res = await axios.post(
      `${AUTH_BASE}/api/v1/auth/refresh`,
      rt ? { refresh_token: rt } : {},
      {
        withCredentials: true, // sends httpOnly cookie
        headers: { 'X-Device-Id': getDeviceId() },
      }
    )

    const token = res.data?.access_token as string
    const expiresInSec = res.data?.expires_in as number || 900
    const tokenExp = new Date(Date.now() + expiresInSec * 1000).toISOString()

    // Use server-provided refresh metadata (ideal) or estimate from expires_in
    const newRt = res.data?.refresh_token as string | undefined
    const refreshExpiresAt = res.data?.refresh_expires_at as string | undefined
    const refreshExpiresIn = res.data?.refresh_expires_in as number | undefined
    const newRtExp = refreshExpiresAt
      || (refreshExpiresIn ? new Date(Date.now() + refreshExpiresIn * 1000).toISOString() : undefined)
      || (newRt ? new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString() : undefined)

    if (!token) throw new Error('Invalid refresh response')
    setAccessToken(token, tokenExp)
    if (newRt && newRtExp) setRefreshToken(newRt, newRtExp)
    waiters.forEach(w => w.resolve(token)); waiters = []
    return token
  } catch (e) {
    waiters.forEach(w => w.reject(e)); waiters = []
    clearTokens()
    throw e
  } finally {
    isRefreshing = false
  }
}

export function installAxiosInterceptors() {
  // Enable cookie-based auth globally for cross-origin requests to our API
  axios.defaults.withCredentials = true

  axios.interceptors.request.use(async (cfg) => {
    const url = typeof cfg.url === 'string' ? cfg.url : ''
    const isRefreshCall = url.includes('/api/v1/auth/refresh')

    // Always attach device ID for fingerprinting
    if (!cfg.headers) cfg.headers = {} as any
    ;(cfg.headers as any)['X-Device-Id'] = getDeviceId()

    // Proactively refresh if access token is very close to expiring (<10s)
    // IMPORTANT: never try to refresh while performing the refresh call itself to avoid deadlocks.
    if (!isRefreshCall && !wasExplicitlyLoggedOut()) {
      const exp = getAccessTokenExp()
      if (exp && exp - Date.now() < 10_000) {
        try { await refreshOnce() } catch {}
      }
    }

    // Attach Authorization except for refresh call (body carries refresh_token)
    if (!isRefreshCall) {
      const tok = getAccessToken()
      if (tok) {
        cfg.headers = cfg.headers || {}
        cfg.headers['Authorization'] = `Bearer ${tok}`
      }
    }
    return cfg
  })

  axios.interceptors.response.use(r => r, async (error) => {
    const original = error.config || {}
    const url = typeof original.url === 'string' ? original.url : ''
    const isRefreshCall = url.includes('/api/v1/auth/refresh')

    if (!isRefreshCall && error?.response?.status === 401 && !original?._retry && !wasExplicitlyLoggedOut()) {
      original._retry = true
      try {
        const newTok = await refreshOnce()
        original.headers = original.headers || {}
        original.headers['Authorization'] = `Bearer ${newTok}`
        return axios(original)
      } catch (e) {
        return Promise.reject(error)
      }
    }
    return Promise.reject(error)
  })
}

