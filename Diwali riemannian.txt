// ============================================================
// RIEMANN ZETA TOUCH VISUALIZER - CHAOS & OEIS SEEKER
// COMPLETE APDE ANDROID / PROCESSING JAVA MODE
// ============================================================

import java.util.Locale;
import java.util.ArrayList;

// ============================================================
// SETTINGS & DOMAINS
// ============================================================

final int LEVELS = 120; // Increased for better precision at higher t
final int MAX_TRACE = 600;
final int UPDATE_MS = 30;

// Dynamic domains for auto-zoom
double targetRealMin = -12.0;
double targetImagMax = 50.0;
float currentRealMin = -12.0f;
float currentImagMax = 50.0f;

final double REAL_MAX = 2.0;
final double IMAG_MIN = 0.0;
final double OUTPUT_LIMIT = 4.0;

final double LN2 = 0.693147180559945309417232121458176568;
final double CRITICAL_LINE = 0.5;

// ============================================================
// STATE VARIABLES
// ============================================================

boolean lockedMode = true;
boolean autoPlay = false;
boolean showConformal = false;

// Auto Pilot State Machine
int pilotState = 0; 
// 0: Horizontal Left, 1: Horizontal Right, 2: Vertical Up, 3: Vertical Down

double autoT = 0.0;
double autoSigma = 0.0;
double prevMag = 100.0;
boolean justFiredCrit = false;
boolean justFiredTriv = false;
double lastZeroT = 0.0;
double currentGap = 0.0;
double infinitesimalResidue = 0.0;

double inputRe = CRITICAL_LINE;
double inputIm = 0.0;
double outputRe = 0.0;
double outputIm = 0.0;

double[] workRe = new double[LEVELS + 1];
double[] workIm = new double[LEVELS + 1];
double[] logarithms = new double[LEVELS + 2];

double[] inputTraceRe = new double[MAX_TRACE];
double[] inputTraceIm = new double[MAX_TRACE];
int inputTraceCount = 0;

float[] outputTraceX = new float[MAX_TRACE];
float[] outputTraceY = new float[MAX_TRACE];
int outputTraceCount = 0;

boolean touching = false;
boolean newTouchStroke = false;
float middle, graphTop, graphBottom;

int[] primes = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61};

// ============================================================
// PARTICLE SYSTEM
// ============================================================

class Particle {
  String emoji;
  float x, y, vx, vy, life;
  Particle(String e, float x, float y) {
    this.emoji = e;
    this.x = x; this.y = y;
    float angle = random(TWO_PI);
    float speed = random(2, 7);
    this.vx = cos(angle) * speed;
    this.vy = sin(angle) * speed;
    this.life = 255.0f;
  }
  void update() {
    x += vx; y += vy;
    vy += 0.2; // gravity
    life -= 4.0;
  }
  void display() {
    fill(255, life);
    textSize(28);
    textAlign(CENTER, CENTER);
    text(emoji, x, y);
  }
}
ArrayList<Particle> particles = new ArrayList<Particle>();

// ============================================================
// SETUP & GEOMETRY
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
}

void updateGeometry() {
  middle = width * 0.5f;
  graphTop = height * 0.23f; 
  graphBottom = height * 0.77f;
}

// ============================================================
// MAIN DRAW LOOP
// ============================================================

void draw() {
  background(6);
  updateGeometry();
  
  // Smooth Camera Zooming interpolation
  currentRealMin = lerp(currentRealMin, (float)targetRealMin, 0.05f);
  currentImagMax = lerp(currentImagMax, (float)targetImagMax, 0.05f);
  
  if (autoPlay) updateAutoSeekerStateMachine();
  else handleTouch();
  
  drawTitles();
  drawLeftGraph();
  drawRightGraph();

  drawInputMarker();
  drawOutputMarker();
  
  if (showConformal) drawConformalPlot();
  
  drawParticles();
  drawInformation();
  drawUIControls();
}

// ============================================================
// AUTO-SEEKER STATE MACHINE (👎 and 🔥)
// ============================================================

