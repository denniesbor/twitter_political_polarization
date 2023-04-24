import { useContext } from "react";
import Footer from "./footer";
import Navbar from "./navbar";
import Menu from "./menu";
import MainCharts from "./charts";
import Method from "./project-desc";
import Loader from "./loader";

import { AppContext } from "./context/AppContext";

function App() {
  const { loading } = useContext(AppContext);

  // scroll to top on reload
  window.onbeforeunload = function () {
    window.scrollTo(0, 0);
  };

  return (
    <>
      {loading && <Loader />}
      {!loading && (
        <>
          <Navbar />
          <div className="main-section">
            <Menu />
            <MainCharts />
            <Method/>
          </div>
          <Footer />
        </>
      )}
    </>
  );
}

export default App;
