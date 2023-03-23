import * as d3 from "d3";

// mouse hover tool tip for the parliamentary chart and boxplot

const tippingTool = (toolTip) => {
  const mapParty = { I: "Independent", R: "Republican", D: "Democrat" };

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
          `<img src=${d.img}>` +
            `<h2>${d.name}</h2>` +
            `<p class=${`party ${mapParty[d.Party]}`}>Party: ${
              mapParty[d.Party]
            }</p>` +
            `<p>Congress: ${
              d.house.charAt(0).toUpperCase() + d.house.slice(1)
            }</p>` +
            `<p>St/Dis: ${d["St/Dis"]}</p>` +
            `<p>Govtrack Score ${d.score}</p>`
        )
        .style("left", event.pageX + 10 + "px")
        .style("top", event.pageY + 10 + "px");
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
        .style("left", event.pageX + 10 + "px")
        .style("top", event.pageY + 10 + "px");
    }
  };

  const mouseleave = function (d) {
    toolTip.style("opacity", 0);
    d3.select(this).style("stroke", "none").style("opacity", 1);
  };

  return { mousemove, mouseleave, mouseover };
};

export default tippingTool;