void updateAutoSeekerStateMachine() {
  double[] zOut;
  double mag;
  
  if (pilotState == 0) {
    // 1. Move Left along Im = 0 (Searching Trivial Zeros)
    targetRealMin = -20.0; targetImagMax = 20.0; // Zoom out horizontally
    
    double distToEven = Math.abs(autoSigma - Math.round(autoSigma/2.0)*2.0);
    double stepSigma = Math.max(0.05, Math.min(0.2, distToEven * 0.5));
    
    if (autoSigma < -0.5 && distToEven < 0.05 && !justFiredTriv) {
      fireParticles("👎", inputX(autoSigma), inputY(0));
      justFiredTriv = true;
    }
    if (distToEven > 0.5) justFiredTriv = false;
    
    autoSigma -= stepSigma;
    inputRe = autoSigma; inputIm = 0.0;
    
    if (autoSigma < -18.0) pilotState = 1; // Reached limit, return
    
  } else if (pilotState == 1) {
    // 2. Move Right back to Critical Line
    autoSigma += 0.4;
    inputRe = autoSigma; inputIm = 0.0;
    if (autoSigma >= CRITICAL_LINE) {
      autoSigma = CRITICAL_LINE;
      autoT = 0.0;
      pilotState = 2;
    }
    
  } else if (pilotState == 2) {
    // 3. Move UP Critical Line (Searching Nontrivial Zeros)
    targetRealMin = -6.0; targetImagMax = 65.0; // Zoom out vertically
    
    zOut = calculateZetaValue(CRITICAL_LINE, autoT);
    mag = Math.sqrt(zOut[0]*zOut[0] + zOut[1]*zOut[1]);
    
    double stepT = Math.max(0.01, Math.min(0.25, mag * 0.1));
    
    if (mag < 0.03 && prevMag < mag && !justFiredCrit) {
      fireParticles("🔥", inputX(CRITICAL_LINE), inputY(autoT));
      infinitesimalResidue = mag;
      justFiredCrit = true;
      if (lastZeroT > 0) currentGap = autoT - lastZeroT;
      lastZeroT = autoT;
    }
    if (mag > 0.15) justFiredCrit = false;
    
    autoT += stepT;
    inputRe = CRITICAL_LINE; inputIm = autoT;
    prevMag = mag;
    
    if (autoT > 60.0) pilotState = 3; // Halfway limit reached, go down
    
  } else if (pilotState == 3) {
    // 4. Move DOWN Critical Line
    targetImagMax = 30.0; // Zoom back in
    autoT -= 0.3; // Travel down fast
    inputRe = CRITICAL_LINE; inputIm = autoT;
    
    if (autoT <= 0.0) {
      autoT = 0.0;
      pilotState = 0; // Restart cycle
    }
  }

  calculateZeta(inputRe, inputIm);
  addTracePoint(inputRe, inputIm, outputRe, outputIm);
}

void fireParticles(String emoji, float px, float py) {
  for(int i=0; i<18; i++) {
    particles.add(new Particle(emoji, px, py));
    particles.add(new Particle(emoji, outputX(0), outputY(0)));
  }
}

void drawParticles() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.life <= 0) particles.remove(i);
  }
}

// ============================================================
// CONFORMAL MAPPING (YELLOW PLANE)
// ============================================================

void drawConformalPlot() {
  noFill();
  stroke(255, 205, 0, 180); 
  strokeWeight(2.5f);
  beginShape();
  for (double t = 0; t <= currentImagMax; t += 0.3) {
    double[] z = calculateZetaValue(CRITICAL_LINE, t);
    vertex(outputX(safeOutput(z[0])), outputY(safeOutput(z[1])));
  }
  endShape();
  
  for (int p : primes) {
    if (p > currentImagMax) continue;
    double[] zP = calculateZetaValue(CRITICAL_LINE, p);
    float px = outputX(safeOutput(zP[0]));
    float py = outputY(safeOutput(zP[1]));
    fill(255, 50, 100); noStroke(); ellipse(px, py, 8, 8);
    fill(255); textSize(10); textAlign(LEFT, BOTTOM); text("Prime t=" + p, px + 5, py - 5);
  }
}

// ============================================================
// UI AND GRAPHS
// ============================================================

void drawTitles() {
  textAlign(CENTER, CENTER); textSize(Math.max(15, height * 0.030f)); fill(255);
  text("RIEMANN ZETA VISUALIZER — CHAOS & OEIS", middle, height * 0.035f);

  textSize(Math.max(13, height * 0.024f)); fill(65, 165, 255);
  text("INPUT COMPLEX PLANE s", middle * 0.5f, height * 0.08f);
  fill(255, 205, 0);
  text("OUTPUT COMPLEX PLANE zeta(s)", middle * 1.5f, height * 0.08f);
}

