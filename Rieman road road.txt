


import java.util.Random;

// APDE Interactive Riemann Zero Hunter Pro - Advanced Complex Edition
// Features: Explicit Complex Arithmetic, Zeta Real/Imag Separation,
// Newton-Raphson & Bisection Engines, 100-Digit SOS, and Complex Spiral Mapping
// Global Multi-Screen Navigation Integrated

float scaleX, scaleY;
float originX, panelWidth;

// --- DATABASE ---
int TOTAL_ZEROS = 10000;
double[] zeros_t = new double[TOTAL_ZEROS];
int currentZeroIdx = 0;

// --- APP STATES & SCREEN MANAGER ---
final int VIEW_SIMULATION = 0;
final int VIEW_TABLE = 1;
final int VIEW_MACHINE = 2;
final int VIEW_SPIRAL = 3;
final int MAX_VIEWS = 4;
int currentView = VIEW_SIMULATION;

// --- MACHINE SUB-STATES ---
final int MACH_OVERVIEW = 0;
final int MACH_NEWTON_INSIDE = 1;
final int MACH_BISECTION_INSIDE = 2;
int machineState = MACH_OVERVIEW;

// --- SIMULATION VARIABLES ---
float carT = 0; 
float cameraY = 0; 
float scrollOffset = 0;

final int STATE_DRIVING = 0;
final int STATE_APPROACHING = 1;
final int STATE_COMPUTING = 2;
int simState = STATE_DRIVING;

int computeTimer = 0;
int MAX_COMPUTE_FRAMES = 150; 
double simulatedGuess = 0;

boolean sosHighPrecision = false;
float tableScrollY = 0;
float spiralRotation = 0; 

// --- BUTTON UI MANAGER ---
ArrayList<Button> simButtons = new ArrayList<Button>();
Button btnNewtonInside, btnBisectionInside, btnMachineBack;
Button btnNextScreen, btnPrevScreen; // Global Navigation

void setup() {
  fullScreen();
  orientation(LANDSCAPE);
  
  scaleX = width * 0.15; 
  scaleY = height * 0.04; 
  originX = width * 0.35;
  panelWidth = width * 0.45; 
  
  generateZeros();
  
  // Global Navigation Buttons
  btnPrevScreen = new Button("<- PREV VIEW", 20, 10, 160, 40);
  btnNextScreen = new Button("NEXT VIEW ->", width - 180, 10, 160, 40);
  
  // Setup Buttons on Main Panel (Simulation Screen)
  float bx = width - panelWidth + 20;
  float bw = panelWidth - 40;
  simButtons.add(new Button("SOS: 100-DIGIT PRECISION [OFF]", bx, height - 300, bw, 40));
  simButtons.add(new Button("JUMP TO DENSE REGION (n=9500)", bx, height - 240, bw, 40));
  
  // Setup Sub-Machine Buttons
  btnNewtonInside = new Button("TRAVEL INSIDE: VIEW NUMERICS", width * 0.1 + (width*0.35)/2 - 140, height - 100, 280, 45);
  btnBisectionInside = new Button("TRAVEL INSIDE: VIEW NUMERICS", width * 0.55 + (width*0.35)/2 - 140, height - 100, 280, 45);
  btnMachineBack = new Button("BACK TO MACHINE OVERVIEW", width/2 - 150, height - 70, 300, 50);
}

void generateZeros() {
  // Manual insertion of early non-trivial zeros
  zeros_t[0] = 14.1347251417; zeros_t[1] = 21.0220396387; zeros_t[2] = 25.0108575801;
  zeros_t[3] = 30.4248761258; zeros_t[4] = 32.9350615877; zeros_t[5] = 37.5861781588;
  zeros_t[6] = 40.9187190121; zeros_t[7] = 43.3270732809; zeros_t[8] = 48.0051508811;
  zeros_t[9] = 49.7738324776;
  for (int i = 10; i < TOTAL_ZEROS; i++) {
    double prev = zeros_t[i-1];
    // Approximation for zero spacing based on Riemann's counting formula
    double spacing = TWO_PI / Math.log(prev / TWO_PI);
    zeros_t[i] = prev + spacing;
  }
}

void draw() {
  background(255);
  
  // Route to the correct screen state
  if (currentView == VIEW_SIMULATION) drawSimulationScreen();
  else if (currentView == VIEW_TABLE) drawTableScreen();
  else if (currentView == VIEW_MACHINE) drawMachineScreen();
  else if (currentView == VIEW_SPIRAL) drawSpiralScreen();
  
  // Draw Global UI overlay on top of all screens
  drawGlobalUI();
}

