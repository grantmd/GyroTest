/*
  The simplest possible test code for the ITG-3200 gyro, specifically as packaged
  in the IMU Digital Combo Board - 6 Degrees of Freedom ITG3200/ADXL345 from Sparkfun:
  http://www.sparkfun.com/products/10121
  
  Created by Myles Grant <myles@mylesgrant.com>
  See also: https://github.com/grantmd/QuadCopter
  
  This program is free software: you can redistribute it and/or modify 
  it under the terms of the GNU General Public License as published by 
  the Free Software Foundation, either version 3 of the License, or 
  (at your option) any later version. 

  This program is distributed in the hope that it will be useful, 
  but WITHOUT ANY WARRANTY; without even the implied warranty of 
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
  GNU General Public License for more details. 

  You should have received a copy of the GNU General Public License 
  along with this program. If not, see <http://www.gnu.org/licenses/>. 
*/

#include <Wire.h>

#define I2C_ADDR 0x68 // The i2c address of the gyro

unsigned long previousTime = 0;

void setup(){
  Serial.begin(115200);
  Wire.begin();
  
  gyroInit();
  
  previousTime = millis();
}

void loop(){
  if (millis() - previousTime >= 5000){
    readAll();
    
    Serial.print("Temp: ");
    Serial.println(getTemp());
    
    
    previousTime = millis();
  }
}

// Verify the gyro is present and write some configuration to it
void gyroInit(){
  Serial.println("Initing Gyro");
  
  if (!getAddressFromDevice()){
    Serial.println("GYRO NOT CONNECTED!");
  }
  else{
    writeSetting(0x3E, 0x80); // Reset it
    delay(50); // Give it some time to startup (20ms from the datasheet, plus wiggle room!)
    writeSetting(0x16, 0x1D); // 10Hz low pass filter/1kHz internal sample rate
    writeSetting(0x3E, 0x01); // use X gyro oscillator
  }
}

// Read "all" the data off the gyro and print it
void readAll(){
  sendReadRequest(0x1D);
  requestBytes(6);

  for (byte axis = 0; axis <= 2; axis++) {
    Serial.print("Axis ");
    Serial.print(axis);
    Serial.print(": ");
    Serial.println(readNextWordFlip());
  }
}

int getTemp(){
  sendReadRequest(0x1B);
  int temp = readWord();
  temp = 35.0 + ((temp + 13200) / 280.0); // -13200 == 35C, 280 == Each degree
  temp = 32 + (temp * 1.8); // Convert to F
  
  return temp;
}

//
// I2C helper functions
//

// Read the address off of the device
byte getAddressFromDevice(){
  sendReadRequest(0x00);
  return readByte();
}

// Write a setting to the device at register data_address
byte writeSetting(byte data_address, byte data_value){
  Wire.beginTransmission(I2C_ADDR);
  Wire.send(data_address);
  Wire.send(data_value);
  return Wire.endTransmission();
}

// Tell the device that we will be reading from register data_address
byte sendReadRequest(byte data_address){
  Wire.beginTransmission(I2C_ADDR);
  Wire.send(data_address);
  return Wire.endTransmission();
}

// Request 2 bytes and read it
word readWord(){
  requestBytes(2);
  return ((Wire.receive() << 8) | Wire.receive());
}

// Request 2 bytes and read it
word readWordFlip(){
  requestBytes(2);
  byte one = Wire.receive();
  byte two = Wire.receive();
  return ((two << 8) | one);
}

// Request a byte and read it
byte readByte(){
  requestBytes(1);
  return Wire.receive();
}

// Request some number of bytes
void requestBytes(int bytes){
  Wire.beginTransmission(I2C_ADDR);
  Wire.requestFrom(I2C_ADDR, bytes);
}

// Read the next available byte
byte readNextByte(){
  return Wire.receive();
}

// Read the next available 2 bytes
word readNextWord(){
  return ((Wire.receive() << 8) | Wire.receive());
}

// Read the next available 2 bytes
word readNextWordFlip(){
  byte one = Wire.receive();
  byte two = Wire.receive();
  return ((two << 8) | one);
}
