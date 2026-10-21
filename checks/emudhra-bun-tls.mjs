// Run with Bun, or Pi's embedded Bun via BUN_BE_BUN=1. No custom tls.ca.
// SSL_CERT_FILE must be set before starting the process, if testing a bundle.
// Expected: 12 certificate rejections and one successful control per API.
import https from "node:https";

const badHosts = [];
for (const kind of ["dv", "ov", "ev"])
  for (const generation of ["g3b", "g3c"])
    for (const route of ["", "-aaa"])
      badHosts.push(`${kind}-${generation}${route}-emudhra.we-have-a-problem.com`);
const control = "emudhra.we-have-a-problem.com";
const certificateErrors = new Set([
  "CERT_REJECTED", "CERT_REVOKED", "CERT_UNTRUSTED", "INVALID_PURPOSE",
  "UNABLE_TO_GET_ISSUER_CERT", "UNABLE_TO_GET_ISSUER_CERT_LOCALLY",
  "UNABLE_TO_VERIFY_LEAF_SIGNATURE", "SELF_SIGNED_CERT_IN_CHAIN",
  "DEPTH_ZERO_SELF_SIGNED_CERT", "CERT_HAS_EXPIRED", "CERT_NOT_YET_VALID",
  "ERR_TLS_CERT_ALTNAME_INVALID",
]);
const clients = {
  fetch: async (host) => {
    const response = await fetch(`https://${host}/`, {
      signal: AbortSignal.timeout(15000), redirect: "manual",
    });
    await response.body?.cancel();
    return response.status;
  },
  https: (host) => new Promise((resolve, reject) => {
    const request = https.get(`https://${host}/`, (response) => {
      response.resume();
      resolve(response.statusCode);
    });
    request.setTimeout(15000, () => request.destroy(new Error("probe timeout")));
    request.on("error", reject);
  }),
};
let failures = 0;
for (const [name, request] of Object.entries(clients)) {
  for (const host of [control, ...badHosts]) {
    const isControl = host === control;
    try {
      const status = await request(host);
      const pass = isControl && status === 200;
      console.log(`${pass ? "PASS" : "FAIL"} ${name} ${host}: HTTP ${status}`);
      if (!pass) failures++;
    } catch (error) {
      const code = error.code ?? error.cause?.code;
      const pass = !isControl && certificateErrors.has(code);
      console.log(`${pass ? "PASS" : "FAIL"} ${name} ${host}: ${code ?? "INCONCLUSIVE"} ${error.message}`);
      if (!pass) failures++;
    }
  }
}
console.log(`RESULT: ${failures} failures`);
process.exitCode = failures ? 1 : 0;