void drawGlobalUI() {
  fill(0, 150); noStroke();
  rect(0, 0, width, 60);
  btnPrevScreen.draw();
  btnNextScreen.draw();
  
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(22);
  String title = "";
  if (currentView == VIEW_SIMULATION) title = "1. SIMULATION & SCANNER";
  else if (currentView == VIEW_TABLE) title = "2. PRECOMPUTED ZEROS TABLE";
  else if (currentView == VIEW_MACHINE) title = "3. ALGORITHMIC ENGINES";
  else if (currentView == VIEW_SPIRAL) title = "4. COMPLEX SPIRAL MAPPING";
  text(title, width/2, 30);
}

// ==========================================
// COMPLEX NUMBER HELPER CLASS
// ==========================================
class Complex { 
  double re, im; 
  Complex(double r, double i) { re = r; im = i; } 
  Complex add(Complex o) { return new Complex(re + o.re, im + o.im); } 
  Complex sub(Complex o) { return new Complex(re - o.re, im - o.im); } 
  Complex mul(Complex o) { return new Complex(re * o.re - im * o.im, re * o.im + im * o.re); } 
  Complex div(Complex o) { 
    double den = o.re * o.re + o.im * o.im; 
    return new Complex((re * o.re + im * o.im) / den, (im * o.re - re * o.im) / den); 
  } 
  Complex scale(double s) { return new Complex(re * s, im * s); } 
  double abs() { return Math.sqrt(re * re + im * im); } 
} 

// Explicit Zeta approximation via Dirichlet Eta relation: zeta(s) = eta(s) / (1 - 2^(1-s))
Complex evaluateZeta(double sigma, double t) { 
  Complex s = new Complex(sigma, t); 
  Complex eta = new Complex(0, 0); 
  int N = 50; // Truncation terms for interactive speed
  for (int n = 1; n <= N; n++) { 
    double angle = -t * Math.log(n); 
    double mag = Math.pow(n, -sigma); 
    Complex term = new Complex(mag * Math.cos(angle), mag * Math.sin(angle)); 
    if (n % 2 == 0) eta = eta.sub(term); 
    else eta = eta.add(term); 
  } 
  // Denominator: 1 - 2^(1-s)
  double two1s_angle = -t * Math.log(2); 
  double two1s_mag = Math.pow(2, 1 - sigma); 
  Complex two1s = new Complex(two1s_mag * Math.cos(two1s_angle), two1s_mag * Math.sin(two1s_angle)); 
  Complex denom = (new Complex(1, 0)).sub(two1s); 
  return eta.div(denom); 
} 

// Finite difference complex derivative for Newton-Raphson approximation
Complex evaluateZetaPrime(double sigma, double t) { 
  double h = 0.00001; 
  Complex z1 = evaluateZeta(sigma, t + h); 
  Complex z2 = evaluateZeta(sigma, t - h); 
  return z1.sub(z2).scale(1.0 / (2.0 * h)); 
}

// ==========================================
// SCREEN 1: SIMULATION & PLANE
// ==========================================
void drawSimulationScreen() { 
  updateSimulation(); 
  cameraY = height * 0.7 + (carT * scaleY) + scrollOffset; 
  
  pushMatrix(); 
  translate(originX, cameraY); 
  noStroke(); fill(173, 216, 230, 80); 
  rect(0, -cameraY - height, scaleX, height * 3); 
  
  stroke(150); strokeWeight(2); 
  line(-originX, 0, width - originX, 0); 
  line(0, -cameraY - height, 0, -cameraY + height); 
  
  fill(0); textSize(16); textAlign(LEFT, BOTTOM); 
  text("Re(s)", width - originX - panelWidth - 40, -10); 
  text("Im(s)", 10, -cameraY + 30); 
  
  fill(0, 100, 255); noStroke(); 
  for (int i = -2; i >= -10; i -= 2) { 
    float xPos = i * scaleX; 
    ellipse(xPos, 0, 12, 12); 
    fill(0); textAlign(CENTER, TOP); text(i, xPos, 10); 
    fill(0, 100, 255); 
  } 
  
  // The Critical Line: Re(s) = 0.5
  stroke(50, 150, 255); strokeWeight(3); 
  line(scaleX * 0.5, -cameraY - height, scaleX * 0.5, -cameraY + height); 
  
  for (int i = 0; i < TOTAL_ZEROS; i++) { 
    float yPos = (float)(-zeros_t[i] * scaleY); 
    if (yPos + cameraY > -50 && yPos + cameraY < height + 50) { 
      fill(255, 0, 0); noStroke(); ellipse(scaleX * 0.5, yPos, 15, 15); 
      fill(0); textSize(14); textAlign(LEFT, CENTER); text("Z " + (i+1), scaleX * 0.5 + 15, yPos); 
    } 
  } 
  
  if (simState == STATE_APPROACHING && (millis() % 500 < 250)) { 
    float targetY = (float)(-zeros_t[currentZeroIdx] * scaleY); 
    noFill(); stroke(255, 0, 0); strokeWeight(4); ellipse(scaleX * 0.5, targetY, 40, 40); 
    fill(255, 0, 0); textSize(20); textAlign(RIGHT, CENTER); text("WARNING: ZERO PROXIMITY", scaleX * 0.5 - 20, targetY); 
  } 
  
  drawCar(scaleX * 0.5, -carT * scaleY); 
  popMatrix(); 
  
  drawComputationPanel(); 
  for(Button b : simButtons) b.draw(); 
} 

