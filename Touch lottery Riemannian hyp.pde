// ============================================================
// RIEMANN ZETA TOUCH VISUALIZER
// COMPLETE APDE ANDROID / PROCESSING JAVA MODE
//
// FEATURES
// ------------------------------------------------------------
// 1. LOCKED INPUT MODE
//       s = 0.5 + i*t
//
// 2. FREE INPUT MODE
//       s = sigma + i*t
//
// 3. INDEPENDENT YELLOW SEARCH MODE
//       Touch / scribble on RIGHT graph.
//       The program searches along:
//
//                 s = 0.5 + i*t
//
//       The BLUE INPUT POINT remains on the straight
//       critical line Re(s) = 0.5.
//
// 4. YELLOW TARGET SCRIBBLE
//       User draws on the zeta output plane.
//
// 5. ORIGIN / ZERO SEARCH
//       Scribbling near zeta = 0 numerically searches through
//       the first 8 known non-trivial zero neighborhoods.
//
// 6. ZERO EVENT
//       Re(s) = 0.5
//       AND
//       Im(s) exactly equals one of the stored zero heights.
//
//       Then:
//       - Blue input tip blinks red
//       - Yellow output tip blinks red
//       - Red laser connects both
//
// 7. SYNCHRONIZED BLUE/YELLOW LOCI
//
// 8. 10 DECIMAL ZERO LABELS
//
// 9. STABLE APDE ANDROID / PROCESSING JAVA MODE
//
// ------------------------------------------------------------
// IMPORTANT
// ------------------------------------------------------------
// This is a visualization and numerical search.
// The first 8 zero heights are supplied as known numerical
// values. The program also evaluates zeta numerically to
// confirm the corresponding output is extremely close to 0.
//
// NUMERICAL METHOD
// ------------------------------------------------------------
//
// eta(s) = sum (-1)^(n-1) / n^s
//
// Euler transformation:
//
// eta(s)
//   = sum Delta^k a(1) / 2^(k+1)
//
// zeta(s)
//   = eta(s) / (1 - 2^(1-s))
//
// ============================================================

import java.util.Locale;


// ============================================================
// SETTINGS
// ============================================================

final int LEVELS = 96;

final int MAX_TRACE = 600;

final int UPDATE_MS = 30;

final int SEARCH_UPDATE_MS = 55;


// ============================================================
// INPUT DOMAIN
// ============================================================

final double REAL_MIN = 0.0;

final double REAL_MAX = 1.5;

final double IMAG_MIN = 0.0;

final double IMAG_MAX = 50.0;


// ============================================================
// OUTPUT DISPLAY DOMAIN
// ============================================================

final double OUTPUT_LIMIT = 4.0;


// ============================================================
// CONSTANTS
// ============================================================

final double LN2 =
  0.693147180559945309417232121458176568;

final double CRITICAL_LINE = 0.5;


// ============================================================
// ZERO SNAP SETTINGS
// ============================================================

final double ZERO_SNAP_TOL = 0.35;


// ============================================================
// ZERO VALIDATION
// ============================================================

final double LINE_TOL = 1.0e-12;

final double ZERO_EXACT_TOL = 1.0e-10;


// ============================================================
// YELLOW SEARCH SETTINGS
// ============================================================
//
// Coarse precomputed critical-line table:
//
//       t = 0 ... 50
//
// Then local numerical refinement is performed.
//

final int SEARCH_SAMPLES = 1001;

final double ZERO_TARGET_RADIUS = 0.45;

final double ZERO_SEARCH_WINDOW = 0.45;


// ============================================================
// TRACE SETTINGS
// ============================================================

final float INPUT_TRACE_GLOW = 9.0f;

final float INPUT_TRACE_WIDTH = 5.0f;

final float OUTPUT_TRACE_GLOW = 8.0f;

final float OUTPUT_TRACE_WIDTH = 3.5f;

final float TRACE_POINT_SIZE = 4.0f;


// ============================================================
// YELLOW SCRIBBLE SETTINGS
// ============================================================

final float SCRIBBLE_GLOW = 11.0f;

final float SCRIBBLE_WIDTH = 4.0f;

final int MAX_SCRIBBLE = 700;

final float SCRIBBLE_POINT = 4.0f;


// ============================================================
// FIRST 8 KNOWN NON-TRIVIAL RIEMANN ZEROS
// ============================================================

double[] zeros = {

  14.134725141734693790,

  21.022039638771554993,

  25.010857580145688763,

  30.424876125859513210,

  32.935061587739189691,

  37.586178158825671257,

  40.918719012147495187,

  43.327073280914999519

};


// ============================================================
// INPUT MODE
// ============================================================
//
// true  = locked critical line
// false = free complex input
//

boolean lockedMode = true;


// ============================================================
// YELLOW SEARCH MODE
// ============================================================
//
// false = normal zeta visualization
// true  = yellow right-side scribble search
//

boolean yellowSearchMode = false;


// ============================================================
// CURRENT INPUT
// ============================================================

double inputRe =
  CRITICAL_LINE;

double inputIm =
  zeros[0];


// ============================================================
// CURRENT OUTPUT
// ============================================================

double outputRe = 0.0;

double outputIm = 0.0;


// ============================================================
// NUMERICAL WORK ARRAYS
// ============================================================

double[] workRe =
  new double[LEVELS + 1];

double[] workIm =
  new double[LEVELS + 1];

double[] logarithms =
  new double[LEVELS + 2];


// ============================================================
// CRITICAL-LINE SEARCH TABLE
// ============================================================

double[] searchT =
  new double[SEARCH_SAMPLES];

double[] searchZRe =
  new double[SEARCH_SAMPLES];

double[] searchZIm =
  new double[SEARCH_SAMPLES];


// ============================================================
// LEFT INPUT TRACE
// ============================================================

double[] inputTraceRe =
  new double[MAX_TRACE];

double[] inputTraceIm =
  new double[MAX_TRACE];

boolean[] inputTraceBreak =
  new boolean[MAX_TRACE];

int inputTraceCount = 0;


// ============================================================
// RIGHT OUTPUT TRACE
// ============================================================

float[] outputTraceX =
  new float[MAX_TRACE];

float[] outputTraceY =
  new float[MAX_TRACE];

boolean[] outputTraceBreak =
  new boolean[MAX_TRACE];

int outputTraceCount = 0;


// ============================================================
// YELLOW SCRIBBLE TRACE
// ============================================================

float[] scribbleX =
  new float[MAX_SCRIBBLE];

float[] scribbleY =
  new float[MAX_SCRIBBLE];

boolean[] scribbleBreak =
  new boolean[MAX_SCRIBBLE];

int scribbleCount = 0;


// ============================================================
// TOUCH STATE
// ============================================================

boolean touching = false;

boolean newTouchStroke = false;

float previousTouchX = -10000;

float previousTouchY = -10000;

long previousCalculation = 0;


// ============================================================
// BUTTON STATE
// ============================================================
//
// 0 = none
// 1 = left input button
// 2 = right yellow search button
//

int buttonDown = 0;


// ============================================================
// GRAPH GEOMETRY
// ============================================================

float middle;

float graphTop;

float graphBottom;


// ============================================================
// ZERO STATE
// ============================================================

int activeZero = -1;

boolean zeroReached = false;

int lastZero = -1;

long zeroHitTime = 0;


// ============================================================
// YELLOW SEARCH STATE
// ============================================================

double searchTargetRe = 0.0;

double searchTargetIm = 0.0;

double searchedT = 0.0;

double searchDistance = 0.0;

boolean searchingZeroTarget = false;


// ============================================================
// ZERO CYCLE
// ============================================================
//
// Repeated new yellow strokes near the origin cycle through
// the first 8 known zero neighborhoods.
//
// This makes it possible to scribble near zeta = 0 and
// inspect the zeros one by one.
//

int zeroCycleIndex = 0;

boolean zeroOriginStrokeHandled = false;


// ============================================================
// SAVED INPUT BEFORE YELLOW SEARCH
// ============================================================

double savedInputRe =
  CRITICAL_LINE;

double savedInputIm =
  zeros[0];


// ============================================================
// SETUP
// ============================================================

void setup() {

  orientation(LANDSCAPE);

  fullScreen();

  frameRate(30);

  textFont(
    createFont(
      "SansSerif",
      16
    )
  );

  updateGeometry();

  // ----------------------------------------------------------
  // Precalculate logarithms
  // ----------------------------------------------------------

  for (
    int i = 1;
    i <= LEVELS + 1;
    i++
  ) {

    logarithms[i] =
      Math.log(i);
  }

  // ----------------------------------------------------------
  // Build numerical critical-line search table
  // ----------------------------------------------------------

  buildSearchTable();

  // ----------------------------------------------------------
  // Start at first known zero
  // ----------------------------------------------------------

  calculateZeta(
    inputRe,
    inputIm
  );

  updateZeroState();

  addTracePoint(
    inputRe,
    inputIm,
    outputRe,
    outputIm,
    true
  );
}


