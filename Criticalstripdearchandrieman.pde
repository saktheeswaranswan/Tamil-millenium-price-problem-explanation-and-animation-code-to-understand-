// ============================================================
// RIEMANN ZETA TOUCH VISUALIZER - EXPANDED DOMAIN & SLIDERS
// COMPLETE APDE ANDROID / PROCESSING JAVA MODE
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

final double REAL_MIN = -10.0;
final double REAL_MAX = 2.0;
final double IMAG_MIN = 0.0;
final double IMAG_MAX = 50.0;

// ============================================================
// OUTPUT DISPLAY DOMAIN
// ============================================================

final double OUTPUT_LIMIT = 4.0;

// ============================================================
// CONSTANTS
// ============================================================

final double LN2 = 0.693147180559945309417232121458176568;
final double CRITICAL_LINE = 0.5;

// ============================================================
// ZERO SNAP SETTINGS
// ============================================================

final double ZERO_SNAP_TOL = 0.35;
final double LINE_TOL = 1.0e-12;
final double ZERO_EXACT_TOL = 1.0e-10;

// ============================================================
// TRACE SETTINGS
// ============================================================

final float INPUT_TRACE_GLOW = 9.0f;
final float INPUT_TRACE_WIDTH = 5.0f;
final float OUTPUT_TRACE_GLOW = 8.0f;
final float OUTPUT_TRACE_WIDTH = 3.5f;
final float TRACE_POINT_SIZE = 4.0f;

// ============================================================
// KNOWN ZEROS (NON-TRIVIAL & TRIVIAL)
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

double[] trivialZeros = {
  -2.0, -4.0, -6.0, -8.0, -10.0
};

// ============================================================
// STATE VARIABLES
// ============================================================

boolean lockedMode = true;
boolean yellowSearchMode = false;

double inputRe = CRITICAL_LINE;
double inputIm = zeros[0];

double outputRe = 0.0;
double outputIm = 0.0;

// Slider states for custom vertical lines and density steps
float customReSlider = 0.5f; // maps from REAL_MIN to REAL_MAX
float densitySlider = 5.0f;  // number of multi-lines (1 to 15)

double[] workRe = new double[LEVELS + 1];
double[] workIm = new double[LEVELS + 1];
double[] logarithms = new double[LEVELS + 2];

double[] inputTraceRe = new double[MAX_TRACE];
double[] inputTraceIm = new double[MAX_TRACE];
boolean[] inputTraceBreak = new boolean[MAX_TRACE];
int inputTraceCount = 0;

float[] outputTraceX = new float[MAX_TRACE];
float[] outputTraceY = new float[MAX_TRACE];
boolean[] outputTraceBreak = new boolean[MAX_TRACE];
int outputTraceCount = 0;

boolean touching = false;
boolean newTouchStroke = false;
float previousTouchX = -10000;
float previousTouchY = -10000;
long previousCalculation = 0;

int activeButton = 0; // 0: None, 1: Mode Toggle, 2: Find Critical Line

float middle;
float graphTop;
float graphBottom;

int activeZero = -1;
boolean zeroReached = false;

int activeTrivialZero = -1;
boolean trivialZeroReached = false;

int lastZero = -1;


// ============================================================
// SETUP
// ============================================================

void setup() {
  orientation(LANDSCAPE);
  fullScreen();
  frameRate(30);

  updateGeometry();

  for (int i = 1; i <= LEVELS + 1; i++) {
    logarithms[i] = Math.log(i);
  }

  calculateZeta(inputRe, inputIm);
  updateZeroState();
  addTracePoint(inputRe, inputIm, outputRe, outputIm, true);
}


// ============================================================
// GEOMETRY
// ============================================================

void updateGeometry() {
  middle = width * 0.5f;
  graphTop = height * 0.23f; 
  graphBottom = height * 0.77f;
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

  if (zeroReached || trivialZeroReached) {
    drawZeroLaser();
  }

  drawInputMarker();
  drawOutputMarker();
  
  drawInformation();
  drawUIControls();
}


