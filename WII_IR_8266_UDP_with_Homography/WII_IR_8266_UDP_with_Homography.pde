import controlP5.*;
import hypermedia.net.*;

/**
   *  Global variable
  */
UDP udp;  // define the UDP object
String str = null;

String ip       = "192.168.1.144";  // the remote IP address
int port        = 4210;    // the destination port

final double dbRefWidth = 100;
final double dbRefHeight = 100;
final int radius = 5;

int bgColor = 0;

boolean boolCalib = false, boolInit = false, boolClicked = false;

PVector[] cam = new PVector[10];
PVector mouseP = new PVector();
PVector objMoving = new PVector();
PVector objLastMoving = new PVector();
SimpleMatrix matrixH;

ControlP5 cp5;

int c1,c2;

// The system time for this and the previous frame (in milliseconds)
int currTime, prevTime;
// The elapsed time since the last frame (in seconds)
float deltaTime;

Homography h;


public class Homography{
  
  /**
   *  the 3x3 matrix
  */
  double H[][] = new double[3][3];
  SimpleMatrix matH = new SimpleMatrix(H);
  
  /**
   * whether to display debug messages
   */
  public boolean debug = false; 
  
  /**
   * the parent processing sketch
   */
  PApplet parent;

  public Homography() {
    this(null);
  }

  public Homography(PApplet p){
          parent= p;
  }
  
  /**
   * Estimate the homography between the camera and the projected image using an
   * array of known correspondences. The four corners of the sketch are good for this.
   * 
   * @param cam an array of points in camera coordinates
   */
   
   public void computeHomography(PVector[] cam,double w, double h){
           // Creates an array of two times the size of the cam[] array 
           //double[][] a = new double[2*cam.length][];
           double[][] a = { {cam[0].x, cam[0].y, 1, 0, 0, 0, 0, 0, 0},
                             {cam[1].x, cam[1].y, 1, 0, 0, 0, 0, 0, 0},
                             {cam[2].x, cam[2].y, 1, 0, 0, 0,  -cam[2].x * w, -cam[2].y * w, w},
                             {cam[3].x, cam[3].y, 1, 0, 0, 0,  -cam[3].x * w, -cam[3].y * w, w},
                             {0, 0, 0, cam[0].x, cam[0].y, 1, 0, 0, 0},
                             {0, 0, 0, cam[1].x, cam[1].y, 1, -cam[1].x * h, -cam[1].y, -h},
                             {0, 0, 0, cam[2].x, cam[2].y, 1, -cam[2].x * h, -cam[2].y, -h},
                             {0, 0, 0, cam[3].x, cam[3].y, 1, 0, 0, 0}
           };
          
              SimpleMatrix matA = new SimpleMatrix(a);
              SimpleSVD svd = matA.svd();
              SimpleMatrix V = svd.getV();
              
               double[] params = new double[9];
                for (int j=0; j<9; ++j) {
                  params[j] = V.get(j, 8);
                }
  
              //matrix reshape
              int j = 0;
              for(int m = 0; m < 3; m++)
              {
                for(int n = 0; n < 3; n++)
                {
                  H[m][n] = params[j++];
                }
              } 
              
              matH = new SimpleMatrix(H);
              matrixH = matH;
       }       
   
   public PVector applyHomography(PVector p){
        double[][] a = new double[3][1];
        a[0][0] = p.x;
        a[1][0] = p.y;
        a[2][0] = 1;
        SimpleMatrix matA = new SimpleMatrix(a);
        SimpleMatrix matU = matH.mult(matA);
        //SimpleMatrix matY = matU.times(1/matU.get(2,0));
        PVector p2 = new PVector();
        double x = matU.get(0, 0)/matU.get(2, 0);
        double y = matU.get(1, 0)/matU.get(2, 0);
        p2.x = (int)x;
        p2.y = (int)y;
        return p2;
   }
}

void setup()
{
  size(1324, 768);
  noStroke();
  cam[0] = new PVector(295, 297);
  cam[1] = new PVector(490, 295);
  cam[2] = new PVector(479, 397);
  cam[3] = new PVector(272, 396);
  cp5 = new ControlP5(this);
  
  // create a new button with name 'calib'
  cp5.addButton("Calib")
     .setValue(100)
     .setPosition(width - 175 ,100)
     .setSize(50,50)
     ;
   boolInit = false;  
   
  udp = new UDP( this, 55056 );    //incoming port;
  udp.log( true );     // <-- printout the connection activity
  udp.listen( true );
  
  udp.send( "pull", ip, port );
}