// ============================================================
// GEOMETRY
// ============================================================

void updateGeometry() {

  middle =
    width * 0.5f;

  graphTop =
    height * 0.19f;

  graphBottom =
    height * 0.78f;
}


// ============================================================
// MAIN DRAW
// ============================================================

void draw() {

  background(6);

  updateGeometry();

  handleTouch();

  drawTitles();

  drawLeftGraph();

  drawRightGraph();

  // ----------------------------------------------------------
  // YELLOW SCRIBBLE
  // ----------------------------------------------------------

  if (yellowSearchMode) {

    drawYellowScribble();
  }

  // ----------------------------------------------------------
  // ZERO LASER
  // ----------------------------------------------------------

  if (zeroReached) {

    drawZeroLaser();
  }

  // ----------------------------------------------------------
  // MOVING MARKERS
  // ----------------------------------------------------------

  drawInputMarker();

  drawOutputMarker();

  // ----------------------------------------------------------
  // INFORMATION
  // ----------------------------------------------------------

  drawInformation();

  // ----------------------------------------------------------
  // BUTTONS
  // ----------------------------------------------------------

  drawInputToggleButton();

  drawYellowSearchButton();
}


// ============================================================
// TITLES
// ============================================================

void drawTitles() {

  textAlign(
    CENTER,
    CENTER
  );

  textSize(
    Math.max(
      17,
      height * 0.035f
    )
  );

  fill(255);

  text(
    "RIEMANN ZETA FUNCTION",
    middle,
    height * 0.045f
  );


  // ----------------------------------------------------------
  // LEFT TITLE
  // ----------------------------------------------------------

  textSize(
    Math.max(
      15,
      height * 0.028f
    )
  );

  if (yellowSearchMode) {

    fill(
      65,
      155,
      255
    );

    text(
      "INPUT — CRITICAL LINE SEARCH",
      middle * 0.5f,
      height * 0.11f
    );

  } else if (lockedMode) {

    fill(
      65,
      165,
      255
    );

    text(
      "INPUT — CRITICAL LINE",
      middle * 0.5f,
      height * 0.11f
    );

  } else {

    fill(
      80,
      210,
      255
    );

    text(
      "INPUT — FREE COMPLEX PLANE",
      middle * 0.5f,
      height * 0.11f
    );
  }


  // ----------------------------------------------------------
  // RIGHT TITLE
  // ----------------------------------------------------------

  textSize(
    Math.max(
      15,
      height * 0.028f
    )
  );

  if (yellowSearchMode) {

    fill(
      255,
      220,
      30
    );

    text(
      "YELLOW SEARCH — zeta(s)",
      middle * 1.5f,
      height * 0.11f
    );

  } else {

    fill(
      255,
      205,
      0
    );

    text(
      "RESULT — zeta(s)",
      middle * 1.5f,
      height * 0.11f
    );
  }


  // ----------------------------------------------------------
  // LEFT DESCRIPTION
  // ----------------------------------------------------------

  textSize(
    Math.max(
      10,
      height * 0.016f
    )
  );

  if (yellowSearchMode) {

    fill(180);

    text(
      "SEARCH MODE: blue input locked to Re(s) = 0.5",
      middle * 0.5f,
      height * 0.155f
    );

  } else if (lockedMode) {

    fill(180);

    text(
      "Locked: Re(s) = 0.5000000000   |   Touch Y controls t",
      middle * 0.5f,
      height * 0.155f
    );

  } else {

    fill(180);

    text(
      "Free: X = Re(s)   |   Y = Im(s)   |   Critical line = reference",
      middle * 0.5f,
      height * 0.155f
    );
  }


  // ----------------------------------------------------------
  // RIGHT DESCRIPTION
  // ----------------------------------------------------------

  fill(180);

  if (yellowSearchMode) {

    text(
      "Scribble here to search the critical line | Near 0 = zero search",
      middle * 1.5f,
      height * 0.155f
    );

  } else {

    text(
      "Yellow locus: zeta(s(t))",
      middle * 1.5f,
      height * 0.155f
    );
  }
}


// ============================================================
// TOUCH HANDLING
// ============================================================

void handleTouch() {

  // ----------------------------------------------------------
  // BUTTON RELEASE
  // ----------------------------------------------------------

  if (!mousePressed) {

    if (buttonDown == 1) {

      if (
        isInsideInputToggle(
          mouseX,
          mouseY
        )
      ) {

        toggleInputMode();
      }
    }

    if (buttonDown == 2) {

      if (
        isInsideYellowButton(
          mouseX,
          mouseY
        )
      ) {

        toggleYellowSearch();
      }
    }

    buttonDown = 0;

    if (touching) {

      newTouchStroke = true;
    }

    touching = false;

    previousTouchX = -10000;

    previousTouchY = -10000;

    return;
  }


  // ----------------------------------------------------------
  // NEW INPUT BUTTON TOUCH
  // ----------------------------------------------------------

  if (
    buttonDown == 0 &&
    !touching &&
    isInsideInputToggle(
      mouseX,
      mouseY
    )
  ) {

    buttonDown = 1;

    return;
  }


  // ----------------------------------------------------------
  // NEW YELLOW SEARCH BUTTON TOUCH
  // ----------------------------------------------------------

  if (
    buttonDown == 0 &&
    !touching &&
    isInsideYellowButton(
      mouseX,
      mouseY
    )
  ) {

    buttonDown = 2;

    return;
  }


  // ----------------------------------------------------------
  // BUTTON HELD
  // ----------------------------------------------------------

  if (buttonDown != 0) {

    return;
  }


  // ==========================================================
  // YELLOW SEARCH MODE
  // ==========================================================

  if (yellowSearchMode) {

    handleYellowSearchTouch();

    return;
  }


  // ==========================================================
  // NORMAL LEFT INPUT TOUCH
  // ==========================================================

  handleNormalInputTouch();
}


// ============================================================
// NORMAL INPUT TOUCH
// ============================================================

void handleNormalInputTouch() {

  // ----------------------------------------------------------
  // ACCEPT LEFT GRAPH ONLY
  // ----------------------------------------------------------

  if (
    mouseX < 0 ||
    mouseX >= middle
  ) {

    return;
  }

  if (
    mouseY < graphTop ||
    mouseY > graphBottom
  ) {

    return;
  }


  // ----------------------------------------------------------
  // NEW TOUCH STROKE
  // ----------------------------------------------------------

  if (!touching) {

    touching = true;

    previousTouchX = -10000;

    previousTouchY = -10000;

    newTouchStroke = true;
  }


  // ----------------------------------------------------------
  // SMALL MOVEMENT CHECK
  // ----------------------------------------------------------

  if (
    previousTouchX > -9000 &&
    previousTouchY > -9000
  ) {

    float dx =
      Math.abs(
        mouseX -
        previousTouchX
      );

    float dy =
      Math.abs(
        mouseY -
        previousTouchY
      );

    if (
      dx < 1.0f &&
      dy < 1.0f
    ) {

      return;
    }
  }


  // ----------------------------------------------------------
  // UPDATE LIMIT
  // ----------------------------------------------------------

  long now =
    millis();

  if (
    now -
    previousCalculation <
    UPDATE_MS
  ) {

    return;
  }


  // ----------------------------------------------------------
  // CALCULATE Re(s)
  // ----------------------------------------------------------

  double re;

  if (lockedMode) {

    re =
      CRITICAL_LINE;

  } else {

    re =
      mapValue(
        mouseX,
        25,
        middle - 25,
        REAL_MIN,
        REAL_MAX
      );

    re =
      limit(
        re,
        REAL_MIN,
        REAL_MAX
      );
  }


  // ----------------------------------------------------------
  // CALCULATE Im(s)
  // ----------------------------------------------------------

  double im =
    mapValue(
      mouseY,
      graphBottom,
      graphTop,
      IMAG_MIN,
      IMAG_MAX
    );

  im =
    limit(
      im,
      IMAG_MIN,
      IMAG_MAX
    );


  // ----------------------------------------------------------
  // ZERO SNAP IN LOCKED MODE
  // ----------------------------------------------------------

  if (lockedMode) {

    int nearest =
      nearestZero(im);

    if (nearest >= 0) {

      if (
        Math.abs(
          im -
          zeros[nearest]
        ) <
        ZERO_SNAP_TOL
      ) {

        im =
          zeros[nearest];
      }
    }
  }


  // ----------------------------------------------------------
  // APPLY
  // ----------------------------------------------------------

  inputRe =
    re;

  inputIm =
    im;


  // ----------------------------------------------------------
  // CALCULATE ZETA
  // ----------------------------------------------------------

  calculateZeta(
    inputRe,
    inputIm
  );


  // ----------------------------------------------------------
  // ZERO CHECK
  // ----------------------------------------------------------

  updateZeroState();


  // ----------------------------------------------------------
  // STORE SYNCHRONIZED TRACE
  // ----------------------------------------------------------

  addTracePoint(
    inputRe,
    inputIm,
    outputRe,
    outputIm,
    newTouchStroke
  );

  newTouchStroke = false;


  previousTouchX =
    mouseX;

  previousTouchY =
    mouseY;

  previousCalculation =
    now;
}


