/* Site-wide motion layer: vanilla ports of Magic UI / Aceternity patterns
   (blur-fade reveal, spotlight card, number ticker, marquee). No dependencies. */
(function () {
  var root = document.documentElement;
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  root.classList.add("fx");

  /* ---- Blur-fade reveal on scroll ---- */
  var revealSelectors = [
    ".section-head", ".value-card", ".achieve-card", ".case-card", ".service-card",
    ".process-card", ".stat-tile", ".post-card", ".team-card", ".ec-compare-col",
    ".admlist-group", ".director-card", ".booking-form", ".cta-banner", ".trust-head",
    ".dashboard-section", ".student-card", ".review-stats"
  ].join(",");

  function revealAll(nodes) {
    nodes.forEach(function (el) { el.classList.add("is-visible"); });
  }

  function setupReveal(scope) {
    var nodes = Array.prototype.slice.call((scope || document).querySelectorAll(revealSelectors))
      .filter(function (el) { return !el.classList.contains("reveal"); });
    nodes.forEach(function (el) {
      el.classList.add("reveal");
      var parent = el.parentElement;
      if (parent) {
        var siblings = Array.prototype.filter.call(parent.children, function (c) { return c.matches(revealSelectors); });
        var idx = siblings.indexOf(el);
        el.style.setProperty("--reveal-delay", Math.min(idx, 6) * 70 + "ms");
      }
    });
    if (!nodes.length) return;
    if (reduceMotion || !("IntersectionObserver" in window)) { revealAll(nodes); return; }
    var fired = false;
    var io = new IntersectionObserver(function (entries) {
      fired = true;
      entries.forEach(function (e) {
        if (e.isIntersecting) { e.target.classList.add("is-visible"); io.unobserve(e.target); }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    nodes.forEach(function (el) { io.observe(el); });
    // IO always delivers an initial callback; if it never does, never leave content hidden.
    setTimeout(function () { if (!fired) revealAll(nodes); }, 1500);
  }

  /* ---- Spotlight (mouse-follow glow) on cards ---- */
  var spotlightSelectors = ".value-card, .achieve-card, .case-card, .service-card, .post-card, .team-card, .student-card, .stat-tile, .review-card, .dashboard-section";
  document.addEventListener("pointermove", function (e) {
    var card = e.target.closest && e.target.closest(spotlightSelectors);
    if (!card) return;
    var r = card.getBoundingClientRect();
    card.style.setProperty("--mx", (e.clientX - r.left) + "px");
    card.style.setProperty("--my", (e.clientY - r.top) + "px");
  }, { passive: true });

  /* ---- Number ticker for stat tiles like "17년+", "1,000명+" ---- */
  function setupTickers() {
    var tiles = document.querySelectorAll(".stat-tile .value, [data-ticker]");
    tiles.forEach(function (el) {
      var m = el.textContent.match(/^(\D*)([\d,]+(?:\.\d+)?)(.*)$/);
      if (!m || el.dataset.tickerReady) return;
      el.dataset.tickerReady = "1";
      var prefix = m[1], suffix = m[3];
      var target = parseFloat(m[2].replace(/,/g, ""));
      var decimals = (m[2].split(".")[1] || "").length;
      var useComma = m[2].indexOf(",") !== -1;
      function fmt(v) {
        var s = v.toFixed(decimals);
        if (useComma) s = Number(s).toLocaleString("en-US", { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
        return prefix + s + suffix;
      }
      if (reduceMotion || !("IntersectionObserver" in window)) return;
      el.textContent = fmt(0);
      var io = new IntersectionObserver(function (entries) {
        if (!entries[0].isIntersecting) return;
        io.disconnect();
        var start = performance.now(), dur = 1400;
        (function tick(now) {
          var p = Math.min((now - start) / dur, 1);
          var eased = 1 - Math.pow(1 - p, 4);
          el.textContent = fmt(target * eased);
          if (p < 1) requestAnimationFrame(tick); else el.textContent = fmt(target);
        })(start);
      }, { threshold: 0.4 });
      io.observe(el);
    });
  }

  /* ---- Reviews marquee (data: window.SOOMGO_REVIEWS) ---- */
  function stars(n) {
    var s = "";
    for (var i = 0; i < 5; i++) s += '<span class="' + (i < n ? "on" : "") + '">★</span>';
    return s;
  }
  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  }
  function reviewCard(rv, i) {
    var card = el("button", "review-card");
    card.type = "button";
    card.dataset.idx = i;
    var head = el("div", "review-card-head");
    var avatar = el("span", "review-avatar", rv.n.charAt(0));
    var meta = el("div", "review-meta");
    meta.appendChild(el("strong", null, rv.n));
    meta.appendChild(el("span", null, rv.s + " · " + rv.d));
    var st = el("span", "review-stars");
    st.innerHTML = stars(rv.r);
    st.setAttribute("aria-label", "별점 " + rv.r + "점");
    head.appendChild(avatar); head.appendChild(meta);
    card.appendChild(head);
    card.appendChild(st);
    card.appendChild(el("p", "review-text", rv.t));
    return card;
  }

  function setupReviews() {
    var host = document.getElementById("review-marquee");
    var data = window.SOOMGO_REVIEWS;
    if (!host) return;
    var section = host.closest("section");
    if (!data || !data.length) { if (section) section.hidden = true; return; }

    var avg = data.reduce(function (a, r) { return a + r.r; }, 0) / data.length;
    var countEl = document.getElementById("review-count");
    var avgEl = document.getElementById("review-avg");
    if (countEl) countEl.textContent = data.length;
    if (avgEl) avgEl.textContent = avg.toFixed(1);

    var rows = 2;
    for (var r = 0; r < rows; r++) {
      var row = el("div", "marquee" + (r === 1 ? " marquee-slow" : ""));
      var track = el("div", "marquee-track");
      var items = data.filter(function (_, i) { return i % rows === r; });
      // two copies so the -50% translate loops seamlessly
      for (var copy = 0; copy < 2; copy++) {
        items.forEach(function (rv) {
          var c = reviewCard(rv, data.indexOf(rv));
          if (copy === 1) { c.setAttribute("aria-hidden", "true"); c.tabIndex = -1; }
          track.appendChild(c);
        });
      }
      track.style.setProperty("--marquee-duration", Math.round(items.length * 6.5) + "s");
      row.appendChild(track);
      host.appendChild(row);
    }

    var modal = document.getElementById("review-modal");
    host.addEventListener("click", function (e) {
      var card = e.target.closest(".review-card");
      if (!card || !modal) return;
      var rv = data[+card.dataset.idx];
      modal.querySelector(".rm-name").textContent = rv.n;
      modal.querySelector(".rm-meta").textContent = rv.s + " · " + rv.d;
      modal.querySelector(".rm-stars").innerHTML = stars(rv.r);
      modal.querySelector(".rm-text").textContent = rv.t;
      var tags = modal.querySelector(".rm-tags");
      tags.innerHTML = "";
      (rv.g || []).forEach(function (g) { tags.appendChild(el("span", "rm-tag", g)); });
      modal.classList.add("open");
      modal.querySelector(".rm-close").focus();
    });
    if (modal) {
      modal.addEventListener("click", function (e) {
        if (e.target === modal || e.target.closest(".rm-close")) modal.classList.remove("open");
      });
      document.addEventListener("keydown", function (e) {
        if (e.key === "Escape") modal.classList.remove("open");
      });
    }
  }

  /* ---- Logo marquees (합격 실적): right-to-left, slow, seamless ---- */
  function setupLogoMarquees() {
    document.querySelectorAll(".logo-marquee").forEach(function (host) {
      if (host.dataset.marqueeReady) return;
      host.dataset.marqueeReady = "1";
      var items = Array.prototype.slice.call(host.children);
      if (!items.length) return;
      var track = el("div", "marquee-track");
      // short groups are repeated so one copy is always wider than the screen
      var reps = Math.max(1, Math.ceil(14 / items.length));
      var set = [];
      for (var r = 0; r < reps; r++) {
        items.forEach(function (it) { set.push(r === 0 ? it : it.cloneNode(true)); });
      }
      set.forEach(function (it) { track.appendChild(it); });
      set.forEach(function (it) {
        var c = it.cloneNode(true);
        c.setAttribute("aria-hidden", "true");
        track.appendChild(c);
      });
      for (var i = items.length; i < set.length; i++) set[i].setAttribute("aria-hidden", "true");
      track.style.setProperty("--marquee-duration", Math.round(set.length * 3.4) + "s");
      host.innerHTML = "";
      host.appendChild(track);
    });
  }

  function setupHeader() {
    var header = document.querySelector(".site-header");
    if (!header) return;
    var onScroll = function () { header.classList.toggle("scrolled", window.scrollY > 8); };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
  }

  function init() {
    setupHeader();
    setupLogoMarquees();
    setupReviews();
    setupReveal();
    setupTickers();
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();

  // Dynamic content (Supabase-rendered lists) gets revealed as it arrives.
  window.fxRefresh = function () { setupReveal(); };
  if ("MutationObserver" in window) {
    var pending = null;
    new MutationObserver(function () {
      clearTimeout(pending);
      pending = setTimeout(setupReveal, 60);
    }).observe(document.body || root, { childList: true, subtree: true });
  }
})();
