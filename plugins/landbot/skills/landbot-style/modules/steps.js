/* lb-js: steps 0.3.4 — a form-style Landbot v4 web chat: a progress bar, "2 of 5", and letter keys.
   Pairs with steps.css (append it to the look's CSS). Change only CONFIG below.
   What it does, all on the page and nothing else:
     1. a thin bar at the top that fills as the visitor answers, with an optional "n of N" label;
     2. A, B, C… press the matching button when the visitor is not typing in a field.
   It counts the visitor's own answers on the page; it never reads their content or sends anything.
   On any error the plain chat keeps working. Extracted from the verified Typeform-style demo
   (channel 3512809, 2026-09-16). */
(function () {
  var CONFIG = {
    total: 5,                  // questions on the longest path, greeting included
    counter: true,             // show the "n of N" label
    counterText: '{n} of {total}',
    keys: true                 // letter keys pick buttons
  };
  try {
    if (window.__lbJsSteps) return;
    var stats = window.__lbJsSteps = { renders: 0 };
    document.body.classList.add('lb-js-steps');
    var total = Math.max(1, parseInt(CONFIG.total, 10) || 1);

    var bar = document.createElement('div');
    bar.id = 'lb-steps'; bar.setAttribute('aria-hidden', 'true');
    bar.innerHTML = '<div class="lb-steps-fill"></div><div class="lb-steps-label"></div>';
    document.body.appendChild(bar);
    var fill = bar.firstChild, lab = bar.lastChild;

    function render() {
      try {
        var answered = document.querySelectorAll('[data-lb-part="message"][data-lb-author="user"]').length;
        var done = Math.min(answered, total);
        fill.style.width = Math.round(done / total * 100) + '%';
        lab.textContent = CONFIG.counter ? CONFIG.counterText.replace('{n}', Math.min(done + 1, total)).replace('{total}', total) : '';
        stats.renders++;
      } catch (e) { stats.error = String(e); }
    }

    if (CONFIG.keys) {
      document.addEventListener('keydown', function (e) {
        try {
          var t = e.target;
          if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) return;
          if (e.metaKey || e.ctrlKey || e.altKey) return;
          var k = (e.key || '').toUpperCase();
          if (k.length !== 1 || k < 'A' || k > 'Z') return;
          var btns = document.querySelectorAll('[data-lb-part="option-button"]');
          var b = btns[k.charCodeAt(0) - 65];
          if (b) { b.click(); e.preventDefault(); }
        } catch (err) { stats.error = String(err); }
      }, true);
    }

    render();
    setInterval(render, 400);
  } catch (err) { window.__lbJsError = 'steps: ' + String(err); }
})();
