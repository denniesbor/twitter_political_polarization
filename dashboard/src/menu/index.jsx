import React from "react";
import { Policy } from "./Policy";
import { House } from "./House";

const Menu = () => {
  return (
    <div className="left-sidebar">
      <div className="menu-desc">
        <p>
          Please choose a Congress house and policy to view from the dropdown
          menus below. There are 12 policies available to explore.
        </p>
      </div>
      <House />
      <Policy />
    </div>
  );
};

export default Menu;
