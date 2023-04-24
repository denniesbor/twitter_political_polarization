import React, { useContext } from "react";
import { AppContext } from "../context/AppContext";

const Navbar = () => {
  const { isOpen, setIsOpen } = useContext(AppContext);

  const handleSidebarToggle = () => {
    setIsOpen(!isOpen);
  };

  return (
    <div className="navbar">
      <div className="navbrand">
        <a href="#"> Twitter Polarization Dashboard </a>
      </div>
      <div className="project-desc" onClick={handleSidebarToggle}>
        Description
      </div>
    </div>
  );
};

export default Navbar;
