import React from "react";
import oughton from "../images/oughton.jpg";
import bor from "../images/bor.jpg";

const Footer = () => {
  return (
    <footer className="footer">
      <div className="about">
        <div className="contributors">
          <div className="contributor">
            <img src={bor} alt="bor" />
            <h4>Dennies Bor</h4>
            <p>
              Affiliate faculty, George Mason University, Department of
              Geography and Geoinformation Science
            </p>
            <div className="social-media-links">
              <a
                href="https://twitter.com/bordennies"
                target="_blank"
                rel="noopener noreferrer"
              >
                <i className="fa-brands fa-twitter"></i>
              </a>
              <a
                href="https://github.com/denniesbor"
                target="_blank"
                rel="noopener noreferrer"
              >
                <i className="fa-brands fa-github"></i>
              </a>
              <a
                href="https://www.linkedin.com/in/denniesbor/"
                target="_blank"
                rel="noopener noreferrer"
              >
                <i className="fa-brands fa-linkedin"></i>
              </a>
            </div>
          </div>
          <div className="contributor">
            <img src={oughton} alt="Ed" />
            <h4>Ed Oughton</h4>
            <p>Assistant Professor of Data Analytics George Mason University</p>
            <div className="social-media-links">
              <a
                href="https://twitter.com/EdwardOughton"
                target="_blank"
                rel="noopener noreferrer"
              >
                <i className="fa-brands fa-twitter"></i>
              </a>
              <a
                href="https://github.com/edwardoughton"
                target="_blank"
                rel="noopener noreferrer"
              >
                <i className="fa-brands fa-github"></i>
              </a>
              <a
                href="https://www.linkedin.com/in/edwardoughton/"
                target="_blank"
                rel="noopener noreferrer"
              >
                <i className="fa-brands fa-linkedin"></i>
              </a>
            </div>
          </div>
        </div>
        <div className="acknowledgment">
          <h4>Acknowledgment</h4>
          <p>
            We would like to thank the Pluralism and Civil Exchange program of
            the Mercatus Center for research funding for this activity, in
            particular Ben Klutsey and Daniel Rothschild.
          </p>
        </div>
      </div>
      <div className="copyright">
        <p>
          &copy; 2023. A metrics dashboard examining linguistic similarities in
          political tweets on major public affairs issues.
        </p>
      </div>
    </footer>
  );
};

export default Footer;
