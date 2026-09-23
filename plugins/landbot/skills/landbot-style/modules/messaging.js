/* lb-js: messaging 0.3.4 — makes a Landbot v4 web chat behave like a messaging app.
   Pairs with messaging.css (append it to the look's CSS). Change only CONFIG below.
   What it does, all on the page and nothing else:
     1. stamps each bubble with the time it first appeared (data-lb-ts) and the first message with a
        day chip (data-lb-daychip); the CSS draws them from those attributes;
     2. shows reply buttons inside the bubble that asked, the way a messaging app does, and forwards
        each tap to the real (hidden) button, so the flow receives exactly what it would have;
     3. keeps a decorative composer bar in the footer on button turns, and flags "typing" so the
        CSS can show it under the header name.
   It only adds attributes, classes and its own elements; it never re-parents Landbot's nodes, never
   reads or sends answers, and on any error the plain chat keeps working (the CSS only styles what
   this script adds). Extracted from a verified messaging-look demo (2026-09-17/19) and re-checked on 2026-09-23. */
(function () {
  var CONFIG = {
    placeholder: 'Type a message', // the composer's placeholder, also used on question turns
    dayLabel: 'Today'              // the chip above the first message
  };
  try {
    if (window.__lbJsMessaging) return;
    var stats = window.__lbJsMessaging = { stamps: 0, restamped: 0, groupsBuilt: 0, reattached: 0, barPlaced: 0 };
    document.body.classList.add('lb-js-messaging');

    var pad = function (n) { return (n < 10 ? '0' : '') + n; };
    var hhmm = function () { var d = new Date(); return pad(d.getHours()) + ':' + pad(d.getMinutes()); };

    /* the decorative composer: shown only while the native input is gone (button turns) */
    var bar = document.createElement('div');
    bar.id = 'lb-msg-composer'; bar.setAttribute('aria-hidden', 'true');
    bar.innerHTML = '<div class="lb-msg-plus"></div><div class="lb-msg-pill"></div><div class="lb-msg-mic"></div>';
    bar.querySelector('.lb-msg-pill').textContent = CONFIG.placeholder;
    document.body.appendChild(bar);
    /* parked in the footer container, above the branding line, so it takes the thread's width at every
       viewport (position:fixed spans the whole window while the flow moves between blocks) */
    function placeBar() {
      var foot = document.querySelector('[data-lb-part="window"] > .responsive-container:last-child');
      if (!foot || bar.parentElement === foot) return;
      var brand = foot.querySelector('[data-lb-part="branding"]');
      var before = brand ? (brand.parentElement === foot ? brand : brand.closest('[data-lb-part="window"] > .responsive-container > *')) : null;
      if (before && before.parentElement === foot) foot.insertBefore(bar, before); else foot.appendChild(bar);
      stats.barPlaced++;
    }
    function syncComposer() {
      placeBar();
      var input = document.querySelector('[data-lb-part="input-field"] > input, [data-lb-part="input-field"] > textarea');
      document.body.classList.toggle('lb-msg-nocomposer', !input);
      document.body.classList.toggle('lb-msg-typing', !!document.querySelector('[aria-label="Conversation messages"] > span'));
      return input;
    }
    bar.addEventListener('click', function () {
      var i = document.querySelector('[data-lb-part="input-field"] > input, [data-lb-part="input-field"] > textarea');
      if (i) i.focus();
    });

    var tsByKey = {};
    var group = null, groupBubble = null, groupSig = '';
    var answered = []; /* answered button groups stay under their bubble; React may drop our node on re-render */
    var bubbleKey = function (b) { var t = b.querySelector('[data-lb-part="message-text"]'); return t ? t.textContent.trim() : ''; };
    var label = function (b) { return (b.textContent || '').trim(); };
    function lastBotBubble() {
      var ms = document.querySelectorAll('[data-lb-part="message"][data-lb-author="bot"]');
      for (var i = ms.length - 1; i >= 0; i--) {
        var b = ms[i].querySelector('[data-lb-part="message-bubble"]');
        if (b) return b;
      }
      return null;
    }
    function answer() {
      if (!group) return;
      group.setAttribute('data-state', 'answered');
      if (groupBubble) answered.push({ key: bubbleKey(groupBubble), node: group });
      var bs = group.querySelectorAll('.lb-msg-btn');
      for (var i = 0; i < bs.length; i++) bs[i].disabled = true;
      group = null; groupBubble = null; groupSig = '';
    }
    function reattach() {
      for (var i = 0; i < answered.length; i++) {
        var a = answered[i]; if (a.node.isConnected || !a.key) continue;
        var bs = document.querySelectorAll('[data-lb-part="message"][data-lb-author="bot"] [data-lb-part="message-bubble"]');
        for (var j = 0; j < bs.length; j++) {
          if (bs[j] !== groupBubble && !bs[j].querySelector('.lb-msg-buttons') && bubbleKey(bs[j]) === a.key) {
            bs[j].appendChild(a.node); bs[j].setAttribute('data-lb-msg-has-buttons', ''); stats.reattached++; break;
          }
        }
      }
    }
    function syncButtons() {
      var real = document.querySelectorAll('[data-lb-part="option-button"]');
      if (!real.length) { answer(); document.body.classList.remove('lb-msg-inline'); return; }
      var bubble = lastBotBubble();
      if (!bubble) { document.body.classList.remove('lb-msg-inline'); return; }
      var sig = [].map.call(real, label).join('\u0001');
      if (group && group.isConnected && groupBubble === bubble && groupSig === sig) { document.body.classList.add('lb-msg-inline'); return; }
      if (group && (groupBubble !== bubble || groupSig !== sig)) answer();
      var g = document.createElement('div');
      g.className = 'lb-msg-buttons';
      for (var i = 0; i < real.length; i++) {
        var row = document.createElement('div'); row.className = 'lb-msg-row';
        var btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'lb-msg-btn' + (real[i].querySelector('svg') ? ' lb-msg-link' : '');
        btn.textContent = label(real[i]);
        btn.addEventListener('click', function (e) {
          var want = e.currentTarget.textContent;
          var now = document.querySelectorAll('[data-lb-part="option-button"]');
          for (var k = 0; k < now.length; k++) if (label(now[k]) === want) { now[k].click(); return; }
        });
        row.appendChild(btn); g.appendChild(row);
      }
      bubble.appendChild(g);
      bubble.setAttribute('data-lb-msg-has-buttons', '');
      group = g; groupBubble = bubble; groupSig = sig; stats.groupsBuilt++;
      document.body.classList.add('lb-msg-inline');
    }

    var lastH = 0;
    function render() {
      try {
        var ts = hhmm();
        /* follow the newest bubble when late content grows the thread, unless the visitor scrolled up */
        var sc = document.querySelector('[aria-label="Scrollable conversation area"]');
        if (sc) { if (sc.scrollHeight > lastH && sc.scrollTop + sc.clientHeight >= lastH - 120) sc.scrollTop = sc.scrollHeight; lastH = sc.scrollHeight; }
        /* React re-creates some bubbles; remember each one's first-seen time by content so it never moves */
        var fresh = document.querySelectorAll('[data-lb-part="message-bubble"]:not([data-lb-ts]), [data-lb-part="media"]:not([data-lb-ts])');
        for (var k = 0; k < fresh.length; k++) {
          var m = fresh[k].closest('[data-lb-part="message"]'), img = fresh[k].querySelector('img');
          var key = (m ? m.getAttribute('data-lb-author') : '') + '|' + (fresh[k].getAttribute('data-lb-part') === 'media' ? (img ? img.src : '') : bubbleKey(fresh[k]));
          var seen = (key.length > 2) ? tsByKey[key] : null;
          if (seen) stats.restamped++; else { stats.stamps++; if (key.length > 2) tsByKey[key] = ts; }
          fresh[k].setAttribute('data-lb-ts', seen || ts);
        }
        var first = document.querySelector('[data-lb-part="message"]');
        if (first && !first.hasAttribute('data-lb-daychip')) first.setAttribute('data-lb-daychip', CONFIG.dayLabel);
        syncButtons();
        reattach();
        var input = syncComposer();
        if (input && input.getAttribute('placeholder') !== CONFIG.placeholder) input.setAttribute('placeholder', CONFIG.placeholder);
      } catch (e) { stats.error = String(e); }
    }
    render();
    setInterval(render, 400);
    /* v4 re-creates the footer between blocks; put the bar back in the same frame */
    try { new MutationObserver(function () { try { syncComposer(); } catch (e) { stats.error = String(e); } }).observe(document.body, { childList: true, subtree: true }); }
    catch (e) { stats.observer = String(e); }
  } catch (err) { window.__lbJsError = 'messaging: ' + String(err); }
})();
