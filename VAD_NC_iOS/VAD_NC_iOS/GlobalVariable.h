//
//  GlobalVariable.h
//  Trial
//
//  Created by Sehgal, Abhishek on 3/20/15.
//  
//  Copyright (c) 2015 UT Dallas. All rights reserved.
//

#import "ViewController.h"

void setDecisionRate(float set);
float getDecisionRate(void);

void setQuietAdjustment(float set);
float getQuietAdjustment(void);

void setTextFile(NSString *set);
NSString* getTextFile(void);

void setFileName(void* set);
void* getFileName(void);

void setViewController(void* set);
void* getViewController(void);

void setPlayAudio(BOOL set);
BOOL getPlayAudio(void);

void setStoreFeature(BOOL set);
BOOL getStoreFeature(void);

void setOutputType(BOOL set);
BOOL getOutputType(void);

void setMic(BOOL set);
BOOL getMic(void);

void setValue(int set);
int getValue(void);

void setFrameSize(float set);
int getFrameSize(void);

void setStepSize(float set);
int getStepSize(void);

void setView(void* set);
void* getView(void);

void printTime(float duration, int class, int noiseClass, const char* noiseClassLabel, float dbPower);

void enableButtons(void);

int getValueSwitchCase(int input);
void setUserDefaults(void);
void loadUserDefaults(void);
