// Problem generator. Pure functions, no QML/DOM dependencies, so the same file
// runs inside the Omarchy shell (imported as a QML .js module) and under Node
// for the unit tests. The trailing module.exports block is a no-op in QML.
//
// generate(world, level, rng) -> {
//   world, level, op, operands:[...], text, answer, choices:[4 shuffled ints]
// }

function makeRng(seed) {
  // Mulberry32 — deterministic PRNG for tests. Returns a function like Math.random.
  var a = seed >>> 0;
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    var t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function randInt(rng, min, max) {
  return min + Math.floor(rng() * (max - min + 1));
}

function pick(rng, arr) {
  return arr[Math.floor(rng() * arr.length)];
}

function shuffle(rng, arr) {
  var a = arr.slice();
  for (var i = a.length - 1; i > 0; i--) {
    var j = Math.floor(rng() * (i + 1));
    var tmp = a[i]; a[i] = a[j]; a[j] = tmp;
  }
  return a;
}

function digits(n) {
  return { ones: n % 10, tens: Math.floor(n / 10) % 10 };
}

// ---- per-world operand generators -----------------------------------------

function addOperands(level, rng) {
  var a, b, c, guard;
  switch (level) {
    case 1: // sums to 5
      a = randInt(rng, 0, 5);
      b = randInt(rng, 0, 5 - a);
      if (a + b === 0) b = 1;
      return [a, b];
    case 2: // sums to 10
      a = randInt(rng, 1, 9);
      b = randInt(rng, 1, 10 - a);
      return [a, b];
    case 3: // sums to 20
      a = randInt(rng, 1, 19);
      b = randInt(rng, 1, 20 - a);
      return [a, b];
    case 4: // 2-digit + 1-digit
      return [randInt(rng, 10, 99), randInt(rng, 2, 9)];
    case 5: // 2-digit + 2-digit, no carrying
      for (guard = 0; guard < 200; guard++) {
        a = randInt(rng, 10, 89);
        b = randInt(rng, 10, 89);
        if (digits(a).ones + digits(b).ones <= 9 && digits(a).tens + digits(b).tens <= 9) return [a, b];
      }
      return [12, 13];
    case 6: // 2-digit + 2-digit, with carrying
      for (guard = 0; guard < 200; guard++) {
        a = randInt(rng, 15, 89);
        b = randInt(rng, 15, 89);
        if (digits(a).ones + digits(b).ones > 9) return [a, b];
      }
      return [17, 25];
    case 7: // three addends
      a = randInt(rng, 2, 20);
      b = randInt(rng, 2, 20);
      c = randInt(rng, 2, 20);
      return [a, b, c];
    default:
      return [randInt(rng, 1, 9), randInt(rng, 1, 9)];
  }
}

var WORLDS = {
  add: { op: "+", symbol: "+", operands: addOperands, apply: function (xs) { return xs.reduce(function (s, x) { return s + x; }, 0); } }
};

// ---- distractors ----------------------------------------------------------

function buildChoices(answer, operands, world, rng) {
  var candidates = [
    answer + 1, answer - 1, answer + 2, answer - 2,
    answer + 10, answer - 10
  ];
  // "wrong operation" trap: what you'd get subtracting instead of adding.
  if (world === "add" && operands.length === 2) {
    candidates.push(Math.abs(operands[0] - operands[1]));
  }
  // transposed digits of the answer (a classic slip)
  if (answer >= 10 && answer <= 98) {
    var d = digits(answer);
    candidates.push(d.ones * 10 + d.tens);
  }

  var seen = {};
  seen[answer] = true;
  var distractors = [];
  var ordered = shuffle(rng, candidates);
  for (var i = 0; i < ordered.length && distractors.length < 3; i++) {
    var v = ordered[i];
    if (v < 0 || !Number.isInteger(v) || seen[v]) continue;
    seen[v] = true;
    distractors.push(v);
  }
  // Fill any gap with fresh nearby values.
  var spread = 3;
  while (distractors.length < 3) {
    var v2 = answer + randInt(rng, -spread, spread);
    spread++;
    if (v2 < 0 || seen[v2]) continue;
    seen[v2] = true;
    distractors.push(v2);
  }

  return shuffle(rng, [answer].concat(distractors));
}

// ---- public API ----------------------------------------------------------

function generate(world, level, rng) {
  var r = rng || Math.random;
  var spec = WORLDS[world];
  if (!spec) throw new Error("unknown world: " + world);

  var operands = spec.operands(level, r);
  var answer = spec.apply(operands);
  var text = operands.join(" " + spec.symbol + " ");

  return {
    world: world,
    level: level,
    op: spec.op,
    operands: operands,
    text: text,
    answer: answer,
    choices: buildChoices(answer, operands, world, r)
  };
}

// Ten questions for one round. `seed` makes a round reproducible.
function buildRound(world, level, count, seed) {
  var r = (seed === undefined) ? Math.random : makeRng(seed);
  var n = count || 10;
  var out = [];
  for (var i = 0; i < n; i++) out.push(generate(world, level, r));
  return out;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = { generate: generate, buildRound: buildRound, makeRng: makeRng, WORLDS: WORLDS };
}
