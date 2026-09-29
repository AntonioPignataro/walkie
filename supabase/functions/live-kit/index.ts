import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// LiveKit token generation using JWT
// Based on LiveKit Server SDK protocol
const encoder = new TextEncoder();

async function createLiveKitToken(
  apiKey: string,
  apiSecret: string,
  roomName: string,
  identity: string,
): Promise<string> {
  // Create JWT header
  const header = {
    alg: "HS256",
    typ: "JWT",
  };

  // Create JWT payload with LiveKit claims
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: apiKey,
    sub: identity,
    iat: now,
    nbf: now,
    exp: now + 3600, // 1 hour expiry
    jti: identity + "-" + now,
    video: {
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    },
  };

  // Base64URL encode
  function base64UrlEncode(data: Uint8Array): string {
    const base64 = btoa(String.fromCharCode(...data));
    return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  }

  function strToBase64Url(str: string): string {
    return base64UrlEncode(encoder.encode(str));
  }

  const headerB64 = strToBase64Url(JSON.stringify(header));
  const payloadB64 = strToBase64Url(JSON.stringify(payload));
  const signingInput = `${headerB64}.${payloadB64}`;

  // Sign with HMAC-SHA256
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(apiSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(signingInput),
  );

  const signatureB64 = base64UrlEncode(new Uint8Array(signature));

  return `${signingInput}.${signatureB64}`;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    // Verify the user is authenticated
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    // Create Supabase client to verify the JWT
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } },
      );
    }

    // Parse request body
    const { roomName } = await req.json();
    if (!roomName) {
      return new Response(
        JSON.stringify({ error: "roomName is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // Get LiveKit credentials from env
    const livekitUrl = Deno.env.get("LIVEKIT_URL");
    const livekitApiKey = Deno.env.get("LIVEKIT_API_KEY");
    const livekitApiSecret = Deno.env.get("LIVEKIT_API_SECRET");

    if (!livekitUrl || !livekitApiKey || !livekitApiSecret) {
      console.error("Missing LiveKit environment variables");
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    // Generate LiveKit access token
    const token = await createLiveKitToken(
      livekitApiKey,
      livekitApiSecret,
      roomName,
      user.id,
    );

    return new Response(
      JSON.stringify({
        token,
        url: livekitUrl,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
  } catch (err) {
    console.error("Error generating token:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
  }
});