// ============================================================
// TITLES & UI TEXT
// ============================================================

void drawTitles() {
  textAlign(CENTER, CENTER);
  textSize(Math.max(15, height * 0.030f));
  fill(255);
  text("RIEMANN ZETA FUNCTION — EXPANDED DOMAIN", middle, height * 0.035f);

  textSize(Math.max(13, height * 0.024f));
  fill(65, 165, 255);
  text("INPUT COMPLEX PLANE s = Re + Im·i", middle * 0.5f, height * 0.08f);

  fill(255, 205, 0);
  text("OUTPUT COMPLEX PLANE zeta(s)", middle * 1.5f, height * 0.08f);
}


// ============================================================
// TOUCH & SLIDER HANDLING
// ============================================================

void handleTouch() {
  if (!mousePressed) {
    if (activeButton == 1 && isInsideInputToggle(mouseX, mouseY)) {
      toggleInputMode();
    } else if (activeButton == 2 && isInsideFindCriticalButton(mouseX, mouseY)) {
      snapToCriticalLine();
    }
    activeButton = 0;
    if (touching) newTouchStroke = true;
    touching = false;
    previousTouchX = -10000;
    previousTouchY = -10000;
    return;
  }

  if (activeButton == 0 && !touching) {
    if (isInsideInputToggle(mouseX, mouseY)) { activeButton = 1; return; }
    if (isInsideFindCriticalButton(mouseX, mouseY)) { activeButton = 2; return; }
  }
  if (activeButton != 0) return;

  if (mouseY >= height * 0.12f && mouseY <= height * 0.21f) {
    if (mouseX < middle) {
      if (mouseX >= 35 && mouseX <= middle - 35) {
        customReSlider = (float) mapValue(mouseX, 35, middle - 35, REAL_MIN, REAL_MAX);
        customReSlider = (float) limit(customReSlider, REAL_MIN, REAL_MAX);
        inputRe = customReSlider;
        calculateZeta(inputRe, inputIm);
        updateZeroState();
        addTracePoint(inputRe, inputIm, outputRe, outputIm, true);
      }
    } else {
      if (mouseX >= middle + 35 && mouseX <= width - 35) {
        densitySlider = (float) mapValue(mouseX, middle + 35, width - 35, 1.0f, 15.0f);
        densitySlider = (float) limit(densitySlider, 1.0f, 15.0f);
      }
    }
    return;
  }

  handleNormalInputTouch();
}

void handleNormalInputTouch() {
  if (mouseX < 0 || mouseX >= middle || mouseY < graphTop || mouseY > graphBottom) return;

  if (!touching) {
    touching = true;
    previousTouchX = -10000;
    previousTouchY = -10000;
    newTouchStroke = true;
  }

  if (previousTouchX > -9000 && previousTouchY > -9000) {
    if (Math.abs(mouseX - previousTouchX) < 1.0f && Math.abs(mouseY - previousTouchY) < 1.0f) return;
  }

  long now = millis();
  if (now - previousCalculation < UPDATE_MS) return;

  double re;
  if (lockedMode) {
    re = CRITICAL_LINE;
  } else {
    re = mapValue(mouseX, 25, middle - 25, REAL_MIN, REAL_MAX);
    re = limit(re, REAL_MIN, REAL_MAX);
  }

  double im = mapValue(mouseY, graphBottom, graphTop, IMAG_MIN, IMAG_MAX);
  im = limit(im, IMAG_MIN, IMAG_MAX);

  if (lockedMode) {
    int nearest = nearestZero(im);
    if (nearest >= 0 && Math.abs(im - zeros[nearest]) < ZERO_SNAP_TOL) {
      im = zeros[nearest];
    }
  } else {
    int nearestTrivial = -1;
    for (int i = 0; i < trivialZeros.length; i++) {
      if (Math.abs(re - trivialZeros[i]) < ZERO_SNAP_TOL && Math.abs(im - 0.0) < ZERO_SNAP_TOL) {
        nearestTrivial = i;
        break;
      }
    }
    if (nearestTrivial >= 0) {
      re = trivialZeros[nearestTrivial];
      im = 0.0;
    }
  }

  inputRe = re;
  inputIm = im;
  customReSlider = (float) re;
  
  calculateZeta(inputRe, inputIm);
  updateZeroState();
  
  addTracePoint(inputRe, inputIm, outputRe, outputIm, newTouchStroke);
  newTouchStroke = false;

  previousTouchX = mouseX;
  previousTouchY = mouseY;
  previousCalculation = now;
}


