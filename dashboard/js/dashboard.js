import * as d3 from "d3";

import { parliamentChart } from "./parliament-chart.js";
import { menu } from "./menu.js";
import { boxPlot } from "./boxPlot.js";

const height = window.innerHeight;
const width = window.innerWidth;

// parliament chart
const svg = d3.select("#parliament-seat").append("svg");
// .attr("viewBox", `0 0 300 300`)
//   .attr("width", width)

// menus
const menuContainer = d3.select("#menu-options");

const xMenu = menuContainer
  .append("div")
  .attr("class", "col")
  .append("div")
  .attr("class", "form-floating mb-3");

const yMenu = menuContainer
  .append("div")
  .attr("class", "col")
  .append("div")
  .attr("class", "form-floating mb-3");

// Boxplot chart
const boxPlotFig = d3
  .select("#dataviz")
  .append("svg")
  .attr("height", height)
  .attr("width", width);
// .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

//  sidebar

const sideBarMenu = d3
  .select("#sidebar")
  .append("div")
  .attr("class", "col")
  .attr("class", "form-floating mb-3");

// parse rows of data from boxPlot
const parseDesc = (row) => {
  row.count = +row.count;
  row.min = +row.min;
  row.max = +row.max;
  row.mean = +row.mean;
  row.median = +row.median;
  row.q1 = +row.q1;
  row.q3 = +row.q2;
  row.std = +row.std;

  return row;
};

// parse rows of the parliament seat chart

const parseRow = (row) => {
  row.name = row.name;
  row["Twitter Handle"] = row["Twitter Handle"];
  row["St/Dis"] = row["St/Dis"];
  row["Party"] = row["Party"];
  row["score"] = +row["score"];

  return row;
};

const partyColors = { D: "blue", R: "red", "": "#808080", I: "000000" };
// user inputs to filter the data
const gist =
  "https://gist.githubusercontent.com/denniesbor/32d9b7a67ff9d885c62e70eddc320430/raw/de7067dd10bed40d6ff1348ab4ce28e7c5075e80/";

let descStat;
let testStatData;
let politicalScores;

let politicalGroup = "all";
let politicalParty = "all";
let policy = "Abortion";
let house = "all";

