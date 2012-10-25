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
  boolean hasHitThisFrame = false;
  
  ///Is used for hull generation. Will not be collided with
  boolean isTracer = false;
  
  ///A ball that the tracer will not collide with
  Ball nonCollide = null;
  
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
    Edge edge = (Edge)o;
    if( (verts[0] == edge.verts[0] && verts[1] == edge.verts[1]) ||
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
    Tri tri = (Tri)o;
    if( (edges[0] == tri.edges[0] && edges[1] == tri.edges[1] && edges[2] == tri.edges[2]) ||
        (edges[0] == tri.edges[1] && edges[1] == tri.edges[2] && edges[2] == tri.edges[0]) ||
        (edges[0] == tri.edges[2] && edges[1] == tri.edges[0] && edges[2] == tri.edges[1]) ||
        (edges[0] == tri.edges[0] && edges[1] == tri.edges[2] && edges[2] == tri.edges[1]) ||
        (edges[0] == tri.edges[1] && edges[1] == tri.edges[0] && edges[2] == tri.edges[2]) ||
        (edges[0] == tri.edges[2] && edges[1] == tri.edges[1] && edges[2] == tri.edges[0]))
      return 0;
    
    return -1;
  }
}

///A counter that keeps track of the number of Ball objects created
static int UIDcounter = 0;

///The Ball objects in the system
ArrayList<Ball> balls = new ArrayList<Ball>();

ArrayList<Ball> toRemove = new ArrayList<Ball>();

ArrayList<Ball> toAdd = new ArrayList<Ball>();

///The minimum velocity a ball can have before being stopped
final float minSpeed = .005f;

///A point used to calculate the ball launch angle
PVector POV;

///The velocity balls are launched at
float launchVel = 50f;

///The velocity balls are set to when they contact another ball
float contactVel = 1f;

///The radius user spawned balls will be created with
float defaultRadius = 40f;

///The maximum number of physics steps before moving to another frame
int maxCounter = 1000;
boolean rotation=false;
boolean pressed=false;
boolean zoom=false;
boolean spray=false;
pt C = new pt();

ArrayList<Edge> edges = new ArrayList<Edge>();

ArrayList<Tri> triList = new ArrayList<Tri>();

boolean meshMode = false;

long frameCounter = 0;
int framesPerSpawn = 5;

void setup()
{
  size(400, 400, P3D);
  
  POV = new PVector(width / 2, height / 2, 500);
  
  //Initialize field
  for(int i = 0; i < height / defaultRadius / 2; i++)
  {
    for(int j = 0; j < width / defaultRadius / 2; j++)
    {
      println(i + ", " + j);
      balls.add(new Ball(j * (defaultRadius * 2) + (i % 2 == 0 ?  0 : defaultRadius), i * (defaultRadius * 1.5), -500, defaultRadius));
    }
  }
  //Initialize the camera
  initView();
  
}