// ============================================================
// UI CONTROLS & SLIDER RENDERING
// ============================================================

void drawUIControls() {
  float bx1 = 35, by1 = height * 0.90f, bw1 = Math.min(200, (int)(middle - 65)), bh1 = 34;
  noStroke();
  fill(0, 0, 0, 170);
  rect(bx1 + 2, by1 + 2, bw1, bh1, 6);
  fill(lockedMode ? 15 : 15, lockedMode ? 80 : 125, lockedMode ? 145 : 120, 235);
  rect(bx1, by1, bw1, bh1, 6);
  noFill();
  stroke(lockedMode ? 60 : 70, lockedMode ? 190 : 240, 255);
  strokeWeight(2);
  rect(bx1, by1, bw1, bh1, 6);

  textAlign(CENTER, CENTER);
  textSize(Math.max(10, height * 0.015f));
  fill(255);
  text(lockedMode ? "FREE INPUT MODE" : "LOCK TO Re(s) = 0.5", bx1 + bw1 * 0.5f, by1 + bh1 * 0.5f);

  float bx2 = middle + 35, by2 = height * 0.12f, bw2 = Math.min(210, (int)(width - middle - 65)), bh2 = 32;
  noStroke();
  fill(0, 0, 0, 170);
  rect(bx2 + 2, by2 + 2, bw2, bh2, 6);
  fill(30, 110, 180, 235);
  rect(bx2, by2, bw2, bh2, 6);
  noFill();
  stroke(80, 190, 255);
  strokeWeight(2);
  rect(bx2, by2, bw2, bh2, 6);

  fill(255);
  textSize(Math.max(10, height * 0.015f));
  text("FIND CRITICAL LINE", bx2 + bw2 * 0.5f, by2 + bh2 * 0.5f);

  drawVerticalSliders();
}

void drawVerticalSliders() {
  float sliderY = height * 0.165f;
  
  // Left Slider: Re-Line Slider
  float lStart = 35, lEnd = middle - 35;
  stroke(80, 150, 220);
  strokeWeight(4);
  line(lStart, sliderY, lEnd, sliderY);

  float handleX = (float) mapValue(customReSlider, REAL_MIN, REAL_MAX, lStart, lEnd);
  noStroke();
  fill(255, 220, 50);
  ellipse(handleX, sliderY, 14, 14);

  textSize(Math.max(9, height * 0.013f));
  fill(200);
  textAlign(LEFT, TOP);
  text("Re-Slider: " + format10(customReSlider), lStart, sliderY + 8);

  // Right Slider: Density / Multi-Line Step Slider
  float rStart = middle + 35, rEnd = width - 35;
  stroke(220, 160, 50);
  strokeWeight(4);
  line(rStart, sliderY, rEnd, sliderY);

  float handleX2 = (float) mapValue(densitySlider, 1.0f, 15.0f, rStart, rEnd);
  noStroke();
  fill(255, 220, 50);
  ellipse(handleX2, sliderY, 14, 14);

  textAlign(LEFT, TOP);
  text("Multi-Line Density: " + (int)densitySlider, rStart, sliderY + 8);
}

boolean isInsideInputToggle(float px, float py) {
  float bx = 35, by = height * 0.90f, bw = Math.min(200, middle - 65), bh = 34;
  return px >= bx && px <= bx + bw && py >= by && py <= by + bh;
}

