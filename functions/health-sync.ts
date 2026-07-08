import { createAdminClient } from "npm:@insforge/sdk";

type HealthDayInput = {
  date: string;
  steps?: number;
  dietary_energy_kcal?: number;
  protein_g?: number;
  carbs_g?: number;
  fat_g?: number;
};

type HealthSyncPayload = {
  source?: string;
  timezone?: string;
  days?: HealthDayInput[];
};

type HealthDayRow = {
  date: string;
  timezone: string;
  steps: number;
  dietary_energy_kcal: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  source: string;
  synced_at: string;
};

type ExistingHealthDayRow = Pick<
  HealthDayRow,
  "dietary_energy_kcal" | "protein_g" | "carbs_g" | "fat_g"
> & {
  id: string;
};

export default async function(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (req.method !== "POST") {
    return jsonResponse({ ok: false, error: "Method not allowed" }, 405);
  }

  const configuredToken = requiredEnv("HEALTH_SYNC_TOKEN");
  const receivedToken = req.headers.get("x-health-sync-token");
  if (!receivedToken || receivedToken !== configuredToken) {
    return jsonResponse({ ok: false, error: "Unauthorized" }, 401);
  }

  let payload: HealthSyncPayload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ ok: false, error: "Invalid JSON body" }, 400);
  }

  try {
    const rows = validatePayload(payload);
    if (rows.length === 0) {
      return jsonResponse({ ok: false, error: "No health days supplied" }, 400);
    }

    const admin = createAdminClient({
      baseUrl: requiredEnv("INSFORGE_BASE_URL"),
      apiKey: requiredEnv("INSFORGE_API_KEY")
    });

    for (const row of rows) {
      const { data: existingRows, error: selectError } = await admin.database
        .from("health_daily_summaries")
        .select("id,dietary_energy_kcal,protein_g,carbs_g,fat_g")
        .eq("date", row.date)
        .eq("source", row.source)
        .limit(1);

      if (selectError) throw selectError;

      const existingRow = Array.isArray(existingRows) ? existingRows[0] as ExistingHealthDayRow | undefined : undefined;
      if (existingRow?.id) {
        const { error: updateError } = await admin.database
          .from("health_daily_summaries")
          .update(mergeHealthRowForUpdate(row, existingRow))
          .eq("id", existingRow.id);
        if (updateError) throw updateError;
      } else {
        const { error: insertError } = await admin.database
          .from("health_daily_summaries")
          .insert([row]);
        if (insertError) throw insertError;
      }
    }

    return jsonResponse({ ok: true, rows: rows.length });
  } catch (error) {
    return jsonResponse({ ok: false, error: errorMessage(error) }, 400);
  }
}

function validatePayload(payload: HealthSyncPayload): HealthDayRow[] {
  const source = cleanText(payload.source || "apple_health_ios", "source");
  const timezone = cleanText(payload.timezone || "UTC", "timezone");
  const syncedAt = new Date().toISOString();
  const days = Array.isArray(payload.days) ? payload.days : [];

  if (days.length > 45) {
    throw new Error("A sync request can include at most 45 days.");
  }

  return days.map((day) => ({
    date: cleanDate(day.date),
    timezone,
    steps: cleanInteger(day.steps ?? 0, "steps"),
    dietary_energy_kcal: cleanNumber(day.dietary_energy_kcal ?? 0, "dietary_energy_kcal"),
    protein_g: cleanNumber(day.protein_g ?? 0, "protein_g"),
    carbs_g: cleanNumber(day.carbs_g ?? 0, "carbs_g"),
    fat_g: cleanNumber(day.fat_g ?? 0, "fat_g"),
    source,
    synced_at: syncedAt
  }));
}

function mergeHealthRowForUpdate(row: HealthDayRow, existing: ExistingHealthDayRow): HealthDayRow {
  return {
    ...row,
    dietary_energy_kcal: preserveExistingNutrition(row.dietary_energy_kcal, existing.dietary_energy_kcal),
    protein_g: preserveExistingNutrition(row.protein_g, existing.protein_g),
    carbs_g: preserveExistingNutrition(row.carbs_g, existing.carbs_g),
    fat_g: preserveExistingNutrition(row.fat_g, existing.fat_g)
  };
}

function preserveExistingNutrition(incoming: number, existing: number | string): number {
  const existingNumber = Number(existing ?? 0);
  if (incoming === 0 && Number.isFinite(existingNumber) && existingNumber > 0) {
    return existingNumber;
  }
  return incoming;
}

function cleanText(value: string, field: string): string {
  const trimmed = String(value).trim();
  if (!trimmed || trimmed.length > 80) {
    throw new Error(`Invalid ${field}.`);
  }
  return trimmed;
}

function cleanDate(value: string): string {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(value))) {
    throw new Error("Invalid date.");
  }
  return value;
}

function cleanInteger(value: number, field: string): number {
  const numeric = Number(value);
  if (!Number.isFinite(numeric) || numeric < 0) {
    throw new Error(`Invalid ${field}.`);
  }
  return Math.round(numeric);
}

function cleanNumber(value: number, field: string): number {
  const numeric = Number(value);
  if (!Number.isFinite(numeric) || numeric < 0) {
    throw new Error(`Invalid ${field}.`);
  }
  return Math.round(numeric * 100) / 100;
}

function corsHeaders(): HeadersInit {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Health-Sync-Token"
  };
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(), "Content-Type": "application/json; charset=utf-8" }
  });
}

function requiredEnv(key: string): string {
  const value = Deno.env.get(key);
  if (!value) throw new Error(`Missing ${key}`);
  return value;
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
