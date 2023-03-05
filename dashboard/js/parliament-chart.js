import { getXYCoordinates } from "./data.js";
import { colorPicker } from "./colors.js";
import * as d3 from "d3";

export const parliamentChart = () => {
  // Dimensions of the graphic

  let width;
  let height;
  let data;
  let rawData;


  // //////////////////////////////////////////////////////////////////////////
  // Selection call
  //
  // This function gets called on instances such as:
  //    d3.select('g').call(my())
  const my = (selection) => {
    if (width === 0) {
      // Sets the width based on our selected container
      width = selection.node().getBoundingClientRect().width;
    }

    const totalPoints = data.length;

    // The locations of all the points
    const locations_ = getXYCoordinates(height, width, 0.4, totalPoints);

    // Add locations to the rawData object
    locations_.forEach((coords, i) => (data[i] = { ...data[i], ...coords }));

    // Get the processed data (filter for entries that have x and y locations)
    const processedData = data.filter((r) => r.x && r.y);

    // Remove existing chart
    selection.select("g.parliament-chart").remove();

    // Add new chart
    const innerSelection = selection
      .append("g")
      .attr("class", "parliament-chart");

    // First remove any existing debug lines
    innerSelection.select("g.debug").remove();

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
      // Remove existing chart
      toolTip
        .html(
          d.name +
            "<br>" +
            d.Party +
            "<br>" +
            d["St/Dis"] +
            "<br>" +
            `Govtrack Score ${d.score}`
        )
        .style("left", event.pageX + 70 + "px")
        .style("top", event.pageY + 30 + "px");
    };
    const mouseleave = function (d) {
      toolTip.style("opacity", 0);
      d3.select(this).style("stroke", "none").style("opacity", 1);
    };

    innerSelection
      .selectAll("circle")
      .data(processedData)
      .join(
        (enter) =>
          enter
            .append("circle")
            .attr("cx", (d) => d.x)
            .attr("cy", (d) => d.y)
            .attr("r", (d) => d.seatRadius)
            .attr(
              "fill",
              (d) => colorPicker(d.Party, d.govtrack_class) || "#AAA"
            ),

        (update) =>
          update
            .transition()
            .duration(750)
            .attr("cx", (d) => d.x)
            .attr("cy", (d) => d.y),

        (exit) => exit.remove()
      )
      .on("mouseover", mouseover)
      .on("mousemove", mousemove)
      .on("mouseleave", mouseleave);
  };

  // //////////////////////////////////////////////////////////////////////////
  // Getters and Setters

  // Sets the width and the height of the graphic

  my.width = function (_) {
    return arguments.length ? ((width = +_), my) : width;
  };

  my.height = function (_) {
    return arguments.length ? ((height = +_), my) : height;
  };

  my.sections = function (_) {
    return arguments.length ? ((sections = +_), my) : sections;
  };
  my.sectionGap = function (_) {
    return arguments.length ? ((sectionGap = +_), my) : sectionGap;
  };
  my.seatRadius = function (_) {
    return arguments.length ? ((seatRadius = +_), my) : seatRadius;
  };
  my.rowHeight = function (_) {
    return arguments.length ? ((rowHeight = +_), my) : rowHeight;
  };

  my.data = function (_) {
    return arguments.length ? ((data = _), my) : data;
  };

  // enable / disable debug mode
  my.debug = (b) => {
    debug = !!b;
    return my;
  };

  return my;
};
