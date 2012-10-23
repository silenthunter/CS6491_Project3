/**
* @brief Ball class
*
* @Note Not thread safe
*/
class Ball
{ 
  ///A unique ID that is used to index vertices
  int UID;
  
  ///The 3D position of the Ball
  PVector pos;
  
  ///The velocity of the Ball
  PVector vel;
  
  ///The radius of the Ball
  float r;
  boolean hasHit = false;
  
  ///Is used for hull generation. Will not be collided with
  boolean isTracer = false;
  
  /**
  * @brief Initializes a Ball object with the given parameters
  * @param x The ball's X position
  * @param y The ball's Y position
  * @param z The ball's Z position
  * @param r The ball's radius
  * @param vx The ball's velocity's X component
  * @param vy The ball's velocity's Y component
  * @param vz The ball's velocity's Z component
  */
  public Ball(float x, float y, float z, float r, float vx, float vy, float vz)
  {
    pos = new PVector(x, y, z);
    vel = new PVector(vx, vy, vz);
    this.r = r;
    
    UID = UIDcounter++;
  }

  /**
  * @brief Initializes a Ball object with the given parameters, and a velocity of 0
  * @param x The ball's X position
  * @param y The ball's Y position
  * @param z The ball's Z position
  * @param r The ball's radius
  */  
  public Ball(float x, float y, float z, float r)
  {
    this(x, y, z, r, 0, 0, 0);
  }
  
  public void SetVelocity(PVector vel)
  {
    this.vel = vel.get();
  }
  
  public void SetTracer(boolean isTracer)
  {
    this.isTracer = isTracer;
  }
}

/**
* @brief Represents and edge composed of 2 vertices
*/
class Edge implements Comparable
{
  int[] verts = new int[2];
  
  /**
  * @brief Constructs an edge from 2 vertices
  * @param vert1 The first vertex
  * @param vert2 The second vertex
  */
  public Edge(int vert1, int vert2)
  {
    verts[0] = vert1;
    verts[1] = vert2;
  }
  
  public int compareTo(Object o)
  {
    //I should handle this error....
    if(o instanceof Edge) return -1;
    
    Edge edge = (Edge)o;
    if((verts[0] == edge.verts[0] && verts[1] == edge.verts[1]) ||
        (verts[0] == edge.verts[1] && verts[1] == edge.verts[0]))
      return 0;
    
    return -1;
  }
}

class Tri implements Comparable
{
  Edge[] edges = new Edge[3];
  
  /**
  * @brief Constructs an triangle from 3 edges
  * @param e1 The first edge
  * @param e2 The second edge
  * @param e3 The third edge
  */
  public Tri(Edge e1, Edge e2, Edge e3)
  {
    edges[0] = e1;
    edges[1] = e2;
    edges[2] = e3;
  }
  
  public int compareTo(Object o)
  {
    //I should handle this error....
    if(o instanceof Tri) return -1;
    
    Tri tri = (Tri)o;
    if((edges[0] == tri.edges[0] && edges[1] == tri.edges[1] && tri.edges[2] == tri.edges[2]) ||
        (edges[0] == tri.edges[1] && edges[1] == tri.edges[2] && tri.edges[2] == tri.edges[0]) ||
        (edges[0] == tri.edges[2] && edges[1] == tri.edges[0] && tri.edges[2] == tri.edges[1]) ||
        (edges[0] == tri.edges[1] && edges[1] == tri.edges[0] && tri.edges[2] == tri.edges[2]) ||
        (edges[0] == tri.edges[2] && edges[1] == tri.edges[1] && tri.edges[2] == tri.edges[0]) ||
        (edges[0] == tri.edges[0] && edges[1] == tri.edges[2] && tri.edges[2] == tri.edges[1]))
      return 0;
    
    return -1;
  }
}

///A counter that keeps track of the number of Ball objects created
static int UIDcounter = 0;

///The Ball objects in the system
ArrayList<Ball> balls = new ArrayList<Ball>();

///The minimum velocity a ball can have before being stopped
final float minSpeed = .01f;

///A point used to calculate the ball launch angle
PVector POV;

///The velocity balls are launched at
float launchVel = 100f;

///The velocity balls are set to when they contact another ball
float contactVel = 1f;

///The radius user spawned balls will be created with
float defaultRadius = 40f;

///The maximum number of physics steps before moving to another frame
int maxCounter = 1000;

Hashtable edges = new Hashtable();

ArrayList<Tri> triList = new ArrayList<Tri>();

boolean meshMode = false;

void setup()
{
  size(400, 400, P3D);
  
  POV = new PVector(width / 2, height / 2, 500);
  
  //Initialize field
  for(int i = 0; i < height / defaultRadius; i++)
  {
    for(int j = 0; j < width / defaultRadius; j++)
    {
      println(i + ", " + j);
      balls.add(new Ball(j * (defaultRadius * 2) + (i % 2 == 0 ?  0 : defaultRadius), i * (defaultRadius * 1.5), -500, defaultRadius));
    }
  }
  
}

