int n = 1000;
int m = 2;
final float dt = 0.02;
final float frictionHalfLife = 0.040;
float rMax = 0.2;
float[][] matrix;

final float frictionFactor = pow(0.5, dt / frictionHalfLife);
float forceFactor = 10;

boolean isView3D = true;
boolean showOctree = false;
boolean pause = false;
boolean wrap = true;

Octree octree;
Volume volume;

SliderWindow sliderWindow;

float[][] makeRandomMatrix() {
  float[][] rows = new float[m][m];
  for (int i=0; i<m; i++) {
    float[] row = new float[m];
    for (int j=0; j<m; j++) {
      row[j] = random(1.0)*2-1;
    }
    rows[i] = row;
  }
  return rows;
}

int[] colors = new int[n];
float[] positionsX = new float[n];
float[] positionsY = new float[n];
float[] positionsZ = new float[n];
float[] velocitiesX = new float[n];
float[] velocitiesY = new float[n];
float[] velocitiesZ = new float[n];

void setup() {
  size(640, 640, P3D);
  surface.setResizable(true);
  frameRate(100);

  colorMode(RGB);

  sliderWindow = new SliderWindow(width - 350, 50, 300, color(50), "Config");
  sliderWindow.addSlider(new Slider(20, 10, 25000, n, color(0, 127, 200), "n", 0));
  sliderWindow.addSlider(new Slider(20, 1, 1000, m, color(200, 0, 127), "m", 0));
  sliderWindow.addSlider(new Slider(20, .01, .5, rMax, color(127, 200, 0), "rMax", 1));
  sliderWindow.addSlider(new Slider(20, 0, 200, forceFactor, color(255, 0, 0), "forceFactor", 1));

  colorMode(HSB);
  sphereDetail(1);

  matrix = makeRandomMatrix();
  colors = new int[n];
  positionsX = new float[n];
  positionsY = new float[n];
  positionsZ = new float[n];
  velocitiesX = new float[n];
  velocitiesY = new float[n];
  velocitiesZ = new float[n];

  for (int i=0; i<n; i++) {
    colors[i] = floor(random(1.0)*m);
    positionsX[i] = random(1.0);
    positionsY[i] = random(1.0);
    positionsZ[i] = random(1.0);
    velocitiesX[i] = 0;
    velocitiesY[i] = 0;
    velocitiesZ[i] = 0;
  }
}

float force(float r, float a) {
  final float beta = 0.3;
  if      (r<beta)        return r/beta-1;
  else if (r>beta && r<1) return a*(1-abs(2*r-1-beta)/(1-beta));
  else                    return 0;
}

void updateParticles() {
  float startTime = millis();
  for (int i=0; i<n; i++) {
    float totalForceX = 0;
    float totalForceY = 0;
    float totalForceZ = 0;

    //for (int j=0; j<n; j++) {
    //  if (j==i) continue;
    //  float rx = positionsX[j] - positionsX[i];
    //  float ry = positionsY[j] - positionsY[i];
    //  float rz = positionsZ[j] - positionsZ[i];

    //  if (rx > 0.5) rx -= 1.0;
    //  else if (rx < -0.5) rx += 1.0;
    //  if (ry > 0.5) ry -= 1.0;
    //  else if (ry < -0.5) ry += 1.0;
    //  if (rz > 0.5) rz -= 1.0;
    //  else if (rz < -0.5) rz += 1.0;

    //  float r  = sqrt(rx*rx + ry*ry + rz*rz);
    //  if (r>0 && r<rMax) {
    //    float f = force(r / rMax, matrix[colors[i]][colors[j]]);
    //    totalForceX += rx/r*f;
    //    totalForceY += ry/r*f;
    //    totalForceZ += rz/r*f;
    //  }
    //}


    ArrayList<Point> points = new ArrayList<>();
    ArrayList<Volume> queryRanges = new ArrayList<>();

    // Add the main query range
    queryRanges.add(new Volume(positionsX[i] - rMax, positionsY[i] - rMax, positionsZ[i] - rMax, rMax * 2, rMax * 2, rMax * 2));

    // Add wrap-around queries if wrap is enabled
    if (wrap) {
      if (positionsX[i] - rMax < 0) {
        queryRanges.add(new Volume(positionsX[i] - rMax + 1, positionsY[i] - rMax, positionsZ[i] - rMax, rMax * 2, rMax * 2, rMax * 2));
      }
      if (positionsX[i] + rMax > 1) {
        queryRanges.add(new Volume(positionsX[i] - rMax - 1, positionsY[i] - rMax, positionsZ[i] - rMax, rMax * 2, rMax * 2, rMax * 2));
      }
      if (positionsY[i] - rMax < 0) {
        queryRanges.add(new Volume(positionsX[i] - rMax, positionsY[i] - rMax + 1, positionsZ[i] - rMax, rMax * 2, rMax * 2, rMax * 2));
      }
      if (positionsY[i] + rMax > 1) {
        queryRanges.add(new Volume(positionsX[i] - rMax, positionsY[i] - rMax - 1, positionsZ[i] - rMax, rMax * 2, rMax * 2, rMax * 2));
      }
      if (positionsZ[i] - rMax < 0) {
        queryRanges.add(new Volume(positionsX[i] - rMax, positionsY[i] - rMax, positionsZ[i] - rMax + 1, rMax * 2, rMax * 2, rMax * 2));
      }
      if (positionsZ[i] + rMax > 1) {
        queryRanges.add(new Volume(positionsX[i] - rMax, positionsY[i] - rMax, positionsZ[i] - rMax - 1, rMax * 2, rMax * 2, rMax * 2));
      }
    }

    // Perform the multi-query
    points = octree.multiQuery(queryRanges, points);

    for (Point p : points) {
      if (p.index == i)
        continue;

      float rx = p.x - positionsX[i];
      float ry = p.y - positionsY[i];
      float rz = p.z - positionsZ[i];

      if (wrap) {
        if (rx > 0.5) rx -= 1.0;
        else if (rx < -0.5) rx += 1.0;
        if (ry > 0.5) ry -= 1.0;
        else if (ry < -0.5) ry += 1.0;
        if (rz > 0.5) rz -= 1.0;
        else if (rz < -0.5) rz += 1.0;
      }

      float r  = sqrt(rx*rx + ry*ry + rz*rz);
      if (r > 0 && r < rMax) {
        float f = force(r / rMax, matrix[colors[i]][colors[p.index]]);
        totalForceX += rx/r*f;
        totalForceY += ry/r*f;
        totalForceZ += rz/r*f;
      }
    }

    totalForceX *= rMax * forceFactor;
    totalForceY *= rMax * forceFactor;
    totalForceZ *= rMax * forceFactor;

    velocitiesX[i] *= frictionFactor;
    velocitiesY[i] *= frictionFactor;
    velocitiesZ[i] *= frictionFactor;

    velocitiesX[i] += totalForceX * dt;
    velocitiesY[i] += totalForceY * dt;
    velocitiesZ[i] += totalForceZ * dt;
  }

  for (int i=0; i<n; i++) {
    positionsX[i] += velocitiesX[i] * dt;
    positionsY[i] += velocitiesY[i] * dt;
    positionsZ[i] += velocitiesZ[i] * dt;

    positionsX[i] = (positionsX[i] + 1) % 1;
    positionsY[i] = (positionsY[i] + 1) % 1;
    positionsZ[i] = (positionsZ[i] + 1) % 1;
  }

  float endTime = millis();
  println("Updating time: " + (endTime - startTime) + " ms");
}

