import { useEffect } from "react";
import Footer from "./footer";
import Navbar from "./navbar";
import Menu from "./menu";
import MainCharts from "./charts";

import { QueryClient, QueryClientProvider } from "react-query";
import { ContextWrapper } from "./context/AppContext";
const queryClient = new QueryClient();

function App() {
  // scroll to top on reload
  window.onbeforeunload = function () {
    window.scrollTo(0, 0);
  };

  return (
    <QueryClientProvider client={queryClient}>
      <ContextWrapper>
        <Navbar />
        <div className="main-section">
          <Menu />
          <MainCharts />
        </div>
        <Footer />
      </ContextWrapper>
    </QueryClientProvider>
  );
}

export default App;