void drawLeftGraph() {
  float left = 25, right = middle - 25;
  stroke(30); strokeWeight(1);
  
  for (int i = 0; i <= 6; i++) {
    float x = left + (right - left) * i / 6.0f;
    line(x, graphTop, x, graphBottom);
  }
  for (int i = 0; i <= 10; i++) {
    float y = graphTop + (graphBottom - graphTop) * i / 10.0f;
    line(left, y, right, y);
  }

  float originX = inputX(0);
  stroke(150, 160, 180); strokeWeight(2);
  line(originX, graphTop, originX, graphBottom);
  line(left, graphBottom, right, graphBottom);

  float criticalX = inputX(CRITICAL_LINE);
  stroke(35, 155, 255, 220); strokeWeight(3.5f);
  line(criticalX, graphTop, criticalX, graphBottom);

  if (!autoPlay) drawInputLocus();

  fill(160); textSize(10); textAlign(CENTER, CENTER);
  text(String.format(Locale.US, "%.1f", currentRealMin), inputX(currentRealMin), graphBottom + 14);
  text("0.0", originX, graphBottom + 14);
  fill(100, 190, 255);
  text("0.5", criticalX, graphBottom + 14);
}

void drawRightGraph() {
  float left = middle + 25, right = width - 25;
  float originX = outputX(0), originY = outputY(0);

  stroke(30); strokeWeight(1);
  for (int i = 0; i <= 12; i++) {
    float x = left + (right - left) * i / 12.0f;
    line(x, graphTop, x, graphBottom);
    float y = graphTop + (graphBottom - graphTop) * i / 12.0f;
    line(left, y, right, y);
  }

  stroke(150, 160, 180); strokeWeight(2);
  line(originX, graphTop, originX, graphBottom);
  line(left, originY, right, originY);

  noFill(); stroke(255, 50, 50, 150); strokeWeight(2);
  ellipse(originX, originY, 15, 15);

  if (!autoPlay) drawOutputLocus();
}

void drawInputLocus() {
  if (inputTraceCount < 2) return;
  noFill(); stroke(55, 190, 255, 225); strokeWeight(3.5f);
  beginShape();
  for (int i = 0; i < inputTraceCount; i++) vertex(inputX(inputTraceRe[i]), inputY(inputTraceIm[i]));
  endShape();
}

void drawOutputLocus() {
  if (outputTraceCount < 2) return;
  noFill(); stroke(255, 205, 30, 225); strokeWeight(2.5f);
  beginShape();
  for (int i = 0; i < outputTraceCount; i++) vertex(outputTraceX[i], outputTraceY[i]);
  endShape();
}

void drawInputMarker() {
  float x = inputX(inputRe), y = inputY(inputIm);
  noStroke(); fill(40, 155, 255); ellipse(x, y, 17, 17);
  fill(255); ellipse(x, y, 4, 4);
}

void drawOutputMarker() {
  float x = outputX(safeOutput(outputRe)), y = outputY(safeOutput(outputIm));
  noStroke(); fill(255, 205, 0); ellipse(x, y, 17, 17);
  fill(255); ellipse(x, y, 4, 4);
}

// ============================================================
// TOUCH / BUTTONS / UI CONTROLS
// ============================================================

void drawUIControls() {
  drawButton(35, height*0.90f, 180, 34, autoPlay ? "STOP AUTO PILOT" : "AUTO PILOT (🔥/👎)", autoPlay ? color(255,50,50) : color(40,180,100));
  drawButton(middle+35, height*0.90f, 220, 34, showConformal ? "HIDE CONFORMAL MAP" : "PLOT CONFORMAL Re=0.5", color(200, 160, 20));
}

void drawButton(float x, float y, float w, float h, String txt, int c) {
  fill(0, 150); noStroke(); rect(x+2, y+2, w, h, 6);
  fill(c, 220); rect(x, y, w, h, 6);
  stroke(255); strokeWeight(1.5f); noFill(); rect(x, y, w, h, 6);
  fill(255); textAlign(CENTER, CENTER); textSize(11); text(txt, x+w/2, y+h/2);
}

void handleTouch() {
  if (!mousePressed) { touching = false; newTouchStroke = true; return; }
  
  if (mouseY > height*0.85f) {
    if (mouseX > 35 && mouseX < 35+180) { 
      autoPlay = !autoPlay; 
      if(autoPlay){ pilotState = 0; autoSigma = 0; targetRealMin = -20; targetImagMax = 50; }
      else { targetRealMin = -12; targetImagMax = 50; }
      delay(200); return; 
    }
    if (mouseX > middle+35 && mouseX < middle+35+220) { showConformal = !showConformal; delay(200); return; }
  }

  if (mouseX > 25 && mouseX < middle-25 && mouseY > graphTop && mouseY < graphBottom) {
    touching = true;
    inputRe = lockedMode ? CRITICAL_LINE : mapValue(mouseX, 25, middle-25, currentRealMin, REAL_MAX);
    inputIm = mapValue(mouseY, graphBottom, graphTop, IMAG_MIN, currentImagMax);
    calculateZeta(inputRe, inputIm);
    addTracePoint(inputRe, inputIm, outputRe, outputIm);
    newTouchStroke = false;
  }
}