// ============================================================
// YELLOW SEARCH TOUCH
// ============================================================

void handleYellowSearchTouch() {

  // ----------------------------------------------------------
  // RIGHT GRAPH ONLY
  // ----------------------------------------------------------

  if (
    mouseX < middle ||
    mouseX > width
  ) {

    return;
  }

  if (
    mouseY < graphTop ||
    mouseY > graphBottom
  ) {

    return;
  }


  // ----------------------------------------------------------
  // NEW YELLOW STROKE
  // ----------------------------------------------------------

  if (!touching) {

    touching = true;

    previousTouchX = -10000;

    previousTouchY = -10000;

    newTouchStroke = true;

    zeroOriginStrokeHandled = false;
  }


  // ----------------------------------------------------------
  // SMALL MOVEMENT CHECK
  // ----------------------------------------------------------

  if (
    previousTouchX > -9000 &&
    previousTouchY > -9000
  ) {

    float dx =
      Math.abs(
        mouseX -
        previousTouchX
      );

    float dy =
      Math.abs(
        mouseY -
        previousTouchY
      );

    if (
      dx < 1.0f &&
      dy < 1.0f
    ) {

      return;
    }
  }


  // ----------------------------------------------------------
  // UPDATE LIMIT
  // ----------------------------------------------------------

  long now =
    millis();

  if (
    now -
    previousCalculation <
    SEARCH_UPDATE_MS
  ) {

    return;
  }


  // ----------------------------------------------------------
  // SCREEN -> OUTPUT COMPLEX VALUE
  // ----------------------------------------------------------

  double targetRe =
    mapValue(
      mouseX,
      middle + 25,
      width - 25,
      -OUTPUT_LIMIT,
      OUTPUT_LIMIT
    );

  double targetIm =
    mapValue(
      mouseY,
      graphBottom,
      graphTop,
      -OUTPUT_LIMIT,
      OUTPUT_LIMIT
    );

  targetRe =
    limit(
      targetRe,
      -OUTPUT_LIMIT,
      OUTPUT_LIMIT
    );

  targetIm =
    limit(
      targetIm,
      -OUTPUT_LIMIT,
      OUTPUT_LIMIT
    );


  searchTargetRe =
    targetRe;

  searchTargetIm =
    targetIm;


  // ----------------------------------------------------------
  // DISTANCE TO ORIGIN
  // ----------------------------------------------------------

  double targetMagnitude =
    Math.sqrt(
      targetRe * targetRe +
      targetIm * targetIm
    );


  // ==========================================================
  // SPECIAL ZERO SEARCH
  // ==========================================================

  if (
    targetMagnitude <=
    ZERO_TARGET_RADIUS
  ) {

    searchingZeroTarget = true;

    // --------------------------------------------------------
    // Only perform the zero selection once for a stroke.
    // --------------------------------------------------------

    if (!zeroOriginStrokeHandled) {

      zeroOriginStrokeHandled = true;

      int chosen =
        zeroCycleIndex;

      // ------------------------------------------------------
      // Numerically refine around the selected known zero.
      // ------------------------------------------------------

      double refinedT =
        refineKnownZero(
          zeros[chosen]
        );

      // ------------------------------------------------------
      // Snap to stored known zero for exact event recognition.
      // ------------------------------------------------------

      inputRe =
        CRITICAL_LINE;

      inputIm =
        zeros[chosen];

      searchedT =
        refinedT;

      calculateZeta(
        inputRe,
        inputIm
      );

      updateZeroState();

      addTracePoint(
        inputRe,
        inputIm,
        outputRe,
        outputIm,
        true
      );

      // ------------------------------------------------------
      // Next zero on next distinct zero-target stroke.
      // ------------------------------------------------------

      zeroCycleIndex++;

      if (
        zeroCycleIndex >=
        zeros.length
      ) {

        zeroCycleIndex = 0;
      }

    } else {

      // ------------------------------------------------------
      // Keep current exact zero while scribbling near origin.
      // ------------------------------------------------------

      inputRe =
        CRITICAL_LINE;

      calculateZeta(
        inputRe,
        inputIm
      );

      updateZeroState();
    }

  } else {

    // ========================================================
    // GENERAL ZETA-PLANE SEARCH
    // ========================================================

    searchingZeroTarget = false;

    double bestT =
      searchCriticalLineForTarget(
        targetRe,
        targetIm
      );

    searchedT =
      bestT;

    inputRe =
      CRITICAL_LINE;

    inputIm =
      bestT;

    calculateZeta(
      inputRe,
      inputIm
    );

    updateZeroState();

    addTracePoint(
      inputRe,
      inputIm,
      outputRe,
      outputIm,
      newTouchStroke
    );
  }


  // ----------------------------------------------------------
  // ADD SCRIBBLE POINT
  // ----------------------------------------------------------

  addScribblePoint(
    mouseX,
    mouseY,
    newTouchStroke
  );

  newTouchStroke = false;

  previousTouchX =
    mouseX;

  previousTouchY =
    mouseY;

  previousCalculation =
    now;
}


// ============================================================
// INPUT TOGGLE BUTTON
// ============================================================

void drawInputToggleButton() {

  float x =
    35;

  float y =
    graphTop + 10;

  float w =
    Math.min(
      210,
      middle - 65
    );

  float h =
    38;


  // ----------------------------------------------------------
  // SHADOW
  // ----------------------------------------------------------

  noStroke();

  fill(
    0,
    0,
    0,
    170
  );

  rect(
    x + 3,
    y + 3,
    w,
    h,
    8
  );


  // ----------------------------------------------------------
  // BODY
  // ----------------------------------------------------------

  if (yellowSearchMode) {

    fill(
      30,
      65,
      105,
      235
    );

  } else if (lockedMode) {

    fill(
      15,
      80,
      145,
      235
    );

  } else {

    fill(
      15,
      125,
      120,
      235
    );
  }

  rect(
    x,
    y,
    w,
    h,
    8
  );


  // ----------------------------------------------------------
  // BORDER
  // ----------------------------------------------------------

  noFill();

  if (yellowSearchMode) {

    stroke(
      80,
      155,
      220
    );

  } else if (lockedMode) {

    stroke(
      60,
      190,
      255
    );

  } else {

    stroke(
      70,
      240,
      210
    );
  }

  strokeWeight(2);

  rect(
    x,
    y,
    w,
    h,
    8
  );


  // ----------------------------------------------------------
  // TEXT
  // ----------------------------------------------------------

  textAlign(
    CENTER,
    CENTER
  );

  textSize(
    Math.max(
      10,
      height * 0.016f
    )
  );

  fill(255);

  if (yellowSearchMode) {

    text(
      "INPUT LOCKED DURING SEARCH",
      x + w * 0.5f,
      y + h * 0.5f
    );

  } else if (lockedMode) {

    text(
      "FREE INPUT MODE",
      x + w * 0.5f,
      y + h * 0.5f
    );

  } else {

    text(
      "LOCK TO Re(s) = 0.5",
      x + w * 0.5f,
      y + h * 0.5f
    );
  }
}


// ============================================================
// YELLOW SEARCH BUTTON
// ============================================================

void drawYellowSearchButton() {

  float x =
    middle + 35;

  float y =
    graphTop + 10;

  float w =
    Math.min(
      220,
      width - middle - 65
    );

  float h =
    38;


  // ----------------------------------------------------------
  // SHADOW
  // ----------------------------------------------------------

  noStroke();

  fill(
    0,
    0,
    0,
    180
  );

  rect(
    x + 3,
    y + 3,
    w,
    h,
    8
  );


  // ----------------------------------------------------------
  // BODY
  // ----------------------------------------------------------

  if (yellowSearchMode) {

    fill(
      150,
      105,
      0,
      245
    );

  } else {

    fill(
      115,
      85,
      0,
      235
    );
  }

  rect(
    x,
    y,
    w,
    h,
    8
  );


  // ----------------------------------------------------------
  // BORDER
  // ----------------------------------------------------------

  noFill();

  stroke(
    255,
    220,
    40
  );

  strokeWeight(2.5f);

  rect(
    x,
    y,
    w,
    h,
    8
  );


  // ----------------------------------------------------------
  // BUTTON TEXT
  // ----------------------------------------------------------

  textAlign(
    CENTER,
    CENTER
  );

  textSize(
    Math.max(
      10,
      height * 0.016f
    )
  );

  fill(255);

  if (yellowSearchMode) {

    text(
      "EXIT YELLOW SEARCH",
      x + w * 0.5f,
      y + h * 0.5f
    );

  } else {

    text(
      "YELLOW SEARCH / SCRIBBLE",
      x + w * 0.5f,
      y + h * 0.5f
    );
  }
}


