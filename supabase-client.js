// Shared Supabase client + admin session helpers.
// Requires supabase-config.js and the Supabase JS CDN script to load first.

var supabaseClient = null;
var supabaseReady = false;

(function initSupabase() {
  var configured =
    typeof SUPABASE_URL !== "undefined" &&
    typeof SUPABASE_ANON_KEY !== "undefined" &&
    SUPABASE_URL.indexOf("YOUR_SUPABASE") === -1;

  if (configured && window.supabase) {
    supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    supabaseReady = true;
  }
})();

function toggleAdminUI(isAdmin) {
  document.querySelectorAll(".admin-only").forEach(function (el) {
    el.style.display = isAdmin ? "" : "none";
  });
  var barText = document.getElementById("admin-bar-text");
  var bar = document.getElementById("admin-bar");
  if (bar) bar.style.display = isAdmin ? "block" : "none";
}

window.isAdminState = false;

async function checkAdmin() {
  if (!supabaseReady) {
    window.isAdminState = false;
    toggleAdminUI(false);
    return false;
  }
  var { data } = await supabaseClient.auth.getSession();
  var isAdmin = !!(data && data.session);
  window.isAdminState = isAdmin;
  toggleAdminUI(isAdmin);
  return isAdmin;
}

async function adminLogout() {
  if (!supabaseReady) return;
  await supabaseClient.auth.signOut();
  window.location.href = "index.html";
}

async function uploadPhoto(file, folder) {
  if (!supabaseReady || !file) return null;
  var path = folder + "/" + Date.now() + "-" + file.name.replace(/[^a-zA-Z0-9.\-_]/g, "");
  var { error } = await supabaseClient.storage.from("Photos").upload(path, file);
  if (error) {
    alert("사진 업로드 실패: " + error.message);
    return null;
  }
  var { data } = supabaseClient.storage.from("Photos").getPublicUrl(path);
  return data.publicUrl;
}

async function deletePhotoIfAny(photoUrl) {
  if (!supabaseReady || !photoUrl) return;
  var marker = "/object/public/Photos/";
  var idx = photoUrl.indexOf(marker);
  if (idx === -1) return;
  var path = photoUrl.substring(idx + marker.length);
  await supabaseClient.storage.from("Photos").remove([path]);
}

document.addEventListener("DOMContentLoaded", function () {
  checkAdmin();
});
