document.addEventListener("DOMContentLoaded", function () {
  var toggle = document.getElementById("nav-toggle");
  var nav = document.querySelector(".nav-links");
  if (!toggle || !nav) return;

  var iconOpen = toggle.querySelector(".icon-open");
  var iconClose = toggle.querySelector(".icon-close");

  function setOpen(isOpen) {
    nav.classList.toggle("open", isOpen);
    toggle.setAttribute("aria-expanded", isOpen ? "true" : "false");
    if (iconOpen) iconOpen.style.display = isOpen ? "none" : "";
    if (iconClose) iconClose.style.display = isOpen ? "" : "none";
  }

  toggle.addEventListener("click", function () {
    setOpen(!nav.classList.contains("open"));
  });

  nav.querySelectorAll("a").forEach(function (a) {
    a.addEventListener("click", function () { setOpen(false); });
  });
});
