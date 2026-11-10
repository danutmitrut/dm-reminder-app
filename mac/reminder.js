// reminder.js: arată un reminder din remindere.json (JXA + Cocoa).
// Folosire: /usr/bin/osascript -l JavaScript reminder.js <id>
// Nu are nevoie de Python. Citește lista din același folder cu scriptul.
// „Am înțeles” sau Enter închid fereastra. „Repetă în” o ascunde și o readuce după N minute.
// Culorile stau în stânga sus, ceasul analogic în dreapta sus, data în stânga ceasului. design.json lângă script.

ObjC.import('Cocoa'); ObjC.import('QuartzCore'); ObjC.import('Foundation');
var ctxFereastra = null;

var C1 = [0.88, 0.80, 0.97], C2 = [0.72, 0.50, 0.97], C3 = [0.45, 0.76, 0.84];
var BORDURA_IMPLICITA = [0.62, 0.50, 0.92];
var ZILE = ['duminică', 'luni', 'marți', 'miercuri', 'joi', 'vineri', 'sâmbătă'];
var LUNI = ['ianuarie', 'februarie', 'martie', 'aprilie', 'mai', 'iunie', 'iulie', 'august', 'septembrie', 'octombrie', 'noiembrie', 'decembrie'];

function dezval(x) {
  if (x === undefined || x === null) return x;
  return ObjC.unwrap(x);
}

function directorPachet() {
  var args = dezval($.NSProcessInfo.processInfo.arguments);
  var i, a, p, last, cwd;
  for (i = 0; i < args.length; i++) {
    a = dezval(args[i]);
    if (typeof a === 'string' && a.length >= 11 && a.substring(a.length - 11) === 'reminder.js') {
      p = a;
      if (p.charAt(0) !== '/') {
        cwd = dezval($.NSFileManager.defaultManager.currentDirectoryPath);
        p = cwd + '/' + p;
      }
      last = p.lastIndexOf('/');
      return last <= 0 ? p : p.substring(0, last);
    }
  }
  return dezval($.NSHomeDirectory()) + '/Remindere';
}

function citesteText(path) {
  var str = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null);
  if (!str) return null;
  return dezval(str);
}


function scrieJurnal(dir, linie) {
  var path = dir + '/jurnal.log';
  var fm = $.NSFileManager.defaultManager;
  if (!fm.fileExistsAtPath(path)) {
    $.NSString.alloc.initWithString('').writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null);
  }
  var handle = $.NSFileHandle.fileHandleForWritingAtPath(path);
  if (!handle) return;
  handle.seekToEndOfFile;
  var data = $.NSString.alloc.initWithString(linie + '\n').dataUsingEncoding($.NSUTF8StringEncoding);
  handle.writeData(data);
  handle.closeFile;
}

function acumLocal() {
  var d = new Date();
  function p(n) { return (n < 10 ? '0' : '') + n; }
  return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate()) + ' ' + p(d.getHours()) + ':' + p(d.getMinutes()) + ':' + p(d.getSeconds());
}

function alerta(mesaj) {
  try {
    var a = Application.currentApplication();
    a.includeStandardAdditions = true;
    a.displayAlert(mesaj);
  } catch (e) {}
}

function redaSunet() {
  try {
    var a = Application.currentApplication();
    a.includeStandardAdditions = true;
    a.doShellScript('afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1 &');
  } catch (e) {}
}

function dezarmeazaOData(rid) {
  try {
    var a = Application.currentApplication();
    a.includeStandardAdditions = true;
    var uid = a.doShellScript('id -u').replace(/\s+/g, '');
    a.doShellScript('launchctl bootout gui/' + uid + '/com.cursant.reminder.' + rid + ' >/dev/null 2>&1 || true');
  } catch (e) {}
}

function culoareNS(rgb) {
  return $.NSColor.colorWithSRGBRedGreenBlueAlpha(rgb[0], rgb[1], rgb[2], 1);
}

function rgbDinNS(color) {
  if (!color) return [0, 0, 0];
  var c = color.colorUsingColorSpace($.NSColorSpace.sRGBColorSpace);
  if (!c || dezval(c) === undefined || dezval(c) === null) return [0, 0, 0];
  return [Number(c.redComponent), Number(c.greenComponent), Number(c.blueComponent)];
}

function rotunjRgb(rgb) {
  function r(x) { return Math.round(Number(x) * 10000) / 10000; }
  return [r(rgb[0]), r(rgb[1]), r(rgb[2])];
}

