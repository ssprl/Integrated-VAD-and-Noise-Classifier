//
//  GlobalVariable.m
//  Trial
//
//  Created by Sehgal, Abhishek on 3/20/15.
//  
//  Copyright (c) 2015 UT Dallas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GlobalVariable.h"

static int samplingFrequency = 48000;
static int frameSize = 480;
static int stepSize = 240;
static void* view;
static void* viewControllerPointer;
UITextView *textView;
UILabel *classifierOutput;
static BOOL micStatus = 1;
static BOOL playAudio = 0;
static BOOL outputType = 0;
static BOOL storeFeature = 0;
static NSString *fileName = @"TestSignal";
static NSString *textFile;
static float decisionRate = 1.0;
static float quietAdjustment = 52.0;

NSUserDefaults *defaults;


void setUserDefaults() {
    defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"Initialized"]) {
        [defaults setInteger:   samplingFrequency  forKey:@"Sampling Frequency"];
        [defaults setInteger:   frameSize          forKey:@"Frame Size"];
        [defaults setFloat:     decisionRate       forKey:@"Decision Rate"];
        [defaults setFloat:     quietAdjustment    forKey:@"Quiet Adjustment"];
        [defaults setBool:      playAudio          forKey:@"Play Audio"];
        //[defaults setBool:      storeFeature       forKey:@"Store Features"];
    }
    else{
        [defaults setBool:      TRUE    forKey:@"Initialized"];
        [defaults setInteger:   48000   forKey:@"Sampling Frequency"];
        [defaults setInteger:   480     forKey:@"Frame Size"];
        [defaults setFloat:     1.0     forKey:@"Decision Rate"];
        [defaults setFloat:     52.0    forKey:@"Quiet Adjustment"];
        [defaults setBool:      FALSE   forKey:@"Play Audio"];
        //[defaults setBool:      FALSE   forKey:@"Store Features"];
    }
    [defaults synchronize];
}

void loadUserDefaults() {
    defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"Initialized"]) {
        samplingFrequency   = (int)[defaults  integerForKey:@"Sampling Frequency"];
        frameSize           = [defaults floatForKey:@"Frame Size"];
        decisionRate        = [defaults floatForKey:@"Decision Rate"];
        quietAdjustment     = [defaults floatForKey:@"Quiet Adjustment"];
        playAudio           = [defaults boolForKey:@"Play Audio"];
        //storeFeature        = [defaults boolForKey:@"Store Features"];
    }
}

void setQuietAdjustment(float set) {
    quietAdjustment = set;
}

float getQuietAdjustment() {
    return quietAdjustment;
}

void setDecisionRate(float set){
    decisionRate = set;
}
float getDecisionRate(){
    return decisionRate;
}

void setTextFile(NSString *set) {
    textFile = set;
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt",textFile]];
    
    [[NSFileManager defaultManager] createFileAtPath:path contents:[NSData new] attributes: nil];
}

NSString* getTextFile() {
    return textFile;
}

void setFileName(void* set) {
    fileName = (__bridge NSString *)(set);
}

void* getFileName() {
    return (__bridge void *)(fileName);
}

void setViewController(void* set) {
    viewControllerPointer = set;
}

void* getViewController() {
    return viewControllerPointer;
}

void setMic(BOOL set)
{
    micStatus = set;
}

BOOL getMic()
{
    return micStatus;
}

void setPlayAudio(BOOL set)
{
    playAudio = set;
}

BOOL getPlayAudio()
{
    return playAudio;
}

void setStoreFeature(BOOL set){
    storeFeature = set;
}

BOOL getStoreFeature(){
    return storeFeature;
}

void setOutputType(BOOL set)
{
    outputType = set;
}

BOOL getOutputType()
{
    return outputType;
}

void setValue(int set)
{
    samplingFrequency = set;
}

int getValue()
{
    return samplingFrequency;
}

void setFrameSize(float set)
{
    frameSize = (int)(set * samplingFrequency/1e3);
}

int getFrameSize()
{
    return frameSize;
}

void setStepSize(float set)
{
    stepSize = (int)(set * samplingFrequency/1e3);
}

int getStepSize()
{
    return (int)frameSize/2;
}

void setView(void* set)
{
    view = set;
}

void* getView()
{
    return view;
}

void printTime(float duration, int class, int noiseClass, const char* noiseClassLabel, float dbPower){
    
        NSString *noiseClassStr;
    
        // Select class based on noise classifier output
        switch (noiseClass) {
            case 1:
//                noiseClassStr = @"Non-Stationary";
                noiseClassStr = @"Class1";//@"Babble/Restaurant/Cafe babble";
                break;
            case 2:
//                noiseClassStr = @"Semi-Stationary";
                noiseClassStr = @"Class2";//@"Driving-Car";
                break;
            case 3:
                //noiseClassStr = @"Stationary";
                noiseClassStr = @"Class3";//@"Machinery";
                break;
            default:
                noiseClassStr = @"Quiet";
                break;
        }
    
    
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
        ViewController* viewController = (__bridge ViewController *)(viewControllerPointer);
        [viewController changeLabel:class];
        viewController.labelFrameProcessingTime.text = [NSString stringWithFormat:@"Frame Processing Time: %.2f ms",duration*1e3];
        viewController.labeldBPower.text = [NSString stringWithFormat:@"SPL: %.0f dB", dbPower];
        if(class == 1){
            textView = (__bridge UITextView *)(view);
            NSString *status = [NSString stringWithFormat:@"Noise Class : %s\n", noiseClassLabel];
            textView.text = [textView.text stringByAppendingString:status];
            [textView scrollRangeToVisible:NSMakeRange([[textView text] length], 0)];
        }
    });
    
    
    
    
    if(/* DISABLES CODE */ (0)) { //view.debugClassification.isOn) {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* documentsDirectory = [paths objectAtIndex:0];
        NSString* path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt",textFile]];
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[[NSString stringWithFormat:@"%d\n",class] dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    }
    
    
}

void enableButtons() {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        ViewController* viewController = (__bridge ViewController *)(viewControllerPointer);
        [viewController buttonEnable];
    });
}

int getValueSwitchCase(int input) {
    switch (input){
        case 8000:
            return 1;
            break;
        case 11025:
            return 2;
            break;
        case 12000:
            return 3;
            break;
        case 16000:
            return 4;
            break;
        case 22050:
            return 5;
            break;
        case 24000:
            return 6;
            break;
        case 32000:
            return 7;
            break;
        case 44100:
            return 8;
            break;
        case 48000:
            return 9;
            break;
        default:
            return 1;
            break;
    }
}
