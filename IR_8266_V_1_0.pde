// import UDP library
import hypermedia.net.*;


UDP udp;  // define the UDP object
String str = null;

String ip       = "192.168.1.144";  // the remote IP address
int port        = 4210;    // the destination port


void setup() {
  udp = new UDP( this, 55056 );    //incoming port;
  udp.log( true );     // <-- printout the connection activity
  udp.listen( true );
  size(1023, 1023);
}

void draw_position()
{
  int[] splitStr = int (split(str, ','));
  print(str);
  if(str.charAt(0) == 's')
  {
    str = null;                //reload str
    background(77);
    
    int xx = splitStr[1];
    int yy = splitStr[2];
    
    int ww = splitStr[3];
    int zz = splitStr[4];
    
    int xxx = splitStr[5];
    int yyy = splitStr[6];
    
    int www = splitStr[7];
    int zzz = splitStr[8];
    
    ellipseMode(RADIUS);  // Set ellipseMode to RADIUS
        fill(255, 0, 0);  // Set fill to white
        ellipse(xx, yy, 10, 10);
        ellipseMode(RADIUS);  // Set ellipseMode to RADIUS
        fill(0, 255, 0);  // Set fill to white
        ellipse(ww, zz, 10, 10);
        
        ellipseMode(RADIUS);  // Set ellipseMode to RADIUS
        fill(0, 0, 255);  // Set fill to white
        ellipse(xxx, yyy, 10, 10);
        ellipseMode(RADIUS);  // Set ellipseMode to RADIUS
        fill(255);  // Set fill to white
        ellipse(www, zzz, 10, 10);
        
        noFill();
        beginShape();
        vertex(xx, yy);
        vertex(ww, zz);
        vertex(www, zzz);
        vertex(xxx, yyy);
        endShape(CLOSE);
  }
}

void draw(){
 udp.send( "pull", ip, port );
 if(str != null) draw_position();
}

//receive data handler 
void receive( byte[] data, String ip, int port ) {  // <-- extended handler
  str = new String(data);
  println(str);
}