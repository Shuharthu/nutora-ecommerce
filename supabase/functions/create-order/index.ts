// NUTORA — Supabase Edge Function: create-order
// Serves as trusted server-side boundary for order validation & placement

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
    const {
      customerName,
      phone,
      email,
      division,
      district,
      upazila,
      address,
      instructions,
      paymentMethod,
      couponCode,
      items,
      idempotencyKey
    } = body;

    // Validate inputs
    if (!customerName || !phone || !division || !district || !address || !items || items.length === 0) {
      return new Response(
        JSON.stringify({ error: "Missing required order fields" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Call trusted PostgreSQL stored procedure
    const { data, error } = await supabaseClient.rpc("create_order_transaction", {
      p_customer_name: customerName,
      p_customer_phone: phone,
      p_customer_email: email || null,
      p_division: division,
      p_district: district,
      p_upazila: upazila,
      p_address: address,
      p_instructions: instructions || null,
      p_payment_method: paymentMethod || "cod",
      p_coupon_code: couponCode || null,
      p_items: items,
      p_idempotency_key: idempotencyKey || null
    });

    if (error) {
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify(data),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
