import { NextRequest } from "next/server";

import { socketTokenResponse } from "@/lib/server/backend-proxy";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export function GET(request: NextRequest) {
  return socketTokenResponse(request);
}