void draw()
{
  background(255);
  noStroke();
  
  lights();
  
  boolean hasHit = false;
  int counter = 0;
  int tracerCount = 0;
  
  //Only 3 should ever touch, but just in case...
  int[] touched = new int[8];
  
  if (rotation) {
    if(pressed) {
      rotateCam(E,F,U);
    }
  }
  if (zoom) {
    if(pressed) {
      C= Pmouse().makeClone();
      zoom(E,F,U,C);      
    }
  }
  if (spray) {
//    pushMatrix();
//    translate(mouseX, mouseY, 0);
//    stroke(0,0,255);
//    noFill();
//    ellipse(0,0,r,r);
//    popMatrix();
    if (pressed) {
      //spray(b,E,F,U,r);
      spawnBall(mouseX, mouseY);
    }
    
  }
  if (key=='i') {initView(); setCam(E,F,U);}
  
  do
  {
    tracerCount = 0;
    hasHit = false;
    counter++;
    
    for(Ball ball : balls)
    {
      if(ball.isTracer)
        if(tracerCount++ > 50) continue;
      
      fill(0, 255, 0);
      if(counter == 1 || ball.hasHit) ball.pos.add(ball.vel);
     
      ArrayList<Ball> collisions = new ArrayList<Ball>();
      
      //Don't check for collisions if the ball isn't moving.
      if(ball.vel.mag() != 0) 
      {
        //Find collisions
        for(Ball check : balls)
        {
          //Don't attempt to collide with 'self' or a tracer ball
          if(ball == check || check.isTracer || check == ball.nonCollide) continue;
          
          float d = ball.pos.dist(check.pos);
          if(d <= .1 + ball.r + check.r && ball.vel.mag() > minSpeed)
          {
            //if(ball.isTracer) println(d + " (" + check.UID + ")");
            collisions.add(check);
          }
          
          //Slow the balls down for fine grain collisions
          if( d <= launchVel * 5)
          {
            ball.hasHit = true;
            ball.vel.mult(contactVel / ball.vel.mag());
          }
        }
      }
      
      //DEBUGING
      if(false && ball.isTracer)
      {
        println("Contacts: " + collisions.size());
        println("Vel: " + ball.vel);
        println("---------------------");
      }
      
      if(collisions.size() > 0)
        hasHit = true;
      
      
      //Compute collisions
      if(collisions.size() == 1)
      {
        Ball check = collisions.get(0);
          //Keep the tracers moving
          if(ball.isTracer)
            ball.vel.mult(contactVel / ball.vel.mag());
          
          hasHit = true;
          
          //Get the normal of the plane
          PVector vAnti = check.pos.get();
          vAnti.sub(ball.pos);
          PVector N = new PVector();
          PVector.cross(ball.vel, vAnti, N);
          
          //Get the tangent
          PVector tang = new PVector();
          PVector.cross(vAnti, N, tang);
          tang.mult(ball.vel.mag() / tang.mag());
          
          ball.vel = tang;
          
          //Adjust for the discrete timesteps
          PVector translation = vAnti.get();
          float magn = (vAnti.mag() - (check.r + ball.r)) / vAnti.mag();
          translation.set(translation.x * magn, translation.y * magn, translation.z * magn);
          
          ball.pos.add(translation);
          
          ball.hasHitThisFrame = true;
          
          fill(255, 0, 255);
        //end inner ball loop
        }
        //handle collisions between 2 balls
        else if(collisions.size() == 2)
        {
          Ball c1 = collisions.get(0);
          Ball c2 = collisions.get(1);
          
          PVector tang = getTangent(ball.pos, c1.pos, c2.pos);
          
          if(PVector.angleBetween(tang, ball.vel) > Math.PI / 2)
            tang.mult(-1);
          
          ball.vel = tang;
          
          //fix the position of the ball
          PVector v1 = c1.pos.get(); v1.sub(ball.pos);
          PVector v2 = c2.pos.get(); v2.sub(ball.pos);
          float magn1 = (v1.mag() - (c1.r + ball.r)) / v1.mag();
          float magn2 = (v2.mag() - (c2.r + ball.r)) / v2.mag();
          
          v1.mult(magn1);
          v2.mult(magn2);
          
          PVector translation = v1.get();
          translation.add(v2);
          translation.div(2);
          
          ball.pos.add(translation);          
          
          fill(255, 0, 255);
        }
        //Found all 3 points
        else if(collisions.size() >= 3)
        {
          Ball c1 = collisions.get(0);
          Ball c2 = collisions.get(1);
          Ball c3 = collisions.get(2);
          
          touched[0] = c1.UID;
          touched[1] = c2.UID;
          touched[2] = c3.UID;
          
          ball.vel.set(0, 0, 0);
          
          if(ball.isTracer)
            spawnTracers(ball, touched);
        }
        
        //If a ball's speed is too low, stop it        
        if(ball.vel.mag() < minSpeed && !ball.isTracer)
          ball.vel.set(0, 0, 0);
      //}
         
      if(counter == 1 && !meshMode)
      {  
        pushMatrix();
        translate(ball.pos.x, ball.pos.y, ball.pos.z);
        sphere(ball.r);
        popMatrix();
      }
      
      if(ball.isTracer && ball.vel.mag() < minSpeed) toRemove.add(ball);
    }
  }while(counter < maxCounter && hasHit);
  
  for(Ball ball : toRemove)
    balls.remove(ball);
  toRemove.clear();
  
  for(Ball ball : toAdd)
    balls.add(ball);
  toAdd.clear();
  
  //Draw the triangle mesh
 if(meshMode)
  {
    for(int i = 0; i < triList.size(); i++)
    {
      beginShape();
      
      int p1 = triList.get(i).edges[0].verts[0];
      int p2 = triList.get(i).edges[1].verts[0];
      if(p2 == p1)
      {
        p2 = triList.get(i).edges[1].verts[1];
      }
      int p3 = triList.get(i).edges[2].verts[0];
      if(p3 == p2 || p3 == p1)
      {
        p3 = triList.get(i).edges[2].verts[1];
      }
      
      if (p1 == p2 || p2 == p3 || p3 ==p1) println("shit");
      
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

}

void spawnTracers(Ball ball, int[] touched)
{
    //Mark the finished tracer for removal
    toRemove.add(ball);
    
    //Make sure it's not a redundant triangle
    if(addTriangle(touched[0], touched[1], touched[2]))
    {
      Ball p1 = null, p2 = null, p3 = null;
      
      //Get the vertices
      for(int i = 0; i < balls.size(); i++)
      {
        if(balls.get(i).UID == touched[0]) p1 = balls.get(i);
        if(balls.get(i).UID == touched[1]) p2 = balls.get(i);
        if(balls.get(i).UID == touched[2]) p3 = balls.get(i);
      }
      
      Ball b1 = new Ball(ball.pos.x, ball.pos.y, ball.pos.z, ball.r);
      b1.SetVelocity(getTangent(ball.pos, p1.pos, p2.pos));
      //b1.pos.add(b1.vel);
      b1.SetTracer(true);
      b1.nonCollide = p3;
      
      Ball b2 = new Ball(ball.pos.x, ball.pos.y, ball.pos.z, ball.r);
      b2.SetVelocity(getTangent(ball.pos, p2.pos, p3.pos));
      //b2.pos.add(b2.vel);
      b2.SetTracer(true);
      b2.nonCollide = p1;
      
      Ball b3 = new Ball(ball.pos.x, ball.pos.y, ball.pos.z, ball.r);
      b3.SetVelocity(getTangent(ball.pos, p1.pos, p3.pos));
      b3.vel.mult(-1);
      //b3.pos.add(b3.vel);
      b3.SetTracer(true);
      b3.nonCollide = p2;
      
      toAdd.add(b1);
      toAdd.add(b2);
      toAdd.add(b3);
    }
}


PVector getTangent(PVector origin, PVector p1, PVector p2)
{
  PVector retn = new PVector();
  PVector v1 = p1.get();
  PVector v2 = p2.get();
  
  v1.sub(origin);
  v2.sub(origin);
  
  PVector.cross(v2, v1, retn);
  retn.normalize();
  
  retn.mult(contactVel);
  
  return retn;
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
  for(int i = 0; i < edges.size(); i++)
  {
    Edge edge = edges.get(i);
    
    if(edge.compareTo(e1) == 0) e1 = edge;
    if(edge.compareTo(e2) == 0) e2 = edge;
    if(edge.compareTo(e3) == 0) e3 = edge;
  }
  
  edges.add(e1);
  edges.add(e2);
  edges.add(e3);
  
  Tri newTri = new Tri(e1, e2, e3);
  
  //Check if the triangle exists
  for(int i = 0; i < triList.size(); i++)
  {
    Tri tri = triList.get(i);
    
    //Return false if the triangle is already in the mesh
    if(tri.compareTo(newTri) == 0)
    {
      //println("False");
      return false;
    }
  }
  
  triList.add(newTri);
  
  return true;
}

void generateHull()
{
  //Clear any old information
  triList.clear();
  edges.clear();
  
  //launch the first tracer ball
  Ball firstTracer = new Ball(width / 2, height / 2, 500, defaultRadius, 0, 0, -launchVel);
  firstTracer.SetTracer(true);
  balls.add(firstTracer);
}

void keyTyped()
{
  if(key == 'q') meshMode = !meshMode;
}


//Geometry functions used for the camera
class pt { 
  float x=0,y=0,z=0; 
  boolean fixed=false;
  
  pt () {};
  pt (float px, float py, float pz) {x = px; y = py; z=pz;};
  pt (pt P, float s, vec I, float t, vec J) {x=P.x+s*I.x+t*J.x; y=P.y+s*I.y+t*J.y; z=P.z+s*I.z+t*J.z;}
  
  pt P(float x, float y, float z) {return new pt(x,y,z); }; 
  pt makeClone() {return new pt(x,y,z); } 
  pt add(vec V) {x+=V.x; y+=V.y; z+=V.z; return this;};
  pt add(float s, vec V) {x+=s*V.x; y+=s*V.y; z+=s*V.z; return this;};
  
  void setTo(float px, float py, float pz) {x = px; y = py; z = pz;}; 
  void setTo(pt P) {x = P.x; y = P.y; z=P.z;} 
  vec vecTo(pt P) {return(new vec(P.x-x,P.y-y, P.z-z)); }
  void translateBy(vec V) {x += V.x; y += V.y; z += V.z;}
  void R(float a, vec I, vec J, pt G) {float x=dot(new vec(G,this),I), y=dot(new vec(G,this),J); float c=cos(a), s=sin(a); this.add(x*c-x-y*s,I).add(x*s+y*c-y,J);}
  
  float disTo(pt P) {return(sqrt(sq(P.x-x)+sq(P.y-y)+sq(P.z-z))); }

  void show(int r) {ellipse(x, y, r, r);}
  void showLabel(int i) {text(str(i), x,y,z);}
  void v() {vertex(x,y,z);};  // used for drawing polygons between beginShape(); and endShape();
  void to (pt P) {line(x,y,z,P.x,P.y,P.z);}
  
  String toString() {
    return "x = " + this.x + " y = " + this.y + " z = " + this.z + "\n";
  }
}


//return new pt(P,x*c-x-y*s,I,x*s+y*c-y,J); }; // Rotated P by a around G in plane (I,J)


class vec { 
  float x=0,y=0,z=0; 
  
  vec () {};
  vec (vec V) {x = V.x; y = V.y; z = V.z;};
  vec (float s, vec V) {x = s*V.x; y = s*V.y; z = s*V.z;};
  vec (float px, float py, float pz) {x = px; y = py; z=pz;};
  vec (pt P, pt Q) {x = Q.x-P.x; y = Q.y-P.y; z = Q.z-P.z;};
  vec (float s, pt P, pt Q) {x = s*(Q.x-P.x); y = s*(Q.y-P.y); z = s*(Q.z-P.z);};
  
  void setTo(float px, float py, float pz) {x = px; y = py; z = pz;};
  void scaleBy(float f) {x*=f; y*=f; z*=f;};
  vec makeClone() {return(new vec(x,y,z));}; 
  void add(vec V) {x += V.x; y += V.y; z+= V.z;};
  float norm() {return(sqrt(sq(x)+sq(y)+sq(z)));};  
  vec X() {return(new vec(this.x, 0, 0));}
  vec Y() {return(new vec(0, this.y, 0));}
  vec Z() {return(new vec(0, 0, this.z));}
}

vec N(vec U, vec V) {return new vec(U.y*V.z-U.z*V.y, U.z*V.x-U.x*V.z, U.x*V.y-U.y*V.x); }
vec U(vec V) {return new vec(1/V.norm(), V);}
float dot(vec U, vec V) {return U.x*V.x+U.y*V.y+U.z*V.z; };


//Camera settings
pt F = new pt(width/2.0, height/2.0, 0.0); 
pt E = new pt(width/2.0, height/2.0, (height/2.0) / tan(PI*30.0 / 180.0)); 
vec U= new vec(0,1,0); 
pt Q= new pt(0,0,0); 
vec I= new vec(1,0,0); 
vec J= new vec(0,1,0); 
vec K= new vec(0,0,1); 

void initView() {
  Q.setTo(0,0,0); 
  I.setTo(1,0,0); 
  J.setTo(0,1,0); 
  K.setTo(0,0,1); 
  F.setTo(width/2.0, height/2.0, 0); 
  E.setTo(width/2.0, height/2.0,(height/2.0) / tan(PI*30.0 / 180.0)); 
  U.setTo(0,1,0); 
} 

void setCam(pt E, pt F, vec U) {
  camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z);
}

void rotateCam(pt E, pt F, vec U) {
  E.R(PI*float(mouseX-pmouseX)/width,I,K,F); 
  E.R(-PI*float(mouseY-pmouseY)/width,J,K,F);
  camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z);
}