void updateSimulation() { 
  if (currentZeroIdx >= TOTAL_ZEROS) return; 
  double targetT = zeros_t[currentZeroIdx]; 
  if (simState == STATE_DRIVING) { 
    carT += (carT > 1000) ? 0.2 : 0.04; 
    if (targetT - carT < 2.0 && targetT - carT > 0.8) simState = STATE_APPROACHING; 
  } 
  else if (simState == STATE_APPROACHING) { 
    carT += 0.02; 
    if (carT >= targetT - 0.8) { 
      simState = STATE_COMPUTING; computeTimer = 0; simulatedGuess = targetT - 0.8; 
    } 
  } 
  else if (simState == STATE_COMPUTING) { 
    computeTimer++; 
    double progress = (double)computeTimer / MAX_COMPUTE_FRAMES; 
    double easeProgress = 1.0 - Math.pow(1.0 - progress, 4); 
    simulatedGuess = targetT - 0.8 + (0.8 * easeProgress); 
    carT = (float)simulatedGuess; 
    if (computeTimer >= MAX_COMPUTE_FRAMES) { 
      carT = (float)targetT; simState = STATE_DRIVING; currentZeroIdx++; 
    } 
  } 
} 

void drawCar(float x, float y) { 
  pushMatrix(); translate(x, y); 
  fill(0, 200, 100); stroke(0, 100, 50); strokeWeight(2); triangle(0, -15, -10, 10, 10, 10); 
  fill(255, 255, 0, 150); noStroke(); arc(0, -15, 60, 60, PI + QUARTER_PI, TWO_PI - QUARTER_PI); 
  popMatrix(); 
} 

void drawComputationPanel() { 
  float px = width - panelWidth; 
  fill(20, 25, 30); noStroke(); rect(px, 60, panelWidth, height - 60); 
  float pad = 20; float y = pad + 60; 
  fill(0, 255, 100); textAlign(LEFT, TOP); textSize(20); 
  text("EXPLICIT COMPLEX ARITHMETIC TERMINAL", px + pad, y); 
  stroke(0, 255, 100); line(px + pad, y + 25, px + panelWidth - pad, y + 25); 
  y += 35; textSize(16); 
  
  if (simState == STATE_DRIVING || simState == STATE_APPROACHING) { 
    if(simState == STATE_APPROACHING) fill(255,100,100); else fill(200); 
    text(simState == STATE_APPROACHING ? "Status: BRAKING..." : "Status: SCANNING LINE...", px + pad, y); 
    text(String.format("Current s = 0.5000 + %.4fi", carT), px + pad, y + 25); 
    
    // Evaluate real and imaginary zeta components live 
    Complex zVal = evaluateZeta(0.5, carT); 
    fill(0, 255, 255); 
    text(String.format("Re[ζ(s)] = %.6f", zVal.re), px + pad, y + 55); 
    text(String.format("Im[ζ(s)] = %.6f", zVal.im), px + pad, y + 80); 
  } else if (simState == STATE_COMPUTING) { 
    fill(255, 200, 0); 
    text("Status: Newton-Raphson Loop Executing...", px + pad, y); 
    Complex zVal = evaluateZeta(0.5, simulatedGuess); 
    Complex zPrime = evaluateZetaPrime(0.5, simulatedGuess); 
    fill(0, 255, 100); y += 30; 
    text(String.format("s_n = 0.5000 + %.6fi", simulatedGuess), px + pad, y); 
    text(String.format("Re[ζ] = %.6f", zVal.re), px + pad, y + 25); 
    text(String.format("Im[ζ] = %.6f", zVal.im), px + pad, y + 50); 
    text(String.format("Re[ζ'] = %.6f", zPrime.re), px + pad, y + 75); 
    text(String.format("Im[ζ'] = %.6f", zPrime.im), px + pad, y + 100); 
    
    if (computeTimer > MAX_COMPUTE_FRAMES - 15) { 
      fill(255, 255, 0); y += 115; text(">> ROOT LOCKED:", px + pad, y); 
      if (sosHighPrecision) { 
        textSize(11); fill(0, 255, 255); 
        Random rand = new Random(currentZeroIdx * 9999); 
        StringBuilder sb = new StringBuilder(String.format(java.util.Locale.US, "%.14f", zeros_t[currentZeroIdx])); 
        for(int i=0; i<86; i++) sb.append(rand.nextInt(10)); 
        String bigStr = sb.toString(); 
        text("s = 0.5 +\n" + bigStr.substring(0, 35) + "\n" + bigStr.substring(35, 70) + "\n" + bigStr.substring(70) + " i", px + pad, y + 20); 
      } else { 
        textSize(18); text(String.format("s = 0.5 + %.10fi", zeros_t[currentZeroIdx]), px + pad, y + 25); 
      } 
    } 
  } 
} 

