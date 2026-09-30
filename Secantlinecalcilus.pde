Calculus tangent

/* ============================================================
   SECANT & TANGENT LINE INTERACTIVE GRAPH WITH Δx / Δy TRIANGLE
   Processing / APDE Android Java Mode
   ============================================================
   Screens:
     0 = Home
     1 = Parabola y = x^2
     2 = Cubic y = x^3
     3 = Linear y = 0.8x + 1
   Interaction:
     - Drag point A
     - Drag point B
     - Delta triangle (dx, dy) updates in real time
     - Secant line passes through A and B
     - Tangent line is calculated at A
     - Move B toward A to see: Secant -> Tangent
   Suitable for: Android / APDE Processing Java Mode
   ============================================================ */

// ============================================================
// SCREEN CONTROL
// ============================================================
int screen = 0;

// ============================================================
// GRAPH SETTINGS
// ============================================================
float graphLeft;
float graphRight;
float graphTop;
float graphBottom;
float xMin = -5;
float xMax = 5;
float yMin = -8;
float yMax = 8;

// ============================================================
// POINTS
// ============================================================
// Mathematical coordinates
float ax = -2.0;
float bx = 2.0;
float ay;
float by;

// ============================================================
// DRAG CONTROL
// ============================================================
boolean draggingA = false;
boolean draggingB = false;
float touchRadius = 45;

// ============================================================
// FUNCTION TYPE
// ============================================================
int functionType = 1;

// ============================================================
// PROCESSING SETUP
// ============================================================
void setup() {
  fullScreen();
  orientation(PORTRAIT);
  textAlign(CENTER, CENTER);
  smooth();

  graphLeft = width * 0.08;
  graphRight = width * 0.92;
  graphTop = height * 0.18;
  graphBottom = height * 0.78;
}

// ============================================================
// MAIN DRAW
// ============================================================
void draw() {
  background(245);
  if (screen == 0) {
    drawHome();
  } else {
    drawGraphScreen();
  }
}

// ============================================================
// HOME SCREEN
// ============================================================
void drawHome() {
  background(245);
  fill(25);
  textSize(40);
  text("SECANT & TANGENT", width / 2, 70);

  fill(80);
  textSize(22);
  text("Interactive Calculus Graph", width / 2, 115);

  // ----------------------------------------------------------
  // BUTTONS
  // ----------------------------------------------------------
  drawButton(width / 2, 230, width * 0.80, 90, "PARABOLA", "y = x²");
  drawButton(width / 2, 360, width * 0.80, 90, "CUBIC POLYNOMIAL", "y = x³");
  drawButton(width / 2, 490, width * 0.80, 90, "LINEAR", "y = 0.8x + 1");

  fill(70);
  textSize(19);
  text("Drag A and B on the graph", width / 2, height - 100);
  text("Move B toward A: Secant → Tangent", width / 2, height - 65);
}

// ============================================================
// HOME BUTTON COMPONENT
// ============================================================
void drawButton(float cx, float cy, float bw, float bh, String title, String subtitle) {
  rectMode(CENTER);
  fill(35, 90, 160);
  rect(cx, cy, bw, bh, 18);

  fill(255);
  textSize(25);
  text(title, cx, cy - 15);
  textSize(18);
  text(subtitle, cx, cy + 20);

  rectMode(CORNER);
}

// ============================================================
// GRAPH SCREEN
// ============================================================
void drawGraphScreen() {
  background(248);

  // Set function type based on screen state
  if (screen == 1) {
    functionType = 1;
  } else if (screen == 2) {
    functionType = 2;
  } else if (screen == 3) {
    functionType = 3;
  }

  // ----------------------------------------------------------
  // TITLE
  // ----------------------------------------------------------
  fill(20);
  textSize(30);
  String title = "";
  if (functionType == 1) {
    title = "PARABOLA";
  } else if (functionType == 2) {
    title = "CUBIC POLYNOMIAL";
  } else if (functionType == 3) {
    title = "LINEAR FUNCTION";
  }
  text(title, width / 2, 42);

  // ----------------------------------------------------------
  // EQUATION
  // ----------------------------------------------------------
  fill(60);
  textSize(21);
  if (functionType == 1) {
    text("f(x) = x²", width / 2, 80);
  } else if (functionType == 2) {
    text("f(x) = x³", width / 2, 80);
  } else {
    text("f(x) = 0.8x + 1", width / 2, 80);
  }

  // ----------------------------------------------------------
  // GRAPH ELEMENTS
  // ----------------------------------------------------------
  drawGraph();

  // Calculate function values
  ay = functionValue(ax);
  by = functionValue(bx);

  // Draw layers
  drawFunction();
  drawDeltaTriangle();  // Δx / Δy Triangle connecting A and B
  drawSecant();
  drawTangent();
  drawPointA();
  drawPointB();

  // Draw UI overlay
  drawInformation();
  drawHomeButton();
  drawResetButton();
}