boolean isInsideFindCriticalButton(float px, float py) {
  float bx = middle + 35, by = height * 0.12f, bw = Math.min(210, width - middle - 65), bh = 32;
  return px >= bx && px <= bx + bw && py >= by && py <= by + bh;
}

void toggleInputMode() {
  lockedMode = !lockedMode;
  if (lockedMode) {
    inputRe = CRITICAL_LINE;
    customReSlider = (float) CRITICAL_LINE;
  }
  calculateZeta(inputRe, inputIm);
  updateZeroState();
  newTouchStroke = true;
}

void snapToCriticalLine() {
  lockedMode = true;
  inputRe = CRITICAL_LINE;
  customReSlider = (float) CRITICAL_LINE;
  inputIm = zeros[0];
  calculateZeta(inputRe, inputIm);
  updateZeroState();
  clearAllTraces();
  addTracePoint(inputRe, inputIm, outputRe, outputIm, true);
}

void clearAllTraces() {
  inputTraceCount = 0;
  outputTraceCount = 0;
}


// ============================================================
// LEFT GRAPH (INPUT PLANE)
// ============================================================

void drawLeftGraph() {
  float left = 25, right = middle - 25;
  stroke(30);
  strokeWeight(1);
  
  for (int i = 0; i <= 6; i++) {
    float x = left + (right - left) * i / 6.0f;
    line(x, graphTop, x, graphBottom);
  }
  for (int i = 0; i <= 10; i++) {
    float y = graphTop + (graphBottom - graphTop) * i / 10.0f;
    line(left, y, right, y);
  }

  float originX = inputX(0);
  stroke(150, 160, 180);
  strokeWeight(2);
  line(originX, graphTop, originX, graphBottom);
  line(left, graphBottom, right, graphBottom);

  int count = (int) densitySlider;
  for (int k = 0; k < count; k++) {
    double rVal = mapValue(k, 0, Math.max(1, count - 1), REAL_MIN, REAL_MAX);
    float lineX = inputX(rVal);
    stroke(40, 120, 255, 40);
    strokeWeight(1.5f);
    line(lineX, graphTop, lineX, graphBottom);
  }

  float customX = inputX(customReSlider);
  stroke(255, 220, 50, 180);
  strokeWeight(3);
  line(customX, graphTop, customX, graphBottom);

  float criticalX = inputX(CRITICAL_LINE);
  stroke(35, 155, 255, 220);
  strokeWeight(3.5f);
  line(criticalX, graphTop, criticalX, graphBottom);

  drawInputLocus();
  drawZeroPoints(criticalX);
  drawTrivialZeroPoints();

  textAlign(CENTER, CENTER);
  textSize(Math.max(9, height * 0.014f));
  fill(100, 190, 255);
  text("0.5", criticalX, graphBottom + 14);

  fill(160);
  text("-10.0", inputX(-10.0), graphBottom + 14);
  text("-5.0", inputX(-5.0), graphBottom + 14);
  text("0.0", originX, graphBottom + 14);
}

void drawInputLocus() {
  if (inputTraceCount < 2) return;
  noFill();
  stroke(0, 120, 255, 45);
  strokeWeight(INPUT_TRACE_GLOW);
  drawInputTracePath();

  stroke(55, 190, 255, 225);
  strokeWeight(INPUT_TRACE_WIDTH);
  drawInputTracePath();
}

void drawInputTracePath() {
  boolean shapeOpen = false;
  for (int i = 0; i < inputTraceCount; i++) {
    if (inputTraceBreak[i]) {
      if (shapeOpen) { endShape(); shapeOpen = false; }
    }
    if (!shapeOpen) { beginShape(); shapeOpen = true; }
    vertex(inputX(inputTraceRe[i]), inputY(inputTraceIm[i]));
  }
  if (shapeOpen) endShape();
}


// ============================================================
// ZERO POINTS
// ============================================================