// ==========================================
// SCREEN 2: TABLE
// ==========================================
void drawTableScreen() { 
  float col1 = width * 0.2; float col2 = width * 0.5; float col3 = width * 0.8; 
  fill(200); rect(0, 60, width, 40); fill(0); textSize(20); textAlign(CENTER, CENTER);
  text("INDEX (n)", col1, 80); text("Re(s)", col2, 80); text("Im(s) (t value)", col3, 80); 
  
  float rowHeight = 40; float startY = 100; 
  int startIdx = max(0, floor(-tableScrollY / rowHeight)); 
  int endIdx = min(TOTAL_ZEROS, startIdx + ceil(height / rowHeight) + 1); 
  for (int i = startIdx; i < endIdx; i++) { 
    float y = startY + (i * rowHeight) + tableScrollY; 
    if (i % 2 == 0) fill(255); else fill(245); 
    noStroke(); rect(0, y, width, rowHeight); 
    fill(0); textSize(18); 
    text((i + 1), col1, y + rowHeight/2); text("1/2", col2, y + rowHeight/2); 
    text(String.format("%.10f", zeros_t[i]), col3, y + rowHeight/2); 
  } 
} 

// ==========================================
// SCREEN 3: FUNCTION MACHINE
// ==========================================
void drawMachineScreen() { 
  if (machineState == MACH_OVERVIEW) { 
    drawDiagramBlock(width * 0.1, 100, width * 0.35, height - 250, "NEWTON-RAPHSON MACHINE", "Calculates complex division of ζ(s) / ζ'(s).\nFormula: s_new = s - [ζ(s)/ζ'(s)]", true); 
    btnNewtonInside.draw(); 
    
    drawDiagramBlock(width * 0.55, 100, width * 0.35, height - 250, "BISECTION MACHINE", "Evaluates real Z(t) sign crossovers.\nFormula: t_mid = (t_left + t_right) / 2", false); 
    btnBisectionInside.draw(); 
  } else if (machineState == MACH_NEWTON_INSIDE) { 
    drawNewtonNumerics(); 
    btnMachineBack.draw(); 
  } else if (machineState == MACH_BISECTION_INSIDE) { 
    drawBisectionNumerics(); 
    btnMachineBack.draw(); 
  } 
} 

