import "./css/style.css";
import * as d3 from "d3";

import dashboard from "./js/dashboard";

// open sidebar
const openNav = () => {
  const sideBarStatus = document.getElementById("sidebar");
  const dashArea = document.getElementById("main");

  if (sideBarStatus.style.visibility === "collapse") {
    dashArea.classList.remove("col-lg-10");
    dashArea.classList.add("col-lg-7");
    dashboard();

    sideBarStatus.style.opacity = "1";
    sideBarStatus.style.visibility = "visible";
  } else {
    dashArea.classList.remove("col-lg-7");
    dashArea.classList.add("col-lg-10");
    dashboard();
    sideBarStatus.style.opacity = "0";
    sideBarStatus.style.visibility = "collapse";
  }
};

// event listener on click
document.getElementById("about").addEventListener("click", openNav);
document.getElementById("close-sidebar").addEventListener("click", openNav);

dashboard();

// Add an event listener that run the function when dimension change
window.addEventListener("resize", dashboard);
