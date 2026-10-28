// NUTORA — Supabase Edge Function: admin-users
// Handles privileged user management using service-role key
// Only executable by callers with 'super_admin' role

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
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing auth header" }), { status: 401, headers: corsHeaders });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Verify caller is super_admin
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Invalid user token" }), { status: 401, headers: corsHeaders });
    }

    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("*, user_roles(name)")
      .eq("id", user.id)
      .single();

    if (profile?.user_roles?.name !== "super_admin") {
      return new Response(JSON.stringify({ error: "Access denied. Super Admin role required." }), { status: 403, headers: corsHeaders });
    }

    const { action, email, roleName, fullName } = await req.json();

    if (action === "invite_editor") {
      const { data: inviteData, error: inviteErr } = await supabaseAdmin.auth.admin.inviteUserByEmail(email, {
        data: { full_name: fullName }
      });
      if (inviteErr) throw inviteErr;

      // Assign requested role
      const { data: roleRow } = await supabaseAdmin
        .from("user_roles")
        .select("id")
        .eq("name", roleName || "editor")
        .single();

      if (roleRow) {
        await supabaseAdmin
          .from("profiles")
          .update({ role_id: roleRow.id, full_name: fullName })
          .eq("id", inviteData.user.id);
      }

      return new Response(JSON.stringify({ success: true, user: inviteData.user }), { headers: corsHeaders });
    }

    return new Response(JSON.stringify({ error: "Unknown action" }), { status: 400, headers: corsHeaders });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: corsHeaders });
  }
});