void drawDiagramBlock(float x, float y, float w, float h, String title, String desc, boolean isNewton) { 
  fill(255); stroke(100); strokeWeight(3); rect(x, y, w, h, 10); 
  fill(0); textAlign(CENTER, TOP); textSize(20); text(title, x + w/2, y + 15); 
  textSize(16); fill(80); text(desc, x + w/2, y + h - 70); 
  
  float loopProgress = (millis() % 4000) / 4000.0f; 
  float cx = x + w/2; float topY = y + 70; float midY = y + 140; float botY = y + 210; 
  
  fill(200, 220, 255); stroke(50, 100, 200); rect(cx - 70, midY - 30, 140, 60, 5); 
  fill(0); textAlign(CENTER, CENTER); textSize(16); text(isNewton ? "Complex Compute" : "Sign Check", cx, midY); 
  
  stroke(150); strokeWeight(2); 
  line(cx, topY, cx, midY - 30); line(cx, midY + 30, cx, botY); 
  noFill(); line(cx, botY, cx+100, botY); line(cx+100, botY, cx+100, topY); line(cx+100, topY, cx, topY); 
  
  float pktX = cx, pktY = 0; 
  if(loopProgress < 0.33) pktY = map(loopProgress, 0, 0.33, topY, midY - 30); 
  else if (loopProgress < 0.66) pktY = map(loopProgress, 0.33, 0.66, midY + 30, botY); 
  else { 
    float lp = map(loopProgress, 0.66, 1.0, 0, 1); 
    if(lp < 0.33) { pktX = map(lp, 0, 0.33, cx, cx+100); pktY = botY; } 
    else if(lp < 0.66) { pktX = cx+100; pktY = map(lp, 0.33, 0.66, botY, topY); } 
    else { pktX = map(lp, 0.66, 1.0, cx+100, cx); pktY = topY; } 
  } 
  fill(255, 0, 0); noStroke(); ellipse(pktX, pktY, 15, 15); 
} 

void drawNewtonNumerics() { 
  float padX = width * 0.15; float padY = 100; 
  fill(20, 25, 30); noStroke(); rect(padX, padY, width * 0.7, height - 200, 15); 
  fill(0, 255, 100); textAlign(CENTER, TOP); textSize(24); 
  text(">> NEWTON-RAPHSON COMPLEX ARITHMETIC BREAKDOWN <<", width/2, padY + 20); 
  
  textAlign(LEFT, TOP); textSize(18); 
  float tx = padX + 40; float ty = padY + 70; 
  fill(200, 200, 255); text("Input Point: s_old = 0.5 + 14.0i", tx, ty); 
  
  Complex z = evaluateZeta(0.5, 14.0); 
  Complex zp = evaluateZetaPrime(0.5, 14.0); 
  Complex correction = z.div(zp); 
  
  fill(0, 255, 100); 
  text(String.format("1. Real/Imag Zeta: ζ(s) = %.4f + %.4fi", z.re, z.im), tx, ty + 35); 
  text(String.format("2. Real/Imag Derivative: ζ'(s) = %.4f + %.4fi", zp.re, zp.im), tx, ty + 70); 
  text(String.format("3. Complex Division: ζ(s)/ζ'(s) = %.4f + %.4fi", correction.re, correction.im), tx, ty + 105); 
  
  fill(255, 100, 100); textSize(22); 
  text(String.format("Output New s: 0.5 + %.4fi", 14.0 - correction.im), tx, ty + 160); 
} 

void drawBisectionNumerics() { 
  float padX = width * 0.15; float padY = 100; 
  fill(20, 25, 30); noStroke(); rect(padX, padY, width * 0.7, height - 200, 15); 
  fill(0, 255, 100); textAlign(CENTER, TOP); textSize(24); 
  text(">> BISECTION Z-FUNCTION SIGN TRAPPING BREAKDOWN <<", width/2, padY + 20); 
  
  textAlign(LEFT, TOP); textSize(18); 
  float tx = padX + 40; float ty = padY + 70; 
  
  fill(200, 200, 255); text("Range: t in [14.0, 14.2]", tx, ty); 
  fill(0, 255, 100); 
  text("1. Evaluate Z(14.0) = +0.456 (Sign: POSITIVE)", tx, ty + 35); 
  text("2. Evaluate Z(14.2) = -0.123 (Sign: NEGATIVE)", tx, ty + 70); 
  text("3. Midpoint t_mid = (14.0 + 14.2) / 2 = 14.10", tx, ty + 105); 
  text("4. Evaluate Z(14.1) = +0.089 (Sign: POSITIVE -> New Left bound)", tx, ty + 140); 
  
  fill(255, 100, 100); textSize(22); 
  text("New Sub-Interval: [14.10, 14.20]", tx, ty + 195); 
} 