void resetCamera() {
  float cameraX = width / 2.0;
  float cameraY = height / 2.0;
  float cameraZ = (height/2.0) / tan(PI * 30.0 / 180.0); // Default perspective camera

  float centerX = width / 2.0;
  float centerY = height / 2.0;
  float centerZ = 0;

  float upX = 0;
  float upY = 1;
  float upZ = 0;

  camera(cameraX, cameraY, cameraZ, centerX, centerY, centerZ, upX, upY, upZ);
}

void updateOctree(Octree octree) {
  for (int i = 0; i < n; i++) {
    octree.insert(new Point(positionsX[i], positionsY[i], positionsZ[i], i));
  }
}

void drawHUD() {
  // Switch to 2D rendering mode
  hint(DISABLE_DEPTH_TEST);

  // Draw HUD elements
  fill(255);
  float size = 16;
  float paddingFactor = 1.5;
  textSize(size);

  textAlign(LEFT);
  text(
    //"FPS: " +
    frameRate, 10, size*paddingFactor*1);
  //text("n: " + n, 10, size*paddingFactor*2);
  //text("m: " + m, 10, size*paddingFactor*3);
  //text("rMax: " + rMax, 10, size*paddingFactor*4);
  //text("forceFactor: " + forceFactor, 10, size*paddingFactor*5);
  //text("isView3D: " + isView3D, 10, size*paddingFactor*6);

  sliderWindow.display();

  // Switch back to 3D rendering mode
  hint(ENABLE_DEPTH_TEST);
}

