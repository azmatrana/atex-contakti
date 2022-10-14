var Stopwatch = function(elem, options) {

  var timer       = createTimer(),
      startButton = document.getElementById("start"),
      stopButton  = document.getElementById("stop"),
      resetButton = document.getElementById("reset"),
      offset,
      clock,
      interval;

  // default options
  options = options || {};
  options.delay = options.delay || 1;

  // append elements
  elem.appendChild(timer);
  if (!options.customControlls)
  {
    elem.appendChild(startButton);
    elem.appendChild(stopButton);
    elem.appendChild(resetButton);


    startButton.addEventListener("click", start)
    stopButton.addEventListener("click", stop)
    resetButton.addEventListener("click", reset)
  }
  // initialize
  reset();

  // private functions
  function createTimer() {
    return document.createElement("span");
  }

  function start() {
    if (!interval) {
      offset   = Date.now();
      interval = setInterval(update, options.delay);
    }
  }

  function stop() {
    if (interval) {
      clearInterval(interval);
      interval = null;
    }
  }

  function reset() {
    clock = 0;
    render(0);
  }

  function update() {
    clock += delta();
    render();
  }

  function render() {
    var units = ""
    if (options.units){
      units = options.units
    }
    // timer.innerHTML = parseInt(clock/1000) + ' ' + units;
    timer.innerHTML = fancyTimeFormat(clock/1000)
  }

  function fancyTimeFormat(duration)
  {
      // Hours, minutes and seconds
      var hrs = ~~(duration / 3600);
      var mins = ~~((duration % 3600) / 60);
      var secs = ~~duration % 60;

      // Output like "1:01" or "4:03:59" or "123:03:59"
      var ret = "";

      if (hrs > 0) {
          ret += "" + hrs + ":" + (mins < 10 ? "0" : "");
      }

      ret += "" + mins + ":" + (secs < 10 ? "0" : "");
      ret += "" + secs;
      return ret;
  }

  function delta() {
    var now = Date.now(),
        d   = now - offset;

    offset = now;
    return d;
  }

  // public API
  this.start  = start;
  this.stop   = stop;
  this.reset  = reset;
};
