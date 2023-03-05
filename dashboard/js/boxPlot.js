import { colorPicker } from "./colors.js";
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
      .call(d3.axisBottom(x))
      .attr("stroke-width", 1.5)
      .selectAll("text")
      .attr("transform", "translate(-40,30)rotate(-45)")
      .attr("font-size", "12px")

    // Show the y scale
    const y = d3
      .scaleLinear()
      .domain([-1.2, 1.2])
      .range([height - height * scaleFactor, height * scaleFactor]);
    innerSelection
      .append("g")
      .attr("transform", `translate(${width * 0.1},0)`)
      .call(d3.axisLeft(y))
      .attr("stroke-width", 1.5)
      .attr("font-size", "12px")

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
      );

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

        str = str.repeat(pValue.split("*").slice(1).length);

        let groups = politicalGroups.domain();

        let groupOneName = groups[customFilter(groups, d.split("-")[0]).at(-1)];

        let groupTwoName = groups[customFilter(groups, d.split("-")[1]).at(-1)];

        getMax(groupTwoName) > getMax(groupOneName)
          ? (currentMax = getMax(groupTwoName))
          : (currentMax = getMax(groupOneName));

        const getValues = (d1, d2) => {
          if (max) {
            max + 0.1 > currentMax
              ? (max = max + 0.1)
              : (max = currentMax + 0.1);
          } else {
            getMax(groupTwoName) > getMax(groupOneName)
              ? (max = getMax(groupTwoName) + 0.1)
              : (max = getMax(groupOneName) + 0.1);
          }

          d1 > d2
            ? ((name1 = groupOneName), (name2 = groupTwoName))
            : ((name1 = groupTwoName), (name2 = groupOneName));
        };

        getValues(getMax(groupOneName), getMax(groupTwoName));

        let moveToX = x(name1);
        let moveToY = y(max + 0.1);

        let moveToXTop = y(max + 0.15);
        let moveToRight = x(name2);
        let moveToRightDown = y(max + 0.1);

        //   if (nextItemMax > OneMax) {
        //     moveToXTop = y(nextItemMax + nextItemMax*2*i);
        //   }

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
