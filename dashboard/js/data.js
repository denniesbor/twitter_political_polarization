import * as d3 from "d3";

export const getXYCoordinates = (height, width, innerRadiusCoef, nSeats) => {

  const outerParliamentRadius = Math.min(width/2, height);
  const innerParliementRadius = outerParliamentRadius * 0.4;

  // util
  function series(s, n) {
    let r = 0;
    for (let i = 0; i <= n; i++) {
      r += s(i);
    }
    return r;
  }

  let nRows = 0;
  let maxSeatNumber = 0;
  let b = 0.5;
  (function () {
    let a = innerRadiusCoef / (1 - innerRadiusCoef);
    while (maxSeatNumber < nSeats) {
      nRows++;
      b += a;
      /* NOTE: the number of seats available in each row depends on the total number
            of rows and floor() is needed because a row can only contain entire seats. So,
                it is not possible to increment the total number of seats adding a row. */
      maxSeatNumber = series(function (i) {
        return Math.floor(Math.PI * (b + i));
      }, nRows - 1);
    }
  })();

  /***
   * create the seats list */
  /* compute the cartesian and polar coordinates for each seat */
  const rowWidth = (outerParliamentRadius - innerParliementRadius) / nRows;
  let seats = [];
  (function () {
    let seatsToRemove = maxSeatNumber - nSeats;
    for (let i = 0; i < nRows; i++) {
      let rowRadius = innerParliementRadius + rowWidth * (i + 0.5);
      let rowSeats =
        Math.floor(Math.PI * (b + i)) -
        Math.floor(seatsToRemove / nRows) -
        (seatsToRemove % nRows > i ? 1 : 0);
      let anglePerSeat = Math.PI / rowSeats;
      for (let j = 0; j < rowSeats; j++) {
        let s = {};
        s.polar = {
          r: rowRadius,
          teta: -Math.PI + anglePerSeat * (j + 0.5),
        };
        s.cartesian = {
          x: s.polar.r * Math.cos(s.polar.teta),
          y: s.polar.r * Math.sin(s.polar.teta),
        };
        seats.push(s);
      }
    }
  })();

  /* sort the seats by angle */
  seats.sort(function (a, b) {
    return a.polar.teta - b.polar.teta || b.polar.r - a.polar.r;
  });

  /***
   * helpers to get value from seat data */
  const seatClasses = function (d) {
    let c = "seat ";
    c += (d.party && d.party.id) || "";
    return c.trim();
  };
  const seatX = function (d) {
    return d.cartesian.x;
  };
  const seatY = function (d) {
    return d.cartesian.y;
  };
  const seatRadius = function (d) {
    let r = 0.4 * rowWidth;
    if (d.data && typeof d.data.size === "number") {
      r *= d.data.size;
    }
    return r;
  };

  // translated x and y values
  const x = d3
    .scaleLinear()
    .domain(d3.extent(seats, seatX))
    .nice()
    .range([width * 0.1, width - width * 0.1]);

  const y = d3
    .scaleLinear()
    .domain(d3.extent(seats, seatY))
    .nice()
    .range([height * 0.1, height - height * 0.1]);

  const translatedTweets = seats.map((d) => ({
    x: x(seatX(d)),
    y: y(seatY(d)),
    seatRadius: seatRadius(d),
  }));

  return translatedTweets;
};
