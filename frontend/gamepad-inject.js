(function () {
  if (window.BMO_PAD) {
    console.log('[BMO] Virtual gamepad ja injetado');
    return;
  }

  var _btns = [];
  for (var i = 0; i < 17; i++) {
    _btns.push({ pressed: false, touched: false, value: 0 });
  }
  var _axes = [0, 0, 0, 0];
  var _ts = performance.now();
  var _lastServerTs = 0;

  var _pad = {
    id: 'R36S Virtual Gamepad (BMO Emulator)',
    index: 0,
    connected: true,
    get timestamp() { return _ts; },
    mapping: '',
    axes: _axes,
    buttons: _btns
  };

  try {
    Object.defineProperty(navigator, 'getGamepads', {
      value: function () { return [_pad]; },
      configurable: true,
      writable: true
    });
  } catch (e) {
    navigator.getGamepads = function () { return [_pad]; };
  }

  // Poll server relay for cross-portal button events
  function pollServer() {
    fetch('http://localhost:8360/gamepad-state', { cache: 'no-store' })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (d.ts !== _lastServerTs) {
          _lastServerTs = d.ts;
          for (var i = 0; i < Math.min(d.buttons.length, _btns.length); i++) {
            _btns[i].pressed = d.buttons[i].pressed;
            _btns[i].value = d.buttons[i].value;
          }
          for (var j = 0; j < Math.min(d.axes.length, _axes.length); j++) {
            _axes[j] = d.axes[j];
          }
          _ts = performance.now();
        }
      })
      .catch(function () {});
    setTimeout(pollServer, 50);
  }
  pollServer();

  // Direct API (Lumina via evaluate — bypasses server relay)
  window.BMO_PAD = {
    press: function (btn, ms) {
      if (_btns[btn]) {
        _btns[btn].pressed = true;
        _btns[btn].value = 1;
      }
      _ts = performance.now();
      var self = this;
      if (ms === undefined) ms = 120;
      if (ms > 0) setTimeout(function () { self.release(btn); }, ms);
    },
    release: function (btn) {
      if (_btns[btn]) {
        _btns[btn].pressed = false;
        _btns[btn].value = 0;
      }
      _ts = performance.now();
    },
    tap: function (btn) { this.press(btn, 120); },
    axis: function (i, v) {
      if (_axes[i] !== undefined) _axes[i] = v;
      _ts = performance.now();
    }
  };

  // Keyboard → gamepad (para controle manual no BMO Preview)
  var KB = {
    'ArrowUp': 13, 'ArrowDown': 14, 'ArrowLeft': 15, 'ArrowRight': 16,
    'z': 0, 'Z': 0,
    'x': 1, 'X': 1,
    'a': 3, 'A': 3,
    's': 2, 'S': 2,
    'q': 4, 'Q': 4,
    'e': 5, 'E': 5,
    'Enter': 9,
    'f': 10, 'F': 10
  };
  var _held = {};
  window.addEventListener('keydown', function (ev) {
    var btn = KB[ev.key];
    if (btn === undefined || _held[btn]) return;
    _held[btn] = true;
    window.BMO_PAD.press(btn, 0);
  });
  window.addEventListener('keyup', function (ev) {
    var btn = KB[ev.key];
    if (btn === undefined) return;
    _held[btn] = false;
    window.BMO_PAD.release(btn);
  });

  try {
    window.dispatchEvent(new GamepadEvent('gamepadconnected', { gamepad: _pad }));
  } catch (e) {}

  console.log('[BMO] Virtual gamepad OK — BMO_PAD, poll HTTP e teclado ativos.');
})();
