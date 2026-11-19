<!DOCTYPE html>
<html>
<head>
<title>Ridoy.Net - Access Control</title>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Cache-Control" content="no-cache">
<link rel="shortcut icon" href="images/favicon.ico">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<style>
.portal-wrap{padding:18px}
.portal-card{background:#10243c;border:1px solid #23415f;border-radius:14px;padding:18px;margin:0 0 18px;color:#f4f8ff}
.portal-card h3{margin:0 0 14px;color:#37d6e8;font-size:19px}
.portal-help{color:#9fb6cc;font-size:13px}
.portal-table{width:100%;border-collapse:collapse;background:#0b1b2d}
.portal-table th,.portal-table td{padding:10px 9px;border-bottom:1px solid #23415f;text-align:left;vertical-align:middle;font-size:13px}
.portal-table th{color:#9fb6cc;font-weight:700}
.portal-table td{color:#f4f8ff;overflow-wrap:anywhere}
.portal-btn{border:0;border-radius:7px;padding:7px 11px;margin:2px;font-weight:700;cursor:pointer}
.portal-approve{background:#32c99b;color:#06251d}
.portal-reject,.portal-revoke{background:#d85a66;color:#fff}
.portal-muted{color:#9fb6cc}
.portal-status{display:inline-block;padding:4px 8px;border-radius:20px;font-size:11px;background:#173c39;color:#a8f2cf}
.portal-status.off{background:#47303a;color:#ffc6ce}
.portal-message{padding:10px 12px;border-radius:8px;margin-bottom:12px;display:none;background:#163a3b;color:#c3f7e6}
.portal-message.error{background:#4a2630;color:#ffd3d9}
@media(max-width:760px){.portal-table{display:block;overflow-x:auto;white-space:nowrap}.portal-wrap{padding:8px}}
</style>
<script>
var portalPrevious = {};
var portalRequest = null;

function portalNode(tag, text) {
    var el = document.createElement(tag);
    if (text !== undefined && text !== null) el.textContent = String(text);
    return el;
}
function portalCell(row, text) {
    var td = portalNode("td", text);
    row.appendChild(td);
    return td;
}
function portalButton(row, label, cls, action, ip) {
    var td = row.lastChild;
    var btn = portalNode("button", label);
    btn.className = "portal-btn " + cls;
    btn.type = "button";
    btn.onclick = function(){ portalAction(action, ip); };
    td.appendChild(btn);
}
function portalMessage(message, isError) {
    var el = document.getElementById("portalMessage");
    el.textContent = message || "";
    el.className = "portal-message" + (isError ? " error" : "");
    el.style.display = message ? "block" : "none";
}
function portalBytes(n) {
    n = Number(n || 0);
    if (n >= 1073741824) return (n / 1073741824).toFixed(2) + " GB";
    if (n >= 1048576) return (n / 1048576).toFixed(2) + " MB";
    if (n >= 1024) return (n / 1024).toFixed(2) + " KB";
    return Math.round(n) + " B";
}
function portalRate(current, previous, elapsed) {
    if (!previous || elapsed <= 0 || current < previous) return "0.00 Mbps";
    return ((current - previous) * 8 / elapsed / 1000000).toFixed(2) + " Mbps";
}
function portalAction(action, ip) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/ridoy_portal_admin.cgi", true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== 4) return;
        try {
            var result = JSON.parse(xhr.responseText);
            portalMessage(result.message || (result.ok ? "Done." : "Action failed."), !result.ok);
        } catch(e) {
            portalMessage("Could not read the router response.", true);
        }
        portalLoad();
    };
    xhr.send("action=" + encodeURIComponent(action) + "&ip=" + encodeURIComponent(ip));
}
function portalLoad() {
    var xhr = new XMLHttpRequest();
    var status = document.getElementById("portalRefreshTime");
    if (status) status.textContent = "Contacting router…";
    xhr.open("GET", "/ridoy_portal_admin.cgi?action=list&_=" + new Date().getTime(), true);
    xhr.timeout = 8000;
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== 4) return;
        if (xhr.status !== 200) {
            if (status) status.textContent = "Router API HTTP error: " + xhr.status;
            portalMessage("Router API request failed (HTTP " + xhr.status + "). Check router login and CGI route.", true);
            return;
        }
        try {
            var data = JSON.parse(xhr.responseText);
            if (!data || data.ok !== true) {
                var reason = data && data.message ? data.message : "Router API returned an unexpected response.";
                if (status) status.textContent = reason;
                portalMessage(reason, true);
                return;
            }
            portalRenderPending(data.pending || []);
            portalRenderApproved(data.approved || []);
            if (status) status.textContent = "Connected · Updated " + new Date().toLocaleTimeString();
            portalMessage("", false);
        } catch(e) {
            if (status) status.textContent = "Router returned non-JSON data.";
            portalMessage("Invalid router response (HTTP 200). First response: " + String(xhr.responseText || "").substring(0, 120), true);
        }
    };
    xhr.ontimeout = function() {
        if (status) status.textContent = "Router API timed out.";
        portalMessage("No response from /ridoy_portal_admin.cgi within 8 seconds.", true);
    };
    xhr.onerror = function() {
        if (status) status.textContent = "Network error contacting router.";
        portalMessage("Network error while contacting the router API.", true);
    };
    xhr.send(null);
}
function portalRenderPending(items) {
    var body = document.getElementById("pendingBody");
    body.innerHTML = "";
    document.getElementById("pendingCount").textContent = items.length;
    if (!items.length) {
        var row = portalNode("tr");
        var td = portalCell(row, "No pending access requests.");
        td.colSpan = 5;
        td.className = "portal-muted";
        body.appendChild(row);
        return;
    }
    for (var i=0; i<items.length; i++) {
        var item = items[i], row = portalNode("tr");
        portalCell(row, item.name);
        portalCell(row, item.mac);
        portalCell(row, item.ip);
        portalCell(row, item.stamp ? new Date(item.stamp * 1000).toLocaleString() : "—");
        var actions = portalNode("td");
        row.appendChild(actions);
        portalButton(row, "Approve", "portal-approve", "approve", item.ip);
        portalButton(row, "Reject", "portal-reject", "reject", item.ip);
        body.appendChild(row);
    }
}
function portalRenderApproved(items) {
    var body = document.getElementById("approvedBody");
    var now = new Date().getTime();
    body.innerHTML = "";
    document.getElementById("approvedCount").textContent = items.length;
    if (!items.length) {
        var row = portalNode("tr");
        var td = portalCell(row, "No approved devices yet.");
        td.colSpan = 7;
        td.className = "portal-muted";
        body.appendChild(row);
        portalPrevious = {};
        return;
    }
    var nextPrevious = {};
    for (var i=0; i<items.length; i++) {
        var item = items[i], row = portalNode("tr");
        var old = portalPrevious[item.ip];
        var elapsed = old ? (now - old.at) / 1000 : 0;
        var downRate = portalRate(Number(item.rx || 0), old ? old.rx : null, elapsed);
        var upRate = portalRate(Number(item.tx || 0), old ? old.tx : null, elapsed);
        nextPrevious[item.ip] = {rx:Number(item.rx || 0), tx:Number(item.tx || 0), at:now};
        portalCell(row, item.name);
        portalCell(row, item.mac);
        portalCell(row, item.ip);
        var status = portalCell(row, "");
        var badge = portalNode("span", item.active ? "Active" : "Expired / Offline");
        badge.className = item.active ? "portal-status" : "portal-status off";
        status.appendChild(badge);
        portalCell(row, "↓ " + downRate + " / ↑ " + upRate);
        portalCell(row, "↓ " + portalBytes(item.rx) + " / ↑ " + portalBytes(item.tx));
        var actions = portalNode("td");
        row.appendChild(actions);
        portalButton(row, "Revoke", "portal-revoke", "revoke", item.ip);
        body.appendChild(row);
    }
    portalPrevious = nextPrevious;
}
function initial() {
    /* Start the router API request first. A theme/menu JavaScript error
       must never leave this page stuck on "Waiting for router data". */
    portalLoad();
    window.setInterval(portalLoad, 5000);
    try { if (typeof show_banner === "function") show_banner(0); } catch(e) {}
    try { if (typeof show_menu === "function") show_menu(7, 5, 6); } catch(e) {}
    try { if (typeof show_footer === "function") show_footer(); } catch(e) {}
}
</script>
</head>
<body onload="initial();">
<div class="wrapper">
  <div class="container-fluid" style="padding-right:0">
    <div class="row-fluid">
      <div class="span3"><center><div id="logo"></div></center></div>
      <div class="span9"><div id="TopBanner"></div></div>
    </div>
  </div>
  <div class="container-fluid">
    <div class="row-fluid">
      <div class="span3">
        <div class="well sidebar-nav side_nav" style="padding:0">
          <ul id="mainMenu" class="clearfix"></ul>
          <ul class="clearfix"><li><div id="subMenu" class="accordion"></div></li></ul>
        </div>
      </div>
      <div class="span9">
        <div class="box well grad_colour_dark_blue">
          <h2 class="box_head round_top">Ridoy.Net - Device Access Control</h2>
          <div class="round_bottom portal-wrap">
            <div id="portalMessage" class="portal-message"></div>
            <div class="portal-card">
              <h3>Pending Requests (<span id="pendingCount">0</span>)</h3>
              <p class="portal-help">Devices listed here have no Internet access until you approve them.</p>
              <table class="portal-table">
                <thead><tr><th>Name</th><th>MAC Address</th><th>IP Address</th><th>Requested</th><th>Action</th></tr></thead>
                <tbody id="pendingBody"><tr><td colspan="5">Loading…</td></tr></tbody>
              </table>
            </div>
            <div class="portal-card">
              <h3>Approved Devices (<span id="approvedCount">0</span>)</h3>
              <p class="portal-help">Live rates are calculated from router firewall byte counters. Access expires after 24 hours.</p>
              <table class="portal-table">
                <thead><tr><th>Name</th><th>MAC Address</th><th>IP Address</th><th>Status</th><th>Current Speed</th><th>Total Usage</th><th>Action</th></tr></thead>
                <tbody id="approvedBody"><tr><td colspan="7">Loading…</td></tr></tbody>
              </table>
            </div>
            <p id="portalRefreshTime" class="portal-help">Waiting for router data…</p>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div id="footer"></div>
</div>
</body>
</html>