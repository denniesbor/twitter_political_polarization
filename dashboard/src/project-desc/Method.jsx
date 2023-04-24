import React, { useState, useContext } from "react";
import { AppContext } from "../context/AppContext";

const Method = () => {
  const { isOpen, setIsOpen } = useContext(AppContext);

  const toggleSidebar = () => {
    setIsOpen(!isOpen);
  };

  return (
    <div className={`about-sidebar ${isOpen ? "open" : ""}`}>
      <div className="close-btn" onClick={toggleSidebar}>
        <i class="fa fa-times" aria-hidden="true"></i>
      </div>
      <div className="sidebar-content">
        <h2>Project methodology</h2>
        <p>
          In this section, an overview of the project methodology is provided,
          from data collection to statistical analysis and inference. The
          methods are summarized in the method box diagram below.
        </p>
        <div className="methodology-box">
          <img
            src="https://github.com/denniesbor/twitter_political_polarization/raw/main/figures/MethodBox.png"
            alt="box-diagran"
          />
        </div>
        <h3>Data collection and cleaning</h3>
        <p>
          Tweets dating from 2021 to 2022 from the 117th US Congress members
          are scraped using the Python archiving library
          <em> snscrape </em> and then exported into a CSV file for cleaning.
          The cleaning involves removing URL links, non-alphanumeric words,
          expanding contracted words, and converting all text to lower case.
        </p>
        <h3>Policy grouping</h3>
        <p>
          Specific terminologies related to policy classes are used to search
          through the tweets. If a tweet contains one or more of the search
          keywords, it is assigned to that particular policy. For example,
          LGBTQ, Trans, etc., are applied to search for tweets related to LGBTQ
          policy.
        </p>
        <h3>Sentiment analysis</h3>
        <p>
          VADER, a lexicon-based sentiment analysis tool, is utilized to compute
          the sentiment of the cleaned tweets. The sentiment of the tweet is
          based on the score output from VADER, which ranges from -1 (more
          negative) to 1 (more positive).
        </p>
        <h3>Political scoring</h3>
        <p>
          Voting records from Govtrack are applied to classify legislators
          (using K Means clustering) into five political groupings from Far-Left
          to Far-Right. The score ranges from 0 (more politically left) to 1
          (more politically right).
        </p>
        <h3>Statistical analysis</h3>
        <p>
          Independent t-tests are applied to carry out formal statistical
          testing and explore whether the mean sentiment scores between the
          ideological groups are likely to have occurred randomly. The
          significance level used is 95% confidence, and no difference is
          assumed in the mean of the sentiments between the political groups as
          the null hypothesis for each test. This approach is employed to
          ascertain the extent of polarization within the political groups.
        </p>
      </div>
    </div>
  );
};

export default Method;
