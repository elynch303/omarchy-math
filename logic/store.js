// Progress document: load, validate, update, serialize. Pure — the QML side
// owns the actual file IO (Quickshell.Io FileView), this just shapes the data.
//
// Shape (v1). `worlds.<id>.levels.<n>` is created lazily.
//   {
//     version: 1,
//     settings: { sound, reduceMotion, largeText },
//     worlds: { add: { levels: { "1": { bestStars, bestScore, plays } } } },
//   }

var CURRENT_VERSION = 1;

function emptyProgress() {
  return {
    version: CURRENT_VERSION,
    settings: { sound: true, reduceMotion: false, largeText: false },
    worlds: {}
  };
}

function isObject(x) {
  return x !== null && typeof x === "object" && !Array.isArray(x);
}

// Coerce anything (a parsed file, junk, undefined) into a valid progress doc.
function normalize(raw) {
  var base = emptyProgress();
  if (!isObject(raw)) return base;

  if (isObject(raw.settings)) {
    if (typeof raw.settings.sound === "boolean") base.settings.sound = raw.settings.sound;
    if (typeof raw.settings.reduceMotion === "boolean") base.settings.reduceMotion = raw.settings.reduceMotion;
    if (typeof raw.settings.largeText === "boolean") base.settings.largeText = raw.settings.largeText;
  }

  if (isObject(raw.worlds)) {
    for (var world in raw.worlds) {
      var w = raw.worlds[world];
      if (!isObject(w) || !isObject(w.levels)) continue;
      base.worlds[world] = { levels: {} };
      for (var lv in w.levels) {
        var entry = w.levels[lv];
        if (!isObject(entry)) continue;
        base.worlds[world].levels[String(lv)] = {
          bestStars: clampInt(entry.bestStars, 0, 3),
          bestScore: clampInt(entry.bestScore, 0, 999),
          plays: clampInt(entry.plays, 0, 999999)
        };
      }
    }
  }
  return base;
}

function clampInt(v, min, max) {
  v = Math.floor(Number(v));
  if (!isFinite(v)) return min;
  return Math.max(min, Math.min(max, v));
}

function parse(text) {
  try { return normalize(JSON.parse(text)); }
  catch (e) { return emptyProgress(); }
}

function serialize(progress) {
  return JSON.stringify(normalize(progress), null, 2) + "\n";
}

// Fold one finished round into a NEW progress doc (does not mutate the input).
function recordRound(progress, world, level, correct, total, stars) {
  var next = normalize(progress);
  if (!next.worlds[world]) next.worlds[world] = { levels: {} };
  var key = String(level);
  var lv = next.worlds[world].levels[key] || { bestStars: 0, bestScore: 0, plays: 0 };
  lv.plays += 1;
  lv.bestStars = Math.max(lv.bestStars, clampInt(stars, 0, 3));
  lv.bestScore = Math.max(lv.bestScore, clampInt(correct, 0, total));
  next.worlds[world].levels[key] = lv;
  return next;
}

function setSetting(progress, key, value) {
  var next = normalize(progress);
  if (key in next.settings) next.settings[key] = !!value;
  return next;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = {
    CURRENT_VERSION: CURRENT_VERSION, emptyProgress: emptyProgress, normalize: normalize,
    parse: parse, serialize: serialize, recordRound: recordRound, setSetting: setSetting
  };
}
