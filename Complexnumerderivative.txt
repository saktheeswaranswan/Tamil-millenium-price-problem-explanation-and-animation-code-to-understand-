Complex numbers derivative


// Conformal Mapping & Secant Slope Triangle App for APDE (Android)
// Left side: Z-plane (Input). Right side: W-plane (Output).
// Mapping: w = f(z) = z^2

int state = 0; // 0: wait A, 1: wait B, 2: curves active
PVector ptA, ptB;

// Sliders
Slider curveSlider;
Slider t1Slider;
Slider t2Slider;

float scaleFactor;

void setup() {
  fullScreen();
  orientation(LANDSCAPE);
  smooth();
  
  // Scale factor for coordinate conversion (pixels per math unit)
  scaleFactor = min(width / 4f, height / 2f) * 0.6f;
  
  // Initialize Sliders
  // Curve selector on the left
  float sW = width / 3f;
  curveSlider = new Slider(20, height - 60, sW, 30, 0.0f, 1.0f, 0.5f, "Change Curve Path");
  
  // Point 1 and Point 2 sliders on the right
  float tW = width / 2.5f;
  float tX = width - tW - 20;
  t1Slider = new Slider(tX, height - 90, tW, 30, 0.0f, 1.0f, 0.3f, "Move Point 1 (t1)");
  t2Slider = new Slider(tX, height - 40, tW, 30, 0.0f, 1.0f, 0.7f, "Move Point 2 (t2)");
}

void draw() {
  background(245);
  
  drawEnvironment();
  
  // Top UI Button
  drawButton(20, 20, 100, 40, "CLEAR", color(220));
  
  if (state == 0) {
    fill(50);
    textSize(displayDensity * 16);
    textAlign(CENTER, TOP);
    text("Tap a STARTING point on the left side (Z-Plane)", width / 4f, height / 2f + 50);
  } 
  else if (state == 1) {
    drawPointLeft(ptA, color(0, 150, 0), "A");
    fill(50);
    textSize(displayDensity * 16);
    textAlign(CENTER, TOP);
    text("Tap an ENDING point on the left side (Z-Plane)", width / 4f, height / 2f + 50);
  } 
  else if (state == 2) {
    // 1. Draw endpoints
    drawPointLeft(ptA, color(0, 150, 0), "A");
    drawPointLeft(ptB, color(0, 150, 0), "B");
    
    // 2. Draw Faint Background Curves
    for (float s = 0.1f; s <= 0.9f; s += 0.1f) {
      if (abs(s - curveSlider.val) > 0.05f) {
        ArrayList<PVector> faintCurve = generateCurve(ptA, ptB, s);
        drawMappedStroke(faintCurve, color(180, 180, 255), color(255, 180, 180), 1);
      }
    }
    
    // 3. Draw Selected Active Curve
    ArrayList<PVector> activeCurve = generateCurve(ptA, ptB, curveSlider.val);
    drawMappedStroke(activeCurve, color(0, 100, 255), color(255, 50, 0), 3);
    
    // 4. Calculate the two movable points on the curve
    PVector z1 = getCurvePoint(ptA, ptB, curveSlider.val, t1Slider.val);
    PVector z2 = getCurvePoint(ptA, ptB, curveSlider.val, t2Slider.val);
    
    PVector w1 = complexSq(z1);
    PVector w2 = complexSq(z2);
    
    // 5. Draw the Slope Triangles and Secant Lines
    drawSlopeTriangle(z1, z2, false); // Left side (Z-plane)
    drawSlopeTriangle(w1, w2, true);  // Right side (W-plane)
    
    // 6. Draw the actual points on top
    drawMovingPoint(z1, w1, color(0, 0, 200), "P1");
    drawMovingPoint(z2, w2, color(150, 0, 200), "P2");
    
    // 7. Draw Sliders
    curveSlider.display();
    t1Slider.display();
    t2Slider.display();
  }
}

// --- Math & Complex Plane Functions ---

PVector complexSq(PVector z) {
  // w = z^2 = (x + iy)^2 = (x^2 - y^2) + i(2xy)
  return new PVector(z.x * z.x - z.y * z.y, 2 * z.x * z.y);
}

// Generates a Quadratic Bezier curve in the complex plane
ArrayList<PVector> generateCurve(PVector A, PVector B, float sVal) {
  ArrayList<PVector> pts = new ArrayList<PVector>();
  int resolution = 50;
  for (int i = 0; i <= resolution; i++) {
    float t = i / (float) resolution;
    pts.add(getCurvePoint(A, B, sVal, t));
  }
  return pts;
}