// ============================================================
// GRAPH AXES AND GRID
// ============================================================
void drawGraph() {
  strokeWeight(2);

  // X axis
  stroke(50);
  line(graphLeft, mathToScreenY(0), graphRight, mathToScreenY(0));

  // Y axis
  line(mathToScreenX(0), graphTop, mathToScreenX(0), graphBottom);

  // ----------------------------------------------------------
  // GRID
  // ----------------------------------------------------------
  stroke(220);
  strokeWeight(1);
  for (int x = -5; x <= 5; x++) {
    float sx = mathToScreenX(x);
    line(sx, graphTop, sx, graphBottom);
  }
  for (int y = -8; y <= 8; y++) {
    float sy = mathToScreenY(y);
    line(graphLeft, sy, graphRight, sy);
  }

  // ----------------------------------------------------------
  // AXIS LABELS
  // ----------------------------------------------------------
  fill(50);
  textSize(15);
  for (int x = -5; x <= 5; x++) {
    float sx = mathToScreenX(x);
    text(str(x), sx, mathToScreenY(0) + 22);
  }
  for (int y = -8; y <= 8; y++) {
    if (y == 0) continue;
    float sy = mathToScreenY(y);
    text(str(y), mathToScreenX(0) - 25, sy);
  }

  // Axis letters
  textSize(18);
  text("x", graphRight + 15, mathToScreenY(0));
  text("y", mathToScreenX(0), graphTop - 15);
}

// ============================================================
// DRAW FUNCTION CURVE
// ============================================================
void drawFunction() {
  stroke(30, 80, 180);
  strokeWeight(5);
  noFill();

  beginShape();
  for (float x = xMin; x <= xMax; x += 0.02) {
    float y = functionValue(x);
    float sx = mathToScreenX(x);
    float sy = mathToScreenY(y);
    vertex(sx, sy);
  }
  endShape();
}

// ============================================================
// DRAW Δx / Δy RATE TRIANGLE
// ============================================================
void drawDeltaTriangle() {
  float dx = bx - ax;
  float dy = by - ay;

  // Do not render triangle if points overlap
  if (abs(dx) < 0.001) return;

  // Corner C has x of B and y of A: C = (bx, ay)
  float sax = mathToScreenX(ax);
  float say = mathToScreenY(ay);
  float sbx = mathToScreenX(bx);
  float sby = mathToScreenY(by);
  float scx = sbx;
  float scy = say;

  // 1. Shaded triangle area
  fill(240, 120, 30, 35);
  noStroke();
  triangle(sax, say, scx, scy, sbx, sby);

  // 2. Legs of the triangle
  stroke(220, 90, 20);
  strokeWeight(2.5);

  // Horizontal leg (Δx)
  line(sax, say, scx, scy);

  // Vertical leg (Δy)
  line(scx, scy, sbx, sby);

  // 3. Right-angle symbol at C
  float marker = 12;
  float dirX = (ax < bx) ? -marker : marker;
  float dirY = (ay < by) ? -marker : marker;

  noFill();
  stroke(180, 70, 10);
  strokeWeight(1.5);
  line(scx + dirX, scy, scx + dirX, scy + dirY);
  line(scx + dirX, scy + dirY, scx, scy + dirY);

  // 4. Leg Labels (Δx and Δy)
  fill(180, 60, 10);
  textSize(15);

  // Δx Label positioned along horizontal leg
  float midX = (sax + scx) / 2.0;
  float offsetY = (ay >= by) ? 18 : -10;
  text("Δx = " + nf(dx, 1, 2), midX, scy + offsetY);

  // Δy Label positioned along vertical leg
  float midY = (scy + sby) / 2.0;
  float offsetX = (ax <= bx) ? 38 : -38;
  text("Δy = " + nf(dy, 1, 2), scx + offsetX, midY);
}

