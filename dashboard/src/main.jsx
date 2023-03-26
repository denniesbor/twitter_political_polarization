import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { ContextWrapper } from "./context/AppContext";
import { QueryClient, QueryClientProvider } from "react-query";
import "./index.css";

const queryClient = new QueryClient();

ReactDOM.createRoot(document.getElementById("root")).render(
  <QueryClientProvider client={queryClient}>
    <ContextWrapper>
      <App />
    </ContextWrapper>
  </QueryClientProvider>
);