PVector getCurvePoint(PVector A, PVector B, float sVal, float t) {
  float s = (sVal - 0.5f) * 4.0f; 
  PVector M = new PVector((A.x + B.x) / 2f, (A.y + B.y) / 2f);
  float dx = B.x - A.x;
  float dy = B.y - A.y;
  PVector N = new PVector(-dy, dx);
  PVector C = new PVector(M.x + s * N.x, M.y + s * N.y);
  
  float mt = 1 - t;
  float x = (mt * mt * A.x) + (2 * mt * t * C.x) + (t * t * B.x);
  float y = (mt * mt * A.y) + (2 * mt * t * C.y) + (t * t * B.y);
  return new PVector(x, y);
}

// --- Drawing Functions ---

void drawEnvironment() {
  // Divider
  stroke(150);
  strokeWeight(4);
  line(width / 2f, 0, width / 2f, height);
  
  drawAxes(width / 4f, "Real (x)", "Imag (iy)", "Input Z-Plane");
  drawAxes(3 * width / 4f, "Real (u)", "Imag (iv)", "Output W-Plane (w=z²)");
}

void drawAxes(float offsetX, String labelX, String labelY, String title) {
  pushMatrix();
  translate(offsetX, height / 2f);
  stroke(200);
  strokeWeight(2);
  line(-width / 4f, 0, width / 4f, 0); 
  line(0, -height / 2f, 0, height / 2f); 
  fill(100);
  textSize(displayDensity * 12);
  textAlign(RIGHT, BOTTOM);
  text(labelX, width / 4f - 10, -5);
  textAlign(LEFT, TOP);
  text(labelY, 5, -height / 2f + 10);
  popMatrix();
  
  fill(50);
  textSize(displayDensity * 16); 
  textAlign(CENTER, TOP);
  text(title, offsetX, 20);
}

void drawMappedStroke(ArrayList<PVector> pts, int colIn, int colOut, float wt) {
  if (pts.size() < 2) return;
  // Z-Plane
  noFill();
  strokeWeight(displayDensity * wt);
  stroke(colIn);
  beginShape();
  for (PVector p : pts) {
    PVector s = complexToLeftScreen(p);
    vertex(s.x, s.y);
  }
  endShape();
  // W-Plane
  stroke(colOut);
  beginShape();
  for (PVector p : pts) {
    PVector w = complexSq(p);
    PVector s = complexToRightScreen(w);
    vertex(s.x, s.y);
  }
  endShape();
}

void drawPointLeft(PVector z, int col, String label) {
  PVector zScreen = complexToLeftScreen(z);
  noStroke();
  fill(col);
  ellipse(zScreen.x, zScreen.y, displayDensity * 10, displayDensity * 10);
  fill(0);
  textSize(displayDensity * 14);
  textAlign(LEFT, BOTTOM);
  text(label, zScreen.x + 5, zScreen.y - 5);
}

void drawMovingPoint(PVector z, PVector w, int col, String label) {
  PVector zs = complexToLeftScreen(z);
  PVector ws = complexToRightScreen(w);
  fill(col);
  noStroke();
  ellipse(zs.x, zs.y, displayDensity * 12, displayDensity * 12);
  ellipse(ws.x, ws.y, displayDensity * 12, displayDensity * 12);
  
  fill(0);
  textSize(displayDensity * 12);
  textAlign(CENTER, BOTTOM);
  text(label, zs.x, zs.y - 10);
  text(label + "'", ws.x, ws.y - 10);
}

void drawSlopeTriangle(PVector mathP1, PVector mathP2, boolean isWPlane) {
  PVector s1 = isWPlane ? complexToRightScreen(mathP1) : complexToLeftScreen(mathP1);
  PVector s2 = isWPlane ? complexToRightScreen(mathP2) : complexToLeftScreen(mathP2);
  
  // 1. Draw Secant Line (Hypotenuse)
  stroke(0, 180, 0);
  strokeWeight(displayDensity * 2);
  line(s1.x, s1.y, s2.x, s2.y);
  
  // 2. Draw Triangle Legs (Horizontal & Vertical)
  stroke(100, 100, 100);
  strokeWeight(displayDensity * 1.5f);
  // Drawing dashed-style conceptually by making it slightly transparent
  stroke(0, 150, 0, 150);
  line(s1.x, s1.y, s2.x, s1.y); // Horizontal leg
  line(s2.x, s1.y, s2.x, s2.y); // Vertical leg
  
  // 3. Math Distances for Text Labels
  float deltaX = mathP2.x - mathP1.x;
  float deltaY = mathP2.y - mathP1.y;
  
  fill(0, 100, 0);
  textSize(displayDensity * 12);
  textAlign(CENTER, CENTER);
  
  // Determine placement offsets so text doesn't overlap lines
  float midX = (s1.x + s2.x) / 2f;
  float midY = (s1.y + s2.y) / 2f;
  
  if (isWPlane) {
    text("Δu = " + nf(deltaX, 0, 2), midX, s1.y + (s2.y > s1.y ? -12 : 12));
    textAlign(LEFT, CENTER);
    text("Δv = " + nf(deltaY, 0, 2), s2.x + 8, midY);
  } else {
    text("Δx = " + nf(deltaX, 0, 2), midX, s1.y + (s2.y > s1.y ? -12 : 12));
    textAlign(LEFT, CENTER);
    text("Δy = " + nf(deltaY, 0, 2), s2.x + 8, midY);
  }
}

