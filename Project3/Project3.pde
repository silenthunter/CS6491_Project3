/**
* @brief Ball class
*
*/
class Ball
{
  ///The 3D position of the Ball
  PVector pos;
  
  ///The velocity of the Ball
  PVector vel;
  
  ///The radius of the Ball
  float r;
  boolean hasHit = false;
  
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
}

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

///
int maxCounter = 1000;
boolean rotation=false;
boolean pressed=false;
boolean zoom=false;
boolean spray=false;
pt C = new pt();

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
    hasHit = false;
    counter++;
    
    for(Ball ball : balls)
    {
      
      fill(0, 255, 0);
      if(counter == 1 || ball.hasHit) ball.pos.add(ball.vel);
     
      //Don't check for collisions if the ball isn't moving. (I really should use brackets....)
      if(ball.vel.mag() != 0) 
      //Find collisions
      for(Ball check : balls)
      {
        if(ball == check) continue;
        
        float d = ball.pos.dist(check.pos);
        if(d <= 1 + ball.r + check.r && ball.vel.mag() > minSpeed)
        {
          if(!ball.hasHit)
          {
            ball.vel.mult(contactVel / ball.vel.mag());
          }
          
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
      
      if(counter == 1)
      {  
        pushMatrix();
        translate(ball.pos.x, ball.pos.y, ball.pos.z);
        sphere(ball.r);
        popMatrix();
      }
    }
  }while(counter < maxCounter && hasHit);
  

}

void mousePressed() {pressed=true;}
void mouseReleased() {pressed=false;}

void keyPressed() {
   if (key=='r') {rotation=!rotation;zoom=false;spray=false;}
   if (key=='z') {rotation=false;zoom=!zoom;spray=false;}
   if (key=='s') {rotation=false;zoom=false;spray=!spray;}
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
  