void drawZeroPoints(float criticalX) {
  textSize(Math.max(8, height * 0.013f));
  for (int i = 0; i < zeros.length; i++) {
    float y = inputY(zeros[i]);
    if (y < graphTop || y > graphBottom) continue;

    boolean selected = (activeZero == i);
    noStroke();
    fill(selected ? 255 : 30, selected ? 220 : 155, selected ? 100 : 255);
    ellipse(criticalX, y, selected ? 13 : 8, selected ? 13 : 8);

    textAlign(RIGHT, CENTER);
    fill(selected ? 255 : 120, 220, 255);
    text("#" + (i + 1), criticalX - 10, y);
  }
}

void drawTrivialZeroPoints() {
  float y = inputY(0.0);
  for (int i = 0; i < trivialZeros.length; i++) {
    float x = inputX(trivialZeros[i]);
    if (x < 25 || x > middle - 25) continue;

    noStroke();
    fill(50, 220, 100);
    ellipse(x, y, 9, 9);

    textAlign(CENTER, BOTTOM);
    fill(100, 255, 100);
    text("" + (int)trivialZeros[i], x, y - 8);
  }
}


// ============================================================
// RIGHT GRAPH (OUTPUT PLANE)
// ============================================================

void drawRightGraph() {
  float left = middle + 25, right = width - 25;
  float originX = outputX(0), originY = outputY(0);

  stroke(30);
  strokeWeight(1);
  for (int i = 0; i <= 12; i++) {
    float x = left + (right - left) * i / 12.0f;
    line(x, graphTop, x, graphBottom);
    float y = graphTop + (graphBottom - graphTop) * i / 12.0f;
    line(left, y, right, y);
  }

  stroke(150, 160, 180);
  strokeWeight(2);
  line(originX, graphTop, originX, graphBottom);
  line(left, originY, right, originY);

  noFill();
  stroke(230);
  strokeWeight(2);
  ellipse(originX, originY, 20, 20);
  noStroke();
  fill(255);
  ellipse(originX, originY, 4, 4);

  drawOutputLocus();

  textAlign(CENTER, CENTER);
  textSize(Math.max(9, height * 0.013f));
  fill(165);
  text("0", originX + 12, originY + 14);
}

void drawOutputLocus() {
  if (outputTraceCount < 2) return;
  noFill();
  stroke(255, 185, 0, 40);
  strokeWeight(OUTPUT_TRACE_GLOW);
  drawOutputTracePath();

  stroke(255, 205, 30, 225);
  strokeWeight(OUTPUT_TRACE_WIDTH);
  drawOutputTracePath();
}

void drawOutputTracePath() {
  boolean shapeOpen = false;
  for (int i = 0; i < outputTraceCount; i++) {
    if (outputTraceBreak[i]) {
      if (shapeOpen) { endShape(); shapeOpen = false; }
    }
    if (!shapeOpen) { beginShape(); shapeOpen = true; }
    vertex(outputTraceX[i], outputTraceY[i]);
  }
  if (shapeOpen) endShape();
}


// ============================================================
// MARKERS & LASER
// ============================================================

void drawInputMarker() {
  float x = inputX(inputRe);
  float y = inputY(inputIm);

  noStroke();
  fill(40, 155, 255);
  ellipse(x, y, 17, 17);
  fill(255);
  ellipse(x, y, 4, 4);
}

void drawOutputMarker() {
  float x = outputX(safeOutput(outputRe));
  float y = outputY(safeOutput(outputIm));

  noStroke();
  fill(255, 205, 0);
  ellipse(x, y, 17, 17);
  fill(255);
  ellipse(x, y, 4, 4);
}

void drawZeroLaser() {
  float x1 = inputX(inputRe), y1 = inputY(inputIm);
  float x2 = outputX(safeOutput(outputRe)), y2 = outputY(safeOutput(outputIm));

  stroke(trivialZeroReached ? color(0, 255, 0, 180) : color(255, 50, 50, 180));
  strokeWeight(3);
  line(x1, y1, x2, y2);
}


