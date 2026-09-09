// Worlds, levels, star thresholds, and unlock rules. Pure functions — shared
// between the QML shell and the Node tests.

var WORLD_ORDER = ["add", "sub", "mul", "div"];

var WORLD_META = {
  add: { id: "add", name: "Adding",       symbol: "+", levels: 7 },
  sub: { id: "sub", name: "Subtracting",  symbol: "−", levels: 7 },
  mul: { id: "mul", name: "Multiplying",  symbol: "×", levels: 7 },
  div: { id: "div", name: "Dividing",     symbol: "÷", levels: 7 }
};

// Short kid-facing description of what a level drills. Index 0 == level 1.
var LEVEL_BLURBS = {
  add: ["Sums to 5", "Sums to 10", "Sums to 20", "Big + small",
        "Two-digit sums", "Carrying over", "Three numbers"]
};

var ROUND_SIZE = 10;

// 0-3 stars for a finished round.
function starsFor(correct, total) {
  if (total <= 0) return 0;
  if (correct >= total) return 3;
  if (correct >= Math.ceil(total * 0.8)) return 2;
  if (correct >= Math.ceil(total * 0.6)) return 1;
  return 0;
}

function levelCount(world) {
  return (WORLD_META[world] && WORLD_META[world].levels) || 0;
}

function bestStars(progress, world, level) {
  var w = progress && progress.worlds && progress.worlds[world];
  var lv = w && w.levels && w.levels[String(level)];
  return (lv && lv.bestStars) || 0;
}

// Level 1 of every world is always open. Any later level opens once the
// previous one has been cleared with at least 2 stars.
function isUnlocked(progress, world, level) {
  if (level <= 1) return true;
  if (level > levelCount(world)) return false;
  return bestStars(progress, world, level - 1) >= 2;
}

// The level the kid should land on when they open a world: the first one that
// isn't yet 3-starred, clamped to what's unlocked.
function suggestedLevel(progress, world) {
  var count = levelCount(world);
  for (var lv = 1; lv <= count; lv++) {
    if (!isUnlocked(progress, world, lv)) return lv - 1 < 1 ? 1 : lv - 1;
    if (bestStars(progress, world, lv) < 3) return lv;
  }
  return count;
}

function worldStars(progress, world) {
  var total = 0;
  for (var lv = 1; lv <= levelCount(world); lv++) total += bestStars(progress, world, lv);
  return total;
}

function totalStars(progress) {
  return WORLD_ORDER.reduce(function (s, w) { return s + worldStars(progress, w); }, 0);
}

function maxStars(world) {
  return world ? levelCount(world) * 3 : WORLD_ORDER.reduce(function (s, w) { return s + levelCount(w) * 3; }, 0);
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    WORLD_ORDER: WORLD_ORDER, WORLD_META: WORLD_META, LEVEL_BLURBS: LEVEL_BLURBS,
    ROUND_SIZE: ROUND_SIZE, starsFor: starsFor, levelCount: levelCount,
    bestStars: bestStars, isUnlocked: isUnlocked, suggestedLevel: suggestedLevel,
    worldStars: worldStars, totalStars: totalStars, maxStars: maxStars
  };
}
