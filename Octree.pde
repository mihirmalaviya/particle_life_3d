// Point class
class Point {
  float x, y, z;
  int index;

  Point(float x, float y, float z, int i) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.index = i;
  }
}

// Volume class
class Volume {
  float x, y, z, w, h, d;

  Volume(float x, float y, float z, float w, float h, float d) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.w = w;
    this.h = h;
    this.d = d;
  }

  boolean contains(Point point) {
    return (point.x >= this.x - this.w && point.x <= this.x + this.w &&
      point.y >= this.y - this.h && point.y <= this.y + this.h &&
      point.z >= this.z - this.d && point.z <= this.z + this.d);
  }

  boolean intersects(Volume range) {
    return !(range.x - range.w > this.x + this.w ||
      range.x + range.w < this.x - this.w ||
      range.y - range.h > this.y + this.h ||
      range.y + range.h < this.y - this.h ||
      range.z - range.d > this.z + this.d ||
      range.z + range.d < this.z - this.d);
  }
}

// Octree class (replaces QuadTree for 3D)
class Octree {
  Volume boundary;
  int capacity;
  ArrayList<Point> points;
  boolean divided;
  Octree[] octants;

  Octree(Volume boundary, int capacity) {
    if (boundary == null || capacity < 1) {
      throw new IllegalArgumentException("Invalid parameters");
    }
    this.boundary = boundary;
    this.capacity = capacity;
    this.points = new ArrayList<>();
    this.divided = false;
    this.octants = new Octree[8];
  }

  void subdivide() {
    float x = this.boundary.x;
    float y = this.boundary.y;
    float z = this.boundary.z;
    float w = this.boundary.w / 2;
    float h = this.boundary.h / 2;
    float d = this.boundary.d / 2;

    this.octants[0] = new Octree(new Volume(x - w, y - h, z - d, w, h, d), this.capacity);
    this.octants[1] = new Octree(new Volume(x + w, y - h, z - d, w, h, d), this.capacity);
    this.octants[2] = new Octree(new Volume(x - w, y + h, z - d, w, h, d), this.capacity);
    this.octants[3] = new Octree(new Volume(x + w, y + h, z - d, w, h, d), this.capacity);
    this.octants[4] = new Octree(new Volume(x - w, y - h, z + d, w, h, d), this.capacity);
    this.octants[5] = new Octree(new Volume(x + w, y - h, z + d, w, h, d), this.capacity);
    this.octants[6] = new Octree(new Volume(x - w, y + h, z + d, w, h, d), this.capacity);
    this.octants[7] = new Octree(new Volume(x + w, y + h, z + d, w, h, d), this.capacity);

    this.divided = true;
  }

  boolean insert(Point point) {
    if (!this.boundary.contains(point)) {
      return false;
    }

    if (this.points.size() < this.capacity) {
      this.points.add(point);
      return true;
    }

    if (!this.divided) {
      this.subdivide();
    }

    for (Octree octant : this.octants) {
      if (octant.insert(point)) {
        return true;
      }
    }

    return false;
  }

  ArrayList<Point> query(Volume range, ArrayList<Point> found) {
    if (found == null) {
      found = new ArrayList<>();
    }

    if (!range.intersects(this.boundary)) {
      return found;
    }

    for (Point p : this.points) {
      if (range.contains(p)) {
        found.add(p);
      }
    }

    if (this.divided) {
      for (Octree octant : this.octants) {
        octant.query(range, found);
      }
    }

    return found;
  }

  ArrayList<Point> multiQuery(ArrayList<Volume> ranges, ArrayList<Point> found) {
    if (found == null) {
      found = new ArrayList<>();
    }

    boolean intersectsAnyRange = false;

    for (Volume range : ranges) {
      if (range.intersects(this.boundary)) {
        intersectsAnyRange = true;
        break;
      }
    }

    if (!intersectsAnyRange) {
      return found;
    }

    for (Point p : this.points) {
      for (Volume range : ranges) {
        if (range.contains(p)) {
          found.add(p);
          // Assuming a point can only be in one range, you may break out of the inner loop here
          // if you want to prevent adding the same point multiple times.
          // break;
        }
      }
    }

    if (this.divided) {
      for (Octree octant : this.octants) {
        octant.multiQuery(ranges, found);
      }
    }

    return found;
  }

  void draw(Octree octree) {
    float minSize = width;

    stroke(70.0, 255, 255, 255/2.0);
    noFill();
    //boxMode(CENTER);

    pushMatrix();
    translate(octree.boundary.x * minSize, octree.boundary.y * minSize, octree.boundary.z * minSize);
    box(octree.boundary.w * 2 * minSize, octree.boundary.h * 2 * minSize, octree.boundary.d * 2 * minSize);
    popMatrix();
    fill(255);

    if (octree.divided) {
      draw(octree.octants[0]);
      draw(octree.octants[1]);
      draw(octree.octants[2]);
      draw(octree.octants[3]);
      draw(octree.octants[4]);
      draw(octree.octants[5]);
      draw(octree.octants[6]);
      draw(octree.octants[7]);
    }
  }
}
