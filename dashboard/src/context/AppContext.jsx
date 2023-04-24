import { createContext, useState } from "react";
import useQueryClient from "../hooks";
import { select } from "d3";

// create context
export const AppContext = createContext(null);

const gist =
  "https://gist.githubusercontent.com/denniesbor/32d9b7a67ff9d885c62e70eddc320430/raw/de7067dd10bed40d6ff1348ab4ce28e7c5075e80/";

export const ContextWrapper = (props) => {
  // set window height and width
  const [height, setHeight] = useState(window.innerHeight);
  const [width, setWidth] = useState(
    window.innerWidth < 768 ? window.innerWidth : (75 / 200) * window.innerWidth
  );

  const [politicalGroup, setPoliticalGroup] = useState("all");
  const [politicalParty, setPoliticalParty] = useState("all");
  const [policy, setPolicy] = useState("Abortion");
  const [house, setHouse] = useState("all");
  const [isOpen, setIsOpen] = useState(false);

  // functions used in parse read data
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

  //  functions to parse fetched data, i.e., string numbers to int
  const parseRow = (row) => {
    row.name = row.name;
    row["Twitter Handle"] = row["Twitter Handle"];
    row["St/Dis"] = row["St/Dis"];
    row["Party"] = row["Party"];
    row["score"] = +row["score"];

    return row;
  };

  const { isLoading: q2Loading, data: descStat } = useQueryClient(
    "desc",
    gist + "descriptives.csv",
    parseDesc
  );
  const { isLoading: q3Loading, data: testStatData } = useQueryClient(
    "test",
    gist + "ind_t_test.csv"
  );

  const { isLoading: q1Loading, data: politicalScores } = useQueryClient(
    "members",
    "https://gist.githubusercontent.com/denniesbor/32d9b7a67ff9d885c62e70eddc320430/raw/626ec9935008bf240f9f4f4cac5f1aa281f89a34/members.csv",
    parseRow
  );

  let loading = false;
  // check for loading
  if (q1Loading || q2Loading || q3Loading) {
    loading = true;
  }

  const toolTip = select("#root").append("g").attr("class", "tooltip");

  // disable background scrolling when about sidebar is open
  if (isOpen) {
    document.body.style.overflow = "hidden";
  } else {
    // Disables Background Scrolling whilst the SideDrawer/Modal is open
    if (typeof window != "undefined" && window.document) {
      document.body.style.overflow = "unset";
    }
  }

  return (
    <AppContext.Provider
      value={{
        height,
        setHeight,
        setWidth,
        width,
        politicalGroup,
        politicalParty,
        setPoliticalParty,
        policy,
        setPolicy,
        toolTip,
        house,
        setHouse,
        q2Loading,
        q1Loading,
        q3Loading,
        loading,
        descStat,
        testStatData,
        politicalScores,
        isOpen,
        setIsOpen,
      }}
    >
      {props.children}
    </AppContext.Provider>
  );
};
