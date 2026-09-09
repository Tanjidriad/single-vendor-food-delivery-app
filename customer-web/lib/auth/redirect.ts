/** Only allow same-origin absolute paths after authentication. */
export function safeAuthRedirect(next?: string | null): string {
  return next && /^\/(?!\/)[^\\\r\n]*$/.test(next) ? next : "/";
}
