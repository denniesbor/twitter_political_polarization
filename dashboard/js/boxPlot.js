import { colorPicker } from "./colors.js";
import { mousemove, mouseleave, mouseover } from "./toolTip.js";
import * as d3 from "d3";

export const boxPlot = () => {
  let data;
  let tTestData;
  let height;
  let width;
  let divWidth;

  const my = (selection) => {
    const scaleFactor = 0.1;
    // let startWidth = width * 0.3

    // Remove existing chart
    selection.select("g.dataviz").remove();

    // Add new chart
    const innerSelection = selection.append("g").attr("class", "dataviz");

    const politicalGroups = d3
      .scaleOrdinal()
      .domain(data.map((d) => d.govtrack_class));

    // Show the x scale
    const x = d3
      .scaleBand()
      .range([width * 0.1, width - width * 0.05])
      .domain(politicalGroups.domain())
      .padding(1);

    innerSelection
      .append("g")
      .attr("transform", `translate(0,${height - height * scaleFactor + 10})`)
      .transition()
      .duration(1500)
      .delay(1000)
      .call(d3.axisBottom(x))
      .attr("stroke-width", 1.5)
      .selectAll("text")
      .attr("transform", "translate(-40,30)rotate(-45)")
      .attr("font-size", "12px");

    // Show the y scale

    console.log()

    const y = d3
      .scaleLinear()
      .domain(d3.extent(data.map((d) => d.max).concat(data.map((d) => d.min))))
      .range([height - height * scaleFactor, height * 0.2]);
    innerSelection
      .append("g")
      .attr("transform", `translate(${width * 0.1},0)`)
      .transition()
      .duration(1500)
      .delay(1000)
      .call(d3.axisLeft(y))
      .attr("stroke-width", 1.5)
      .attr("font-size", "12px");

    // Color scale
    const myColor = d3
      .scaleSequential()
      .interpolator(d3.interpolateInferno)
      .domain([-1, 1]);

    // Show the main vertical line
    innerSelection
      .selectAll("vertLines")
      .data(data)
      .join(
        (enter) =>
          enter
            .append("line")
            .transition()
            .duration(2000)
            .delay(1000)
            .attr("x1", (d) => x(d.govtrack_class))
            .attr("x2", (d) => x(d.govtrack_class))
            .attr("y1", (d) => y(d.min))
            .attr("y2", (d) => y(d.max))
            .attr("stroke", "black")
            .attr("stroke-width", 1.5)
            .style("width", 40),

        (update) =>
          update
            .attr("x1", (d) => x(d.govtrack_class))
            .attr("x2", (d) => x(d.govtrack_class))
            .attr("y1", (d) => y(d.min))
            .attr("y2", (d) => y(d.max)),

        (exit) => exit.remove()
      );

    // rectangle for the main box
    const boxWidth = width * 0.1;

    innerSelection
      .selectAll("boxes")
      .data(data)
      .join(
        (enter) =>
          enter
            .append("rect")
            .transition() // and apply changes to all of them
            .duration(2000)
            .delay(1000)
            .attr("x", (d) => x(d.govtrack_class) - boxWidth / 2)
            .attr("y", (d) => y(d.q3))
            .attr("height", (d) => y(d.q1) - y(d.q3))
            .attr("width", boxWidth)
            .attr("stroke", "black")
            .attr("stroke-width", 1.5)
            .attr(
              "fill",
              (d) => colorPicker(null, d.govtrack_class) || "#2c49d5"
            ),
        (update) =>
          update
            .attr("x", (d) => x(d.govtrack_class) - boxWidth / 2)
            .attr("y", (d) => y(d.q3))
            .attr("height", (d) => y(d.q1) - y(d.q3))
            .attr("width", boxWidth),
        (exit) => exit.remove()
      )
      .on("mouseover", mouseover)
      .on("mousemove", mousemove)
      .on("mouseleave", mouseleave);

    // show median, max and min horizontal lines

    const horizontalLines = (type, value, divider) => {
      // Show the horizontal line
      innerSelection
        .selectAll(type)
        .data(data)
        .join(
          (enter) =>
            enter
              .append("line")
              .merge(innerSelection) // get the already existing elements as well
              .transition() // and apply changes to all of them
              .duration(2000)
              .delay(1000)
              .attr("y1", (d) => y(d[value]))
              .attr("y2", (d) => y(d[value]))
              .attr("x1", (d) => x(d.govtrack_class) - boxWidth / divider)
              .attr("x2", (d) => x(d.govtrack_class) + boxWidth / divider)
              .attr("stroke", "black")
              .attr("stroke-width", 1.5)
              .style("width", 80),

          (update) =>
            update
              .attr("y1", (d) => y(d[value]))
              .attr("y2", (d) => y(d[value]))
              .attr("x1", (d) => x(d.govtrack_class) - boxWidth / divider)
              .attr("x2", (d) => x(d.govtrack_class) + boxWidth / divider),

          (exit) => exit.remove()
        );
    };

    // median lines
    horizontalLines("minLines", "median", 2);

    // min lines
    horizontalLines("minLines", "min", 4);

    // max lines
    horizontalLines("minLines", "max", 4);

    //   show t-test whiskers
    // number of times lineGenerator is called

    let max;
    let currentMax;
    let textProps = [];

    const lineGenerator = (d, pValue) => {
      let name1;
      let name2;
      let path = [];

      const customFilter = (arr, searchtxt) => {
        return arr.reduce(
          (a, c, i) => (c.match(searchtxt) ? [...a, i] : a),
          []
        );
      };

      const getMax = (group) => {
        let obj = data.find((d) => d.govtrack_class === group);

        return obj.max;
      };

      if (isNaN(+pValue)) {
        let str = "*";
        let groups = politicalGroups.domain();
        let element1 = d.split("-")[0];
        let element2 = d.split("-")[1];

        let indexOne = customFilter(groups, element1).at(-1);
        let indexTwo = customFilter(groups, element2).at(-1);

        if (!indexOne) {
          groups.push(element1);
          indexOne = customFilter(groups, element1).at(-1);
        }
        if (!indexTwo) {
          groups.push(element2);
          indexTwo = customFilter(groups, element2).at(-1);
        }

        // Show the x scale
        const newXScale = d3
          .scaleBand()
          .range([width * 0.1, width - width * 0.05])
          .domain(groups)
          .padding(1);

        str = str.repeat(pValue.split("*").slice(1).length);

        let groupOneName = groups[indexOne];
        let groupTwoName = groups[indexTwo];

        getMax(groupOneName) > getMax(groupTwoName)
          ? ((currentMax = getMax(groupOneName)),
            (name1 = groupOneName),
            (name2 = groupTwoName))
          : ((currentMax = getMax(groupTwoName)),
            (name1 = groupTwoName),
            (name2 = groupOneName));

        // check if max exists

        if (max) {
          max > currentMax ? (max = max + 0.07) : (max = currentMax + 0.08);
        } else {
          max = currentMax;
        }

        let moveToX = newXScale(name1);
        let moveToY = y(max + 0.05);

        let moveToXTop = y(max + 0.1);
        let moveToRight = newXScale(name2);
        let moveToRightDown = y(max + 0.05);

        path = [
          [moveToX, moveToY],
          [moveToX, moveToXTop],
          [moveToRight, moveToXTop],
          [moveToRight, moveToRightDown],
        ];

        let d3Gen = d3.line();

        // getting the lcoation of the pvalue text
        let textX = (x(name1) + x(name2)) / 2;
        let textY = moveToXTop;

        textProps.push([textX, textY, str]);

        return d3Gen(path);
      } else {
        return [null];
      }
    };

    innerSelection
      .selectAll("whiskers")
      .data(tTestData)
      .join(
        (enter) =>
          enter
            .append("path")
            .transition()
            .delay(2500)
            .duration(1000)
            .attr("d", (d) => lineGenerator(d[0], d[1]))
            .attr("stroke", "black")
            .attr("stroke-width", 1.5)
            .attr("fill", "none"),
        (update) => update.attr("d", (d) => lineGenerator(d[0], d[1])),

        (exit) => exit.remove()
      );

    // add p value texts

    innerSelection
      .selectAll("p-values")
      .data(textProps)
      .join(
        (enter) =>
          enter
            .append("text")
            .merge(innerSelection) // get the already existing elements as well
            .transition() // and apply changes to all of them
            .duration(3000)
            .delay(2000)
            .attr("x", (d) => d[0])
            .attr("y", (d) => {
              return d[1];
            })
            .attr("fill", "black")
            .text((d) => d[2]),
        (update) =>
          update
            .attr("x", (d) => d[0])
            .attr("y", (d) => {
              return d[1];
            })
            .text((d) => d[2]),

        (exit) => exit.remove()
      );

    // Add X axis label:
    // innerSelection
    // .append("text")
    // .attr("text-anchor", "end")
    // .attr("x", 300)
    // .attr("y", height)
    // .text("Sentiment")
    // .attr("transform", "translate(-25,-25)rotate(-90)");
  };

  my.width = function (_) {
    return arguments.length ? ((width = +_), my) : width;
  };
  my.divWidth = function (_) {
    return arguments.length ? ((divWidth = +_), my) : divWidth;
  };

  my.height = function (_) {
    return arguments.length ? ((height = +_), my) : height;
  };

  my.data = function (_) {
    return arguments.length ? ((data = _), my) : data;
  };
  my.tTestData = function (_) {
    return arguments.length ? ((tTestData = _), my) : tTestData;
  };

  return my;
};