// ============================================================
// INFORMATION TEXT
// ============================================================

void drawInformation() {
  float leftCenter = middle * 0.5f, rightCenter = middle * 1.5f, y = height * 0.82f;
  textAlign(CENTER, CENTER);

  textSize(Math.max(10, height * 0.016f));
  fill(255);
  String inputSign = (inputIm >= 0.0) ? " + " : " - ";
  text("s = " + format10(inputRe) + inputSign + format10(Math.abs(inputIm)) + "i", leftCenter, y);

  String outputSign = (outputIm >= 0.0) ? " + " : " - ";
  text("zeta(s) = " + format10(outputRe) + outputSign + format10(Math.abs(outputIm)) + "i", rightCenter, y);

  fill(180);
  textSize(Math.max(9, height * 0.014f));
  if (trivialZeroReached) {
    fill(50, 255, 50);
    text("TRIVIAL ZERO REACHED!", rightCenter, y + height * 0.045f);
  } else if (zeroReached) {
    fill(100, 200, 255);
    text("NON-TRIVIAL RIEMANN ZERO REACHED!", rightCenter, y + height * 0.045f);
  } else {
    text("|zeta(s)| = " + format10(Math.sqrt(outputRe * outputRe + outputIm * outputIm)), rightCenter, y + height * 0.045f);
  }
}


// ============================================================
// MATH & UTILS
// ============================================================

void calculateZeta(double sigma, double t) {
  double[] result = calculateZetaValue(sigma, t);
  outputRe = result[0];
  outputIm = result[1];
}

double[] calculateZetaValue(double sigma, double t) {
  double[] result = new double[2];
  if (!valid(sigma) || !valid(t)) { result[0] = 0; result[1] = 0; return result; }

  double poleDistance = Math.sqrt((sigma - 1.0) * (sigma - 1.0) + t * t);
  if (poleDistance < 1.0e-10) { result[0] = 1000000.0; result[1] = 0.0; return result; }

  for (int n = 0; n <= LEVELS; n++) {
    double logValue = logarithms[n + 1];
    double amplitude = Math.exp(-sigma * logValue);
    double angle = -t * logValue;
    workRe[n] = amplitude * Math.cos(angle);
    workIm[n] = amplitude * Math.sin(angle);
  }

  double sumRe = 0.0, sumIm = 0.0, factor = 0.5;
  for (int level = 0; level < LEVELS; level++) {
    sumRe += workRe[0] * factor;
    sumIm += workIm[0] * factor;
    int countL = LEVELS - level;
    for (int j = 0; j < countL; j++) {
      workRe[j] = workRe[j] - workRe[j + 1];
      workIm[j] = workIm[j] - workIm[j + 1];
    }
    factor *= 0.5;
  }

  double exponentRe = (1.0 - sigma) * LN2;
  double exponentIm = -t * LN2;
  double power = Math.exp(exponentRe);
  double pRe = power * Math.cos(exponentIm);
  double pIm = power * Math.sin(exponentIm);

  double denRe = 1.0 - pRe;
  double denIm = -pIm;
  double denominator = denRe * denRe + denIm * denIm;

  if (!valid(denominator) || denominator < 1.0e-28) { result[0] = 0; result[1] = 0; return result; }

  result[0] = limit((sumRe * denRe + sumIm * denIm) / denominator, -1000000.0, 1000000.0);
  result[1] = limit((sumIm * denRe - sumRe * denIm) / denominator, -1000000.0, 1000000.0);
  return result;
}

void updateZeroState() {
  int found = findKnownZero();
  activeZero = found;
  zeroReached = found >= 0;

  int foundTrivial = findKnownTrivialZero();
  activeTrivialZero = foundTrivial;
  trivialZeroReached = foundTrivial >= 0;

  if (found < 0 && foundTrivial < 0) lastZero = -1; 
  else lastZero = Math.max(found, foundTrivial);
}