// ============================================================
// INPUT BUTTON HIT TEST
// ============================================================

boolean isInsideInputToggle(
  float px,
  float py
) {

  float x =
    35;

  float y =
    graphTop + 10;

  float w =
    Math.min(
      210,
      middle - 65
    );

  float h =
    38;

  return
    px >= x &&
    px <= x + w &&
    py >= y &&
    py <= y + h;
}


// ============================================================
// YELLOW BUTTON HIT TEST
// ============================================================

boolean isInsideYellowButton(
  float px,
  float py
) {

  float x =
    middle + 35;

  float y =
    graphTop + 10;

  float w =
    Math.min(
      220,
      width - middle - 65
    );

  float h =
    38;

  return
    px >= x &&
    px <= x + w &&
    py >= y &&
    py <= y + h;
}


// ============================================================
// INPUT MODE TOGGLE
// ============================================================

void toggleInputMode() {

  // Yellow search has priority.
  if (yellowSearchMode) {

    return;
  }

  lockedMode =
    !lockedMode;


  // ----------------------------------------------------------
  // Entering locked mode
  // ----------------------------------------------------------

  if (lockedMode) {

    inputRe =
      CRITICAL_LINE;
  }


  // ----------------------------------------------------------
  // Recalculate
  // ----------------------------------------------------------

  calculateZeta(
    inputRe,
    inputIm
  );

  updateZeroState();


  // ----------------------------------------------------------
  // Separate trace segment
  // ----------------------------------------------------------

  newTouchStroke = true;

  touching = false;

  previousTouchX = -10000;

  previousTouchY = -10000;

  previousCalculation = 0;
}


// ============================================================
// YELLOW SEARCH TOGGLE
// ============================================================

void toggleYellowSearch() {

  yellowSearchMode =
    !yellowSearchMode;


  // ==========================================================
  // ENTER YELLOW SEARCH MODE
  // ==========================================================

  if (yellowSearchMode) {

    // --------------------------------------------------------
    // Save current state
    // --------------------------------------------------------

    savedInputRe =
      inputRe;

    savedInputIm =
      inputIm;


    // --------------------------------------------------------
    // FORCE CRITICAL LINE
    // --------------------------------------------------------

    inputRe =
      CRITICAL_LINE;


    // --------------------------------------------------------
    // Keep current t
    // --------------------------------------------------------

    inputIm =
      limit(
        inputIm,
        IMAG_MIN,
        IMAG_MAX
      );


    // --------------------------------------------------------
    // Reset zero cycle
    // --------------------------------------------------------

    zeroCycleIndex = 0;

    searchingZeroTarget = false;

    zeroOriginStrokeHandled = false;


    // --------------------------------------------------------
    // Clear traces so the displayed blue path is a straight
    // critical-line path during search.
    // --------------------------------------------------------

    clearAllTraces();


    // --------------------------------------------------------
    // Recalculate
    // --------------------------------------------------------

    calculateZeta(
      inputRe,
      inputIm
    );

    updateZeroState();

    addTracePoint(
      inputRe,
      inputIm,
      outputRe,
      outputIm,
      true
    );


    // --------------------------------------------------------
    // Reset touch
    // --------------------------------------------------------

    touching = false;

    newTouchStroke = true;

    previousTouchX = -10000;

    previousTouchY = -10000;

    previousCalculation = 0;
  }


  // ==========================================================
  // EXIT YELLOW SEARCH MODE
  // ==========================================================

  else {

    // --------------------------------------------------------
    // Restore state before search
    // --------------------------------------------------------

    if (lockedMode) {

      inputRe =
        CRITICAL_LINE;

    } else {

      inputRe =
        savedInputRe;
    }

    inputIm =
      savedInputIm;


    // --------------------------------------------------------
    // Recalculate
    // --------------------------------------------------------

    calculateZeta(
      inputRe,
      inputIm
    );

    updateZeroState();


    // --------------------------------------------------------
    // New trace segment
    // --------------------------------------------------------

    clearAllTraces();

    addTracePoint(
      inputRe,
      inputIm,
      outputRe,
      outputIm,
      true
    );


    // --------------------------------------------------------
    // Reset touch
    // --------------------------------------------------------

    touching = false;

    newTouchStroke = true;

    previousTouchX = -10000;

    previousTouchY = -10000;

    previousCalculation = 0;
  }
}


// ============================================================
// CLEAR ALL LOCI
// ============================================================

void clearAllTraces() {

  inputTraceCount = 0;

  outputTraceCount = 0;

  scribbleCount = 0;
}


// ============================================================
// LEFT GRAPH
// ============================================================

void drawLeftGraph() {

  float left =
    25;

  float right =
    middle - 25;


  // ----------------------------------------------------------
  // GRID
  // ----------------------------------------------------------

  stroke(30);

  strokeWeight(1);

  for (
    int i = 0;
    i <= 8;
    i++
  ) {

    float x =
      left +
      (
        right - left
      ) *
      i /
      8.0f;

    line(
      x,
      graphTop,
      x,
      graphBottom
    );


    float y =
      graphTop +
      (
        graphBottom - graphTop
      ) *
      i /
      8.0f;

    line(
      left,
      y,
      right,
      y
    );
  }


  // ----------------------------------------------------------
  // AXES
  // ----------------------------------------------------------

  float originX =
    inputX(0);

  stroke(
    150,
    160,
    180
  );

  strokeWeight(2);

  line(
    originX,
    graphTop,
    originX,
    graphBottom
  );

  line(
    left,
    graphBottom,
    right,
    graphBottom
  );


  // ----------------------------------------------------------
  // CRITICAL LINE
  // ----------------------------------------------------------

  float criticalX =
    inputX(
      CRITICAL_LINE
    );


  // ----------------------------------------------------------
  // CRITICAL LINE GLOW
  // ----------------------------------------------------------

  if (
    yellowSearchMode ||
    lockedMode
  ) {

    stroke(
      20,
      90,
      255,
      65
    );

    strokeWeight(13);

  } else {

    stroke(
      20,
      90,
      255,
      30
    );

    strokeWeight(8);
  }

  line(
    criticalX,
    graphTop,
    criticalX,
    graphBottom
  );


  // ----------------------------------------------------------
  // CRITICAL LINE MAIN
  // ----------------------------------------------------------

  if (
    yellowSearchMode ||
    lockedMode
  ) {

    stroke(
      35,
      155,
      255
    );

    strokeWeight(4);

  } else {

    stroke(
      35,
      120,
      220,
      130
    );

    strokeWeight(2);
  }

  line(
    criticalX,
    graphTop,
    criticalX,
    graphBottom
  );


  // ----------------------------------------------------------
  // BLUE INPUT LOCUS
  // ----------------------------------------------------------

  drawInputLocus();


  // ----------------------------------------------------------
  // ZERO POINTS
  // ----------------------------------------------------------

  drawZeroPoints(
    criticalX
  );


  // ----------------------------------------------------------
  // CRITICAL LINE LABEL
  // ----------------------------------------------------------

  textAlign(
    CENTER,
    CENTER
  );

  textSize(
    Math.max(
      10,
      height * 0.016f
    )
  );

  fill(
    100,
    190,
    255
  );

  text(
    "Re(s) = 0.5000000000",
    criticalX,
    graphBottom - 14
  );


  // ----------------------------------------------------------
  // REAL AXIS LABELS
  // ----------------------------------------------------------

  textSize(
    Math.max(
      9,
      height * 0.014f
    )
  );

  fill(160);

  text(
    "0.0",
    inputX(0.0),
    graphBottom + 14
  );

  text(
    "0.5",
    inputX(0.5),
    graphBottom + 14
  );

  text(
    "1.0",
    inputX(1.0),
    graphBottom + 14
  );

  text(
    "1.5",
    inputX(1.5),
    graphBottom + 14
  );
}


// ============================================================
// BLUE INPUT LOCUS
// ============================================================

void drawInputLocus() {

  if (
    inputTraceCount <
    2
  ) {

    return;
  }


  // ----------------------------------------------------------
  // GLOW
  // ----------------------------------------------------------

  noFill();

  stroke(
    0,
    120,
    255,
    45
  );

  strokeWeight(
    INPUT_TRACE_GLOW
  );

  drawInputTracePath();


  // ----------------------------------------------------------
  // MAIN
  // ----------------------------------------------------------

  stroke(
    55,
    190,
    255,
    225
  );

  strokeWeight(
    INPUT_TRACE_WIDTH
  );

  drawInputTracePath();


  // ----------------------------------------------------------
  // SAMPLE POINTS
  // ----------------------------------------------------------

  noStroke();

  for (
    int i = 0;
    i < inputTraceCount;
    i += 5
  ) {

    float alpha =
      map(
        i,
        0,
        Math.max(
          1,
          inputTraceCount - 1
        ),
        60,
        150
      );

    fill(
      80,
      210,
      255,
      alpha
    );

    ellipse(
      inputX(
        inputTraceRe[i]
      ),
      inputY(
        inputTraceIm[i]
      ),
      TRACE_POINT_SIZE,
      TRACE_POINT_SIZE
    );
  }
}


