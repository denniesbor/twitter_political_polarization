
const partyColors = { D: "blue", R: "red", "": "#808080", I: "000000" };

// pick circle colors
const colorPicker = (party, govtrack_class) => {
  const colorMap = {
    "Far Left": "#2c49d5",
    "Left Centrist": "#4e65d3",
    "Centrist D": "#8f9ee4",
    "Centrist R": "#dda8a8",
    "Right Centrist": "#be5a5a",
    "Far Right": "#c72f2f",
  };

  if (govtrack_class === "Centrist") {
    if (party === "D") {
      return "#8f9ee4";
    } else return "#dda8a8";
  } else return colorMap[govtrack_class];
};

export {partyColors, colorPicker}