// ============================================================
// TEXT FEEDBACK & CHAOS / OEIS INFO
// ============================================================

void drawInformation() {
  float y = height * 0.82f;
  textAlign(CENTER, CENTER); textSize(12); fill(255);
  
  text("s = " + String.format(Locale.US, "%.5f", inputRe) + " + " + String.format(Locale.US, "%.5f", inputIm) + "i", middle*0.5f, y);
  
  if (justFiredCrit) {
    fill(255, 80, 80); textSize(11);
    text("🔥 ZERO REACHED: 0.000000000000000000000000 + 0.000000000000000000000000 i", middle*1.5f, y - 8);
    fill(255, 180, 50);
    text(String.format(Locale.US, "Infinitesimal Mag: %.16f", infinitesimalResidue), middle*1.5f, y + 6);
    
    fill(100, 200, 255);
    String patternText = "Pattern: Quantum Chaos GUE | OEIS A058303 | Cellular Automata Complexity";
    if (currentGap < 3.0 && currentGap > 0.1) {
      patternText = "⚠️ NEAR ZEROS IN CRITICAL LINE! | " + patternText;
    }
    text(patternText, middle*1.5f, y + 22);
    
  } else if (justFiredTriv) {
    fill(50, 255, 100);
    text("👎 TRIVIAL ZERO REACHED (Negative Even Integer)", middle*1.5f, y);
  } else {
    fill(255);
    text("zeta(s) = " + String.format(Locale.US, "%.5f", outputRe) + " + " + String.format(Locale.US, "%.5f", outputIm) + "i", middle*1.5f, y);
  }
}

// ============================================================
// MATH ALGORITHMS
// ============================================================

void calculateZeta(double sigma, double t) {
  double[] result = calculateZetaValue(sigma, t);
  outputRe = result[0]; outputIm = result[1];
}

double[] calculateZetaValue(double sigma, double t) {
  double[] result = new double[2];
  if (Double.isNaN(sigma) || Double.isNaN(t)) return result;

  for (int n = 0; n <= LEVELS; n++) {
    double logValue = logarithms[n + 1];
    double amplitude = Math.exp(-sigma * logValue);
    double angle = -t * logValue;
    workRe[n] = amplitude * Math.cos(angle);
    workIm[n] = amplitude * Math.sin(angle);
  }

  double sumRe = 0.0, sumIm = 0.0, factor = 0.5;
  for (int level = 0; level < LEVELS; level++) {
    sumRe += workRe[0] * factor; sumIm += workIm[0] * factor;
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
  double denRe = 1.0 - pRe, denIm = -pIm;
  double denominator = denRe * denRe + denIm * denIm;

  if (denominator < 1.0e-28) return result;

  result[0] = (sumRe * denRe + sumIm * denIm) / denominator;
  result[1] = (sumIm * denRe - sumRe * denIm) / denominator;
  return result;
}

void addTracePoint(double re, double im, double outRe, double outIm) {
  if (inputTraceCount >= MAX_TRACE) {
    for (int i = 1; i < MAX_TRACE; i++) {
      inputTraceRe[i - 1] = inputTraceRe[i]; inputTraceIm[i - 1] = inputTraceIm[i];
      outputTraceX[i - 1] = outputTraceX[i]; outputTraceY[i - 1] = outputTraceY[i];
    }
    inputTraceCount = MAX_TRACE - 1;
  }
  inputTraceRe[inputTraceCount] = re; inputTraceIm[inputTraceCount] = im;
  outputTraceX[inputTraceCount] = outputX(safeOutput(outRe));
  outputTraceY[inputTraceCount] = outputY(safeOutput(outIm));
  inputTraceCount++; outputTraceCount = inputTraceCount;
}

float inputX(double val) { return (float) mapValue(val, currentRealMin, REAL_MAX, 25, middle - 25); }
float inputY(double val) { return (float) mapValue(val, IMAG_MIN, currentImagMax, graphBottom, graphTop); }
float outputX(double val) { return (float) mapValue(val, -OUTPUT_LIMIT, OUTPUT_LIMIT, middle + 25, width - 25); }
float outputY(double val) { return (float) mapValue(val, -OUTPUT_LIMIT, OUTPUT_LIMIT, graphBottom, graphTop); }

double safeOutput(double val) { return val < -OUTPUT_LIMIT ? -OUTPUT_LIMIT : (val > OUTPUT_LIMIT ? OUTPUT_LIMIT : val); }
double mapValue(double val, double inMin, double inMax, double outMin, double outMax) {
  return outMin + (val - inMin) * (outMax - outMin) / (inMax - inMin);
}