// ============================================================
// INPUT TRACE PATH
// ============================================================

void drawInputTracePath() {

  boolean shapeOpen =
    false;

  for (
    int i = 0;
    i < inputTraceCount;
    i++
  ) {

    if (
      inputTraceBreak[i]
    ) {

      if (shapeOpen) {

        endShape();

        shapeOpen =
          false;
      }
    }

    if (!shapeOpen) {

      beginShape();

      shapeOpen =
        true;
    }

    vertex(
      inputX(
        inputTraceRe[i]
      ),
      inputY(
        inputTraceIm[i]
      )
    );
  }

  if (shapeOpen) {

    endShape();
  }
}


// ============================================================
// ZERO POINTS
// ============================================================

void drawZeroPoints(
  float criticalX
) {

  textSize(
    Math.max(
      8,
      height * 0.013f
    )
  );

  for (
    int i = 0;
    i < zeros.length;
    i++
  ) {

    float y =
      inputY(
        zeros[i]
      );

    if (
      y < graphTop ||
      y > graphBottom
    ) {

      continue;
    }

    boolean selected =
      activeZero == i;

    boolean blink =
      (
        (millis() / 170) % 2
      ) == 0;


    // --------------------------------------------------------
    // NORMAL ZERO
    // --------------------------------------------------------

    if (!selected) {

      noStroke();

      fill(
        30,
        155,
        255
      );

      ellipse(
        criticalX,
        y,
        9,
        9
      );

    } else {

      // ------------------------------------------------------
      // GLOW
      // ------------------------------------------------------

      noFill();

      stroke(
        60,
        190,
        255,
        90
      );

      strokeWeight(8);

      ellipse(
        criticalX,
        y,
        23,
        23
      );


      // ------------------------------------------------------
      // CENTER
      // ------------------------------------------------------

      noStroke();

      fill(
        blink ? 255 : 35,
        blink ? 60 : 155,
        blink ? 60 : 255
      );

      ellipse(
        criticalX,
        y,
        15,
        15
      );


      // ------------------------------------------------------
      // WHITE CORE
      // ------------------------------------------------------

      fill(255);

      ellipse(
        criticalX,
        y,
        4,
        4
      );
    }


    // --------------------------------------------------------
    // LABEL
    // --------------------------------------------------------

    textAlign(
      LEFT,
      CENTER
    );

    if (selected) {

      fill(
        255,
        100,
        100
      );

    } else {

      fill(
        100,
        185,
        255
      );
    }

    String label =
      "#" +
      (i + 1) +
      "  t = " +
      format10(
        zeros[i]
      );

    float labelX =
      criticalX + 12;

    if (
      labelX >
      middle - 155
    ) {

      labelX =
        criticalX - 155;

      textAlign(
        RIGHT,
        CENTER
      );
    }

    text(
      label,
      labelX,
      y
    );
  }
}


// ============================================================
// RIGHT GRAPH
// ============================================================

void drawRightGraph() {

  float left =
    middle + 25;

  float right =
    width - 25;

  float originX =
    outputX(0);

  float originY =
    outputY(0);


  // ----------------------------------------------------------
  // GRID
  // ----------------------------------------------------------

  stroke(30);

  strokeWeight(1);

  for (
    int i = 0;
    i <= 12;
    i++
  ) {

    float x =
      left +
      (
        right - left
      ) *
      i /
      12.0f;

    line(
      x,
      graphTop,
      x,
      graphBottom
    );


    float y =
      graphTop +
      (
        graphBottom - graphTop
      ) *
      i /
      12.0f;

    line(
      left,
      y,
      right,
      y
    );
  }


  // ----------------------------------------------------------
  // AXES
  // ----------------------------------------------------------

  stroke(
    150,
    160,
    180
  );

  strokeWeight(2);

  line(
    originX,
    graphTop,
    originX,
    graphBottom
  );

  line(
    left,
    originY,
    right,
    originY
  );


  // ----------------------------------------------------------
  // ORIGIN TARGET
  // ----------------------------------------------------------

  noFill();

  stroke(230);

  strokeWeight(2);

  ellipse(
    originX,
    originY,
    22,
    22
  );

  noStroke();

  fill(255);

  ellipse(
    originX,
    originY,
    4,
    4
  );


  // ----------------------------------------------------------
  // ZERO TARGET ZONE
  // ----------------------------------------------------------

  if (yellowSearchMode) {

    noFill();

    stroke(
      255,
      220,
      50,
      80
    );

    strokeWeight(2);

    ellipse(
      originX,
      originY,
      (float)
      (
        ZERO_TARGET_RADIUS *
        2.0 *
        (
          width -
          middle -
          50
        ) /
        (
          OUTPUT_LIMIT * 2.0
        )
      ),
      (float)
      (
        ZERO_TARGET_RADIUS *
        2.0 *
        (
          graphBottom -
          graphTop
        ) /
        (
          OUTPUT_LIMIT * 2.0
        )
      )
    );

    textAlign(
      CENTER,
      CENTER
    );

    textSize(
      Math.max(
        9,
        height * 0.013f
      )
    );

    fill(
      255,
      220,
      50
    );

    text(
      "ZERO TARGET",
      originX,
      originY - 26
    );
  }


  // ----------------------------------------------------------
  // NORMAL ZETA LOCUS
  // ----------------------------------------------------------

  drawOutputLocus();


  // ----------------------------------------------------------
  // AXIS LABELS
  // ----------------------------------------------------------

  textAlign(
    CENTER,
    CENTER
  );

  textSize(
    Math.max(
      10,
      height * 0.015f
    )
  );

  fill(165);

  text(
    "-4",
    outputX(-4),
    originY + 14
  );

  text(
    "0",
    originX + 12,
    originY + 14
  );

  text(
    "+4",
    outputX(4),
    originY + 14
  );


  textSize(
    Math.max(
      9,
      height * 0.013f
    )
  );

  text(
    "Re(zeta)",
    right - 40,
    graphBottom + 14
  );

  text(
    "Im(zeta)",
    left + 45,
    graphTop + 12
  );
}


// ============================================================
// OUTPUT LOCUS
// ============================================================

void drawOutputLocus() {

  if (
    outputTraceCount <
    2
  ) {

    return;
  }


  // ----------------------------------------------------------
  // GLOW
  // ----------------------------------------------------------

  noFill();

  stroke(
    255,
    185,
    0,
    40
  );

  strokeWeight(
    OUTPUT_TRACE_GLOW
  );

  drawOutputTracePath();


  // ----------------------------------------------------------
  // MAIN YELLOW LOCUS
  // ----------------------------------------------------------

  stroke(
    255,
    205,
    30,
    225
  );

  strokeWeight(
    OUTPUT_TRACE_WIDTH
  );

  drawOutputTracePath();


  // ----------------------------------------------------------
  // SAMPLE DOTS
  // ----------------------------------------------------------

  noStroke();

  for (
    int i = 0;
    i < outputTraceCount;
    i += 6
  ) {

    float alpha =
      map(
        i,
        0,
        Math.max(
          1,
          outputTraceCount - 1
        ),
        55,
        145
      );

    fill(
      255,
      220,
      50,
      alpha
    );

    ellipse(
      outputTraceX[i],
      outputTraceY[i],
      3.5f,
      3.5f
    );
  }
}


// ============================================================
// OUTPUT TRACE PATH
// ============================================================

void drawOutputTracePath() {

  boolean shapeOpen =
    false;

  for (
    int i = 0;
    i < outputTraceCount;
    i++
  ) {

    if (
      outputTraceBreak[i]
    ) {

      if (shapeOpen) {

        endShape();

        shapeOpen =
          false;
      }
    }

    if (!shapeOpen) {

      beginShape();

      shapeOpen =
        true;
    }

    vertex(
      outputTraceX[i],
      outputTraceY[i]
    );
  }

  if (shapeOpen) {

    endShape();
  }
}


// ============================================================
// YELLOW SCRIBBLE
// ============================================================