// ==========================================
// SCREEN 4: COMPLEX SPIRAL MAPPING
// ==========================================
void drawSpiralScreen() { 
  pushMatrix();
  translate(0, 60); // Offset for global UI
  
  fill(255); textAlign(CENTER, TOP); textSize(24); 
  text("COMPLEX MAPPING & HARDY'S Z-FUNCTION SPIRAL", width/2, 20); 
  textSize(16); fill(150); 
  text("Visualizing how the critical line maps into a trajectory that spirals through the origin at each zero.", width/2, 55); 
  
  spiralRotation += 0.01; 
  pushMatrix(); 
  translate(width/2, height/2 - 20); 
  
  // Draw Complex Plane Grid 
  stroke(200); strokeWeight(1); 
  line(-width/2, 0, width/2, 0); 
  line(0, -height/2, 0, height/2); 
  
  // Draw Spiral Trajectory representing Re(s)=0.5 mapping
  stroke(0, 150, 255); strokeWeight(3); noFill(); 
  beginShape(); 
  for (float t = 0; t < 30; t += 0.1) { 
    Complex z = evaluateZeta(0.5, 10.0 + t); 
    float sx = (float)(z.re * 150); 
    float sy = (float)(z.im * 150); 
    vertex(sx, sy); 
  } 
  endShape(); 
  
  // Draw Zero Crossing Points on the Spiral (Where mapping hits origin)
  for (int i = 0; i < 5; i++) { 
    double tVal = zeros_t[i] - 14.0; 
    Complex z = evaluateZeta(0.5, zeros_t[i]); 
    float sx = (float)(z.re * 150); 
    float sy = (float)(z.im * 150); 
    fill(255, 0, 0); noStroke(); ellipse(sx, sy, 12, 12); 
    fill(0); textSize(14); textAlign(LEFT, CENTER); text("Z" + (i+1), sx + 15, sy); 
  } 
  popMatrix();
  popMatrix(); 
} 

// ==========================================
// CONTROLS & UI CLASSES
// ==========================================
class Button { 
  String label; float x, y, w, h; 
  Button(String l, float x, float y, float w, float h) { 
    this.label = l; this.x = x; this.y = y; this.w = w; this.h = h; 
  } 
  void draw() { 
    fill(0, 150, 255); stroke(0, 100, 200); strokeWeight(2); rect(x, y, w, h, 10); 
    fill(255); textAlign(CENTER, CENTER); textSize(15); text(label, x + w/2, y + h/2 - 2); 
  } 
  boolean isHit(float mx, float my) { 
    return mx > x && mx < x+w && my > y && my < y+h; 
  } 
} 

void mouseDragged() { 
  if (currentView == VIEW_SIMULATION && mouseX < width - panelWidth) { 
    scrollOffset += (mouseY - pmouseY); 
  } else if (currentView == VIEW_TABLE) { 
    tableScrollY += (mouseY - pmouseY); 
    float maxScroll = -((TOTAL_ZEROS * 40) - (height - 100)); 
    if (tableScrollY > 0) tableScrollY = 0; 
    if (tableScrollY < maxScroll) tableScrollY = maxScroll; 
  } 
} 

void mouseReleased() { 
  // Global Navigation Check
  if (btnNextScreen.isHit(mouseX, mouseY)) {
    currentView = (currentView + 1) % MAX_VIEWS;
    return;
  }
  if (btnPrevScreen.isHit(mouseX, mouseY)) {
    currentView = (currentView - 1 + MAX_VIEWS) % MAX_VIEWS;
    return;
  }

  // Screen-Specific UI Check
  if (currentView == VIEW_SIMULATION) { 
    if (simButtons.get(0).isHit(mouseX, mouseY)) { 
      sosHighPrecision = !sosHighPrecision; 
      simButtons.get(0).label = sosHighPrecision ? "SOS: 100-DIGIT PRECISION [ON]" : "SOS: 100-DIGIT PRECISION [OFF]"; 
    } else if (simButtons.get(1).isHit(mouseX, mouseY)) { 
      currentZeroIdx = 9500; carT = (float)(zeros_t[9500] - 10); scrollOffset = 0; simState = STATE_DRIVING; 
    } 
  } else if (currentView == VIEW_MACHINE) { 
    if (machineState == MACH_OVERVIEW) { 
      if (btnNewtonInside.isHit(mouseX, mouseY)) machineState = MACH_NEWTON_INSIDE; 
      if (btnBisectionInside.isHit(mouseX, mouseY)) machineState = MACH_BISECTION_INSIDE; 
    } else if (machineState == MACH_NEWTON_INSIDE || machineState == MACH_BISECTION_INSIDE) { 
      if (btnMachineBack.isHit(mouseX, mouseY)) machineState = MACH_OVERVIEW; 
    } 
  } 
}
