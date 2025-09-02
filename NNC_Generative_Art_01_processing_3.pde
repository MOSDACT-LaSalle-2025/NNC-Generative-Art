/* 
Name:Nancy El Azzi
Date: September 2, 2025
Place of production: Barcelona

Description:
Circles grid with ripple effect that reacts to mouse position. 
Modifiable radius range, speed and wave density, stroke also gets thinner the further you are from the mouse.

My approach was to explore a parametric system. 
I wanted to create some type of ripple effect that would move with the mouse position.
The goal was to create something mesmerizing and simple that viewers play with using their mouse and some parameters.


Instructions:
- SPACE = play/pause animation
- LEFT / RIGHT = speed -, +
- UP / DOWN = wave density +, -
- SHIFT + LEFT / RIGHT = stroke wight concetrates around mouse -, +
- SHIFT + UP / DOWN = feather -, +
- [ / ] = decrease/increase MAX diameter
- { / } = decrease/increase MIN diameter
- Hold mouse = strobe flash
- SAVE PNG button or press S
- START/STOP MP4 button or press V
*/

import controlP5.*;
import com.hamoid.*;
VideoExport video;
boolean recording = false;

// Canvas
final int ART_W = 700;
final int ART_H = 700;
final int UI_H  = 200;

void settings() {
  size(ART_W, ART_H + UI_H, P2D);
  smooth(8);
}

// UI
ControlP5 cp5;
Slider speedSlider, waveSlider, clearSlider, featherSlider;
Range diameterRange;
Toggle animateToggle;
Button saveBtn, recBtn;

Textlabel lblSpeed, lblWave, lblClear, lblFeather, lblRange;

final int ORANGE = color(255, 100, 33);

// Grid / wave
int nb = 25;
float dim = 0;
int margin = 50;

float phaseDeg = 0;
float speedDeg = 2.0;     // internal state mirrors slider
float waveDegPerPx = 1.0; // internal state mirrors slider

// distance-based softening
float CLEAR_RADIUS = 30;
float FEATHER      = 250;
float NEAR_WEIGHT  = 2;
float FAR_WEIGHT   = 0.5;
int   NEAR_ALPHA   = 220;
int   FAR_ALPHA    = 100;

// diameter range
float minDiamPx = 0.1f;
float maxDiamPx = 150f;

// bracket step limits
final float RANGE_MIN = 0.1f;
final float RANGE_MAX = 500f;
final float RANGE_STEP = 5f;
final float RANGE_GAP  = 1f;

boolean animate = true;

// strobe (mouse-held flashes)
int STROBE_ALPHA   = 180; // flash intensity
final int STROBE_PERIOD = 7; // frames per cycle
final int STROBE_ON     = 2;  // frames ON per cycle

void setup() {
  frameRate(60);
  dim = (ART_W - 2 * margin) / (float) nb;
  setupUI();
}