void drawYellowScribble() {

  if (
    scribbleCount <
    2
  ) {

    return;
  }


  // ----------------------------------------------------------
  // GLOW
  // ----------------------------------------------------------

  noFill();

  stroke(
    255,
    220,
    0,
    45
  );

  strokeWeight(
    SCRIBBLE_GLOW
  );

  drawScribblePath();


  // ----------------------------------------------------------
  // MAIN SCRIBBLE
  // ----------------------------------------------------------

  stroke(
    255,
    235,
    40,
    225
  );

  strokeWeight(
    SCRIBBLE_WIDTH
  );

  drawScribblePath();


  // ----------------------------------------------------------
  // SMALL POINTS
  // ----------------------------------------------------------

  noStroke();

  for (
    int i = 0;
    i < scribbleCount;
    i += 5
  ) {

    fill(
      255,
      240,
      70,
      160
    );

    ellipse(
      scribbleX[i],
      scribbleY[i],
      SCRIBBLE_POINT,
      SCRIBBLE_POINT
    );
  }
}


// ============================================================
// SCRIBBLE PATH
// ============================================================

void drawScribblePath() {

  boolean shapeOpen =
    false;

  for (
    int i = 0;
    i < scribbleCount;
    i++
  ) {

    if (
      scribbleBreak[i]
    ) {

      if (shapeOpen) {

        endShape();

        shapeOpen =
          false;
      }
    }

    if (!shapeOpen) {

      beginShape();

      shapeOpen =
        true;
    }

    vertex(
      scribbleX[i],
      scribbleY[i]
    );
  }

  if (shapeOpen) {

    endShape();
  }
}


// ============================================================
// ADD SCRIBBLE POINT
// ============================================================

void addScribblePoint(
  float x,
  float y,
  boolean forceBreak
) {

  if (
    scribbleCount >=
    MAX_SCRIBBLE
  ) {

    for (
      int i = 1;
      i < MAX_SCRIBBLE;
      i++
    ) {

      scribbleX[i - 1] =
        scribbleX[i];

      scribbleY[i - 1] =
        scribbleY[i];

      scribbleBreak[i - 1] =
        scribbleBreak[i];
    }

    scribbleCount =
      MAX_SCRIBBLE - 1;
  }


  scribbleX[
    scribbleCount
  ] =
    x;

  scribbleY[
    scribbleCount
  ] =
    y;

  scribbleBreak[
    scribbleCount
  ] =
    forceBreak;

  scribbleCount++;
}


// ============================================================
// INPUT MARKER
// ============================================================

void drawInputMarker() {

  float x =
    inputX(
      inputRe
    );

  float y =
    inputY(
      inputIm
    );


  // ----------------------------------------------------------
  // OUTER
  // ----------------------------------------------------------

  if (zeroReached) {

    drawRedPulse(
      x,
      y,
      36
    );

  } else {

    noFill();

    stroke(
      80,
      200,
      255,
      150
    );

    strokeWeight(2);

    ellipse(
      x,
      y,
      28,
      28
    );
  }


  // ----------------------------------------------------------
  // TIP
  // ----------------------------------------------------------

  stroke(255);

  strokeWeight(2);

  if (zeroReached) {

    fill(
      255,
      50,
      50
    );

  } else {

    fill(
      40,
      155,
      255
    );
  }

  ellipse(
    x,
    y,
    19,
    19
  );

  noStroke();

  fill(255);

  ellipse(
    x,
    y,
    4,
    4
  );
}


// ============================================================
// OUTPUT MARKER
// ============================================================

void drawOutputMarker() {

  float x =
    outputX(
      safeOutput(
        outputRe
      )
    );

  float y =
    outputY(
      safeOutput(
        outputIm
      )
    );


  // ----------------------------------------------------------
  // OUTER
  // ----------------------------------------------------------

  if (zeroReached) {

    drawRedPulse(
      x,
      y,
      38
    );

  } else {

    noFill();

    stroke(
      255,
      220,
      80,
      150
    );

    strokeWeight(2);

    ellipse(
      x,
      y,
      27,
      27
    );
  }


  // ----------------------------------------------------------
  // TIP
  // ----------------------------------------------------------

  stroke(255);

  strokeWeight(2);

  if (zeroReached) {

    fill(
      255,
      50,
      50
    );

  } else {

    fill(
      255,
      205,
      0
    );
  }

  ellipse(
    x,
    y,
    18,
    18
  );

  noStroke();

  fill(255);

  ellipse(
    x,
    y,
    4,
    4
  );
}


// ============================================================
// RED LASER
// ============================================================

void drawZeroLaser() {

  float x1 =
    inputX(
      inputRe
    );

  float y1 =
    inputY(
      inputIm
    );

  float x2 =
    outputX(
      safeOutput(
        outputRe
      )
    );

  float y2 =
    outputY(
      safeOutput(
        outputIm
      )
    );

  boolean blink =
    (
      (millis() / 150) % 2
    ) == 0;


  // ----------------------------------------------------------
  // GLOW
  // ----------------------------------------------------------

  noFill();

  stroke(
    255,
    0,
    0,
    35
  );

  strokeWeight(16);

  line(
    x1,
    y1,
    x2,
    y2
  );


  stroke(
    255,
    0,
    0,
    65
  );

  strokeWeight(9);

  line(
    x1,
    y1,
    x2,
    y2
  );


  // ----------------------------------------------------------
  // MAIN LASER
  // ----------------------------------------------------------

  stroke(
    255,
    20,
    20,
    230
  );

  strokeWeight(
    blink ? 4 : 2
  );

  line(
    x1,
    y1,
    x2,
    y2
  );


  // ----------------------------------------------------------
  // WHITE CORE
  // ----------------------------------------------------------

  stroke(255);

  strokeWeight(1.2f);

  line(
    x1,
    y1,
    x2,
    y2
  );
}


// ============================================================
// RED PULSE
// ============================================================

void drawRedPulse(
  float x,
  float y,
  float baseSize
) {

  float phase =
    millis() * 0.012f;

  float pulse =
    (
      (float)
      Math.sin(phase) *
      0.5f
    ) +
    0.5f;

  float size =
    baseSize +
    pulse * 18.0f;


  noFill();

  stroke(
    255,
    0,
    0,
    35
  );

  strokeWeight(10);

  ellipse(
    x,
    y,
    size + 16,
    size + 16
  );


  stroke(
    255,
    30,
    30,
    220
  );

  strokeWeight(4);

  ellipse(
    x,
    y,
    size,
    size
  );
}


// ============================================================
// INFORMATION
// ============================================================

void drawInformation() {

  float leftCenter =
    middle * 0.5f;

  float rightCenter =
    middle * 1.5f;

  float y =
    height * 0.835f;


  textAlign(
    CENTER,
    CENTER
  );


  // ----------------------------------------------------------
  // INPUT
  // ----------------------------------------------------------

  textSize(
    Math.max(
      10,
      height * 0.017f
    )
  );

  fill(255);

  String inputSign;

  if (inputIm >= 0.0) {

    inputSign =
      " + ";

  } else {

    inputSign =
      " - ";
  }

  String inputText =
    "s = " +
    format10(inputRe) +
    inputSign +
    format10(
      Math.abs(inputIm)
    ) +
    "i";

  text(
    inputText,
    leftCenter,
    y
  );


  // ----------------------------------------------------------
  // OUTPUT
  // ----------------------------------------------------------

  String outputSign;

  if (outputIm >= 0.0) {

    outputSign =
      " + ";

  } else {

    outputSign =
      " - ";
  }

  String outputText =
    "zeta(s) = " +
    format10(outputRe) +
    outputSign +
    format10(
      Math.abs(outputIm)
    ) +
    "i";

  text(
    outputText,
    rightCenter,
    y
  );


  // ----------------------------------------------------------
  // MODE STATUS
  // ----------------------------------------------------------

  textSize(
    Math.max(
      9,
      height * 0.014f
    )
  );

  if (yellowSearchMode) {

    fill(
      255,
      220,
      40
    );

    text(
      "MODE: YELLOW SEARCH - CRITICAL LINE",
      leftCenter,
      y + height * 0.04f
    );

  } else if (lockedMode) {

    fill(
      80,
      175,
      255
    );

    text(
      "MODE: LOCKED TO Re(s) = 0.5",
      leftCenter,
      y + height * 0.04f
    );

  } else {

    fill(
      80,
      240,
      210
    );

    text(
      "MODE: FREE Re(s), Im(s)",
      leftCenter,
      y + height * 0.04f
    );
  }


  // ----------------------------------------------------------
  // MAGNITUDE
  // ----------------------------------------------------------

  double magnitude =
    Math.sqrt(
      outputRe * outputRe +
      outputIm * outputIm
    );

  fill(180);

  textSize(
    Math.max(
      10,
      height * 0.015f
    )
  );

  text(
    "|zeta(s)| = " +
    format10(magnitude),
    rightCenter,
    y + height * 0.04f
  );


  // ----------------------------------------------------------
  // ZERO STATUS
  // ----------------------------------------------------------

  if (
    zeroReached &&
    activeZero >= 0
  ) {

    boolean blink =
      (
        (millis() / 170) % 2
      ) == 0;

    fill(
      blink ? 255 : 80,
      60,
      60
    );

    textSize(
      Math.max(
        12,
        height * 0.020f
      )
    );

    text(
      "RIEMANN ZERO #" +
      (activeZero + 1),
      rightCenter,
      y + height * 0.075f
    );


    fill(
      255,
      100,
      100
    );

    textSize(
      Math.max(
        10,
        height * 0.015f
      )
    );

    text(
      "t = " +
      format10(
        zeros[activeZero]
      ),
      leftCenter,
      y + height * 0.075f
    );

  } else {

    fill(
      80,
      175,
      255
    );

    textSize(
      Math.max(
        10,
        height * 0.015f
      )
    );

    text(
      "FIRST 8 KNOWN NON-TRIVIAL ZEROS",
      rightCenter,
      y + height * 0.075f
    );
  }


  // ----------------------------------------------------------
  // SEARCH STATUS
  // ----------------------------------------------------------

  if (yellowSearchMode) {

    fill(
      255,
      220,
      50
    );

    textSize(
      Math.max(
        9,
        height * 0.013f
      )
    );

    if (searchingZeroTarget) {

      text(
        "ZERO SEARCH: stroke near origin -> next known zero",
        rightCenter,
        y + height * 0.12f
      );

    } else {

      text(
        "Target = " +
        format10(searchTargetRe) +
        " + " +
        format10(searchTargetIm) +
        "i   |   searched t = " +
        format10(searchedT),
        rightCenter,
        y + height * 0.12f
      );
    }

  }


  // ----------------------------------------------------------
  // GENERAL DESCRIPTION
  // ----------------------------------------------------------

  fill(150);

  textSize(
    Math.max(
      9,
      height * 0.013f
    )
  );

  text(
    "Blue = input locus s(t)   |   Yellow = output zeta(s)   |   Yellow line = search scribble",
    middle,
    height * 0.915f
  );


  if (yellowSearchMode) {

    text(
      "Scribble on RIGHT graph. Touch near zeta = 0 to inspect the 8 zero points on the straight blue critical line.",
      middle,
      height * 0.965f
    );

  } else if (lockedMode) {

    text(
      "Touch the LEFT graph: Y controls t while Re(s) stays at 0.5",
      middle,
      height * 0.965f
    );

  } else {

    text(
      "FREE MODE: touch anywhere in the LEFT graph to control Re(s) and Im(s)",
      middle,
      height * 0.965f
    );
  }
}


