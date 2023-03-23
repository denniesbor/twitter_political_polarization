import React, { useState, useRef, useEffect, useContext } from "react";
import { select } from "d3";

import { partyColors, colorPicker } from "../../colors";
import { AppContext } from "../../context/AppContext";
import { getXYCoordinates, filterPoliticalScores } from "./data";
import tippingTool from "../../hooks/useToolTip";

const Parliament = () => {
  const {
    width,
    politicalParty,
    setPoliticalParty,
    politicalScores,
    house,
    toolTip,
    q1Loading,
  } = useContext(AppContext);
  const [active, setActive] = useState("");

  const ref = useRef(null);

  const handleClick = (e) => {
    setActive(e.currentTarget.value);
    setPoliticalParty(e.currentTarget.value);
  };

  // select party options
  const options = [
    { label: "all", value: "All", fa: "fa-users" },
    { label: "D", value: "Democrats", fa: "fa-solid fa-democrat" },
    { label: "R", value: "Republicans", fa: "fa-solid fa-republican" },
    // { label: "I", value: "Independents" },
  ];

  let newData = politicalScores?.map((d, i) => {
    let partyCode;

    d.Party ? (partyCode = d.Party) : (partyCode = "Unknown");

    return (d[i] = {
      ...d,
      ...{ Party: partyCode, color: partyColors[d.Party] },
    });
  });

  useEffect(() => {
    if (newData) {
      const data = filterPoliticalScores(newData, politicalParty, house);

      // Remove existing chart
      const selection = select(ref.current);

      const totalPoints = data.length;

      selection.select("g.dataviz").remove();

      // The locations of all the points
      const locations_ = getXYCoordinates(width * 0.5, width, 0.4, totalPoints);

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

      // remove tooltip

      toolTip.select("g.tooltip").remove();

      const { mousemove, mouseleave, mouseover } = tippingTool(toolTip);

      // add a custom legend based on the unique values in the dataset

      const unique = (arr, props = []) => [
        ...new Map(
          arr.map((entry) => [props.map((k) => entry[k]).join("|"), entry])
        ).values(),
      ];

      const newArr = unique(processedData, ["govtrack_class", "Party"])
        .filter((d) => d.Party !== "I")
        .filter(
          (d) => !(d.Party === "D" && d.govtrack_class === "Right Centrist")
        );

      // find the minimum and maximum values
      const xMin = Math.min(...processedData.map((d) => d.x));
      const xMax = Math.max(...processedData.map((d) => d.x));
      const yMax = Math.max(...processedData.map((d) => d.y));
      // const yMin = Math.min(...processedData.map((d) => d.y));

      // transition
      innerSelection
        .selectAll("circle")
        .data(processedData)
        .join("circle")
        .transition()
        .delay(500)
        .attr("cx", (d) => d.x)
        .attr("cy", (d) => d.y)
        .delay((d, i) => i * 0.5)
        .attr("r", (d) => d.seatRadius)
        .attr("fill", (d) => colorPicker(d.Party, d.govtrack_class) || "#AAA");

      innerSelection
        .selectAll("circle")
        .data(processedData)
        .join("circle")
        .on("mouseover", mouseover)
        .on("mousemove", mousemove)
        .on("mouseleave", mouseleave);

      // insert the legend
      const legend = innerSelection.append("g").attr("class", "legend");

      legend
        .selectAll("mydots")
        .data(newArr)
        .join("circle")
        .attr("cx", (d, i) =>
          i < 3
            ? xMin + (i * (xMax - xMin)) / 3
            : xMin + ((i - 3) * (xMax - xMin)) / (newArr.length - 3)
        )
        .attr("cy", (d, i) => (i < 3 ? yMax + 40 : yMax + 60))
        .attr("r", (d) => (d.seatRadius > 8 ? 8 : d.seatRadius))
        .attr("fill", (d) => colorPicker(d.Party, d.govtrack_class) || "#AAA");

      // Add one dot in the legend for each name.
      legend
        .selectAll("mylabels")
        .data(newArr)
        .join("text")
        .attr("x", (d, i) =>
          i < 3
            ? xMin + (i * (xMax - xMin)) / 3 + 10
            : 10 + xMin + ((i - 3) * (xMax - xMin)) / (newArr.length - 3)
        )
        .attr("y", (d, i) => (i < 3 ? yMax + 45 : yMax + 65))
        .text((d) => d.govtrack_class)
        .attr("text-anchor", "left")
        .attr("font-size", "0.6rem")
        .style("alignment-baseline", "middle");
    }
  }, [house, width, politicalParty, politicalScores]);

  if (q1Loading) {
    return <>Loading...</>;
  }

  return (
    <>
      <div className="parliament-desc">
        <p>
          {`Parliamentary seat graph of the members of ${
            house == "all"
              ? ""
              : house == "house"
              ? "the Lower House of "
              : "the Upper House of "
          }117th Congress,  classified according to GovTrack scores.`}
        </p>
      </div>
      <div className="political_group">
        {options.map((d) => {
          return (
            <button
              key={d.label}
              className={`btn ${active === d.label ? "active" : ""}`}
              value={d.label}
              onClick={(e) => handleClick(e)}
            >
              <i className={`fa ${d.fa}`}></i>
              {d.value}
            </button>
          );
        })}
      </div>
      <svg
        style={{ height: width > 512 ? width * 0.6 : width, width: width }}
        ref={ref}
      ></svg>
    </>
  );
};

export default Parliament;
