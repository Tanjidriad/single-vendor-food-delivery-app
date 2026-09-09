/**
 * Fetch with automatic retry for transient failures.
 * Only retries on network errors and 5xx responses; 4xx is returned immediately.
 */
export async function retryFetch(
  url: string,
  options: RequestInit,
  maxRetries = 2,
): Promise<Response> {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const res = await fetch(url, options);
      if (res.status < 500 || attempt === maxRetries) return res;
    } catch (err) {
      if (attempt === maxRetries) throw err;
    }
    await new Promise((r) => setTimeout(r, 1000 * (attempt + 1)));
  }
  throw new Error('retryFetch: unreachable');
}