void draw()
{
  background(bgColor);
  stroke(255,0,0);   
  strokeWeight(4);  // Thicker
  line(1024, 0, 1024 , height); 
  
  PVector[] centroid = new PVector[2];
  centroid[0] = new PVector();
  centroid[1] = new PVector();
  if(str != null) {
    centroid = draw_position();
  
    // get the current time
    currTime = millis();
    // calculate the elapsed time in seconds
    deltaTime = (currTime - prevTime)/1000.0;
    // remember current time for the next frame
    prevTime = currTime;
    
    //println(deltaTime);
   
    if(!boolInit)
    {
    textSize(60);
    fill(255, 0, 0);
    text("Waiting for Initilization", 200, height/2); 
    }
    
    if(boolInit)
    {
      //compute homography 
      h = new Homography();
      h.computeHomography(cam, dbRefWidth, dbRefHeight);
      textSize(16);
      fill(0, 255, 50);
      text("Homography Matix", 1030, 200); 
      
      //show Homography matrix value
      textSize(12);
      fill(0, 100, 255);
      for(int i = 0; i < 3; i++)
      text((float)matrixH.get(i,0) + "  ,  " + (float)matrixH.get(i,1) + "  ,  " + (float)matrixH.get(i,2) , 1030, 230 + (i*30)); 
      
      boolCalib = true;
      boolClicked = false;
    }
    
   /* if(boolCalib)
    {
      PVector[] centroid = new PVector[2];
      if(str != null) centroid = draw_position();
        pushMatrix();
        translate(mouseP.x, mouseP.y);
        polygon(0, 0, 10, 3);
        PVector origin = new PVector(mouseP.x, mouseP.y);
        PVector mouseTMP = new PVector(0,0);
        mouseTMP = new PVector(mouseX, mouseY);
        float d = PVector.dist(origin, mouseTMP);
        float a = PVector.angleBetween(origin, mouseTMP);
        popMatrix();
        pushMatrix();
        translate(mouseX, mouseY);
        textSize(20);
        fill(255, 255, 0);
        text(d + "," + a, 0, -40);
        popMatrix();
    }*/
    
    if(boolCalib)
    {
          h.computeHomography(cam, dbRefWidth, dbRefHeight);
          pushMatrix();
          translate(mouseP.x, mouseP.y);
          polygon(0, 0, 10, 3);
          PVector origin = new PVector(mouseP.x, mouseP.y);
          float d = PVector.dist(origin, centroid[0]);
          float a = PVector.angleBetween(origin, centroid[0]);
          popMatrix();
          pushMatrix();
          translate(centroid[0].x, centroid[0].y);
          textSize(20);
          fill(255, 255, 0);
          text(d + "," + a, 0, -40);
          popMatrix();
          string strMessage = str(d) + "\n";
          udp.send(strMessage, "192.168.1", 6000);
    }
  }
}

float cal_length(PVector p0, PVector p1)
{
  PVector temp;
  temp = new PVector(p1.x, p1.y);
  temp.sub(p0);
  return sqrt((temp.x * temp.x) +(temp.y * temp.y));
}

public PVector centroid_cal(PVector[] p)
{
  PVector[] pTF = new PVector[p.length];
  for(int i = 0; i < p.length; i++) pTF[i] = h.applyHomography(p[i]);
  PVector temp = new PVector();
  temp.x = (pTF[0].x + pTF[1].x + pTF[2].x) / 3;
  temp.y = (pTF[0].x + pTF[1].x + pTF[2].x) / 3;
  return temp;
}

public PVector[] draw_position()
{
  int[] splitStr = int (split(str, ','));
  PVector[] temp = new PVector[4];
  print(str);
  if(str.charAt(0) == 's')
  {
    str = null;                //reload str
    
    int xx = abs(splitStr[1] - 1023);
    int yy = abs(splitStr[2] - 1023);
    
    int ww = abs(splitStr[3] - 1023);
    int zz = abs(splitStr[4] - 1023);
    
    int xxx = abs(splitStr[5] - 1023);
    int yyy = abs(splitStr[6] - 1023);
    
    int www = abs(splitStr[7] - 1023);
    int zzz = abs(splitStr[8] - 1023);
    
    
    temp[0] = new PVector(xx,yy);
    temp[1] = new PVector(ww,zz);
    temp[2] = new PVector(xxx,yyy);
    temp[3] = new PVector(www,zzz);
    
    
    for(int i = 0; i < temp.length; i++)
    {
      ellipseMode(RADIUS);  // Set ellipseMode to RADIUS
      fill(255);  // Set fill to white
      ellipse(temp[i].x, temp[i].y, radius, radius);
    }    
    noFill();
    beginShape();
    for(int i = 0; i < temp.length; i++) vertex(temp[i].x, temp[i].y);
    endShape(CLOSE);
  }
  //for centroid position
  PVector[] centroid = new PVector[2];
  centroid[0] = new PVector((temp[0].x + temp[1].x) / 2, (temp[0].y + temp[3].y) / 2);
  ellipseMode(RADIUS); 
  fill(255, 0, 0);  
  ellipse(centroid[0].x, centroid[0].y, radius, radius);
  
  // for bow position
  centroid[1] = new PVector(centroid[0].x , temp[1].y);
  ellipseMode(RADIUS);  // Set ellipseMode to RADIUS
  fill(255, 0, 0);  // Set fill to white
  ellipse(centroid[1].x, centroid[1].y, radius, radius);
  return centroid;
}

void polygon(float x, float y, float radius, int npoints) {
  float angle = TWO_PI / npoints;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius;
    float sy = y + sin(a) * radius;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

//receive data handler 
void receive( byte[] data, String ip, int port ) {  // <-- extended handler
  str = new String(data);
  //println(str);
}

void mouseClicked() {
    mouseP.x = mouseX;
    mouseP.y = mouseY;
    println(mouseP);
}
public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
}

public void Calib(int theValue) {
  println("Calib Click");
  boolInit = true;
  c1 = c2;
  c2 = color(0,160,100);
}