void rotateCamHoriz(pt E, pt F, vec U) {
  E.R(PI*float(mouseX-pmouseX)/width,I,K,F); 
  camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z);
}

void rotateCamVert(pt E, pt F, vec U) {
  E.R(-PI*float(mouseY-pmouseY)/width,J,K,F); 
  camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z);
}

void zoom(pt E, pt F, vec U, pt C) {
 
  vec W = new vec(C,Mouse());
  float signe = W.y/abs(W.y);
  if (signe==1 || signe==-1) {
    float s = signe*MouseDrag().norm()*2/width;
    vec V = new vec(s,E.vecTo(F));
    E.add(V);
  }
  camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z);
}


pt Mouse() {return new pt(mouseX,mouseY,0);};                                         
pt Pmouse() {return new pt(pmouseX,pmouseY,0);};
vec MouseDrag() {return new vec(mouseX-pmouseX,mouseY-pmouseY,0);};

void mousePressed() {pressed=true;}
void mouseReleased() {pressed=false;}

void keyPressed() {
   if (key=='r') {rotation=!rotation;zoom=false;spray=false;}
   if (key=='z') {rotation=false;zoom=!zoom;spray=false;}
   if (key=='s') {rotation=false;zoom=false;spray=!spray;}
   if (key=='h') generateHull();
   if (key=='m') meshMode = !meshMode;
   if (key=='d') SaveToFile();
   if (key=='l') LoadFromFile();
}

void SaveToFile()
{
  ArrayList<String> strs = new ArrayList<String>();
  
  for(Ball ball: balls)
  {
    String outLine = ball.pos.x + " " + ball.pos.y + " " + ball.pos.z + " " + ball.r;
    strs.add(outLine);
  }
  String[] strArr = new String[strs.size()];
  strs.toArray(strArr);
  
  saveStrings("save.vts", strArr);
  
}

void LoadFromFile()
{
  balls.clear();
  String[] linesArr = loadStrings("save.vts");
  
  for(int i = 0; i < linesArr.length; i++)
  {
    StringTokenizer st = new StringTokenizer(linesArr[i]);
    balls.add(new Ball(Float.parseFloat(st.nextToken()), Float.parseFloat(st.nextToken()), Float.parseFloat(st.nextToken()), Float.parseFloat(st.nextToken())));
    
  }
}
  



