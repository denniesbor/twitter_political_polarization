import BoxPlot from "./box";
import Parliament from "./parliament_chart";

const MainCharts = () => {
  return (
    <div className="middle-section">
      <div className="middle-div" id="parliament-chart">
        <Parliament />
      </div>
      <div className="middle-div" id="box">
        <BoxPlot />
      </div>
    </div>
  );
};

export default MainCharts;
