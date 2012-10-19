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
}

///The Ball objects in the system
ArrayList<Ball> balls = new ArrayList<Ball>();

///The minimum velocity a ball can have before being stopped
final float minSpeed = .01f;

void setup()
{
  size(400, 400, P3D);
  balls.add(new Ball(200f, 200f, -100f, 40f));
  balls.add(new Ball(100f, 150f, -100f, 40f, 1, 0, 0));
  balls.add(new Ball(200f, 150f, 100f, 40f, 0, 0, -1));
  balls.add(new Ball(200f, 200f, 500f, 40f, 0, 0, -1));
  balls.add(new Ball(200f, 200f, 800f, 40f, 0, 0, -1));
  balls.add(new Ball(200f, 200f, 1100f, 40f, 0, 0, -1));
  balls.add(new Ball(200f, 200f, 1300f, 40f, 0, 0, -1));
  balls.add(new Ball(200f, 200f, 1600f, 40f, 0, 0, -1));
  balls.add(new Ball(200f, 200f, 1900f, 40f, 0, 0, -1));
}

void draw()
{
  background(255);
  noStroke();
  
  lights();
  
  for(Ball ball : balls)
  {
    fill(0, 255, 0);
    ball.pos.add(ball.vel);
    
    //Find collisions
    for(Ball check : balls)
    {
      if(ball == check) continue;
      
      float d = ball.pos.dist(check.pos);
      if(d <= 1 + ball.r + check.r && ball.vel.mag() > minSpeed)
      {
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
        
    pushMatrix();
    translate(ball.pos.x, ball.pos.y, ball.pos.z);
    sphere(ball.r);
    popMatrix();
  }
}