function valideazaRgb(v) {
  if (!v || typeof v.length !== 'number' || v.length < 3) return null;
  var r = Number(v[0]), g = Number(v[1]), b = Number(v[2]);
  if (isNaN(r) || isNaN(g) || isNaN(b)) return null;
  function clip(x) { return x < 0 ? 0 : (x > 1 ? 1 : x); }
  return [clip(r), clip(g), clip(b)];
}

function designImplicit() {
  return {
    mod: 'degrade',
    solid: [C1[0], C1[1], C1[2]],
    degrade_inceput: [C1[0], C1[1], C1[2]],
    degrade_sfarsit: [C3[0], C3[1], C3[2]],
    degrade_personalizat: false
  };
}

function citesteDesign(dir) {
  var d = designImplicit();
  var raw = citesteText(dir + '/design.json');
  if (!raw) return d;
  try {
    var o = JSON.parse(raw);
    if (o.mod === 'solid' || o.mod === 'degrade') d.mod = o.mod;
    var s = valideazaRgb(o.solid);
    if (s) d.solid = s;
    var a = valideazaRgb(o.degrade_inceput);
    if (a) d.degrade_inceput = a;
    var b = valideazaRgb(o.degrade_sfarsit);
    if (b) d.degrade_sfarsit = b;
    d.degrade_personalizat = o.degrade_personalizat === true;
  } catch (e) {}
  return d;
}

function scrieDesign(dir, design) {
  var o = {
    mod: design.mod,
    solid: rotunjRgb(design.solid),
    degrade_inceput: rotunjRgb(design.degrade_inceput),
    degrade_sfarsit: rotunjRgb(design.degrade_sfarsit),
    degrade_personalizat: design.degrade_personalizat === true
  };
  var json = JSON.stringify(o, null, 2) + '\n';
  $.NSString.alloc.initWithString(json).writeToFileAtomicallyEncodingError(dir + '/design.json', true, $.NSUTF8StringEncoding, null);
}