// ============================================================
// BUILD CRITICAL-LINE SEARCH TABLE
// ============================================================

void buildSearchTable() {

  for (
    int i = 0;
    i < SEARCH_SAMPLES;
    i++
  ) {

    double t =
      mapValue(
        i,
        0,
        SEARCH_SAMPLES - 1,
        IMAG_MIN,
        IMAG_MAX
      );

    searchT[i] =
      t;


    double[] result =
      calculateZetaValue(
        CRITICAL_LINE,
        t
      );

    searchZRe[i] =
      result[0];

    searchZIm[i] =
      result[1];
  }
}


// ============================================================
// GENERAL ZETA CALCULATION
// ============================================================

void calculateZeta(
  double sigma,
  double t
) {

  double[] result =
    calculateZetaValue(
      sigma,
      t
    );

  outputRe =
    result[0];

  outputIm =
    result[1];
}


// ============================================================
// NUMERICAL ZETA VALUE
// ============================================================
//
// Returns:
//
//     result[0] = Re(zeta)
//     result[1] = Im(zeta)
//
// ============================================================

double[] calculateZetaValue(
  double sigma,
  double t
) {

  double[] result =
    new double[2];


  if (
    !valid(sigma) ||
    !valid(t)
  ) {

    result[0] = 0;

    result[1] = 0;

    return result;
  }


  // ----------------------------------------------------------
  // Pole check
  // ----------------------------------------------------------

  double poleDistance =
    Math.sqrt(
      (sigma - 1.0) *
      (sigma - 1.0) +
      t * t
    );

  if (
    poleDistance <
    1.0e-10
  ) {

    result[0] =
      1000000.0;

    result[1] =
      0.0;

    return result;
  }


  // ----------------------------------------------------------
  // a[n] = (n+1)^(-s)
  // ----------------------------------------------------------

  for (
    int n = 0;
    n <= LEVELS;
    n++
  ) {

    double logValue =
      logarithms[n + 1];

    double amplitude =
      Math.exp(
        -sigma *
        logValue
      );

    double angle =
      -t *
      logValue;

    workRe[n] =
      amplitude *
      Math.cos(angle);

    workIm[n] =
      amplitude *
      Math.sin(angle);
  }


  // ----------------------------------------------------------
  // Euler transformed eta
  // ----------------------------------------------------------

  double sumRe =
    0.0;

  double sumIm =
    0.0;

  double factor =
    0.5;


  for (
    int level = 0;
    level < LEVELS;
    level++
  ) {

    sumRe +=
      workRe[0] *
      factor;

    sumIm +=
      workIm[0] *
      factor;


    int count =
      LEVELS - level;


    for (
      int j = 0;
      j < count;
      j++
    ) {

      workRe[j] =
        workRe[j] -
        workRe[j + 1];

      workIm[j] =
        workIm[j] -
        workIm[j + 1];
    }


    factor *=
      0.5;
  }


  // ----------------------------------------------------------
  // denominator = 1 - 2^(1-s)
  // ----------------------------------------------------------

  double exponentRe =
    (1.0 - sigma) *
    LN2;

  double exponentIm =
    -t *
    LN2;


  double power =
    Math.exp(
      exponentRe
    );


  double pRe =
    power *
    Math.cos(
      exponentIm
    );

  double pIm =
    power *
    Math.sin(
      exponentIm
    );


  double denRe =
    1.0 - pRe;

  double denIm =
    -pIm;


  double denominator =
    denRe * denRe +
    denIm * denIm;


  if (
    !valid(denominator) ||
    denominator <
    1.0e-28
  ) {

    result[0] = 0;

    result[1] = 0;

    return result;
  }


  // ----------------------------------------------------------
  // Complex division
  // ----------------------------------------------------------

  double resultRe =
    (
      sumRe * denRe +
      sumIm * denIm
    ) /
    denominator;

  double resultIm =
    (
      sumIm * denRe -
      sumRe * denIm
    ) /
    denominator;


  if (!valid(resultRe)) {

    resultRe = 0;
  }

  if (!valid(resultIm)) {

    resultIm = 0;
  }


  result[0] =
    limit(
      resultRe,
      -1000000.0,
      1000000.0
    );

  result[1] =
    limit(
      resultIm,
      -1000000.0,
      1000000.0
    );


  return result;
}


// ============================================================
// SEARCH CRITICAL LINE FOR TARGET
// ============================================================
//
// Given a target:
//
//       zTarget = targetRe + i targetIm
//
// search:
//
//       zeta(0.5 + i*t)
//
// for the closest output.
//
// ============================================================

double searchCriticalLineForTarget(
  double targetRe,
  double targetIm
) {

  double bestT =
    0.0;

  double bestDistance =
    Double.MAX_VALUE;


  // ----------------------------------------------------------
  // COARSE SEARCH
  // ----------------------------------------------------------

  for (
    int i = 0;
    i < SEARCH_SAMPLES;
    i++
  ) {

    double dr =
      searchZRe[i] -
      targetRe;

    double di =
      searchZIm[i] -
      targetIm;

    double d =
      dr * dr +
      di * di;

    if (
      d <
      bestDistance
    ) {

      bestDistance =
        d;

      bestT =
        searchT[i];
    }
  }


  // ----------------------------------------------------------
  // LOCAL REFINEMENT
  // ----------------------------------------------------------

  double initialStep =
    IMAG_MAX /
    (
      SEARCH_SAMPLES - 1
    );


  double low =
    Math.max(
      IMAG_MIN,
      bestT -
      initialStep * 3.0
    );

  double high =
    Math.min(
      IMAG_MAX,
      bestT +
      initialStep * 3.0
    );


  for (
    int iteration = 0;
    iteration < 4;
    iteration++
  ) {

    double localBestT =
      bestT;

    double localBestD =
      Double.MAX_VALUE;


    for (
      int j = 0;
      j <= 12;
      j++
    ) {

      double t =
        mapValue(
          j,
          0,
          12,
          low,
          high
        );


      double[] result =
        calculateZetaValue(
          CRITICAL_LINE,
          t
        );


      double dr =
        result[0] -
        targetRe;

      double di =
        result[1] -
        targetIm;

      double d =
        dr * dr +
        di * di;


      if (
        d <
        localBestD
      ) {

        localBestD =
          d;

        localBestT =
          t;
      }
    }


    double width =
      high -
      low;


    double center =
      localBestT;


    low =
      Math.max(
        IMAG_MIN,
        center -
        width * 0.20
      );

    high =
      Math.min(
        IMAG_MAX,
        center +
        width * 0.20
      );


    bestT =
      localBestT;

    bestDistance =
      localBestD;
  }


  searchDistance =
    Math.sqrt(
      Math.max(
        0.0,
        bestDistance
      )
    );


  return bestT;
}


