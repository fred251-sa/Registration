/* PostHog product analytics for the attendance register.
 *
 * Load this after assets/config.js and after the posthog-js browser bundle.
 * It stays inert while window.POSTHOG_KEY is empty, and it sends nothing until
 * the visitor accepts the consent notice on the page: declining leaves PostHog
 * opted out, so no cookie, no event and no person profile is created.
 *
 * The pages call it through window.attendanceAnalytics:
 *
 *   analytics.capture("check_in_completed", { student_id: id });
 *   analytics.identify("student:" + id, { role: "student" });
 *   analytics.reset();
 *
 * Student names are never sent. Only the student ID, which the register
 * itself uses to tell students apart, becomes the analytics person.
 */
(function () {
  "use strict";

  var KEY = window.POSTHOG_KEY || "";
  var HOST = window.POSTHOG_HOST || "https://us.i.posthog.com";
  var CONSENT_KEY = "it-attendance:analytics-consent";
  var BANNER_ID = "analyticsConsent";

  var ph = null;
  var consent = readConsent();
  var queue = [];

  function readConsent() {
    try {
      return window.localStorage.getItem(CONSENT_KEY);
    } catch (e) {
      return null;
    }
  }

  function writeConsent(value) {
    consent = value;
    try {
      window.localStorage.setItem(CONSENT_KEY, value);
    } catch (e) {
      /* Storage blocked: the choice lasts for this page only. */
    }
  }

  function capture(event, properties) {
    if (!ph || !event) return;
    if (consent !== "granted") {
      queue.push([event, properties || {}]);
      return;
    }
    ph.capture(event, properties || {});
  }

  function identify(id, properties) {
    if (!ph || !id || consent !== "granted") return;
    ph.identify(String(id), properties || {});
  }

  function reset() {
    if (!ph) return;
    ph.reset();
  }

  function flush() {
    var pending = queue;
    queue = [];
    pending.forEach(function (item) {
      ph.capture(item[0], item[1]);
    });
  }

  function accept() {
    writeConsent("granted");
    hideBanner();
    if (!ph) return;
    ph.opt_in_capturing();
    // The first pageview is skipped while opted out, so send it now.
    ph.capture("$pageview");
    flush();
  }

  function decline() {
    writeConsent("denied");
    queue = [];
    hideBanner();
  }

  function hideBanner() {
    var banner = document.getElementById(BANNER_ID);
    if (banner && banner.parentNode) banner.parentNode.removeChild(banner);
  }

  function showBanner() {
    if (document.getElementById(BANNER_ID) || !document.body) return;

    var banner = document.createElement("div");
    banner.id = BANNER_ID;
    banner.setAttribute("role", "region");
    banner.setAttribute("aria-label", "Analytics consent");
    banner.style.cssText = [
      "position:fixed",
      "left:16px",
      "right:16px",
      "bottom:16px",
      "z-index:80",
      "margin:0 auto",
      "max-width:460px",
      "padding:16px 16px 14px",
      "border-radius:16px",
      "border:1px solid rgba(148,163,184,.28)",
      "background:rgba(15,23,42,.96)",
      "box-shadow:0 24px 60px -24px rgba(0,0,0,.9)",
      "color:#e6edf7",
      "font-family:Inter, 'Segoe UI', system-ui, -apple-system, sans-serif",
      "font-size:12.5px",
      "line-height:1.55",
      "backdrop-filter:blur(18px)",
      "-webkit-backdrop-filter:blur(18px)"
    ].join(";");

    var text = document.createElement("p");
    text.style.cssText = "margin:0 0 12px;color:#cbd7e8";
    text.textContent = "Allow anonymous usage analytics? This site uses PostHog to see " +
      "how the check-in and admin pages are used. Student names are never sent, and " +
      "nothing is collected unless you allow it.";

    var row = document.createElement("div");
    row.style.cssText = "display:flex;gap:8px;justify-content:flex-end;flex-wrap:wrap";

    var no = document.createElement("button");
    no.type = "button";
    no.textContent = "No thanks";
    no.style.cssText = [
      "font:inherit",
      "font-weight:700",
      "padding:9px 14px",
      "border-radius:10px",
      "border:1px solid rgba(148,163,184,.28)",
      "background:transparent",
      "color:#cbd7e8",
      "cursor:pointer"
    ].join(";");
    no.addEventListener("click", decline);

    var yes = document.createElement("button");
    yes.type = "button";
    yes.textContent = "Allow analytics";
    yes.style.cssText = [
      "font:inherit",
      "font-weight:700",
      "padding:9px 14px",
      "border-radius:10px",
      "border:1px solid transparent",
      "background:linear-gradient(135deg,#22d3ee 0%,#38bdf8 55%,#818cf8 100%)",
      "color:#04121c",
      "cursor:pointer"
    ].join(";");
    yes.addEventListener("click", accept);

    row.appendChild(no);
    row.appendChild(yes);
    banner.appendChild(text);
    banner.appendChild(row);
    document.body.appendChild(banner);
  }

  function start() {
    if (!KEY) return;
    if (typeof window.posthog === "undefined" || typeof window.posthog.init !== "function") {
      return;
    }

    ph = window.posthog;

    ph.init(KEY, {
      api_host: HOST,
      defaults: "2025-05-24",
      person_profiles: "identified_only",
      // The register holds attendance records, so session recording stays off.
      disable_session_recording: true,
      opt_out_capturing_by_default: consent !== "granted"
    });

    if (consent === "granted") flush();
    else if (consent !== "denied") showBanner();
  }

  window.attendanceAnalytics = {
    capture: capture,
    identify: identify,
    reset: reset,
    accept: accept,
    decline: decline
  };

  start();
})();