function luminantaMedie(culori) {
  var i, r, g, b, s = 0;
  if (!culori || !culori.length) return 1;
  for (i = 0; i < culori.length; i++) {
    r = culori[i][0]; g = culori[i][1]; b = culori[i][2];
    s += 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
  return s / culori.length;
}

function culoriFundal(design) {
  if (design.mod === 'solid') return [design.solid];
  if (design.degrade_personalizat) return [design.degrade_inceput, design.degrade_sfarsit];
  return [C1, C2, C3];
}

function eDegradeImplicit(design) {
  return design.mod !== 'solid' && design.degrade_personalizat !== true;
}

function ridicaPanouCulori() {
  try {
    var p = $.NSColorPanel.sharedColorPanel;
    p.setLevel($.NSStatusWindowLevel + 8);
    p.setHidesOnDeactivate(false);
  } catch (e) {}
}

function inchidePanouCulori() {
  try { $.NSColorPanel.sharedColorPanel.orderOut(null); } catch (e) {}
}

function opresteTimer() {
  try {
    if (ctxFereastra && ctxFereastra.timer) {
      ctxFereastra.timer.invalidate();
      ctxFereastra.timer = null;
    }
  } catch (e) {}
}

function partiData() {
  var d = new Date();
  return {
    zi: ZILE[d.getDay()],
    data: d.getDate() + ' ' + LUNI[d.getMonth()],
    an: String(d.getFullYear())
  };
}

function actualizeazaData(ctx) {
  if (!ctx || !ctx.dataZi) return;
  var p = partiData();
  ctx.dataZi.setStringValue(p.zi);
  ctx.dataLuna.setStringValue(p.data);
  ctx.dataAn.setStringValue(p.an);
}

function fontSans(size, gros) {
  var names;
  if (gros === 'demibold') {
    names = ['AvenirNext-DemiBold', 'AvenirNext-Bold', 'AvenirNext-Medium', 'HelveticaNeue-Medium', 'Helvetica Neue', 'HelveticaNeue'];
  } else {
    names = ['AvenirNext-Medium', 'AvenirNext-Regular', 'Avenir Next', 'HelveticaNeue-Medium', 'Helvetica Neue', 'HelveticaNeue'];
  }
  var i, f;
  for (i = 0; i < names.length; i++) {
    f = $.NSFont.fontWithNameSize(names[i], size);
    if (f && dezval(f)) return f;
  }
  if (gros === 'demibold') return $.NSFont.systemFontOfSizeWeight(size, 0.3);
  return $.NSFont.systemFontOfSizeWeight(size, 0.23);
}

function deseneazaCeasImagine(w, h) {
  w = Number(w); h = Number(h);
  if (!(w > 0) || !(h > 0)) return null;
  var img = $.NSImage.alloc.initWithSize($.NSMakeSize(w, h));
  img.lockFocus;
  var cx = w / 2, cy = h / 2;
  var r = Math.min(w, h) / 2 - 3;
  var ink = (ctxFereastra && ctxFereastra.culoareAce) ? ctxFereastra.culoareAce : $.NSColor.colorWithSRGBRedGreenBlueAlpha(0.05, 0.04, 0.09, 1);
  var inel = ink.colorWithAlphaComponent(0.88);
  var tick = ink.colorWithAlphaComponent(0.72);
  var fundal = ink.colorWithAlphaComponent(0.08);
  var oval = $.NSBezierPath.bezierPathWithOvalInRect($.NSMakeRect(cx - r, cy - r, r * 2, r * 2));
  fundal.setFill;
  oval.fill;
  inel.setStroke;
  oval.setLineWidth(1.6);
  oval.stroke;
  var i, theta, inner, outer, lw, p;
  for (i = 0; i < 60; i++) {
    theta = i * Math.PI / 30;
    if (i % 15 === 0) { inner = r - 13; outer = r - 2.5; lw = 2.3; }
    else if (i % 5 === 0) { inner = r - 9; outer = r - 2.5; lw = 1.6; }
    else { inner = r - 5; outer = r - 2.5; lw = 1.0; }
    p = $.NSBezierPath.bezierPath;
    p.moveToPoint($.NSMakePoint(cx + Math.sin(theta) * inner, cy + Math.cos(theta) * inner));
    p.lineToPoint($.NSMakePoint(cx + Math.sin(theta) * outer, cy + Math.cos(theta) * outer));
    p.setLineWidth(lw);
    p.setLineCapStyle($.NSLineCapStyleRound);
    tick.setStroke;
    p.stroke;
  }
  var now = new Date();
  var sec = now.getSeconds();
  var min = now.getMinutes() + sec / 60;
  var hr = (now.getHours() % 12) + min / 60;
  var aH = hr * Math.PI / 6, aM = min * Math.PI / 30, aS = sec * Math.PI / 30;
  function mana(angle, lung, gros, col) {
    var q = $.NSBezierPath.bezierPath;
    q.moveToPoint($.NSMakePoint(cx - Math.sin(angle) * (r * 0.12), cy - Math.cos(angle) * (r * 0.12)));
    q.lineToPoint($.NSMakePoint(cx + Math.sin(angle) * lung, cy + Math.cos(angle) * lung));
    q.setLineWidth(gros);
    q.setLineCapStyle($.NSLineCapStyleRound);
    col.setStroke;
    q.stroke;
  }
  mana(aH, r * 0.52, 3.6, ink);
  mana(aM, r * 0.72, 2.4, ink);
  mana(aS, r * 0.80, 1.2, ink.colorWithAlphaComponent(0.9));
  var cap = $.NSBezierPath.bezierPathWithOvalInRect($.NSMakeRect(cx - 3.6, cy - 3.6, 7.2, 7.2));
  ink.setFill;
  cap.fill;
  img.unlockFocus;
  return img;
}

function reimprospateazaCeas(ctx) {
  if (!ctx || !ctx.ceasImagine) return;
  var b = ctx.ceasImagine.bounds;
  var w = Number(b.size.width), h = Number(b.size.height);
  if (!(w > 0) || !(h > 0)) { w = 132; h = 132; }
  var img = deseneazaCeasImagine(w, h);
  if (img) ctx.ceasImagine.setImage(img);
}

function seteazaEsantion(btn, rgb, bordura, opt) {
  opt = opt || {};
  btn.layer.setBackgroundColor(culoareNS(rgb).CGColor);
  btn.layer.setBorderColor(bordura.CGColor);
  btn.layer.setBorderWidth(opt.grosime || 1.6);
}

function deschidePanouCulori(tag) {
  var ctx = ctxFereastra;
  if (!ctx || !ctx.handler) return;
  ctx.panouTag = tag;
  ridicaPanouCulori();
  var panel = $.NSColorPanel.sharedColorPanel;
  var rgb = tag === 1 ? ctx.design.solid : (tag === 2 ? ctx.design.degrade_inceput : ctx.design.degrade_sfarsit);
  panel.setContinuous(true);
  panel.setColor(culoareNS(rgb));
  panel.setTarget(ctx.handler);
  panel.setAction('culoareDinPanou:');
  panel.makeKeyAndOrderFront(null);
}

function aplicaCuloareDinPanou(rgb, tag) {
  var ctx = ctxFereastra;
  if (!ctx) return;
  if (tag === 1) ctx.design.solid = rgb;
  else if (tag === 2) {
    ctx.design.degrade_inceput = rgb;
    ctx.design.degrade_personalizat = true;
  } else if (tag === 3) {
    ctx.design.degrade_sfarsit = rgb;
    ctx.design.degrade_personalizat = true;
  } else return;
  aplicaDesign(ctx, true);
}

function inregistreazaClase() {
  if (typeof $.CursantReminderWindow === 'undefined') {
    ObjC.registerSubclass({
      name: 'CursantReminderWindow',
      superclass: 'NSWindow',
      methods: {
        'canBecomeKeyWindow': {
          types: ['BOOL', []],
          implementation: function () { return 1; }
        },
        'canBecomeMainWindow': {
          types: ['BOOL', []],
          implementation: function () { return 1; }
        }
      }
    });
  }
  if (typeof $.CursantReminderCeas === 'undefined') {
    ObjC.registerSubclass({
      name: 'CursantReminderCeas',
      superclass: 'NSView',
      methods: {
        'isOpaque': {
          types: ['BOOL', []],
          implementation: function () { return 0; }
        }
      }
    });
  }
  if (typeof $.CursantReminderActiuni === 'undefined') {
    ObjC.registerSubclass({
      name: 'CursantReminderActiuni',
      superclass: 'NSObject',
      methods: {
        'amana:': {
          types: ['void', ['id']],
          implementation: function (sender) {
            var ctx = ctxFereastra;
            var idx = Number(ctx.pop.indexOfSelectedItem);
            if (isNaN(idx) || idx < 0) idx = 0;
            var n = (idx + 1) * 5;
            if (n < 5 || n > 60) n = 5;
            ctx.stare.iesire = 'amana ' + n;
            opresteTimer();
            inchidePanouCulori();
            ctx.win.orderOut(null);
            ctx.app.stop(ctx.app);
          }
        },
        'inchide:': {
          types: ['void', ['id']],
          implementation: function (sender) {
            var ctx = ctxFereastra;
            ctx.stare.iesire = '';
            opresteTimer();
            inchidePanouCulori();
            ctx.win.orderOut(null);
            ctx.app.stop(ctx.app);
          }
        },
        'alegeSolid:': {
          types: ['void', ['id']],
          implementation: function (sender) {
            var ctx = ctxFereastra;
            if (!ctx || ctx.liniste) return;
            if (ctx.design.mod === 'solid') return;
            ctx.design.mod = 'solid';
            aplicaDesign(ctx, true);
          }
        },
        'alegeDegrade:': {
          types: ['void', ['id']],
          implementation: function (sender) {
            var ctx = ctxFereastra;
            if (!ctx || ctx.liniste) return;
            if (ctx.design.mod === 'degrade') return;
            ctx.design.mod = 'degrade';
            aplicaDesign(ctx, true);
          }
        },
        'apasaEsantion:': {
          types: ['void', ['id']],
          implementation: function (sender) {
            var ctx = ctxFereastra;
            if (!ctx || ctx.liniste) return;
            var tag = Number(sender.tag);
            if (tag === 1) ctx.design.mod = 'solid';
            else if (tag === 2 || tag === 3) ctx.design.mod = 'degrade';
            aplicaDesign(ctx, true);
            deschidePanouCulori(tag);
          }
        },
        'culoareDinPanou:': {
          types: ['void', ['id']],
          implementation: function (sender) {
            var ctx = ctxFereastra;
            if (!ctx || ctx.liniste) return;
            ridicaPanouCulori();
            var rgb = rotunjRgb(rgbDinNS(sender.color));
            aplicaCuloareDinPanou(rgb, Number(ctx.panouTag));
          }
        },
        'tic:': {
          types: ['void', ['id']],
          implementation: function (timer) {
            var ctx = ctxFereastra;
            if (!ctx) return;
            reimprospateazaCeas(ctx);
            actualizeazaData(ctx);
          }
        }
      }
    });
  }
}

function aplicaDesign(ctx, salveaza) {
  var design = ctx.design, W = ctx.W, H = ctx.H;
  var img = $.NSImage.alloc.initWithSize($.NSMakeSize(W, H));
  img.lockFocus;
  if (design.mod === 'solid') {
    culoareNS(design.solid).setFill;
    $.NSRectFill($.NSMakeRect(0, 0, W, H));
  } else if (design.degrade_personalizat) {
    $.NSGradient.alloc.initWithColors($([culoareNS(design.degrade_inceput), culoareNS(design.degrade_sfarsit)])).drawInRectAngle($.NSMakeRect(0, 0, W, H), -20);
  } else {
    $.NSGradient.alloc.initWithColors($([culoareNS(C1), culoareNS(C2), culoareNS(C3)])).drawInRectAngle($.NSMakeRect(0, 0, W, H), -20);
  }
  img.unlockFocus;
  ctx.iv.setImage(img);
  var bordura = eDegradeImplicit(design) ? BORDURA_IMPLICITA : (design.mod === 'solid' ? design.solid : design.degrade_inceput);
  var br = eDegradeImplicit(design) ? BORDURA_IMPLICITA[0] : Math.max(0, bordura[0] * 0.72);
  var bg = eDegradeImplicit(design) ? BORDURA_IMPLICITA[1] : Math.max(0, bordura[1] * 0.72);
  var bb = eDegradeImplicit(design) ? BORDURA_IMPLICITA[2] : Math.max(0, bordura[2] * 0.72);
  ctx.layer.setBorderColor(culoareNS([br, bg, bb]).CGColor);
  var intunecat = luminantaMedie(culoriFundal(design)) < 0.45;
  var textC = intunecat ? $.NSColor.whiteColor : $.NSColor.colorWithSRGBRedGreenBlueAlpha(0.05, 0.04, 0.09, 1);
  var titluC = intunecat ? $.NSColor.whiteColor : $.NSColor.colorWithSRGBRedGreenBlueAlpha(0.04, 0.04, 0.06, 1);
  var bordSelectat = intunecat ? $.NSColor.colorWithSRGBRedGreenBlueAlpha(1, 1, 1, 0.92) : $.NSColor.colorWithSRGBRedGreenBlueAlpha(0.05, 0.04, 0.09, 0.92);
  ctx.culoareAce = textC;
  ctx.titluView.setTextColor(titluC);
  ctx.textView.setTextColor(textC);
  ctx.etichetaFundal.setTextColor(textC);
  ctx.dataZi.setTextColor(textC);
  ctx.dataLuna.setTextColor(textC);
  ctx.dataAn.setTextColor(textC);
  reimprospateazaCeas(ctx);
  var apName = intunecat ? $.NSAppearanceNameDarkAqua : $.NSAppearanceNameAqua;
  ctx.randDesign.setAppearance($.NSAppearance.appearanceNamed(apName));
  ctx.liniste = true;
  if (design.mod === 'solid') {
    ctx.radioDegrade.setState(0);
    ctx.radioSolid.setState(1);
  } else {
    ctx.radioSolid.setState(0);
    ctx.radioDegrade.setState(1);
  }
  var eSolid = design.mod === 'solid';
  if (ctx.randDesign && ctx.randDesign.layer) {
    ctx.randDesign.layer.setBorderColor(culoareNS(BORDURA_IMPLICITA).CGColor);
    ctx.randDesign.layer.setBorderWidth(2);
  }
  ctx.esantionSolid.setAlphaValue(eSolid ? 1 : 0.5);
  ctx.esantionInceput.setAlphaValue(eSolid ? 0.5 : 1);
  ctx.esantionSfarsit.setAlphaValue(eSolid ? 0.5 : 1);
  seteazaEsantion(ctx.esantionSolid, design.solid, bordSelectat, { grosime: eSolid ? 2 : 0 });
  seteazaEsantion(ctx.esantionInceput, design.degrade_inceput, bordSelectat, { grosime: eSolid ? 0 : 2 });
  seteazaEsantion(ctx.esantionSfarsit, design.degrade_sfarsit, bordSelectat, { grosime: eSolid ? 0 : 2 });
  ctx.liniste = false;
  if (salveaza) scrieDesign(ctx.dir, design);
}

function radioNou(titlu, x, y, w, h) {
  var b = $.NSButton.alloc.initWithFrame($.NSMakeRect(x, y, w, h));
  b.setButtonType($.NSButtonTypeRadio);
  b.setBordered(false);
  b.setTitle(titlu);
  b.setFont($.NSFont.systemFontOfSize(13));
  b.setControlSize($.NSControlSizeRegular);
  b.setImagePosition($.NSImageLeft);
  b.setAlignment($.NSTextAlignmentLeft);
  return b;
}

function esantionNou(x, y, tag) {
  var b = $.NSButton.alloc.initWithFrame($.NSMakeRect(x, y, 28, 18));
  b.setBordered(false);
  b.setWantsLayer(true);
  b.layer.setCornerRadius(4);
  b.layer.setMasksToBounds(true);
  b.layer.setBorderWidth(0);
  b.setTitle('');
  b.setTag(tag);
  return b;
}

function arataFereastra(titlu, text, dir) {
  var design = citesteDesign(dir);
  inregistreazaClase();
  var app = $.NSApplication.sharedApplication;
  app.setActivationPolicy($.NSApplicationActivationPolicyAccessory);
  var scr = $.NSScreen.mainScreen.frame;
  var W = 880, H = 620;
  var rect = $.NSMakeRect((scr.size.width - W) / 2, (scr.size.height - H) / 2, W, H);
  var win = $.CursantReminderWindow.alloc.initWithContentRectStyleMaskBackingDefer(rect, $.NSWindowStyleMaskBorderless, $.NSBackingStoreBuffered, false);
  win.setOpaque(false);
  win.setBackgroundColor($.NSColor.clearColor);
  win.setLevel($.NSStatusWindowLevel);
  win.setHasShadow(true);
  win.setCollectionBehavior($.NSWindowCollectionBehaviorCanJoinAllSpaces | $.NSWindowCollectionBehaviorFullScreenAuxiliary);
  var v = $.NSView.alloc.initWithFrame($.NSMakeRect(0, 0, W, H));
  v.setWantsLayer(true);
  win.setContentView(v);
  var L = v.layer;
  L.setCornerRadius(28); L.setMasksToBounds(true);
  L.setBackgroundColor(culoareNS([0.86, 0.82, 0.97]).CGColor);
  L.setBorderWidth(2);
  var iv = $.NSImageView.alloc.initWithFrame($.NSMakeRect(0, 0, W, H));
  iv.setImageScaling($.NSImageScaleAxesIndependently);
  iv.setEditable(false);
  iv.setRefusesFirstResponder(true);
  v.addSubview(iv);
  var ink = culoareNS([0.05, 0.04, 0.09]);
  var gold = culoareNS([0.04, 0.04, 0.06]);
  function eticheta(s, size, bold, color, x, y, w, h, align) {
    var t = $.NSTextField.alloc.initWithFrame($.NSMakeRect(x, y, w, h));
    t.setStringValue(s); t.setEditable(false); t.setSelectable(false); t.setBezeled(false); t.setDrawsBackground(false);
    var aliniere = (align === $.NSTextAlignmentCenter || align === 2) ? 2 : align;
    t.setAlignment(aliniere); t.cell.setAlignment(aliniere); t.setTextColor(color);
    t.setFont(bold ? $.NSFont.boldSystemFontOfSize(size) : $.NSFont.systemFontOfSizeWeight(size, 0.23));
    t.cell.setWraps(true); v.addSubview(t); return t;
  }
  var ceasS = 132;
  var ceasX = W - 28 - ceasS;
  var ceasY = H - 22 - ceasS;
  var ceasView = $.CursantReminderCeas.alloc.initWithFrame($.NSMakeRect(ceasX, ceasY, ceasS, ceasS));
  var ceasImagine = $.NSImageView.alloc.initWithFrame($.NSMakeRect(0, 0, ceasS, ceasS));
  ceasImagine.setImageScaling($.NSImageScaleAxesIndependently);
  ceasImagine.setEditable(false);
  ceasImagine.setRefusesFirstResponder(true);
  ceasView.addSubview(ceasImagine);
  v.addSubview(ceasView);
  var dataW = 250, dataH = 110;
  var dataX = ceasX - 16 - dataW;
  var dataY = ceasY + (ceasS - dataH) / 2;
  function dataRand(size, y, h, gros) {
    var t = $.NSTextField.alloc.initWithFrame($.NSMakeRect(dataX, y, dataW, h));
    t.setEditable(false); t.setSelectable(false); t.setBezeled(false); t.setDrawsBackground(false);
    t.setAlignment($.NSTextAlignmentRight);
    t.setTextColor(ink);
    t.setFont(fontSans(size, gros));
    t.cell.setWraps(false);
    v.addSubview(t);
    return t;
  }
  var dataAn = dataRand(26, dataY, 28, 'medium');
  var dataLuna = dataRand(34, dataY + 30, 40, 'demibold');
  var dataZi = dataRand(26, dataY + 74, 30, 'medium');
  var josButon = 40 + 56;
  var zonaJos = josButon + 18;
  var zonaSus = ceasY - 16;
  var textH = 140, titluH = 36, gapTT = 14;
  var blocH = titluH + gapTT + textH;
  var blocY = zonaJos + Math.floor((zonaSus - zonaJos - blocH) / 2);
  if (blocY < zonaJos) blocY = zonaJos;
  var titluY = blocY + textH + gapTT;
  function centreazaEticheta(t, y, hMax) {
    t.setAlignment(2);
    t.cell.setAlignment(2);
    t.cell.setWraps(false);
    t.sizeToFit;
    var f = t.frame;
    var tw = Math.ceil(Number(f.size.width)) + 4;
    var th = Math.max(Number(f.size.height), 20);
    if (tw > W - 48) {
      tw = W - 48;
      t.cell.setWraps(true);
      t.setFrame($.NSMakeRect(24, y, tw, hMax));
      t.sizeToFit;
      f = t.frame;
      tw = Math.min(W - 48, Math.ceil(Number(f.size.width)) + 4);
      th = Math.min(hMax, Math.max(Number(f.size.height), 20));
    }
    t.setFrame($.NSMakeRect(Math.round((W - tw) / 2), y + Math.round((hMax - th) / 2), tw, th));
  }
  var titluView = eticheta(String(titlu).toUpperCase(), 20, true, gold, 36, titluY, W - 72, titluH, $.NSTextAlignmentCenter);
  var textView = eticheta(text, 30, false, ink, 36, blocY, W - 72, textH, $.NSTextAlignmentCenter);
  centreazaEticheta(titluView, titluY, titluH);
  centreazaEticheta(textView, blocY, textH);
  var padP = 10, radioW = 148, casW = 28, casH = 18, rowH = 22, gapRS = 10, gapCas = 8, gapRows = 8, labelH = 16, gapLab = 6;
  var casX = padP + radioW + gapRS;
  var randW = casX + casW + gapCas + casW + padP;
  var randH = padP + labelH + gapLab + rowH + gapRows + rowH + padP;
  var randDesign = $.NSView.alloc.initWithFrame($.NSMakeRect(24, H - 16 - randH, randW, randH));
  randDesign.setWantsLayer(true);
  randDesign.layer.setCornerRadius(12);
  randDesign.layer.setMasksToBounds(true);
  randDesign.layer.setBorderWidth(2);
  randDesign.layer.setBorderColor(culoareNS(BORDURA_IMPLICITA).CGColor);
  v.addSubview(randDesign);
  var yDeg = padP;
  var ySolid = padP + rowH + gapRows;
  var yCasSolid = ySolid + Math.floor((rowH - casH) / 2);
  var yCasDeg = yDeg + Math.floor((rowH - casH) / 2);
  var etichetaFundal = $.NSTextField.alloc.initWithFrame($.NSMakeRect(padP, ySolid + rowH + gapLab, randW - 2 * padP, labelH));
  etichetaFundal.setStringValue('Alege fundalul');
  etichetaFundal.setEditable(false); etichetaFundal.setSelectable(false); etichetaFundal.setBezeled(false); etichetaFundal.setDrawsBackground(false);
  etichetaFundal.setAlignment($.NSTextAlignmentLeft);
  etichetaFundal.setFont($.NSFont.systemFontOfSize(12));
  etichetaFundal.setTextColor(ink);
  randDesign.addSubview(etichetaFundal);
  var radioSolid = radioNou('Culoare solidă', padP, ySolid, radioW, rowH);
  var radioDegrade = radioNou('Degrade', padP, yDeg, radioW, rowH);
  var esantionSolid = esantionNou(casX, yCasSolid, 1);
  var esantionInceput = esantionNou(casX, yCasDeg, 2);
  var esantionSfarsit = esantionNou(casX + casW + gapCas, yCasDeg, 3);
  esantionSolid.setToolTip('Culoare');
  esantionInceput.setToolTip('Început');
  esantionSfarsit.setToolTip('Sfârșit');
  randDesign.addSubview(radioSolid);
  randDesign.addSubview(radioDegrade);
  randDesign.addSubview(esantionSolid);
  randDesign.addSubview(esantionInceput);
  randDesign.addSubview(esantionSfarsit);
  var pop = $.NSPopUpButton.alloc.initWithFramePullsDown($.NSMakeRect(40, 50, 150, 36), false);
  var m;
  for (m = 5; m <= 60; m += 5) {
    pop.addItemWithTitle(m + ' min');
  }
  pop.selectItemAtIndex(1);
  pop.setFont($.NSFont.systemFontOfSize(16));
  v.addSubview(pop);
  var bAmana = $.NSButton.alloc.initWithFrame($.NSMakeRect(202, 40, 180, 56));
  bAmana.setBordered(false); bAmana.setWantsLayer(true);
  bAmana.layer.setBackgroundColor(culoareNS([0.82, 0.72, 0.97]).CGColor);
  bAmana.layer.setCornerRadius(28);
  bAmana.layer.setBorderWidth(1.5);
  bAmana.layer.setBorderColor(culoareNS([0.42, 0.24, 0.82]).CGColor);
  bAmana.setTitle('Repetă în');
  bAmana.setFont($.NSFont.boldSystemFontOfSize(20));
  bAmana.setContentTintColor(culoareNS([0.20, 0.10, 0.40]));
  v.addSubview(bAmana);
  var b = $.NSButton.alloc.initWithFrame($.NSMakeRect(W - 40 - 240, 40, 240, 56));
  b.setBordered(false); b.setWantsLayer(true);
  b.layer.setBackgroundColor(culoareNS([0.42, 0.24, 0.82]).CGColor); b.layer.setCornerRadius(28);
  b.setTitle('Am înțeles'); b.setFont($.NSFont.boldSystemFontOfSize(22));
  b.setContentTintColor($.NSColor.whiteColor);
  b.setKeyEquivalent('\r');
  v.addSubview(b);
  var stare = { iesire: '' };
  ctxFereastra = {
    dir: dir, design: design, W: W, H: H, iv: iv, layer: L,
    titluView: titluView, textView: textView, randDesign: randDesign,
    etichetaFundal: etichetaFundal,
    radioSolid: radioSolid, radioDegrade: radioDegrade,
    esantionSolid: esantionSolid, esantionInceput: esantionInceput, esantionSfarsit: esantionSfarsit,
    ceasView: ceasView, ceasImagine: ceasImagine,
    dataZi: dataZi, dataLuna: dataLuna, dataAn: dataAn,
    culoareAce: ink, timer: null, panouTag: 1, handler: null,
    pop: pop, win: win, app: app, stare: stare, liniste: false
  };
  actualizeazaData(ctxFereastra);
  var handler = $.CursantReminderActiuni.alloc.init;
  ctxFereastra.handler = handler;
  bAmana.setTarget(handler); bAmana.setAction('amana:');
  b.setTarget(handler); b.setAction('inchide:');
  radioSolid.setTarget(handler); radioSolid.setAction('alegeSolid:');
  radioDegrade.setTarget(handler); radioDegrade.setAction('alegeDegrade:');
  esantionSolid.setTarget(handler); esantionSolid.setAction('apasaEsantion:');
  esantionInceput.setTarget(handler); esantionInceput.setAction('apasaEsantion:');
  esantionSfarsit.setTarget(handler); esantionSfarsit.setAction('apasaEsantion:');
  aplicaDesign(ctxFereastra, false);
  inchidePanouCulori();
  var timer = $.NSTimer.timerWithTimeIntervalTargetSelectorUserInfoRepeats(1.0, handler, 'tic:', null, true);
  $.NSRunLoop.currentRunLoop.addTimerForMode(timer, $.NSRunLoopCommonModes);
  ctxFereastra.timer = timer;
  win.makeKeyAndOrderFront(null);
  app.activateIgnoringOtherApps(true);
  win.makeKeyWindow;
  app.run;
  opresteTimer();
  inchidePanouCulori();
  win.orderOut(null);
  win.close();
  return stare.iesire;
}

function run(argv) {
  var rid = (argv && argv[0]) ? String(argv[0]) : '';
  var dir = directorPachet();
  var jsonPath = dir + '/remindere.json';
  var raw = citesteText(jsonPath);
  if (!raw) {
    alerta('Nu pot citi fișierul remindere.json din: ' + dir);
    return;
  }
  var lista;
  try {
    lista = JSON.parse(raw);
  } catch (e) {
    alerta('remindere.json nu este un JSON valid.');
    return;
  }
  var r = lista[rid];
  if (!rid || !r) {
    alerta('Reminder necunoscut: ' + (rid || '(lipsește id-ul)'));
    scrieJurnal(dir, acumLocal() + ' ' + rid + ' eroare=necunoscut');
    return;
  }
  try {
    while (true) {
      redaSunet();
      var rezultat = arataFereastra(r.titlu || 'Reminder', r.text || '', dir);
      if (rezultat && rezultat.indexOf('amana ') === 0) {
        var n = parseInt(rezultat.slice(6), 10);
        if (!(n >= 5 && n <= 60)) n = 5;
        scrieJurnal(dir, acumLocal() + ' ' + rid + ' amana ' + n + ' min');
        $.NSThread.sleepForTimeInterval(n * 60);
        continue;
      }
      scrieJurnal(dir, acumLocal() + ' ' + rid + ' ok');
      break;
    }
  } catch (e) {
    scrieJurnal(dir, acumLocal() + ' ' + rid + ' eroare=' + e);
    alerta('Nu am putut deschide fereastra: ' + e);
    return;
  }
  if (r.o_data === true || r.tip === 'o-data') {
    dezarmeazaOData(rid);
  }
}
