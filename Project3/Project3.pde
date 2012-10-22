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
  
  do
  {
    hasHit = false;
    counter++;
    
    for(Ball ball : balls)
    {
      fill(0, 255, 0);
      if(counter == 1 || ball.hasHit) ball.pos.add(ball.vel);
      
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

void mouseClicked()
{
  
  Ball ball = new Ball(mouseX, mouseY, -defaultRadius, defaultRadius);
  PVector vel = ball.pos.get();
  vel.sub(POV);
  vel.mult(launchVel / vel.mag());
  
  ball.SetVelocity(vel);
  
  balls.add(ball);
}
