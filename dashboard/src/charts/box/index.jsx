import React, { useContext } from "react";
import {
  scaleOrdinal,
  scaleBand,
  scaleLinear,
  extent,
  scaleSequential,
  axisBottom,
  interpolateInferno,
  line,
  axisLeft,
} from "d3";
import * as d3 from "d3";
import { colorPicker } from "../../colors";
import { filterTTestData, filterBoxPlotData } from "./filterBox";
import tippingTool from "../../hooks/useToolTip";

import { AppContext } from "../../context/AppContext";

// base url to github gist containing data

const BoxPlot = () => {
  const {
    height,
    setHeight,
    q2Loading,
    setWidth,
    q3Loading,
    descStat,
    testStatData,
    width,
    politicalParty,
    policy,
    toolTip,
  } = useContext(AppContext);

  const data = filterBoxPlotData(policy, politicalParty, descStat);
  const testData = filterTTestData(policy, politicalParty, testStatData);

  const ref = React.useRef(null);

  React.useEffect(() => {
    const handleResize = () => {
      setHeight(window.innerHeight);
      setWidth(
        window.innerWidth < 768
          ? window.innerWidth
          : (75 / 200) * window.innerWidth
      );
    };

    window.addEventListener("resize", handleResize);
    return (_) => {
      window.removeEventListener("resize", handleResize);
    };
  }, []);

  const boxAspectRatio = width / height < 1 ? width / height : height / width;

  React.useEffect(() => {
    if (data && testData) {
      const scaleFactor = 0.1;

      // Remove existing chart
      const selection = d3.select(ref.current);

      selection.select("g.dataviz").remove();

      // Add new chart
      const innerSelection = selection.append("g").attr("class", "dataviz");

      const { mousemove, mouseleave, mouseover } = tippingTool(toolTip);

      const politicalGroups = scaleOrdinal().domain(
        data.map((d) => d.govtrack_class)
      );

      // Show the x scale
      const x = scaleBand()
        .range([width * 0.1, width - width * 0.05])
        .domain(politicalGroups.domain())
        .padding(1);

      innerSelection
        .append("g")
        .attr(
          "transform",
          `translate(0,${
            height * boxAspectRatio - height * boxAspectRatio * scaleFactor + 10
          })`
        )
        .transition()
        .call(axisBottom(x))
        .attr("stroke-width", 1.5)
        .selectAll("text")
        .attr("transform", "translate(-40,30)rotate(-45)")
        .attr("font-size", "12px");

      // Show the y scale

      const y = scaleLinear()
        .domain(extent(data.map((d) => d.max).concat(data.map((d) => d.min))))
        .range([
          height * boxAspectRatio - height * boxAspectRatio * scaleFactor,
          height * boxAspectRatio * 0.2,
        ]);
      innerSelection
        .append("g")
        .attr("transform", `translate(${width * 0.1},0)`)
        .transition()
        .call(axisLeft(y))
        .attr("stroke-width", 1.5)
        .attr("font-size", "12px");

      // Color scale
      const myColor = scaleSequential()
        .interpolator(interpolateInferno)
        .domain([-1, 1]);

      // Show the main vertical line
      innerSelection
        .selectAll("vertLines")
        .data(data)
        .join("line")
        .transition()
        .delay(100)
        .attr("x1", (d) => x(d.govtrack_class))
        .attr("x2", (d) => x(d.govtrack_class))
        .attr("y1", (d) => y(d.min))
        .attr("y2", (d) => y(d.max))
        .attr("stroke", "black")
        .attr("stroke-width", 1.5)
        .style("width", 40);

      // rectangle for the main box
      const boxWidth = width * 0.1;

      innerSelection
        .selectAll("boxes")
        .data(data)
        .join("rect")
        .transition() // and apply changes to all of them
        .duration(200)
        .attr("x", (d) => x(d.govtrack_class) - boxWidth / 2)
        .attr("y", (d) => y(d.q3))
        .attr("height", (d) => y(d.q1) - y(d.q3))
        .attr("width", boxWidth)
        .attr("stroke", "black")
        .attr("stroke-width", 1.5)
        .attr("fill", (d) => colorPicker(null, d.govtrack_class) || "#2c49d5");

      innerSelection
        .selectAll("rect")
        .data(data)
        .join("rect")
        .on("mouseover", mouseover)
        .on("mousemove", mousemove)
        .on("mouseleave", mouseleave);

      // show median, max and min horizontal lines

      const horizontalLines = (type, value, divider) => {
        // Show the horizontal line
        innerSelection
          .selectAll(type)
          .data(data)
          .join("line")
          .merge(innerSelection) // get the already existing elements as well
          .transition() // and apply changes to all of them
          .delay(300)
          .attr("y1", (d) => y(d[value]))
          .attr("y2", (d) => y(d[value]))
          .attr("x1", (d) => x(d.govtrack_class) - boxWidth / divider)
          .attr("x2", (d) => x(d.govtrack_class) + boxWidth / divider)
          .attr("stroke", "black")
          .attr("stroke-width", 1.5)
          .style("width", 80);
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
          const newXScale = scaleBand()
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

          let d3Gen = line();

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
        .data(testData)
        .join(
          (enter) =>
            enter
              .append("path")
              .transition()
              .delay(400)
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
        .join("text")
        .merge(innerSelection) // get the already existing elements as well
        .transition() // and apply changes to all of them
        .delay(500)
        .attr("x", (d) => d[0])
        .attr("y", (d) => {
          return d[1];
        })
        .attr("fill", "black")
        .text((d) => d[2]);
    }
  }, [data, width]); // Redraw chart if data changes

  if (q3Loading || q2Loading) {
    return <div>Loading...</div>;
  }

  return (
    <>
      <div className="box-desc">
        <p>
          The boxplot chart below illustrates the descriptive statistics for the
          sentiments expressed by political groups towards key policies. The
          significance bars indicate the groups whose means exhibit
          statistically significant differences at a confidence level of 95%.
        </p>
      </div>
      <svg
        style={{
          height: height * boxAspectRatio + 50,
          width: width,
        }}
        ref={ref}
      ></svg>
      <div className="box-desc">
        <p>
          The notations on the bars represent the degree of significance, where{" "}
          <strong>***</strong> indicates <em>p</em> &#60; 0.001,{" "}
          <strong>**</strong> represents <em>p</em> &#60; 0.01, and{" "}
          <strong>*</strong> denotes <em>p</em> &#60; 0.05.
        </p>
      </div>
    </>
  );
};

export default BoxPlot;
