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
const arith = {
  add: (xs) => xs.reduce((s, x) => s + x, 0),
  sub: (xs) => xs.reduce((a, x, i) => (i ? a - x : x)),
  mul: (xs) => xs.reduce((p, x) => p * x, 1),
  div: (xs) => xs.reduce((a, x, i) => (i ? a / x : x))
};
const digs = (n) => [n % 10, Math.floor(n / 10) % 10];

{
  const rng = problems.makeRng(42);
  for (const world of ["add", "sub", "mul", "div"]) {
    for (let lvl = 1; lvl <= 7; lvl++) {
      for (let i = 0; i < 400; i++) {
        const q = problems.generate(world, lvl, rng);
        const truth = arith[world](q.operands);
        ok(`${world} L${lvl} answer is arithmetically correct`, q.answer === truth, `${q.text} -> got ${q.answer}, want ${truth}`);
        ok(`${world} L${lvl} answer is a whole number`, Number.isInteger(q.answer), `${q.text} -> ${q.answer}`);
        ok(`${world} L${lvl} answer >= 0`, q.answer >= 0, `${q.text} -> ${q.answer}`);
        eq(`${world} L${lvl} has 4 choices`, q.choices.length, 4);
        ok(`${world} L${lvl} choices include answer`, q.choices.includes(q.answer));
        ok(`${world} L${lvl} choices unique`, new Set(q.choices).size === 4, JSON.stringify(q.choices));
        ok(`${world} L${lvl} choices are whole & >= 0`, q.choices.every((c) => c >= 0 && Number.isInteger(c)));
        const wantTerms = (lvl === 7 && world !== "div") ? 3 : 2;
        eq(`${world} L${lvl} operand count`, q.operands.length, wantTerms);
        eq(`${world} L${lvl} text token count`, q.text.split(" ").length, wantTerms * 2 - 1);
      }
    }
  }

  // add specifics
  for (let i = 0; i < 500; i++) {
    ok("add L1 sum within 5", ((s) => s >= 1 && s <= 5)(arith.add(problems.generate("add", 1, rng).operands)));
    const q5 = problems.generate("add", 5, rng);
    const [ao, at] = digs(q5.operands[0]); const [bo, bt] = digs(q5.operands[1]);
    ok("add L5 no carrying", ao + bo <= 9 && at + bt <= 9, q5.text);
    ok("add L6 carries", (() => { const q = problems.generate("add", 6, rng); return (q.operands[0] % 10) + (q.operands[1] % 10) > 9; })());
  }

  // sub specifics — never goes negative at any step
  for (let i = 0; i < 500; i++) {
    for (let lvl = 1; lvl <= 7; lvl++) {
      const q = problems.generate("sub", lvl, rng);
      let acc = q.operands[0];
      for (let k = 1; k < q.operands.length; k++) acc -= q.operands[k];
      ok(`sub L${lvl} stays >= 0`, acc >= 0, q.text);
    }
    const q5 = problems.generate("sub", 5, rng);
    const [ao, at] = digs(q5.operands[0]); const [bo, bt] = digs(q5.operands[1]);
    ok("sub L5 no borrowing", ao >= bo && at >= bt, q5.text);
    const q6 = problems.generate("sub", 6, rng);
    ok("sub L6 borrows", (q6.operands[0] % 10) < (q6.operands[1] % 10), q6.text);
  }

  // mul / div specifics
  for (let i = 0; i < 500; i++) {
    const m1 = problems.generate("mul", 1, rng);
    ok("mul L1 uses a 1 or 2", m1.operands.includes(1) || m1.operands.includes(2), m1.text);
    const m5 = problems.generate("mul", 5, rng);
    ok("mul L5 factors 2..12", m5.operands.every((x) => x >= 2 && x <= 12), m5.text);
    const d6 = problems.generate("div", 6, rng);
    ok("div L6 dividend is two digits", d6.operands[0] >= 10 && d6.operands[0] <= 99, d6.text);
    ok("div L6 divides evenly", d6.operands[0] % d6.operands[1] === 0, d6.text);
    const d7 = problems.generate("div", 7, rng);
    ok("div L7 dividend is three digits", d7.operands[0] >= 100 && d7.operands[0] <= 999, d7.text);
  }

  // Determinism: same seed -> same round, for every world.
  for (const world of ["add", "sub", "mul", "div"]) {
    const r1 = problems.buildRound(world, 3, 10, 7).map((q) => q.text);
    const r2 = problems.buildRound(world, 3, 10, 7).map((q) => q.text);
    ok(`${world} buildRound is deterministic for a seed`, JSON.stringify(r1) === JSON.stringify(r2));
  }
  eq("buildRound size", problems.buildRound("add", 1, 10, 1).length, 10);
  ok("unknown world throws", (() => { try { problems.generate("nope", 1, rng); return false; } catch (e) { return true; } })());
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

  // ---- age bands
  const withAge = (n) => { const x = store.emptyProgress(); x.settings.age = n; return x; };
  eq("age unset -> start level 1", prog.ageStartLevel(store.emptyProgress(), "add"), 1);
  eq("age 6 -> still level 1", prog.ageStartLevel(withAge(6), "add"), 1);
  eq("age 9 add -> level 4", prog.ageStartLevel(withAge(9), "add"), 4);
  eq("age 9 mul -> level 2", prog.ageStartLevel(withAge(9), "mul"), 2);
  eq("age 12 add -> level 6", prog.ageStartLevel(withAge(12), "add"), 6);
  ok("age 9: level 4 unlocked without stars", prog.isUnlocked(withAge(9), "add", 4));
  ok("age 9: level 3 still open (lower levels playable)", prog.isUnlocked(withAge(9), "add", 3));
  ok("age 9: level 5 still gated by stars", !prog.isUnlocked(withAge(9), "add", 5));
  eq("age 9: suggestedLevel starts at the band", prog.suggestedLevel(withAge(9), "add"), 4);
  ok("bad age clamps to unset", prog.childAge(withAge(99)) === 0 && prog.childAge(withAge(3)) === 0);
  eq("setSetting age stores a number", store.setSetting(store.emptyProgress(), "age", "10").settings.age, 10);
  eq("setSetting age rejects out-of-range", store.setSetting(store.emptyProgress(), "age", 40).settings.age, 0);
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