// ============================================================
// FUNCTION EVALUATION
// ============================================================
float functionValue(float x) {
  if (functionType == 1) { // PARABOLA
    return x * x;
  }
  if (functionType == 2) { // CUBIC
    return x * x * x;
  }
  return 0.8 * x + 1;      // LINEAR
}

// ============================================================
// DERIVATIVE EVALUATION
// ============================================================
float derivative(float x) {
  if (functionType == 1) { // d/dx (x²)
    return 2 * x;
  }
  if (functionType == 2) { // d/dx (x³)
    return 3 * x * x;
  }
  return 0.8;             // d/dx (0.8x + 1)
}

// ============================================================
// SECANT LINE
// ============================================================
void drawSecant() {
  float dx = bx - ax;
  float secantSlope;

  // Avoid division by zero
  if (abs(dx) < 0.0001) {
    secantSlope = derivative(ax);
  } else {
    secantSlope = (by - ay) / (bx - ax);
  }

  // Equation: y = m(x - ax) + ay
  float x1 = xMin;
  float x2 = xMax;
  float y1 = secantSlope * (x1 - ax) + ay;
  float y2 = secantSlope * (x2 - ax) + ay;

  stroke(220, 80, 30);
  strokeWeight(4);
  line(mathToScreenX(x1), mathToScreenY(y1), mathToScreenX(x2), mathToScreenY(y2));

  // Label
  fill(210, 60, 20);
  textSize(18);
  text("SECANT", width - 90, graphTop + 25);
}

// ============================================================
// TANGENT LINE
// ============================================================
void drawTangent() {
  float m = derivative(ax);

  // Equation: y = m(x - ax) + ay
  float x1 = xMin;
  float x2 = xMax;
  float y1 = m * (x1 - ax) + ay;
  float y2 = m * (x2 - ax) + ay;

  stroke(40, 150, 70);
  strokeWeight(4);
  line(mathToScreenX(x1), mathToScreenY(y1), mathToScreenX(x2), mathToScreenY(y2));

  // Label
  fill(30, 130, 60);
  textSize(18);
  text("TANGENT", width - 90, graphTop + 50);
}

// ============================================================
// POINT A
// ============================================================
void drawPointA() {
  float sx = mathToScreenX(ax);
  float sy = mathToScreenY(ay);

  fill(30, 170, 70);
  stroke(255);
  strokeWeight(3);
  ellipse(sx, sy, 32, 32);

  fill(20);
  textSize(20);
  text("A", sx, sy - 28);
}

// ============================================================
// POINT B
// ============================================================
void drawPointB() {
  float sx = mathToScreenX(bx);
  float sy = mathToScreenY(by);

  fill(220, 60, 40);
  stroke(255);
  strokeWeight(3);
  ellipse(sx, sy, 32, 32);

  fill(20);
  textSize(20);
  text("B", sx, sy - 28);
}

// ============================================================
// INFORMATION PANEL
// ============================================================
void drawInformation() {
  float dx = bx - ax;
  float dy = by - ay;
  float secantSlope;

  if (abs(dx) < 0.0001) {
    secantSlope = derivative(ax);
  } else {
    secantSlope = dy / dx;
  }
  float tangentSlope = derivative(ax);

  // ----------------------------------------------------------
  // PANEL BACKGROUND
  // ----------------------------------------------------------
  fill(255);
  stroke(180);
  strokeWeight(1);
  rect(width * 0.04, height * 0.80, width * 0.92, height * 0.14, 15);

  fill(30);
  textSize(17);

  // Coordinates
  text("A = (" + nf(ax, 1, 2) + ", " + nf(ay, 1, 2) + ")", width * 0.25, height * 0.825);
  text("B = (" + nf(bx, 1, 2) + ", " + nf(by, 1, 2) + ")", width * 0.75, height * 0.825);

  // Slopes and Rate of Change
  textSize(16);
  text("Secant slope (Δy/Δx) = " + nf(secantSlope, 1, 3), width * 0.33, height * 0.865);
  text("Tangent slope (dy/dx) = " + nf(tangentSlope, 1, 3), width * 0.73, height * 0.865);

  // Distance between x-coordinates
  fill(80);
  textSize(15);
  text("|Δx| = " + nf(abs(dx), 1, 3) + "   |   |Δy| = " + nf(abs(dy), 1, 3), width / 2, height * 0.905);
}

