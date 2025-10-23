/// <reference lib="deno.ns" />

import { createClient } from "npm:@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

interface Test {
  text: string;
  profile_id: string;
  name: string;
}

interface WebhookPayload {
  type: "INSERT";
  table: string;
  record: Test;
  schema: "public";
  old_record: null | Test;
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json();

  const { data } = await supabase
    .from("profiles")
    .select("fcm_token")
    .eq("id", payload.record.profile_id) // fixed typo 'if' → 'id'
    .single();

  const fcmToken = data!.fcm_token as string;

  const { default: serviceAccount } = await import("../service-account.json", {
    assert: { type: "json" },
  });

  const accessToken = await getAccessToken(serviceAccount);

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: "Test",
            body: "TEST",
          },
        },
      }),
    },
  );

  const resData = await res.json();

  if (res.status < 200 || res.status > 299) {
    return new Response(JSON.stringify(resData), {
      status: res.status,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify(data), {
    headers: { "Content-Type": "application/json" },
  });
});

const getAccessToken = (serviceAccount: any): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });

    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err);
        return;
      }
      resolve(tokens!.access_token!);
    });
  });
};
