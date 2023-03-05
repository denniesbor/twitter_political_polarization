import "./css/style.css";
import * as d3 from "d3";

import dashboard from "./js/dashboard";

dashboard();

// Add an event listener that run the function when dimension change
window.addEventListener("resize", dashboard);