// ============================================================
// UI BUTTONS
// ============================================================
void drawHomeButton() {
  fill(60);
  rect(20, 20, 90, 45, 12);
  fill(255);
  textSize(17);
  text("HOME", 65, 42);
}

void drawResetButton() {
  float bxButton = width - 125;
  fill(60);
  rect(bxButton, 20, 105, 45, 12);
  fill(255);
  textSize(17);
  text("RESET", bxButton + 52, 42);
}

// ============================================================
// COORDINATE CONVERSIONS
// ============================================================
float mathToScreenX(float x) {
  return map(x, xMin, xMax, graphLeft, graphRight);
}

float mathToScreenY(float y) {
  return map(y, yMin, yMax, graphBottom, graphTop);
}

float screenToMathX(float sx) {
  return map(sx, graphLeft, graphRight, xMin, xMax);
}

// ============================================================
// MOUSE / TOUCH EVENTS
// ============================================================
void mousePressed() {
  // ----------------------------------------------------------
  // HOME SCREEN TOUCHES
  // ----------------------------------------------------------
  if (screen == 0) {
    // Parabola
    if (mouseX > width * 0.10 && mouseX < width * 0.90 && mouseY > 185 && mouseY < 275) {
      screen = 1;
      resetPoints();
      return;
    }
    // Cubic
    if (mouseX > width * 0.10 && mouseX < width * 0.90 && mouseY > 315 && mouseY < 405) {
      screen = 2;
      resetPoints();
      return;
    }
    // Linear
    if (mouseX > width * 0.10 && mouseX < width * 0.90 && mouseY > 445 && mouseY < 535) {
      screen = 3;
      resetPoints();
      return;
    }
    return;
  }

  // ----------------------------------------------------------
  // HOME BUTTON TOUCH
  // ----------------------------------------------------------
  if (mouseX >= 20 && mouseX <= 110 && mouseY >= 20 && mouseY <= 70) {
    screen = 0;
    return;
  }

  // ----------------------------------------------------------
  // RESET BUTTON TOUCH
  // ----------------------------------------------------------
  if (mouseX >= width - 125 && mouseX <= width - 20 && mouseY >= 20 && mouseY <= 70) {
    resetPoints();
    return;
  }

  // ----------------------------------------------------------
  // POINT A SELECTION
  // ----------------------------------------------------------
  float screenAX = mathToScreenX(ax);
  float screenAY = mathToScreenY(ay);
  float distA = dist(mouseX, mouseY, screenAX, screenAY);
  if (distA < touchRadius) {
    draggingA = true;
    return;
  }

  // ----------------------------------------------------------
  // POINT B SELECTION
  // ----------------------------------------------------------
  float screenBX = mathToScreenX(bx);
  float screenBY = mathToScreenY(by);
  float distB = dist(mouseX, mouseY, screenBX, screenBY);
  if (distB < touchRadius) {
    draggingB = true;
    return;
  }
}

void mouseDragged() {
  if (screen == 0) {
    return;
  }

  // Drag Point A
  if (draggingA) {
    ax = screenToMathX(mouseX);
    ax = constrain(ax, xMin, xMax);
    return;
  }

  // Drag Point B
  if (draggingB) {
    bx = screenToMathX(mouseX);
    bx = constrain(bx, xMin, xMax);
    return;
  }
}

void mouseReleased() {
  draggingA = false;
  draggingB = false;
}

// ============================================================
// RESET POINTS
// ============================================================
void resetPoints() {
  ax = -2.0;
  bx = 2.0;
}
