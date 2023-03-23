import { index } from "d3";



// prepare and filter boxplot data based on the selected user policy

export const filterBoxPlotData = (policy, party, descStat) => {
  let plotData;

  try {
    party === "all"
      ? (plotData = descStat)
      : (plotData = descStat.filter((d) => d.party === party));
  
    let reduced = index(
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
    
  } catch (error) {
    return null
  }

};

// filter t-test data

export const filterTTestData = (policy, party, testStatData) => {
  let testData = [];

  try {
    
      const filteredIndTest = testStatData.find(
        (d) => d.policy === policy && d.params === "P"
      );
    
      party === "all"
        ? (testData = Object.entries(filteredIndTest).slice(2, -1))
        : party === "D"
        ? testData.push([
            "Left Centrist-Far Left",
            filteredIndTest["Left Centrist-Far Left"],
          ])
        : testData.push([
            "Far Right-Right Centrist",
            filteredIndTest["Far Right-Right Centrist"],
          ]);
    
      return testData;
    
  } catch (error) {
    return null
  }
};
