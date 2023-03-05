import * as d3 from "d3";

function menu() {
  let label;
  let id;
  let columnWidth;
  let options;
  const listeners = d3.dispatch("change");

  const my = (selection) => {
    // selection.text('Foo')
    selection
      .selectAll("label")
      .data([null])
      .join("label")
      .attr("for", id)
      .text("");

    selection
      .selectAll("select")
      .data([null])
      .join("select")
      .attr("class", "form-select")
      .attr("id", id)
      .attr("class", `col-md-${columnWidth}`)
      .on("change", (event) => {
        listeners.call("change", null, event.target.value);
      })
      .selectAll("option")
      .data(options)
      .join("option")
      .attr("value", (d) => d.label)
      .text((d) => d.value);
  };

  my.label = function (_) {
    return arguments.length ? ((label = _), my) : label;
  };
  my.id = function (_) {
    return arguments.length ? ((id = _), my) : id;
  };
  my.columnWidth = function (_) {
    return arguments.length ? ((columnWidth = _), my) : columnWidth;
  };

  my.options = function (_) {
    return arguments.length ? ((options = _), my) : options;
  };
  my.on = function (_) {
    var value = listeners.on.apply(listeners, arguments);
    return value === listeners ? my : value;
  };

  return my;
}

export { menu };