// testing with data
const main = async () => {
  const options = {
    politicalGroup: [
      { label: "far_right", value: "Far Right" },
      { label: "right_centrist", value: "Right Centrist" },
      { label: "centrist", value: "Centrist" },
      { label: "left_centrist", value: "Left Centrist" },
      { label: "far_left", value: "Far Left" },
      { label: "all", value: "All" },
    ],
    party: [
      { label: "all", value: "All" },
      { label: "D", value: "Democrats" },
      { label: "R", value: "Republicans" },
      // { label: "I", value: "Independents" },
    ],
  };

  // read datasets

  if (!descStat && !testStatData && !politicalScores) {
    descStat = await d3.csv(gist + "descriptives.csv", parseDesc);
    testStatData = await d3.csv(gist + "ind_t_test.csv");

    politicalScores = await d3.csv(
      "https://gist.githubusercontent.com/denniesbor/32d9b7a67ff9d885c62e70eddc320430/raw/1bf03cfffaead4184ed16ba3e8a48cf003ba1162/members.csv",
      parseRow
    );
  }

  // get the list of policies

  const policies = d3
    .scaleOrdinal()
    .domain(descStat.map((d) => d.policy))
    .domain();

  // sort the data and map party to color

  let newData = politicalScores.map((d, i) => {
    let partyCode;

    d.Party ? (partyCode = d.Party) : (partyCode = "Unknown");

    return (d[i] = {
      ...d,
      ...{ Party: partyCode, color: partyColors[d.Party] },
    });
  });

  // filter political data into parties and political groups

  const filterPoliticalScores = (
    dataArray = newData,
    partyChoice = politicalParty,
    houseValue = house
  ) => {
    const filtered = (data, attr, value) => {
      if (value === "all") {
        return data.sort((a, b) => a.score - b.score);
      } else {
        return data
          .filter((d) => d[attr] === value)
          .sort((a, b) => a.score - b.score);
      }
    };

    if (partyChoice === "all" && house === "all") {
      const dems = filtered(dataArray, "Party", "D");
      const ind = filtered(dataArray, "Party", "I");
      const reps = filtered(dataArray, "Party", "R");
      const unknown = filtered(dataArray, "Party", "Unknown");

      return dems.concat(ind, reps, unknown);
    } else {
      const firstData = filtered(dataArray, "house", houseValue);
      const secondData = filtered(firstData, "Party", partyChoice);

      return secondData;
    }
  };

  newData = filterPoliticalScores();

  // prepare and filter boxplot data based on the selected user policy

  const filterBoxPlotData = (policy, party) => {
    let plotData;

    politicalParty === "all"
      ? (plotData = descStat)
      : (plotData = descStat.filter((d) => d.party === politicalParty));

    let reduced = d3.index(
      plotData,
      (d) => d.policy,
      (d) => d.govtrack_class,
      (d) => d.party
    );

    // group by policy
    let reducedByParty = reduced.get(policy);

    //   // groupby politicalGroup
    let reducedPolicy = Array.from(reducedByParty, ([key, value]) => ({
      key,
      value,
    }));

    // function that groups data according to party, policy, and political group
    const flattenData = (reducedPolicy) => {
      let flattenedArray = [];
      const _ = reducedPolicy.forEach((d) => {
        const nestedArray = Array.from(d.value);

        if (nestedArray.length > 1) {
          nestedArray.forEach((d) => {
            let party = d[1].party;
            let group = d[1].govtrack_class;

            party == "D" && group.split(" ")[0] == "Left"
              ? flattenedArray.push(d[1])
              : party == "R" && group.split(" ")[0] == "Right"
              ? flattenedArray.push(d[1])
              : "";
          });
        }
        if (nestedArray.length === 1) {
          flattenedArray.push(nestedArray[0][1]);
        }
      });

      return flattenedArray;
    };

    return flattenData(reducedPolicy);
  };

  const filterTTestData = (policy) => {
    let testData = [];

    const filteredIndTest = testStatData.find(
      (d) => d.policy === policy && d.params === "P"
    );

    politicalParty === "all"
      ? (testData = Object.entries(filteredIndTest).slice(2, -1))
      : politicalParty === "D"
      ? testData.push([
          "Left Centrist-Far Left",
          filteredIndTest["Left Centrist-Far Left"],
        ])
      : testData.push([
          "Far Right-Right Centrist",
          filteredIndTest["Far Right-Right Centrist"],
        ]);

    return testData;
  };

  // past filtered data to the box

  const box = (policy) => {
    const currentWidthBox = parseInt(d3.select("#dataviz").style("width"), 10);
    const currentHeightBox = parseInt(
      d3.select("#dataviz").style("height"),
      10
    );

    const boxAspectRatio = currentWidthBox / currentHeightBox;

    return boxPlot()
      .data(filterBoxPlotData(policy, politicalParty))
      .height(currentHeightBox * boxAspectRatio)
      .width(currentWidthBox)
      .divWidth(width)
      .tTestData(filterTTestData(policy));
  };

  function createChart(data) {
    // get the current width of the div where the chart appear, and attribute it to Svg
    const currentWidth = parseInt(
      d3.select("#parliament-seat").style("width"),
      10
    );

    const currentHeight = parseInt(
      d3.select("#parliament-seat").style("height"),
      10
    );

    const windowAspectRatio = currentWidth / currentHeight;

    svg.attr("width", currentWidth).attr("height", currentWidth / 2);

    const seatMap = parliamentChart()
      .data(data)
      .width(currentWidth)
      .height(currentWidth * 0.5);

    boxPlotFig.call(box(policy));
    svg.call(seatMap);
  }

  createChart(newData);

  sideBarMenu.call(
    menu()
      .label("Policy")
      .id("sidebar-menu")
      .columnWidth(12)
      .options(policies.map((d, i) => ({ label: d, value: d })))
      .on("change", (value) => {
        policy = value;
        boxPlotFig.call(box(value));
      })
  );

  xMenu.call(
    menu()
      .label("House")
      .id("house")
      .columnWidth(12)
      .options([
        { label: "all", value: "All" },
        { label: "senate", value: "Senate" },
        { label: "house", value: "House of Representatives" },
      ])
      .on("change", (value) => {
        console.log(value);
        house = value;
        const xMenuData = filterPoliticalScores(newData, politicalParty, house);
        createChart(xMenuData);
      })
  );

  yMenu.call(
    menu()
      .label("Party")
      .id("party-label")
      .columnWidth(12)
      .options(options.party)
      .on("change", (value) => {
        politicalParty = value;
        const yMenuData = filterPoliticalScores(
          newData,
          politicalParty,
          politicalGroup
        );
        createChart(yMenuData);
      })
  );
};

export default main;
