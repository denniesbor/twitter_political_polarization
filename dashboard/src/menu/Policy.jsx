import { useContext } from "react";
import { AppContext } from "../context/AppContext";
import * as d3 from "d3";

export const Policy = () => {
  const { policy, setPolicy, descStat } = useContext(AppContext);

  const handleSelectChange = (event) => {
    setPolicy(event.target.value);
  };

  const policies = descStat?d3
    .scaleOrdinal()
    .domain(descStat.map((d) => d.policy))
    .domain():[]


  return (
    <>
      <h4>Policy</h4>
      <select value={policy} onChange={handleSelectChange}>
        {policies.map((option, index) => (
          <option key={index} value={option}>
            {option}
          </option>
        ))}
      </select>
    </>
  );
};
