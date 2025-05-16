document.addEventListener("turbo:load", function() {
  const select = document.getElementById("theme-select");
  if (!select) return;

  const theme = document.documentElement.getAttribute("data-theme") || "system";
  select.value = theme;
  select.style.visibility = "visible";

  select.addEventListener("change", function() {
    const theme = this.value;
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem("mission_control_theme", theme);
  });
});
