/**
* @brief Ball class
*
*/
class Ball
{
  PVector pos, vel;
  float r;
  boolean hasHit = false;
  
  public Ball(float x, float y, float z, float r, float vx, float vy, float vz)
  {
    pos = new PVector(x, y, z);
    vel = new PVector(vx, vy, vz);
    this.r = r;
  }
  
  public Ball(float x, float y, float z, float r)
  {
    this(x, y, z, r, 0, 0, 0);
  }
}

ArrayList<Ball> balls = new ArrayList<Ball>();

void setup()
{
  size(400, 400, P3D);
  balls.add(new Ball(200f, 200f, -100f, 40f));
  balls.add(new Ball(100f, 150f, -100f, 40f, 1, 0, 0));
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
      if(d < ball.r + check.r && ball.vel.mag() != 0 || ball.hasHit)
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
        ball.vel = tang;
        
        //Adjust for the discrete timesteps
        PVector translation = vAnti.get();
        float magn = (vAnti.mag() - (check.r + ball.r)) / vAnti.mag();
        translation.set(translation.x * magn, translation.y * magn, translation.z * magn);
        
        //Fix the ball's position
        ball.pos.add(translation);
        
        fill(255, 0, 255);
      }
    }
        
    pushMatrix();
    translate(ball.pos.x, ball.pos.y, ball.pos.z);
    sphere(ball.r);
    popMatrix();
  }
}
