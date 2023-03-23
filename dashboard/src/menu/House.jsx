import { useContext } from "react";
import { AppContext } from "../context/AppContext";

export const House = () => {
  const { house, setHouse } = useContext(AppContext);

  const handleSelectChange = (event) => {
    setHouse(event.target.value);
  };

  const options = [
    { label: "all", value: "All" },
    { label: "senate", value: "Senate" },
    { label: "house", value: "House of Representatives" },
  ];

  return (
    <>
      <h4>House</h4>
      <select value={house} onChange={handleSelectChange}>
        {options.map((option, index) => (
          <option key={index} value={option.label}>
            {option.value}
          </option>
        ))}
      </select>
    </>
  );
};
