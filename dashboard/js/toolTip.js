import * as d3 from "d3";

// create a tooltip
const toolTip = d3
  .select("#parliament-seat")
  .append("g")
  .attr("class", "tooltip")
  .style("opacity", 0)
  .attr("class", "tooltip")
  .style("background-color", "white")
  .style("border", "solid")
  .style("border-width", "2px")
  .style("border-radius", "5px")
  .style("padding", "5px");

toolTip.select("g.tooltip").remove();

// create new tooltip
toolTip.append("g").attr("class", "tooltip");

// Three function that change the tooltip when user hover / move / leave a cell
const mouseover = function (d) {
  // Remove existing chart
  toolTip.style("opacity", 1);
  d3.select(this).style("stroke", "black").style("opacity", 1);
};
const mousemove = function (event, d) {

if (!d.mean) {
    toolTip
      .html(
        `<span><img src=${d.img}>`
        + "<br>" +
        d.name +
          "<br>" +
          d.Party +
          "<br>" +
          `House: ${d.house}`+
          "<br>" +
          d["St/Dis"] +
          "<br>" +
          `Govtrack Score ${d.score}`
      )
      .style("left", event.pageX + 70 + "px")
      .style("top", event.pageY + 30 + "px");
  } else {
    toolTip
      .html(
        `Group: ${d.govtrack_class}` +
          "<br>" +
          `Mean: ${d.mean}` +
          "<br>" +
          `Median: ${d.median}` +
          "<br>" +
          `Size: ${d.count}`
      )
      .style("left", event.pageX + 70 + "px")
      .style("top", event.pageY + 30 + "px");
  }
};

const mouseleave = function (d) {
  toolTip.style("opacity", 0);
  d3.select(this).style("stroke", "none").style("opacity", 1);
};

export { mousemove, mouseleave, mouseover };
