#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <Wire.h>

const char* ssid     = "IR_POS";  
const char* password = "00aaff9900"; 

bool blG = false, blB = false;

WiFiUDP Udp;
WiFiServer server(88); 

IPAddress Ip(192, 168, 1, 1);
IPAddress NMask(255, 255, 255, 0);

unsigned int localUdpPort = 4210;  // local port to listen on
char incomingPacket[255];  // buffer for incoming packets
char  replyPacekt[] = "Hi there! Got the message :-)";  // a reply string to send back
char chBuff[50];

int IRsensorAddress = 0xB0;
int slaveAddress;
int led_red = 15;
int led_green = 12;
int led_blue = 13;
int sda = 4;
int scl = 5;

int iLoop = 0;

byte data_buf[16];

int Ix[4];
int Iy[4];

void led_status(boolean r, boolean g, boolean b)
{
    digitalWrite(led_red, r);
    digitalWrite(led_green, g);
    digitalWrite(led_blue, b);
}

void Write_2bytes(byte d1, byte d2)
{
    Wire.beginTransmission(slaveAddress);
    Wire.write(d1); Wire.write(d2);
    Wire.endTransmission();
}

void setup() 
{
    slaveAddress = IRsensorAddress >> 1;   // This results in 0x21 as the address to pass to TWI
    Serial.begin(115200);   
    pinMode(led_red, OUTPUT);
    pinMode(led_green, OUTPUT);
    pinMode(led_blue, OUTPUT);
    led_status(1, 0, 0); 
    Wire.begin(sda,scl);
    // IR sensor initialize
    Write_2bytes(0x30,0x01); delay(10);
    Write_2bytes(0x30,0x08); delay(10);
    Write_2bytes(0x06,0x90); delay(10);
    Write_2bytes(0x08,0xC0); delay(10);
    Write_2bytes(0x1A,0x40); delay(10);
    Write_2bytes(0x33,0x33); delay(10);
    delay(100);
    Serial.println();
    Serial.println();
    Serial.print("Connecting to "); 
    Serial.println(ssid);
    WiFi.mode(WIFI_AP);
    WiFi.softAPConfig(Ip, Ip, NMask);
    WiFi.softAP(ssid, password);      
    //WiFi.begin(ssid, password); 
   /* IPAddress local_ip = {192,168,1,144};   
    IPAddress gateway={192,168,1,1}; 
    IPAddress subnet={255,255,255,0};  
    WiFi.config(local_ip,gateway,subnet);  */
    Udp.begin(localUdpPort) ;
    led_status(0, 0, 1);
    delay(3000);
    led_status(0, 1, 0);
    Serial.println("IR Position soft AP has been already.");  
}

void IR_read()
{
  int s;
  int i = 0;
  //IR sensor read
    Wire.beginTransmission(slaveAddress);
    Wire.write(0x36);
    Wire.endTransmission();

    Wire.requestFrom(slaveAddress, 16);        // Request the 2 byte heading (MSB comes first)
    for (i=0;i<16;i++) { data_buf[i]=0; }
    i=0;
    while(Wire.available() && i < 16) { 
        data_buf[i] = Wire.read();
        i++;
    }

    Ix[0] = data_buf[1];
    Iy[0] = data_buf[2];
    s   = data_buf[3];
    Ix[0] += (s & 0x30) <<4;
    Iy[0] += (s & 0xC0) <<2;

    Ix[1] = data_buf[4];
    Iy[1] = data_buf[5];
    s   = data_buf[6];
    Ix[1] += (s & 0x30) <<4;
    Iy[1] += (s & 0xC0) <<2;

    Ix[2] = data_buf[7];
    Iy[2] = data_buf[8];
    s   = data_buf[9];
    Ix[2] += (s & 0x30) <<4;
    Iy[2] += (s & 0xC0) <<2;

    Ix[3] = data_buf[10];
    Iy[3] = data_buf[11];
    s   = data_buf[12];
    Ix[3] += (s & 0x30) <<4;
    Iy[3] += (s & 0xC0) <<2;
    
    Udp.beginPacket("192.168.1.74", Udp.remotePort());
    sprintf(chBuff, "s,%d,%d,%d,%d,%d,%d,%d,%d,\n", Ix[0],Iy[0],Ix[1],Iy[1],Ix[2],Iy[2],
    Ix[3],Iy[3]);
    Udp.write(chBuff);
    Udp.endPacket();
    delay(15);
    led_status(0, 0, blB);
    blB = !blB;
}

void loop() 
{
  IR_read();
  iLoop++;
  if(iLoop > 10)
  {
    led_status(0, blG, 0);
    blG = !blG;
    iLoop = 0;
  }
}