void draw()
{
  background(255);
  noStroke();
  
  lights();
  
  boolean hasHit = false;
  int counter = 0;
  
  //Only 3 should ever touch, but just in case...
  int[] touched = new int[8];
  
  do
  {
    hasHit = false;
    counter++;
    
    for(Ball ball : balls)
    {
      
      fill(0, 255, 0);
      if(counter == 1 || ball.hasHit) ball.pos.add(ball.vel);
     
      int collisionCount = 0;
      //Don't check for collisions if the ball isn't moving. (I really should use brackets....)
      if(ball.vel.mag() != 0) 
      //Find collisions
      for(Ball check : balls)
      {
        //Don't attempt to collide with 'self' or a tracer ball
        if(ball == check || check.isTracer) continue;
        
        float d = ball.pos.dist(check.pos);
        if(d <= 1 + ball.r + check.r && ball.vel.mag() > minSpeed)
        {
          if(!ball.hasHit)
          {
            ball.vel.mult(contactVel / ball.vel.mag());
          }
          
          touched[collisionCount++] = check.UID;
          hasHit = true;
          ball.hasHit = true;
          
          //Get the normal of the plane
          PVector vAnti = check.pos.get();
          vAnti.sub(ball.pos);
          PVector N = new PVector();
          PVector.cross(ball.vel, vAnti, N);
          
          //Get the tangent
          PVector tang = new PVector();
          PVector.cross(vAnti, N, tang);
          tang.mult(ball.vel.mag() / tang.mag());
          
          //Set the new velocity
          if(ball.hasHit)
          {
            ball.vel.add(tang);
            ball.vel.div(2);
          }
          else
            ball.vel = tang;
          
          //Adjust for the discrete timesteps
          PVector translation = vAnti.get();
          float magn = (vAnti.mag() - (check.r + ball.r)) / vAnti.mag();
          translation.set(translation.x * magn, translation.y * magn, translation.z * magn);
          
          //Fix the ball's position
          ball.pos.add(translation);
          
          fill(255, 0, 255);
        }
        //If a ball's speed is too low, stop it
        else if(ball.vel.mag() < minSpeed)
          ball.vel.set(0, 0, 0);
      }
      
      //Triangle found!
      if(ball.isTracer && collisionCount == 3)
      {
        //Make sure it's not a redundant triangle
        if(addTriangle(touched[0], touched[1], touched[2]))
        {
        }
      }
      
      if(counter == 1 && !meshMode)
      {  
        pushMatrix();
        translate(ball.pos.x, ball.pos.y, ball.pos.z);
        sphere(ball.r);
        popMatrix();
      }
    }
  }while(counter < maxCounter && hasHit);
  
  if(meshMode)
  {
    for(int i = 0; i < triList.size(); i++)
    {
      beginShape();
      
      int p1 = triList.get(i).edges[0].verts[0];
      int p2 = triList.get(i).edges[1].verts[0];
      int p3 = triList.get(i).edges[2].verts[0];
      
      Ball b1 = null, b2 = null, b3 = null;
      
      for(int j = 0; j < balls.size(); j++)
      {
        if(balls.get(j).UID == p1) b1 = balls.get(j);
        if(balls.get(j).UID == p2) b2 = balls.get(j);
        if(balls.get(j).UID == p3) b3 = balls.get(j);
      }
      
      vertex(b1.pos.x, b1.pos.y, b1.pos.z);
      vertex(b2.pos.x, b2.pos.y, b2.pos.z);
      vertex(b3.pos.x, b3.pos.y, b3.pos.z);
      
      endShape();
    }
  }
  
  if(mousePressed)
    spawnBall(mouseX, mouseY);
    
  if(keyPressed && key != 'q')
    generateHull();
}

void spawnBall(float X, float Y)
{
  
  Ball ball = new Ball(X, Y, -defaultRadius, defaultRadius);
  PVector vel = ball.pos.get();
  vel.sub(POV);
  vel.mult(launchVel / vel.mag());
  
  ball.SetVelocity(vel);
  
  balls.add(ball);
}

boolean addTriangle(int p1, int p2, int p3)
{
  Edge e1 = new Edge(p1, p2);
  Edge e2 = new Edge(p2, p3);
  Edge e3 = new Edge(p3, p1);
  
  //Make sure the edge isn't in the table already
  for(Enumeration e = edges.elements(); e.hasMoreElements();)
  {
    Edge edge = (Edge)e.nextElement();
    
    if(edge.compareTo(e1) == 0) e1 = edge;
    if(edge.compareTo(e2) == 0) e2 = edge;
    if(edge.compareTo(e3) == 0) e3 = edge;
  }
  
  Tri newTri = new Tri(e1, e2, e3);
  
  //Check if the triangle exists
  for(int i = 0; i < triList.size(); i++)
  {
    Tri tri = triList.get(i);
    
    //Return false if the triangle is already in the mesh
    if(tri.compareTo(newTri) == 0) return false;
  }
  
  triList.add(newTri);
  
  return true;
}

void generateHull()
{
  //launch the first tracer ball
  Ball firstTracer = new Ball(width / 2, height / 2, 500, defaultRadius, 0, 0, -launchVel);
  firstTracer.SetTracer(true);
  balls.add(firstTracer);
}

void keyTyped()
{
  if(key == 'q') meshMode = !meshMode;
}
