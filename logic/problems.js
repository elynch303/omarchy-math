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

function coin(rng) {
  return rng() < 0.5;
}

function orderPair(rng, a, b) {
  return coin(rng) ? [a, b] : [b, a];
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
    case 1: // sums to 5, both parts at least 1
      a = randInt(rng, 1, 4);
      b = randInt(rng, 1, 5 - a);
      return [a, b];
    case 2: // sums to 10, kept fairly even so the balance pans stay small
      a = randInt(rng, 2, 6);
      b = randInt(rng, 2, 10 - a);
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

function subOperands(level, rng) {
  var a, b, c, guard;
  switch (level) {
    // take at least 1 away, leave at least 1 behind
    case 1: a = randInt(rng, 2, 5); b = randInt(rng, 1, a - 1); return [a, b];
    case 2: a = randInt(rng, 4, 9); b = randInt(rng, 1, Math.min(a - 1, 6)); return [a, b];
    case 3: a = randInt(rng, 6, 20); b = randInt(rng, 1, a - 1); return [a, b];
    case 4: a = randInt(rng, 20, 99); b = randInt(rng, 2, 9); return [a, b];
    case 5: // 2-digit − 2-digit, no borrowing
      for (guard = 0; guard < 200; guard++) {
        a = randInt(rng, 23, 98);
        b = randInt(rng, 11, a - 1);
        if (digits(a).ones >= digits(b).ones && digits(a).tens >= digits(b).tens) return [a, b];
      }
      return [58, 23];
    case 6: // 2-digit − 2-digit, with borrowing
      for (guard = 0; guard < 200; guard++) {
        a = randInt(rng, 22, 98);
        b = randInt(rng, 11, a - 1);
        if (digits(b).ones > digits(a).ones && digits(a).tens > digits(b).tens) return [a, b];
      }
      return [52, 27];
    case 7: // a − b − c, never below zero
      a = randInt(rng, 12, 20);
      b = randInt(rng, 1, Math.floor(a / 2));
      c = randInt(rng, 1, a - b);
      return [a, b, c];
    default:
      a = randInt(rng, 1, 9); return [a, randInt(rng, 0, a)];
  }
}

function mulOperands(level, rng) {
  switch (level) {
    case 1: return orderPair(rng, pick(rng, [1, 2]), randInt(rng, 1, 10));
    case 2: return orderPair(rng, pick(rng, [2, 5, 10]), randInt(rng, 1, 10));
    case 3: return orderPair(rng, pick(rng, [3, 4]), randInt(rng, 1, 10));
    case 4: return orderPair(rng, pick(rng, [6, 7, 8, 9]), randInt(rng, 2, 10));
    case 5: return [randInt(rng, 2, 12), randInt(rng, 2, 12)];
    case 6: return [randInt(rng, 11, 25), randInt(rng, 2, 9)];
    case 7: return [randInt(rng, 2, 5), randInt(rng, 2, 5), randInt(rng, 2, 5)];
    default: return [randInt(rng, 1, 9), randInt(rng, 1, 9)];
  }
}

// Division is always built quotient × divisor so the answer is a whole number.
function divOperands(level, rng) {
  var d, q;
  switch (level) {
    case 1: d = pick(rng, [1, 2]); q = randInt(rng, 1, 10); return [d * q, d];
    case 2: d = pick(rng, [2, 5, 10]); q = randInt(rng, 1, 10); return [d * q, d];
    case 3: d = pick(rng, [3, 4]); q = randInt(rng, 1, 10); return [d * q, d];
    case 4: d = pick(rng, [6, 7, 8, 9]); q = randInt(rng, 2, 10); return [d * q, d];
    case 5: d = randInt(rng, 2, 12); q = randInt(rng, 2, 12); return [d * q, d];
    case 6: // 2-digit ÷ 1-digit
      d = randInt(rng, 2, 9);
      q = randInt(rng, Math.ceil(10 / d), Math.floor(99 / d));
      return [d * q, d];
    case 7: // 3-digit ÷ 1-digit
      d = randInt(rng, 3, 9);
      q = randInt(rng, Math.ceil(100 / d), Math.floor(499 / d));
      return [d * q, d];
    default: d = randInt(rng, 1, 9); q = randInt(rng, 1, 9); return [d * q, d];
  }
}

var WORLDS = {
  add: {
    op: "+", symbol: "+", operands: addOperands,
    apply: function (xs) { return xs.reduce(function (s, x) { return s + x; }, 0); }
  },
  sub: {
    op: "-", symbol: "−", operands: subOperands,
    apply: function (xs) { return xs.reduce(function (a, x, i) { return i ? a - x : x; }); }
  },
  mul: {
    op: "*", symbol: "×", operands: mulOperands,
    apply: function (xs) { return xs.reduce(function (p, x) { return p * x; }, 1); }
  },
  div: {
    op: "/", symbol: "÷", operands: divOperands,
    apply: function (xs) { return xs.reduce(function (a, x, i) { return i ? a / x : x; }); }
  }
};

// ---- distractors ----------------------------------------------------------

function buildChoices(answer, operands, world, rng) {
  var candidates = [
    answer + 1, answer - 1, answer + 2, answer - 2,
    answer + 10, answer - 10
  ];
  // "wrong operation" trap: the number you'd get running the other operation.
  if (operands.length === 2) {
    if (world === "add") candidates.push(Math.abs(operands[0] - operands[1]));
    else if (world === "sub") candidates.push(operands[0] + operands[1]);
    else if (world === "mul") candidates.push(operands[0] + operands[1]);
    else if (world === "div") candidates.push(operands[0] - operands[1]);
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
