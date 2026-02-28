import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
    if (!RESEND_API_KEY) {
      return new Response(JSON.stringify({ error: "Missing RESEND_API_KEY" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { toEmail, toName, userName, userEmail, reason, message } = body ?? {};

    if (!toEmail || !reason || !message) {
      return new Response(
        JSON.stringify({ error: "Missing fields: toEmail/reason/message" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // ✅ IMPORTANTE: “from” tiene que ser un remitente válido en Resend
    // Si NO has verificado dominio, usa "onboarding@resend.dev"
    const from = "WalkPaws <onboarding@resend.dev>";

    const subject = `WalkPaws - Nuevo mensaje: ${reason}`;

    const html = `
      <h2>Nuevo mensaje para ${toName ?? "Refugio"}</h2>
      <p><b>Usuario:</b> ${userName ?? "Usuario"} (${userEmail ?? "sin email"})</p>
      <p><b>Motivo:</b> ${reason}</p>
      <p><b>Mensaje:</b></p>
      <p>${String(message).replace(/\n/g, "<br/>")}</p>
    `;

    const resendResp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from,
        to: [toEmail],
        subject,
        html,
        reply_to: userEmail ? [userEmail] : undefined,
      }),
    });

    const data = await resendResp.json();

    if (!resendResp.ok) {
      console.log("RESEND ERROR:", data);
      return new Response(JSON.stringify({ error: data }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true, resend: data }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    console.log("FUNCTION ERROR:", e);
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