// --- UI & Interactions ---

void drawButton(float x, float y, float w, float h, String label, int col) {
  fill(col);
  stroke(100);
  strokeWeight(2);
  rect(x * displayDensity, y * displayDensity, w * displayDensity, h * displayDensity, 10);
  fill(0);
  textSize(displayDensity * 14);
  textAlign(CENTER, CENTER);
  text(label, (x + w/2) * displayDensity, (y + h/2) * displayDensity - 2);
}

boolean overButton(float mx, float my, float x, float y, float w, float h) {
  x *= displayDensity; y *= displayDensity; w *= displayDensity; h *= displayDensity;
  return mx > x && mx < x + w && my > y && my < y + h;
}

void mousePressed() {
  if (overButton(mouseX, mouseY, 20, 20, 100, 40)) {
    state = 0; ptA = null; ptB = null;
    return;
  }
  
  if (state == 2) {
    if (curveSlider.checkPress(mouseX, mouseY)) return;
    if (t1Slider.checkPress(mouseX, mouseY)) return;
    if (t2Slider.checkPress(mouseX, mouseY)) return;
  }
  
  // Plotting points on left screen
  if (mouseX < width / 2f && state < 2) {
    PVector tap = screenToComplex(mouseX, mouseY);
    if (state == 0) {
      ptA = tap;
      state = 1;
    } else if (state == 1) {
      ptB = tap;
      state = 2;
    }
  }
}

void mouseDragged() {
  if (state == 2) {
    curveSlider.drag(mouseX);
    t1Slider.drag(mouseX);
    t2Slider.drag(mouseX);
  }
}

void mouseReleased() {
  if (state == 2) {
    curveSlider.release();
    t1Slider.release();
    t2Slider.release();
  }
}

// --- Coordinate Converters ---
PVector screenToComplex(float x, float y) {
  float cx = (x - (width / 4f)) / scaleFactor;
  float cy = ((height / 2f) - y) / scaleFactor;
  return new PVector(cx, cy);
}
PVector complexToLeftScreen(PVector c) {
  return new PVector((width / 4f) + (c.x * scaleFactor), (height / 2f) - (c.y * scaleFactor));
}
PVector complexToRightScreen(PVector c) {
  return new PVector((3 * width / 4f) + (c.x * scaleFactor), (height / 2f) - (c.y * scaleFactor));
}

// --- Slider Class ---
class Slider {
  float x, y, w, h, min, max, val;
  String label;
  boolean dragging = false;
  
  Slider(float _x, float _y, float _w, float _h, float _min, float _max, float _start, String _label) {
    x = _x; y = _y; w = _w; h = _h; min = _min; max = _max; val = _start; label = _label;
  }
  
  void display() {
    stroke(150); strokeWeight(displayDensity * 4);
    line(x, y, x + w, y);
    
    float handleX = x + map(val, min, max, 0, w);
    fill(dragging ? color(100, 200, 100) : color(100));
    noStroke();
    ellipse(handleX, y, displayDensity * 20, displayDensity * 20);
    
    fill(50); textSize(displayDensity * 12); textAlign(CENTER, BOTTOM);
    text(label, x + w/2, y - 15);
  }
  
  boolean checkPress(float mx, float my) {
    if (mx > x - 20 && mx < x + w + 20 && my > y - 30 && my < y + 30) {
      dragging = true;
      drag(mx);
      return true;
    }
    return false;
  }
  
  void drag(float mx) {
    if (dragging) val = constrain(map(mx, x, x + w, min, max), min, max);
  }
  
  void release() { dragging = false; }
}