void setupUI() {
  cp5 = new ControlP5(this);
  cp5.setColorForeground(ORANGE);
  cp5.setColorActive(ORANGE);
  cp5.setColorBackground(color(40));
  cp5.setColorCaptionLabel(ORANGE);
  cp5.setColorValueLabel(ORANGE);
  cp5.setAutoDraw(true);

  int x = 16, yTop = ART_H + 16, w = 260, h = 16, gap = 16, lab = 12;

  // SPEED
  lblSpeed = cp5.addTextlabel("lblSpeed").setPosition(x, yTop)
               .setText("SPEED (L/R arrows)").setColorValue(ORANGE);
  speedSlider = cp5.addSlider("speedDeg")         
                   .setLabel("")                  // no label next to slider
                   .setPosition(x, yTop + lab)
                   .setSize(w, h)
                   .setRange(0, 10)
                   .setValue(speedDeg);

  // WAVE DENSITY
  int y1 = yTop + lab + h + gap;
  lblWave = cp5.addTextlabel("lblWave").setPosition(x, y1)
               .setText("WAVE FQCY (U/D arrows)").setColorValue(ORANGE);
  waveSlider = cp5.addSlider("waveDegPerPx")
                  .setLabel("")
                  .setPosition(x, y1 + lab)
                  .setSize(w, h)
                  .setRange(0.1f, 5.0f)
                  .setValue(waveDegPerPx);

  // CLEAR RADIUS
  int y2 = y1 + lab + h + gap;
  lblClear = cp5.addTextlabel("lblClear").setPosition(x, y2)
               .setText("CLEAR RADIUS (SHIFT + L/R)").setColorValue(ORANGE);
  clearSlider = cp5.addSlider("CLEAR_RADIUS")
                   .setLabel("")
                   .setPosition(x, y2 + lab)
                   .setSize(w, h)
                   .setRange(0, 300)
                   .setValue(CLEAR_RADIUS);

  // FEATHER
  int y3 = y2 + lab + h + gap;
  lblFeather = cp5.addTextlabel("lblFeather").setPosition(x, y3)
                 .setText("FEATHER (SHIFT + U/D)").setColorValue(ORANGE);
  featherSlider = cp5.addSlider("FEATHER")
                     .setLabel("")
                     .setPosition(x, y3 + lab)
                     .setSize(w, h)
                     .setRange(0, 500)
                     .setValue(FEATHER);

  // DIAMETER RANGE
  int xR = x + w + 60;
  lblRange = cp5.addTextlabel("lblRange").setPosition(xR, yTop)
               .setText("DIAMETER RANGE  ([/]=MAX  {/}=MIN)").setColorValue(ORANGE);
  diameterRange = cp5.addRange("diameterRange")
                     .setLabel("")
                     .setPosition(xR, yTop + lab)
                     .setSize(w, h)
                     .setRange(RANGE_MIN, RANGE_MAX)
                     .setRangeValues(minDiamPx, maxDiamPx);

  // PLAY/PAUSE
  animateToggle = cp5.addToggle("animate")
                     .setPosition(xR, y3 + lab)
                     .setSize(120, 28)
                     .setValue(animate);
  animateToggle.getCaptionLabel().align(ControlP5.CENTER, ControlP5.CENTER);
  updatePlayPauseCaption();

  // Buttons
  saveBtn = cp5.addButton("savePNG")
               .setPosition(xR + 140, y3 + lab)
               .setSize(100, 28)
               .setCaptionLabel("SAVE PNG (S)");
  recBtn  = cp5.addButton("toggleVideo")
               .setPosition(xR + 250, y3 + lab)
               .setSize(140, 28)
               .setCaptionLabel("START/STOP rec (V)");
}

void updatePlayPauseCaption() {
  animateToggle.setCaptionLabel(animate ? "PAUSE (space)" : "PLAY (space)");
  animateToggle.getCaptionLabel().setColor(animate ? color(0) : ORANGE);
}

void draw() {
  // top art area
  noStroke(); fill(0); rect(0, 0, ART_W, ART_H);

  // read slider states (dragging)
  speedDeg     = speedSlider.getValue();
  waveDegPerPx = waveSlider.getValue();
  CLEAR_RADIUS = clearSlider.getValue();
  FEATHER      = featherSlider.getValue();
  minDiamPx    = diameterRange.getLowValue();
  maxDiamPx    = diameterRange.getHighValue();

  if (animate) phaseDeg += speedDeg;

  // artwork
  noFill();
  for (float j = 1; j < nb; j += 1.6) {
    for (int i = 0; i < nb; i++) {
      float x = margin + dim/2f + i * dim;
      float y = margin + dim/2f + j * dim;
      if (y > ART_H - margin) continue;

      float dMouse = dist(mouseX, mouseY, x, y);
      float angleDeg = waveDegPerPx * dMouse - phaseDeg - 1;
      float wave01 = 0.5f * (sin(radians(angleDeg)) + 1.0f); 
      float d = lerp(minDiamPx, maxDiamPx, wave01);

      float t = dMouse > CLEAR_RADIUS ? constrain((dMouse - CLEAR_RADIUS) / FEATHER, 0, 1) : 0;
      float sw = lerp(NEAR_WEIGHT, FAR_WEIGHT, t);
      float a  = lerp(NEAR_ALPHA,  FAR_ALPHA,  t);

      stroke(ORANGE, a);
      strokeWeight(sw);
      ellipse(x, y, d, d);
    }
  }

  // strobe flashes while mouse is held
  if (mousePressed) {
    if (frameCount % STROBE_PERIOD < STROBE_ON) {
      blendMode(EXCLUSION); // keeps artwork visible
      noStroke();
      fill(255, STROBE_ALPHA);
      rect(0, 0, ART_W, ART_H);
      blendMode(BLEND);
    }
  }

  // record video
  if (recording && video != null) {
    try { 
      video.saveFrame(); 
    } catch (Exception ex) { 
      println("video save err: " + ex.getMessage()); 
      stopRecording(); 
    }
  }

  // UI strip
  noStroke(); fill(0); rect(0, ART_H, width, UI_H);
  stroke(ORANGE, 160); line(0, ART_H, width, ART_H);
}

