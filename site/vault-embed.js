/* demos.sgit.ai — minimal vault-app embed host.
 * Copied from SGit-AI/SGit-AI__Website assets/vault-embed.js (one change: sandbox
 * gains allow-popups so catalogue download links can open in a new tab).
 *
 * Opens a vault APP (its index.html, running as an app) inside a sandboxed iframe on a
 * normal web page, from nothing but { endpoint, vault_id, read_key }. This is the same
 * shape SG/Vault's own vault-in-vault uses: an opaque-origin frame, a `window.sg` bridge
 * spoken over postMessage, and every vault read served by the host.
 *
 * Scope, honestly: this is our MINIMAL host — enough bridge for read-only apps
 * (sg.vfs.readText / sg.vfs.read / sg.loadCss / sg.loadJs, all reads, no mutations by
 * construction: the embed only ever holds a read key, which cannot write). The canonical,
 * full-featured host lives in the SG/Vault UI; a briefing asking to reuse that code is at
 * /briefs/briefing-sgvault-ui-embed.md, and this file is what it replaces when answered.
 *
 * Usage: SGVaultEmbed.mount(el, { endpoint, vault_id, read_key, entry })
 */
(function () {
  'use strict';
  var enc = new TextEncoder(), dec = new TextDecoder();

  function hexToBytes(hex) {
    var out = new Uint8Array(hex.length / 2);
    for (var i = 0; i < out.length; i++) out[i] = parseInt(hex.substr(i * 2, 2), 16);
    return out;
  }
  function bytesToHex(b) {
    var s = ''; for (var i = 0; i < b.length; i++) s += b[i].toString(16).padStart(2, '0'); return s;
  }
  function b64ToBytes(b64) {
    var bin = atob(b64), out = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
    return out;
  }

  // ---- the read-only vault reader (same derivations as assets/vault-docs.js)
  function Reader(cfg) {
    this.endpoint = cfg.endpoint.replace(/\/$/, '');
    this.vaultId  = cfg.vault_id;
    this.readKey  = cfg.read_key;
    this.mem      = new Map();
  }
  Reader.prototype.init = async function () {
    if (!(window.crypto && window.crypto.subtle))
      throw new Error('Web Crypto unavailable — the embed needs a secure context (https or localhost).');
    var raw = hexToBytes(this.readKey);
    this.aesKey  = await crypto.subtle.importKey('raw', raw, 'AES-GCM', false, ['decrypt']);
    this.hmacKey = await crypto.subtle.importKey('raw', raw, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
    return this;
  };
  Reader.prototype.fileId = async function (domain) {
    var mac = await crypto.subtle.sign('HMAC', this.hmacKey, enc.encode(domain));
    return bytesToHex(new Uint8Array(mac)).slice(0, 12);
  };
  Reader.prototype.decrypt = async function (bytes) {
    var pt = await crypto.subtle.decrypt({ name: 'AES-GCM', iv: bytes.slice(0, 12), tagLength: 128 },
                                         this.aesKey, bytes.slice(12));
    return new Uint8Array(pt);
  };
  Reader.prototype.raw = async function (path) {
    var r = await fetch(this.endpoint + '/api/vault/read/' + this.vaultId + '/' + path,
                        { cache: path.indexOf('-imm-') !== -1 ? 'default' : 'no-store' });
    if (!r.ok) throw new Error('HTTP ' + r.status + ' for ' + path);
    return new Uint8Array(await r.arrayBuffer());
  };
  Reader.prototype.obj = async function (id) {
    if (this.mem.has(id)) return this.mem.get(id);
    var plain = await this.decrypt(await this.raw('bare/data/' + id));
    this.mem.set(id, plain);
    return plain;
  };
  Reader.prototype.objJson = async function (id) { return JSON.parse(dec.decode(await this.obj(id))); };
  Reader.prototype.decB64  = async function (b64) { return b64 ? dec.decode(await this.decrypt(b64ToBytes(b64))) : ''; };

  Reader.prototype.open = async function () {
    var refId  = 'ref-pid-muw-' + await this.fileId('sg-vault-v1:file-id:ref:' + this.vaultId);
    var ref    = JSON.parse(dec.decode(await this.decrypt(await this.raw('bare/refs/' + refId))));
    var commit = await this.objJson(ref.commit_id);
    this.files = {};
    await this.walk(commit.tree_id, '');
    return this;
  };
  Reader.prototype.walk = async function (treeId, prefix) {
    var tree = await this.objJson(treeId);
    for (var i = 0; i < (tree.entries || []).length; i++) {
      var e = tree.entries[i], name = await this.decB64(e.name_enc);
      var full = prefix ? prefix + '/' + name : name;
      if (e.tree_id) await this.walk(e.tree_id, full);
      else this.files[full] = e.blob_id;
    }
  };
  Reader.prototype.readBytes = async function (path) {
    path = path.replace(/^\.?\//, '');
    if (!this.files[path]) throw new Error('not in vault: ' + path);
    return this.obj(this.files[path]);
  };
  Reader.prototype.readText = async function (path) { return dec.decode(await this.readBytes(path)); };

  // ---- the bridge shim injected into the app frame.
  // Runs inside the sandboxed iframe; everything routes to the host page over postMessage.
  var SHIM = "(function(){'use strict';var seq=0,pending={};" +
    "function rpc(op,path){return new Promise(function(res,rej){var id=++seq;pending[id]=[res,rej];" +
    "parent.postMessage({sgvEmbed:1,id:id,op:op,path:path},'*');});}" +
    "window.addEventListener('message',function(ev){var m=ev.data;if(!m||m.sgvEmbed!==1||!pending[m.id])return;" +
    "var p=pending[m.id];delete pending[m.id];m.ok?p[0](m.data):p[1](new Error(m.error||'embed rpc failed'));});" +
    "window.sg={embedded:true,readOnly:true," +
    "vfs:{readText:function(p){return rpc('readText',p);}," +
    "read:function(p){return rpc('readB64',p).then(function(b64){var bin=atob(b64),o=new Uint8Array(bin.length);" +
    "for(var i=0;i<bin.length;i++)o[i]=bin.charCodeAt(i);return o;});}}," +
    "loadCss:function(p){return rpc('readText',p).then(function(t){var s=document.createElement('style');" +
    "s.textContent=t;document.head.appendChild(s);});}," +
    "loadJs:function(p){return rpc('readText',p).then(function(t){(0,eval)(t);});}};" +
    // Vault-path <img> support: apps set img.src to relative vault paths (per the authoring
    // contract, from JS). In a srcdoc frame those resolve against an opaque origin and 404,
    // so intercept them — read the bytes over the bridge, swap in a blob: URL. Same job the
    // real host's interceptor does.
    "var MIME={png:'image/png',jpg:'image/jpeg',jpeg:'image/jpeg',webp:'image/webp',gif:'image/gif',svg:'image/svg+xml'};" +
    "function vaultImg(img){var p=img.getAttribute('src');" +
    "if(!p||/^(data:|blob:|https?:|\\/\\/)/.test(p))return;" +
    "img.removeAttribute('src');" +
    "rpc('readB64',p.replace(/^\\.?\\//,'')).then(function(b64){" +
    "var ext=(p.split('.').pop()||'').toLowerCase();" +
    "var bin=atob(b64),o=new Uint8Array(bin.length);for(var i=0;i<bin.length;i++)o[i]=bin.charCodeAt(i);" +
    "img.src=URL.createObjectURL(new Blob([o],{type:MIME[ext]||'application/octet-stream'}));" +
    "}).catch(function(){});}" +
    "new MutationObserver(function(ms){ms.forEach(function(m){" +
    "if(m.type==='attributes'&&m.target.tagName==='IMG')vaultImg(m.target);" +
    "(m.addedNodes||[]).forEach(function(n){if(n.tagName==='IMG')vaultImg(n);" +
    "else if(n.querySelectorAll)n.querySelectorAll('img').forEach(vaultImg);});});})" +
    ".observe(document.documentElement,{subtree:true,childList:true,attributes:true,attributeFilter:['src']});" +
    "document.addEventListener('DOMContentLoaded',function(){document.querySelectorAll('img').forEach(vaultImg);});" +
    // Link handling: in-page anchors must scroll manually (assigning location.hash re-navigates
    // a srcdoc frame), and relative .html links become a navigation request to the host, which
    // remounts the frame on the new entry — vault apps can cross-link inside the embed.
    "document.addEventListener('click',function(e){var a=e.target&&e.target.closest&&e.target.closest('a[href]');" +
    "if(!a)return;var h=a.getAttribute('href');" +
    "if(/^#/.test(h)){e.preventDefault();var t=document.getElementById(h.slice(1));if(t)t.scrollIntoView({behavior:'smooth'});return;}" +
    "if(/^(https?:|mailto:|data:|blob:)/.test(h))return;" +
    "if(/\\.html(#.*)?$/.test(h)){e.preventDefault();parent.postMessage({sgvEmbed:1,nav:h.split('#')[0]},'*');}" +
    "},true);" +
    "})();";

  // ---- mount
  async function mount(el, cfg) {
    el.innerHTML = '<div class="sgv-embed-loading">opening vault ' + cfg.vault_id + ' — deriving ids, fetching ciphertext, decrypting…</div>';
    var reader = await new Reader(cfg).init();
    await reader.open();
    var entry = cfg.entry || 'index.html';
    var html  = await reader.readText(entry);

    // Inject the bridge shim so it runs before any of the app's own scripts.
    html = /<head[^>]*>/i.test(html)
      ? html.replace(/<head[^>]*>/i, function (m) { return m + '\n<script>' + SHIM + '<\/script>'; })
      : '<script>' + SHIM + '<\/script>' + html;

    var frame = document.createElement('iframe');
    frame.className = 'sgv-embed-frame';
    // allow-scripts only: opaque origin, no same-origin powers, no top-navigation,
    // no popups. The frame can talk to us solely via postMessage.
    frame.setAttribute('sandbox', 'allow-scripts allow-popups');
    frame.setAttribute('referrerpolicy', 'no-referrer');
    frame.setAttribute('title', cfg.title || ('vault ' + cfg.vault_id));
    frame.srcdoc = html;

    // Serve the app's reads — and only reads; there is nothing else to serve.
    window.addEventListener('message', async function (ev) {
      if (ev.source !== frame.contentWindow) return;
      var m = ev.data;
      if (!m || m.sgvEmbed !== 1 || !m.id || typeof m.path !== 'string') return;
      var reply = { sgvEmbed: 1, id: m.id, ok: false };
      try {
        if (m.op === 'readText') { reply.data = await reader.readText(m.path); reply.ok = true; }
        else if (m.op === 'readB64') {
          var bytes = await reader.readBytes(m.path), bin = '';
          for (var i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
          reply.data = btoa(bin); reply.ok = true;
        }
        else reply.error = 'unknown op: ' + m.op;
      } catch (e) { reply.error = String(e && e.message || e); }
      ev.source.postMessage(reply, '*');
    });

    // Cross-app navigation: a vault app clicked a relative .html link — remount this
    // element on the new entry. Same vault, same reader, different app.
    var navigated = false;
    window.addEventListener('message', function (ev) {
      if (navigated || ev.source !== frame.contentWindow) return;
      var m = ev.data;
      if (m && m.sgvEmbed === 1 && typeof m.nav === 'string' && /\.html$/.test(m.nav)) {
        navigated = true;
        el.innerHTML = '';
        mount(el, Object.assign({}, cfg, { entry: m.nav.replace(/^\.?\//, '') }));
      }
    });

    // The app signals readiness the standard way; we clear the loading note on it,
    // or after a grace period for apps that render without announcing.
    var done = false;
    function ready() { if (done) return; done = true; el.querySelectorAll('.sgv-embed-loading').forEach(function (n) { n.remove(); }); }
    window.addEventListener('message', function (ev) {
      if (ev.source === frame.contentWindow && ev.data && ev.data.type === 'sg-app-ready') ready();
    });
    setTimeout(ready, 4000);

    el.appendChild(frame);
    return { reader: reader, frame: frame, files: Object.keys(reader.files) };
  }

  window.SGVaultEmbed = { mount: mount };
})();