void draw() {

  if (!sliderWindow.isDragging) {
    if (n != int(sliderWindow.getSliderValue(0))) {
      n = int(sliderWindow.getSliderValue(0));
      setup();
    }

    if (m != int(sliderWindow.getSliderValue(1))) {
      m = int(sliderWindow.getSliderValue(1));
      setup();
    }
  }

  if (rMax != int(sliderWindow.getSliderValue(2))) {
    rMax = sliderWindow.getSliderValue(2);
    sphereRadius = width * rMax * .025;
  }

  if (forceFactor != int(sliderWindow.getSliderValue(3))) {
    forceFactor = sliderWindow.getSliderValue(3);
  }

  octree = new Octree(new Volume(.5, .5, .5, .5, .5, .5), 4);
  updateOctree(octree);
  updateParticles();
  if (isView3D) {
    float startTime = millis();

    pushMatrix();

    noStroke();
    background(0);

    handleCameraMovement();

    noFill();
    strokeWeight(1);
    stroke(255, 0, 255, 255/10.0);
    pushMatrix();
    translate(width/2, width/2, width/2);
    box(width);
    popMatrix();
    noStroke();
    fill(255);

    if (showOctree) {
      octree.draw(octree);
      noStroke();
    }

    for (int i = 0; i < n; i++) {
      //octree.insert(new Point(positionsX[i], positionsY[i], positionsZ[i], i));

      fill(255 * ((float) colors[i] / m), 255, 255, 255);

      pushMatrix();
      translate(positionsX[i] * width, positionsY[i] * width, positionsZ[i] * width);
      //sphere(sphereRadius);
      box(sphereRadius);

      popMatrix();
    }
    popMatrix();

    drawHUD();

    float endTime = millis();
    println("Drawing time: " + (endTime - startTime) + " ms");
  } else {
    float startTime = millis();

    noStroke();
    background(0);

    pushMatrix();
    translate(width / 2, height / 2);
    float minSize = min(width, height);
    for (int i=0; i<n; i++) {
      //fill(255*((float)colors[i]/m), 255, 255);
      //fill(255*((float)colors[i]/m), 255, 255, 255-255*.5*positionsZ[i]);
      fill(255*((float)colors[i]/m), 255, 255, 255*.5);
      circle(positionsX[i] * minSize - minSize / 2, positionsY[i] * minSize - minSize / 2, sphereRadius*2);
    }
    popMatrix();

    drawHUD();

    float endTime = millis();
    println("Drawing time: " + (endTime - startTime) + " ms");
  }

  //loadPixels();

  //for (int i = 0; i < pixels.length; i++) {
  //  pixels[i] = color(255 - red(pixels[i]), 255 - green(pixels[i]), 255 - blue(pixels[i]));
  //}

  //updatePixels();
}

PShape createCube(float side) {
  PShape s = createShape(BOX, side);
  return s;
}

void keyPressed() {
  if (key == 'r') setup();
  if (key == '-') {
    n -= 1000;
    setup();
  }
  if (key == '=') {
    n += 1000;
    setup();
  }
  if (key == ',') {
    m -= 1;
    setup();
  }
  if (key == '.') {
    m += 1;
    setup();
  }
  if (keyCode == UP) {
    rMax -= .05;
    rMax = constrain(rMax, 0, 1);
    sphereRadius = width * rMax * .025;
  }
  if (keyCode == DOWN) {
    rMax += .05;
    rMax = constrain(rMax, 0, 1);
    sphereRadius = width * rMax * .025;
  }
  if (keyCode == LEFT) {
    forceFactor -= 5;
    forceFactor = constrain(forceFactor, 0, 100);
  }
  if (keyCode == RIGHT) {
    forceFactor += 5;
    forceFactor = constrain(forceFactor, 0, 100);
  }

  if (key == ' ') {
    resetCamera();
    isView3D = !isView3D;
  }

  if (key == 'q')
    showOctree = !showOctree;

  if (key == 't')
    wrap = !wrap;

  if (key == 'p') {
    pause = !pause;
    if (pause) noLoop();
    else loop();
  }
}

float cameraDistance = 1000;
float cameraSpeed = 50;
float rotY = 0;
float rotX = 0;

float centerX = width / 2;
float centerY = width / 2;
float centerZ = width / 2;

float sphereRadius;

void handleCameraMovement() {
  float rotationSpeed = 0.1;

  if (keyPressed) {
    if (key == 'a') {
      rotY += rotationSpeed;
    }
    if (key == 'd') {
      rotY -= rotationSpeed;
    }
    if (key == 'w') {
      rotX -= rotationSpeed;
    }
    if (key == 's') {
      rotX += rotationSpeed;
    }
  }

  // Rotate camera based on mouse drag
  if (mousePressed && (mouseButton == LEFT) && !sliderWindow.isDragging) {
    float deltaX = mouseX - pmouseX;
    float deltaY = mouseY - pmouseY;
    rotY += deltaX * 0.005;
    rotX -= deltaY * 0.005;
  }
  rotX = constrain(rotX, -HALF_PI+1e-4, HALF_PI-1e-4);

  float cameraX = centerX + cos(rotY) * cos(rotX) * cameraDistance;
  float cameraY = centerY + sin(rotX) * cameraDistance;
  float cameraZ = centerZ + sin(rotY) * cos(rotX) * cameraDistance;

  camera(cameraX, cameraY, cameraZ, centerX, centerY, centerZ, 0, 1, 0);
}

void mouseWheel(MouseEvent event) {
  cameraDistance += event.getCount() * cameraSpeed;
  if (cameraDistance<cameraSpeed) cameraDistance = cameraSpeed;
}

void mousePressed() {
  sliderWindow.mousePressed();
}

void mouseReleased() {
  sliderWindow.mouseReleased();
}

void mouseDragged() {
  sliderWindow.mouseDragged();
}

void windowResized() {
  centerX = width / 2;
  centerY = width / 2;
  centerZ = width / 2;

  sphereRadius = width * rMax * .025;
  //println(sphereRadius);

  // Reposition the SliderWindow to stay sticky to the top right corner
  sliderWindow.position(width - sliderWindow.w - 20, 20);
}
