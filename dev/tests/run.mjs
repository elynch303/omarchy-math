// Plain Node test runner (no deps). Run: node dev/tests/run.mjs
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);

const problems = require("../../logic/problems.js");
const prog = require("../../logic/progression.js");
const store = require("../../logic/store.js");

let pass = 0, fail = 0;
const fails = [];
function ok(name, cond, detail) {
  if (cond) { pass++; }
  else { fail++; fails.push(name + (detail ? "  -> " + detail : "")); }
}
function eq(name, a, b) { ok(name, a === b, `got ${JSON.stringify(a)}, want ${JSON.stringify(b)}`); }

// ---------------------------------------------------------------- problems
{
  const rng = problems.makeRng(42);
  for (let lvl = 1; lvl <= 7; lvl++) {
    for (let i = 0; i < 400; i++) {
      const q = problems.generate("add", lvl, rng);
      const sum = q.operands.reduce((s, x) => s + x, 0);
      ok(`add L${lvl} answer is the real sum`, q.answer === sum, `${q.text} -> ${q.answer}`);
      ok(`add L${lvl} text renders operands`, q.text === q.operands.join(" + "));
      eq(`add L${lvl} has 4 choices`, q.choices.length, 4);
      ok(`add L${lvl} choices include answer`, q.choices.includes(q.answer));
      ok(`add L${lvl} choices unique`, new Set(q.choices).size === 4, JSON.stringify(q.choices));
      ok(`add L${lvl} choices non-negative`, q.choices.every((c) => c >= 0 && Number.isInteger(c)));
      if (lvl <= 3) ok(`add L${lvl} sum within 20`, sum <= 20, String(sum));
      if (lvl === 1) ok("add L1 sum within 5", sum >= 1 && sum <= 5, String(sum));
      if (lvl === 4) ok("add L4 shape 2-digit + 1-digit",
        q.operands[0] >= 10 && q.operands[0] <= 99 && q.operands[1] >= 2 && q.operands[1] <= 9);
      if (lvl === 5) {
        const d = (n) => [n % 10, Math.floor(n / 10) % 10];
        const [ao, at] = d(q.operands[0]); const [bo, bt] = d(q.operands[1]);
        ok("add L5 no carrying", ao + bo <= 9 && at + bt <= 9, q.text);
      }
      if (lvl === 6) {
        const carry = (q.operands[0] % 10) + (q.operands[1] % 10) > 9;
        ok("add L6 has a carry", carry, q.text);
      }
      if (lvl === 7) ok("add L7 is three addends", q.operands.length === 3);
    }
  }

  // Determinism: same seed -> same round.
  const r1 = problems.buildRound("add", 3, 10, 7).map((q) => q.text);
  const r2 = problems.buildRound("add", 3, 10, 7).map((q) => q.text);
  ok("buildRound is deterministic for a seed", JSON.stringify(r1) === JSON.stringify(r2));
  eq("buildRound size", problems.buildRound("add", 1, 10, 1).length, 10);
}

// ------------------------------------------------------------- progression
{
  eq("stars 10/10", prog.starsFor(10, 10), 3);
  eq("stars 9/10", prog.starsFor(9, 10), 2);
  eq("stars 8/10", prog.starsFor(8, 10), 2);
  eq("stars 7/10", prog.starsFor(7, 10), 1);
  eq("stars 6/10", prog.starsFor(6, 10), 1);
  eq("stars 5/10", prog.starsFor(5, 10), 0);
  eq("stars 0/0 guard", prog.starsFor(0, 0), 0);

  const empty = store.emptyProgress();
  ok("L1 unlocked from scratch", prog.isUnlocked(empty, "add", 1));
  ok("L2 locked from scratch", !prog.isUnlocked(empty, "add", 2));
  ok("L8 never exists", !prog.isUnlocked(empty, "add", 8));

  let p = store.recordRound(empty, "add", 1, 8, 10, prog.starsFor(8, 10)); // 2 stars
  ok("L2 unlocks after 2-star L1", prog.isUnlocked(p, "add", 2));
  ok("L3 still locked", !prog.isUnlocked(p, "add", 3));

  p = store.recordRound(p, "add", 1, 6, 10, prog.starsFor(6, 10)); // 1 star, worse
  eq("bestStars keeps the best", prog.bestStars(p, "add", 1), 2);
  eq("plays increments", p.worlds.add.levels["1"].plays, 2);

  eq("suggestedLevel points at first unfinished", prog.suggestedLevel(p, "add"), 1);
  p = store.recordRound(p, "add", 1, 10, 10, 3);
  eq("suggestedLevel advances past a 3-star", prog.suggestedLevel(p, "add"), 2);

  eq("worldStars sums level bests", prog.worldStars(p, "add"), 3);
  eq("maxStars add", prog.maxStars("add"), 21);
}

// -------------------------------------------------------------------- store
{
  eq("parse junk -> empty", store.parse("not json").version, 1);
  eq("normalize clamps stars", store.normalize({ worlds: { add: { levels: { "1": { bestStars: 99 } } } } }).worlds.add.levels["1"].bestStars, 3);
  const round = store.serialize(store.emptyProgress());
  ok("serialize round-trips", store.parse(round).version === 1);
  const p = store.setSetting(store.emptyProgress(), "sound", false);
  eq("setSetting toggles", p.settings.sound, false);
  ok("recordRound does not mutate input", (() => {
    const a = store.emptyProgress();
    store.recordRound(a, "add", 1, 10, 10, 3);
    return Object.keys(a.worlds).length === 0;
  })());
}

console.log(`\n${pass} passed, ${fail} failed`);
if (fail) { console.log("\nFailures:\n  " + fails.slice(0, 25).join("\n  ")); process.exit(1); }
