import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

for (const file of ['frontend/index.html', 'frontend/index.bmo-next.html']) {
  const html = fs.readFileSync(file, 'utf8');
  const scripts = [...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)];
  for (const match of scripts) new vm.Script(match[1], {filename: file});

  const start = html.indexOf('    const BMO_WIFI_KEYBOARD = {');
  const end = html.indexOf('\n    };', start);
  assert(start >= 0 && end > start, `${file}: keyboard source missing`);
  const source = html.slice(start, end + '\n    };'.length);
  const keyboard = vm.runInNewContext(`(() => { ${source}; return BMO_WIFI_KEYBOARD; })()`);
  keyboard.render = () => {};
  keyboard.visible = true;

  const all = new Set();
  for (const page of ['upper', 'lower', 'symbols']) {
    keyboard.page = page;
    assert.equal(keyboard.chars.length, 50, `${file}: ${page} grid length`);
    for (const char of keyboard.chars) all.add(char);
  }
  for (let code = 32; code <= 126; code++) {
    assert(all.has(String.fromCharCode(code)), `${file}: missing ASCII ${code}`);
  }

  keyboard.page = 'upper';
  keyboard.letterPage = 'upper';
  keyboard.index = 50;
  keyboard.activate();
  assert.equal(keyboard.page, 'lower', `${file}: lowercase toggle`);
  keyboard.index = 51;
  keyboard.activate();
  assert.equal(keyboard.page, 'symbols', `${file}: symbols toggle`);
  keyboard.activate();
  assert.equal(keyboard.page, 'lower', `${file}: return to letters`);

  const reachable = new Set();
  for (let col = 0; col < 10; col++) {
    keyboard.index = 40 + col;
    keyboard.down();
    reachable.add(keyboard.index - 50);
    keyboard.up();
    assert(keyboard.index >= 40 && keyboard.index < 50);
  }
  assert.deepEqual([...reachable].sort(), [0, 1, 2, 3, 4, 5]);
  console.log(`${file}: syntax, ASCII coverage, page toggle, six actions OK`);
}