// ============================================================
// NUMERICAL ZERO REFINEMENT
// ============================================================
//
// Refines the numerical minimum around a known zero height.
//
// The result is reported, but the visual zero event is finally
// snapped to the stored 10-decimal zero value so that the
// marker, label and laser agree exactly.
//

double refineKnownZero(
  double seed
) {

  double low =
    Math.max(
      IMAG_MIN,
      seed -
      ZERO_SEARCH_WINDOW
    );

  double high =
    Math.min(
      IMAG_MAX,
      seed +
      ZERO_SEARCH_WINDOW
    );


  double bestT =
    seed;

  double bestMagnitude =
    Double.MAX_VALUE;


  // ----------------------------------------------------------
  // Multiple refinement passes
  // ----------------------------------------------------------

  for (
    int pass = 0;
    pass < 5;
    pass++
  ) {

    double localBestT =
      bestT;

    double localBestMagnitude =
      Double.MAX_VALUE;


    for (
      int i = 0;
      i <= 20;
      i++
    ) {

      double t =
        mapValue(
          i,
          0,
          20,
          low,
          high
        );


      double[] z =
        calculateZetaValue(
          CRITICAL_LINE,
          t
        );


      double mag =
        Math.sqrt(
          z[0] * z[0] +
          z[1] * z[1]
        );


      if (
        mag <
        localBestMagnitude
      ) {

        localBestMagnitude =
          mag;

        localBestT =
          t;
      }
    }


    double span =
      high -
      low;


    low =
      Math.max(
        IMAG_MIN,
        localBestT -
        span * 0.18
      );

    high =
      Math.min(
        IMAG_MAX,
        localBestT +
        span * 0.18
      );


    bestT =
      localBestT;

    bestMagnitude =
      localBestMagnitude;
  }


  // Keep compiler from treating numerical result as unused.
  if (!valid(bestMagnitude)) {

    return seed;
  }


  return bestT;
}


// ============================================================
// ZERO STATE
// ============================================================

void updateZeroState() {

  int found =
    findKnownZero();

  activeZero =
    found;

  boolean newZero =
    found >= 0 &&
    found != lastZero;

  zeroReached =
    found >= 0;


  if (newZero) {

    zeroHitTime =
      millis();
  }


  if (found < 0) {

    lastZero = -1;

  } else {

    lastZero =
      found;
  }
}


// ============================================================
// FIND KNOWN ZERO
// ============================================================

int findKnownZero() {

  if (
    Math.abs(
      inputRe -
      CRITICAL_LINE
    ) >
    LINE_TOL
  ) {

    return -1;
  }


  for (
    int i = 0;
    i < zeros.length;
    i++
  ) {

    if (
      Math.abs(
        inputIm -
        zeros[i]
      ) <
      ZERO_EXACT_TOL
    ) {

      return i;
    }
  }


  return -1;
}


// ============================================================
// NEAREST ZERO
// ============================================================

int nearestZero(
  double t
) {

  int nearest =
    -1;

  double best =
    Double.MAX_VALUE;


  for (
    int i = 0;
    i < zeros.length;
    i++
  ) {

    double d =
      Math.abs(
        t -
        zeros[i]
      );


    if (
      d <
      best
    ) {

      best =
        d;

      nearest =
        i;
    }
  }


  return nearest;
}


// ============================================================
// TRACE STORAGE
// ============================================================

void addTracePoint(
  double re,
  double im,
  double outRe,
  double outIm,
  boolean forceBreak
) {

  if (
    !valid(re) ||
    !valid(im) ||
    !valid(outRe) ||
    !valid(outIm)
  ) {

    return;
  }


  float px =
    outputX(
      safeOutput(
        outRe
      )
    );

  float py =
    outputY(
      safeOutput(
        outIm
      )
    );


  if (
    !validFloat(px) ||
    !validFloat(py)
  ) {

    return;
  }


  boolean breakBefore =
    forceBreak;


  // ----------------------------------------------------------
  // Automatic break for large jumps
  // ----------------------------------------------------------

  if (
    inputTraceCount > 0
  ) {

    double previousRe =
      inputTraceRe[
        inputTraceCount - 1
      ];

    double previousIm =
      inputTraceIm[
        inputTraceCount - 1
      ];


    if (
      Math.abs(
        re -
        previousRe
      ) > 0.18
    ) {

      breakBefore =
        true;
    }


    if (
      Math.abs(
        im -
        previousIm
      ) > 3.0
    ) {

      breakBefore =
        true;
    }
  }


  // ----------------------------------------------------------
  // Shift if full
  // ----------------------------------------------------------

  if (
    inputTraceCount >=
    MAX_TRACE
  ) {

    for (
      int i = 1;
      i < MAX_TRACE;
      i++
    ) {

      inputTraceRe[i - 1] =
        inputTraceRe[i];

      inputTraceIm[i - 1] =
        inputTraceIm[i];

      inputTraceBreak[i - 1] =
        inputTraceBreak[i];

      outputTraceX[i - 1] =
        outputTraceX[i];

      outputTraceY[i - 1] =
        outputTraceY[i];

      outputTraceBreak[i - 1] =
        outputTraceBreak[i];
    }


    inputTraceCount =
      MAX_TRACE - 1;
  }


  // ----------------------------------------------------------
  // Store input
  // ----------------------------------------------------------

  inputTraceRe[
    inputTraceCount
  ] =
    re;

  inputTraceIm[
    inputTraceCount
  ] =
    im;

  inputTraceBreak[
    inputTraceCount
  ] =
    breakBefore;


  // ----------------------------------------------------------
  // Store output
  // ----------------------------------------------------------

  outputTraceX[
    inputTraceCount
  ] =
    px;

  outputTraceY[
    inputTraceCount
  ] =
    py;

  outputTraceBreak[
    inputTraceCount
  ] =
    breakBefore;


  inputTraceCount++;

  outputTraceCount =
    inputTraceCount;
}


// ============================================================
// INPUT X
// ============================================================

float inputX(
  double value
) {

  return (float)
    mapValue(
      value,
      REAL_MIN,
      REAL_MAX,
      25,
      middle - 25
    );
}


// ============================================================
// INPUT Y
// ============================================================

float inputY(
  double value
) {

  return (float)
    mapValue(
      value,
      IMAG_MIN,
      IMAG_MAX,
      graphBottom,
      graphTop
    );
}


// ============================================================
// OUTPUT X
// ============================================================

float outputX(
  double value
) {

  double v =
    limit(
      value,
      -OUTPUT_LIMIT,
      OUTPUT_LIMIT
    );

  return (float)
    mapValue(
      v,
      -OUTPUT_LIMIT,
      OUTPUT_LIMIT,
      middle + 25,
      width - 25
    );
}


// ============================================================
// OUTPUT Y
// ============================================================

float outputY(
  double value
) {

  double v =
    limit(
      value,
      -OUTPUT_LIMIT,
      OUTPUT_LIMIT
    );

  return (float)
    mapValue(
      v,
      -OUTPUT_LIMIT,
      OUTPUT_LIMIT,
      graphBottom,
      graphTop
    );
}


// ============================================================
// SAFE OUTPUT
// ============================================================

double safeOutput(
  double value
) {

  if (!valid(value)) {

    return 0;
  }

  return limit(
    value,
    -OUTPUT_LIMIT,
    OUTPUT_LIMIT
  );
}


// ============================================================
// MAP
// ============================================================

double mapValue(
  double value,
  double inMin,
  double inMax,
  double outMin,
  double outMax
) {

  if (
    inMax ==
    inMin
  ) {

    return outMin;
  }


  return
    outMin +
    (
      value -
      inMin
    ) *
    (
      outMax -
      outMin
    ) /
    (
      inMax -
      inMin
    );
}


// ============================================================
// LIMIT
// ============================================================

double limit(
  double value,
  double minimum,
  double maximum
) {

  if (
    value <
    minimum
  ) {

    return minimum;
  }


  if (
    value >
    maximum
  ) {

    return maximum;
  }


  return value;
}


// ============================================================
// VALID DOUBLE
// ============================================================

boolean valid(
  double value
) {

  return
    !Double.isNaN(value) &&
    !Double.isInfinite(value);
}


// ============================================================
// VALID FLOAT
// ============================================================

boolean validFloat(
  float value
) {

  return
    !Float.isNaN(value) &&
    !Float.isInfinite(value);
}


// ============================================================
// 10 DECIMAL FORMAT
// ============================================================

String format10(
  double value
) {

  if (!valid(value)) {

    return "undefined";
  }


  if (
    Math.abs(value) <
    0.00000000005
  ) {

    value =
      0.0;
  }


  return String.format(
    Locale.US,
    "%.10f",
    value
  );
}


// ============================================================
// END OF COMPLETE SKETCH
// ============================================================
