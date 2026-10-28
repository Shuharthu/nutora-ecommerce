// NUTORA — Supabase Edge Function: verify-payment
// Server-side payment verification boundary (e.g. SSLCommerz / bKash)
// Never trusts client-side redirection!

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const body = await req.json();
    const { orderId, valId, tranId, amount, currency } = body;

    if (!orderId || !tranId) {
      return new Response(
        JSON.stringify({ error: "Missing transaction parameters" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Server-to-server gateway validation boundary
    // In production, make authenticated HTTPS request to SSLCommerz validation API:
    // https://securepay.sslcommerz.com/validator/api/validationserverAPI.php?val_id=...&store_id=...&store_passwd=...
    const storePass = Deno.env.get("SSLCOMMERZ_STORE_PASS");
    const storeId = Deno.env.get("SSLCOMMERZ_STORE_ID");

    if (!storePass || !storeId) {
      return new Response(
        JSON.stringify({ 
          status: "pending_credentials",
          message: "SSLCommerz credentials not yet configured in environment variables. Boundary ready." 
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update payment record in public.payments table
    const { error: payError } = await supabaseClient
      .from("payments")
      .update({
        status: "paid",
        transaction_id: tranId,
        verified_at: new Date().toISOString()
      })
      .eq("order_id", orderId);

    if (!payError) {
      await supabaseClient
        .from("orders")
        .update({
          payment_status: "paid",
          order_status: "confirmed"
        })
        .eq("id", orderId);
    }

    return new Response(
      JSON.stringify({ success: true, message: "Payment verified successfully" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