int findKnownZero() {
  if (Math.abs(inputRe - CRITICAL_LINE) > LINE_TOL) return -1;
  for (int i = 0; i < zeros.length; i++) {
    if (Math.abs(inputIm - zeros[i]) < ZERO_EXACT_TOL) return i;
  }
  return -1;
}

int findKnownTrivialZero() {
  for (int i = 0; i < trivialZeros.length; i++) {
    if (Math.abs(inputRe - trivialZeros[i]) < ZERO_EXACT_TOL && Math.abs(inputIm - 0.0) < ZERO_EXACT_TOL) {
      return i;
    }
  }
  return -1;
}

int nearestZero(double t) {
  int nearest = -1;
  double best = Double.MAX_VALUE;
  for (int i = 0; i < zeros.length; i++) {
    double d = Math.abs(t - zeros[i]);
    if (d < best) { best = d; nearest = i; }
  }
  return nearest;
}

void addTracePoint(double re, double im, double outRe, double outIm, boolean forceBreak) {
  if (!valid(re) || !valid(im) || !valid(outRe) || !valid(outIm)) return;

  float px = outputX(safeOutput(outRe));
  float py = outputY(safeOutput(outIm));
  if (!validFloat(px) || !validFloat(py)) return;

  boolean breakBefore = forceBreak;
  if (inputTraceCount > 0) {
    if (Math.abs(re - inputTraceRe[inputTraceCount - 1]) > 0.18) breakBefore = true;
  }

  if (inputTraceCount >= MAX_TRACE) {
    for (int i = 1; i < MAX_TRACE; i++) {
      inputTraceRe[i - 1] = inputTraceRe[i];
      inputTraceIm[i - 1] = inputTraceIm[i];
      inputTraceBreak[i - 1] = inputTraceBreak[i];
      outputTraceX[i - 1] = outputTraceX[i];
      outputTraceY[i - 1] = outputTraceY[i];
      outputTraceBreak[i - 1] = outputTraceBreak[i];
    }
    inputTraceCount = MAX_TRACE - 1;
  }

  inputTraceRe[inputTraceCount] = re;
  inputTraceIm[inputTraceCount] = im;
  inputTraceBreak[inputTraceCount] = breakBefore;
  outputTraceX[inputTraceCount] = px;
  outputTraceY[inputTraceCount] = py;
  outputTraceBreak[inputTraceCount] = breakBefore;

  inputTraceCount++;
  outputTraceCount = inputTraceCount;
}

float inputX(double value) { return (float) mapValue(value, REAL_MIN, REAL_MAX, 25, middle - 25); }
float inputY(double value) { return (float) mapValue(value, IMAG_MIN, IMAG_MAX, graphBottom, graphTop); }
float outputX(double value) { return (float) mapValue(limit(value, -OUTPUT_LIMIT, OUTPUT_LIMIT), -OUTPUT_LIMIT, OUTPUT_LIMIT, middle + 25, width - 25); }
float outputY(double value) { return (float) mapValue(limit(value, -OUTPUT_LIMIT, OUTPUT_LIMIT), -OUTPUT_LIMIT, OUTPUT_LIMIT, graphBottom, graphTop); }

double safeOutput(double value) { return !valid(value) ? 0 : limit(value, -OUTPUT_LIMIT, OUTPUT_LIMIT); }
double mapValue(double value, double inMin, double inMax, double outMin, double outMax) {
  if (inMax == inMin) return outMin;
  return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin);
}
double limit(double value, double minimum, double maximum) { return value < minimum ? minimum : (value > maximum ? maximum : value); }
boolean valid(double value) { return !Double.isNaN(value) && !Double.isInfinite(value); }
boolean validFloat(float value) { return !Float.isNaN(value) && !Float.isInfinite(value); }
String format10(double value) {
  if (!valid(value)) return "undefined";
  if (Math.abs(value) < 0.00000000005) value = 0.0;
  return String.format(Locale.US, "%.10f", value);
}
