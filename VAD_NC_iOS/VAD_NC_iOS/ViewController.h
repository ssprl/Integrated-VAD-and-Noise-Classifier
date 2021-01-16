//
//  ViewController.h
//  Trial
//
//  Created by Sehgal, Abhishek on 3/6/15.
//  
//  Copyright (c) 2015 UT Dallas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlobalVariable.h"

@interface ViewController : UIViewController {
    
}

@property (weak, nonatomic) IBOutlet UIButton *buttonStart;
@property (weak, nonatomic) IBOutlet UIButton *buttonRead;
@property (weak, nonatomic) IBOutlet UIButton *buttonStop;

@property (weak, nonatomic) IBOutlet UILabel *samplingFrequency;
@property (weak, nonatomic) IBOutlet UITextField *frameSize;
@property (weak, nonatomic) IBOutlet UITextView *myNCTextView;
@property (weak, nonatomic) IBOutlet UIView *settingsView;

@property (weak, nonatomic) IBOutlet UITextField *stepSize;
@property (strong, nonatomic, retain) IBOutlet UISwitch *playAudio;
@property (weak, nonatomic) IBOutlet UISwitch *outputType;
@property (weak, nonatomic) IBOutlet UILabel *outputLabel;

@property (weak, nonatomic) IBOutlet UIStepper *switchQuietAdjustment;

@property (weak, nonatomic) IBOutlet UILabel *labelNoise;
@property (weak, nonatomic) IBOutlet UILabel *labelSpeech;
@property (weak, nonatomic) IBOutlet UILabel *labelQuiet;
@property (weak, nonatomic) IBOutlet UILabel *labelFrameProcessingTime;
@property (weak, nonatomic) IBOutlet UILabel *labeldBPower;

@property (weak, nonatomic) IBOutlet UILabel *labelQuietAdjustment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *selectNoise_Speech_Button;
@property (weak, nonatomic) IBOutlet UISegmentedControl *selectNoiseType_Button;

- (IBAction)pressPlay:(id)sender;
- (IBAction)pressStart:(id)sender;
- (IBAction)pressStop:(id)sender;
- (void)buttonEnable;
- (void)buttonDisable;
- (void)changeLabel:(int)vadOutput;
- (IBAction)enableFeatureClass:(id)sender;

@property (weak, nonatomic) IBOutlet UISwitch *debugClassification;

@property (weak, nonatomic) IBOutlet UISlider *slider;

@end