void controlEvent(ControlEvent e) {
  if (e.isFrom(diameterRange)) {
    minDiamPx = diameterRange.getLowValue();
    maxDiamPx = diameterRange.getHighValue();
  }
  if (e.isFrom(animateToggle)) {
    animate = animateToggle.getState();
    updatePlayPauseCaption();
  }
}

// buttons
public void savePNG() { 
  saveFrame("NNC-Generative-Art-static-####.png"); 
}
public void toggleVideo() { 
  if (!recording) startRecording(); 
  else stopRecording(); 
}

// keys (keep sliders & keys in sync)
void keyPressed() {
  boolean shift = keyEvent != null && keyEvent.isShiftDown();

  if (keyCode == LEFT && !shift) { speedDeg = max(0, speedDeg - 0.2); speedSlider.setValue(speedDeg); }
  else if (keyCode == RIGHT && !shift) { speedDeg += 0.2; speedSlider.setValue(speedDeg); }

  if (keyCode == UP && !shift) { waveDegPerPx = max(0.1, waveDegPerPx + 0.1); waveSlider.setValue(waveDegPerPx); }
  else if (keyCode == DOWN && !shift) { waveDegPerPx = max(0.1, waveDegPerPx - 0.1); waveSlider.setValue(waveDegPerPx); }

  if (keyCode == LEFT && shift) { CLEAR_RADIUS = max(0, CLEAR_RADIUS - 5); clearSlider.setValue(CLEAR_RADIUS); }
  else if (keyCode == RIGHT && shift) { CLEAR_RADIUS += 5; clearSlider.setValue(CLEAR_RADIUS); }

  if (keyCode == UP && shift) { FEATHER = max(0, FEATHER - 5); featherSlider.setValue(FEATHER); }
  else if (keyCode == DOWN && shift) { FEATHER += 5; featherSlider.setValue(FEATHER); }

  if (key == '[') { maxDiamPx = max(minDiamPx + RANGE_GAP, maxDiamPx - RANGE_STEP); diameterRange.setRangeValues(minDiamPx, maxDiamPx); }
  if (key == ']') { maxDiamPx = min(RANGE_MAX, maxDiamPx + RANGE_STEP); diameterRange.setRangeValues(minDiamPx, maxDiamPx); }
  if (key == '{') { minDiamPx = max(RANGE_MIN, minDiamPx - RANGE_STEP); if (minDiamPx > maxDiamPx - RANGE_GAP) minDiamPx = maxDiamPx - RANGE_GAP; diameterRange.setRangeValues(minDiamPx, maxDiamPx); }
  if (key == '}') { minDiamPx = min(maxDiamPx - RANGE_GAP, minDiamPx + RANGE_STEP); diameterRange.setRangeValues(minDiamPx, maxDiamPx); }

  if (key == ' ') { animate = !animate; animateToggle.setState(animate); updatePlayPauseCaption(); }
  if (key == 's' || key == 'S') savePNG();
  if (key == 'v' || key == 'V') toggleVideo();
}

// video helpers (safe path + timestamp filename)
void startRecording() {
  try {
    // ensure exports folder exists
    java.io.File dir = new java.io.File(sketchPath("exports"));
    if (!dir.exists()) dir.mkdirs();

    String timestamp = 
      nf(year(),4) + "-" + nf(month(),2) + "-" + nf(day(),2) + "_" +
      nf(hour(),2) + "-" + nf(minute(),2) + "-" + nf(second(),2);

    String fname = sketchPath("exports/NNC-Generative-Art-video-" + timestamp + ".mp4");

    video = new VideoExport(this, fname);
    video.setFrameRate(60);
    // video.setQuality(90); // optional
    video.startMovie();
    recording = true;
    println("Video recording started: " + fname);
  } catch (Exception ex) {
    println("VideoExport start error: " + ex.getMessage());
    recording = false;
  }
}

void stopRecording() {
  try {
    recording = false;
    if (video != null) {
      video.endMovie();
      println("Video saved.");
    }
  } catch (Exception ex) {
    println("VideoExport stop error: " + ex.getMessage());
  }
}
