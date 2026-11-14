(function () {
  if (window.BMO_PAD) {
    console.log('[BMO] Virtual gamepad ja injetado');
    return;
  }

  // Portal do Maestri sem foco deixa o requestAnimationFrame em ~1 fps (timers nao
  // sofrem isso), o que atrasa o poll() do app e perde toques. No Preview, rAF vira
  // timer de 16 ms. Para usar o rAF nativo: acrescente ?raf=native na URL.
  if (!/[?&]raf=native/.test(location.search)) {
    window.requestAnimationFrame = function (cb) {
      return setTimeout(function () { cb(performance.now()); }, 16);
    };
    window.cancelAnimationFrame = function (id) { clearTimeout(id); };
  }

  var N = 17;
  var MIN_READS = 2;      // leituras distintas do app antes de soltar o botao
  var MAX_HOLD_MS = 4000; // solta mesmo sem leitura (aba oculta, app parado)

  var _btns = [];
  var _want = [];   // estado desejado (relay, teclado ou API)
  var _seen = [];   // leituras distintas que ja viram o botao pressionado
  var _since = [];  // instante em que o botao ficou visivel
  for (var i = 0; i < N; i++) {
    _btns.push({ pressed: false, touched: false, value: 0 });
    _want.push(false);
    _seen.push(0);
    _since.push(0);
  }
  var _axes = [0, 0, 0, 0];
  var _ts = performance.now();
  var _lastServerTs = 0;
  var _lastRead = 0;

  var _pad = {
    id: 'R36S Virtual Gamepad (BMO Emulator)',
    index: 0,
    connected: true,
    get timestamp() { return _ts; },
    mapping: '',
    axes: _axes,
    buttons: _btns
  };

  // Um toque curto nao pode passar entre dois frames do poll() do app (rAF pode
  // ficar lento em portal em segundo plano): o botao so e solto depois que o app o leu.
  function applyRelease(i, now) {
    if (_btns[i].pressed && !_want[i] &&
        (_seen[i] >= MIN_READS || now - _since[i] > MAX_HOLD_MS)) {
      _btns[i].pressed = false;
      _btns[i].value = 0;
      _ts = now;
    }
  }

  function setBtn(i, pressed) {
    if (!_btns[i]) return;
    var now = performance.now();
    _want[i] = pressed;
    if (pressed) {
      if (!_btns[i].pressed) {
        _btns[i].pressed = true;
        _btns[i].value = 1;
        _seen[i] = 0;
        _since[i] = now;
      }
      _ts = now;
    } else {
      applyRelease(i, now);
    }
  }

  function readPads() {
    var now = performance.now();
    if (now - _lastRead >= 8) { // um "frame" distinto do app
      _lastRead = now;
      for (var k = 0; k < N; k++) applyRelease(k, now);
      for (var m = 0; m < N; m++) if (_btns[m].pressed) _seen[m]++;
    }
    return [_pad];
  }

  try {
    Object.defineProperty(navigator, 'getGamepads', {
      value: readPads,
      configurable: true,
      writable: true
    });
  } catch (e) {
    navigator.getGamepads = readPads;
  }

  // Segura soltura pendente mesmo se o app nunca ler (aba oculta)
  setInterval(function () {
    var now = performance.now();
    for (var k = 0; k < N; k++) applyRelease(k, now);
  }, 250);

  // Poll do relay (mesma origem, qualquer porta)
  function pollServer() {
    fetch('/gamepad-state', { cache: 'no-store' })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (d.ts !== _lastServerTs) {
          _lastServerTs = d.ts;
          for (var b = 0; b < Math.min(d.buttons.length, N); b++) {
            setBtn(b, !!d.buttons[b].pressed);
          }
          for (var j = 0; j < Math.min(d.axes.length, _axes.length); j++) {
            _axes[j] = d.axes[j];
          }
          _ts = performance.now();
        }
      })
      .catch(function () {});
    setTimeout(pollServer, 40);
  }
  pollServer();

  // API direta (Lumina via evaluate; ignora o relay)
  window.BMO_PAD = {
    press: function (btn, ms) {
      setBtn(btn, true);
      var self = this;
      if (ms === undefined) ms = 120;
      if (ms > 0) setTimeout(function () { self.release(btn); }, ms);
    },
    release: function (btn) { setBtn(btn, false); },
    tap: function (btn) { this.press(btn, 120); },
    axis: function (i, v) {
      if (_axes[i] !== undefined) _axes[i] = v;
      _ts = performance.now();
    }
  };

  // Teclado do PC -> gamepad (controle manual no BMO Preview)
  var KB = {
    'ArrowUp': 13, 'ArrowDown': 14, 'ArrowLeft': 15, 'ArrowRight': 16,
    'z': 0, 'Z': 0,
    'x': 1, 'X': 1,
    'a': 3, 'A': 3,
    's': 2, 'S': 2,
    'q': 4, 'Q': 4,
    'e': 5, 'E': 5,
    'Backspace': 8,
    'Enter': 9,
    'f': 10, 'F': 10
  };
  var _held = {};
  function typing(ev) {
    var t = ev.target;
    return !!t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable);
  }
  window.addEventListener('keydown', function (ev) {
    var btn = KB[ev.key];
    if (btn === undefined || _held[btn] || typing(ev)) return;
    _held[btn] = true;
    window.BMO_PAD.press(btn, 0);
  });
  window.addEventListener('keyup', function (ev) {
    var btn = KB[ev.key];
    if (btn === undefined || !_held[btn]) return;
    _held[btn] = false;
    window.BMO_PAD.release(btn);
  });

  try {
    window.dispatchEvent(new GamepadEvent('gamepadconnected', { gamepad: _pad }));
  } catch (e) {}

  console.log('[BMO] Virtual gamepad OK: BMO_PAD, relay HTTP e teclado ativos.');
})();
