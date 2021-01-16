//
//  ViewController.m
//  Trial
//
//  Created by Sehgal, Abhishek on 3/6/15.
//  
//  Copyright (c) 2015 UT Dallas. All rights reserved.
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "IosAudioController.h"

@interface ViewController ()


@end

@implementation ViewController


- (void)buttonDisable{
    [_buttonStart setEnabled:NO];
    [_buttonRead setEnabled:NO];
    [_slider setEnabled:NO];
    [_frameSize setEnabled:NO];
    [_playAudio setEnabled:NO];
    [_stepSize setEnabled:NO];
    [_outputType setEnabled: YES];
    [_buttonStop setEnabled:YES];
    [_debugClassification setEnabled:NO];
    [_switchQuietAdjustment setEnabled:NO];
    [_selectNoiseType_Button setEnabled:NO];
    [_selectNoise_Speech_Button setEnabled:NO];
}

- (void)buttonEnable{
    [_buttonStart setEnabled:YES];
    [_buttonRead setEnabled:YES];
    [_slider setEnabled:YES];
    [_frameSize setEnabled:YES];
    [_stepSize setEnabled:YES];
    [_playAudio setEnabled:YES];
    [_outputType setEnabled:NO];
    [_buttonStop setEnabled:NO];
    [_debugClassification setEnabled:YES];
    [_switchQuietAdjustment setEnabled:YES];
    
}

- (IBAction)pressPlay:(id)sender {
    
    //setMic(NO);
    //_myUITextView.text = [_myUITextView.text stringByAppendingString:[NSString stringWithFormat:@"\nReading File :\n"]];
    //[iosAudio start];
    setUserDefaults();
    [self changeLabel:-1];
    if (_debugClassification.isOn) {
        
        NSDateFormatter *formatter;
        NSString *dateString;
        NSString *vadClass;
        NSString *noiseClass;
        
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM_dd_yyyy_HH_mm_ss"];
        
        if(_selectNoise_Speech_Button.isHidden) vadClass = @"VAD";
        else {
            switch (_selectNoise_Speech_Button.selectedSegmentIndex) {
                case 0:
                    vadClass = @"Noise";
                    break;
                case 1:
                    vadClass = @"Speech_Noisy";
                    break;
                default:
                    vadClass = @"Discard_Exc_1"; //discard file if falls under this exception
                    break;
            }
        }
        if(_selectNoiseType_Button.isHidden) noiseClass = @"NC";
        else{
            switch (_selectNoiseType_Button.selectedSegmentIndex) {
                case 0:
                    //                noiseClass = @"Non_Stationary";
                    noiseClass = @"Babble";
                    break;
                case 1:
                    //                noiseClass = @"Stationary";
                    noiseClass = @"Machinery";
                    break;
                case 2:
                    //                noiseClass = @"Semi-Stationary";
                    noiseClass = @"Traffic";
                    break;
                default:
                    noiseClass = @"Discard_Exc_2"; //discard file if falls under this exception
                    break;
            }
        }
        
        //        vadClass = @"Noise";
        //        noiseClass = @"Non_Stationary";
        
        dateString = [formatter stringFromDate:[NSDate date]];
        
        NSLog(@"%@",[NSString stringWithFormat:@"%@_%@_Feature_Data_%@",vadClass, noiseClass, dateString]);
        
        setTextFile([NSString stringWithFormat:@"%@_%@_Feature_Data_%@",vadClass, noiseClass, dateString]);
    }
    [self buttonDisable];
    
}

- (IBAction)enableFeatureClass:(id)sender{
    setStoreFeature(_debugClassification.isOn);
    if(_debugClassification.isOn && _debugClassification.isEnabled){
        [_selectNoiseType_Button setEnabled:YES];
        [_selectNoise_Speech_Button setEnabled:YES];
    } else {
        [_selectNoiseType_Button setEnabled:NO];
        [_selectNoise_Speech_Button setEnabled:NO];
    }
}

- (IBAction)pressStart:(id)sender {
    setMic(YES);
    setUserDefaults();
    _labelNoise.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    _labelSpeech.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    _myNCTextView.text = [_myNCTextView.text stringByAppendingString:@"\nRecording Audio:\n"];
    
    if (_debugClassification.isOn) {

        NSDateFormatter *formatter;
        NSString *dateString;
        NSString *vadClass;
        NSString *noiseClass;
    
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM_dd_yyyy_HH_mm_ss"];
        
        if(_selectNoise_Speech_Button.isHidden) vadClass = @"VAD";
        else {
            switch (_selectNoise_Speech_Button.selectedSegmentIndex) {
                case 0:
                    vadClass = @"Noise";
                    break;
                case 1:
                    vadClass = @"Speech_Noisy";
                    break;
                default:
                    vadClass = @"Discard_Exc_1"; //discard file if falls under this exception
                    break;
            }
        }
        if(_selectNoiseType_Button.isHidden) noiseClass = @"NC";
        else{
            switch (_selectNoiseType_Button.selectedSegmentIndex) {
                case 0:
    //                noiseClass = @"Non_Stationary";
                    noiseClass = @"Babble";
                    break;
                case 1:
    //                noiseClass = @"Stationary";
                    noiseClass = @"Machinery";
                    break;
                case 2:
    //                noiseClass = @"Semi-Stationary";
                    noiseClass = @"Traffic";
                    break;
                default:
                    noiseClass = @"Discard_Exc_2"; //discard file if falls under this exception
                    break;
            }
        }
        
//        vadClass = @"Noise";
//        noiseClass = @"Non_Stationary";
    
        dateString = [formatter stringFromDate:[NSDate date]];
    
        NSLog(@"%@",[NSString stringWithFormat:@"%@_%@_Feature_Data_%@",vadClass, noiseClass, dateString]);
    
        setTextFile([NSString stringWithFormat:@"%@_%@_Feature_Data_%@",vadClass, noiseClass, dateString]);
    }
    [iosAudio start];
    [self buttonDisable];
}




- (IBAction)pressStop:(id)sender {
    [iosAudio stop];
   // _myNCTextView.text = [_myNCTextView.text stringByAppendingString:@"\nStopped\n"];
    [_myNCTextView scrollRangeToVisible:NSMakeRange([[_myNCTextView text] length], 0)];
    [self changeLabel:-1];
    [self buttonEnable];
    if(_debugClassification.isOn && _debugClassification.isEnabled){
        [_selectNoiseType_Button setEnabled:YES];
        [_selectNoise_Speech_Button setEnabled:YES];
    } else {
        [_selectNoiseType_Button setEnabled:NO];
        [_selectNoise_Speech_Button setEnabled:NO];
    }
}

-(BOOL) stringIsNumeric:(NSString *) str {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSNumber * number = [formatter numberFromString:str];
    return !!number;
}

- (IBAction)frameSizeChange:(id)sender {
    
    if (![self stringIsNumeric:_frameSize.text]) {
        if([_frameSize.text rangeOfString:@"."].location != NSNotFound){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Improper Value Entered"
                                                        message:@"Please enter only positive integer values"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
            [alert show];
            [_frameSize becomeFirstResponder];
        }
    }
    
    setFrameSize(_frameSize.text.intValue);
    
}

- (IBAction)sliderChanged:(id)sender {
    
    switch ((int)_slider.value){
        case 1:
            setValue(8000);
            break;
        case 2:
            setValue(11025);
            break;
        case 3:
            setValue(12000);
            break;
        case 4:
            setValue(16000);
            break;
        case 5:
            setValue(22050);
            break;
        case 6:
            setValue(24000);
            break;
        case 7:
            setValue(32000);
            break;
        case 8:
            setValue(44100);
            break;
        case 9:
            setValue(48000);
            break;
        default:
            setValue(8000);
            break;
    }
    _samplingFrequency.text = [NSString stringWithFormat:@"Sampling Frequency: %d Hz", getValue()];
    setFrameSize(_frameSize.text.floatValue);
    setStepSize(_stepSize.text.floatValue);
}

- (BOOL) shouldAutorotate{
    return NO;
}

- (IBAction)playAudioChanged:(id)sender {
    setPlayAudio(_playAudio.isOn);
}

- (IBAction)outputTypeChanged:(id)sender {
    if (_outputType.isOn) {
        _outputLabel.text = @"Audio Output: Enhanced";
    } else {
        _outputLabel.text = @"Audio Output: Original";
    }
    setOutputType(_outputType.isOn);
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
    //[ endEditing:YES];
    [super touchesBegan:touches withEvent:event];
    setFrameSize(_frameSize.text.floatValue);
    setStepSize(_stepSize.text.floatValue);
}

- (void)sliderMoved:(UISlider *)mySlider {
    mySlider.value = round(mySlider.value);
}

- (void)changeLabel: (int) vadOutput {
    switch (vadOutput) {
        case 0:
            _labelQuiet.backgroundColor =[UIColor colorWithRed:0 green:0.1 blue:0.6 alpha:0.25];
            _labelNoise.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
            _labelSpeech.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
            break;
        case 1:
            _labelQuiet.backgroundColor =[UIColor colorWithRed:0 green:0 blue:0 alpha:0];
            _labelNoise.backgroundColor = [UIColor colorWithRed:0.6 green:0 blue:0.3 alpha:0.25];
            _labelSpeech.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
            break;
        case 2:
            _labelQuiet.backgroundColor =[UIColor colorWithRed:0 green:0 blue:0 alpha:0];
            _labelNoise.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
            _labelSpeech.backgroundColor = [UIColor colorWithRed:0 green:0.6 blue:0.3 alpha:0.25];
            break;
            
        default:
            _labelQuiet.backgroundColor =[UIColor colorWithRed:0 green:0 blue:0 alpha:0];
            _labelNoise.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
            _labelSpeech.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
            break;
    }
}

- (IBAction)quietAdjusted:(id)sender {
    
    setQuietAdjustment((float)_switchQuietAdjustment.value);
    _labelQuietAdjustment.text = [NSString stringWithFormat:@"Quiet Adjustment: %.0f dB SPL",getQuietAdjustment()];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    loadUserDefaults();
    [_buttonStop setEnabled:NO];
    [_outputType setEnabled:NO];
    [_selectNoiseType_Button setEnabled:NO];
    [_selectNoise_Speech_Button setEnabled:NO];
    _samplingFrequency.text = [NSString stringWithFormat:@"Sampling Frequency: %d Hz", getValue()];
    _outputLabel.text = @"Audio Output: Original";
    _playAudio.on = getPlayAudio();
    _debugClassification.on = getStoreFeature();
    _outputType.on = getOutputType();
    
    /*------------------------*/
    
    _slider.minimumValue = 1;
    _slider.maximumValue = 9;
    [_slider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
    _slider.value = getValueSwitchCase(getValue());
    float frame = 1 * (float)getFrameSize()/getValue();
    _frameSize.text = [NSString stringWithFormat:@"%.2f",(1e3 * frame)];
    _stepSize.text = [NSString stringWithFormat:@"%.2f",getDecisionRate()];
    _labelQuietAdjustment.text = [NSString stringWithFormat:@"Quiet Adjustment: %.0f dB SPL",getQuietAdjustment()];
    
    _labelNoise.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    _labelSpeech.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];

    /*------------------------*/
    _myNCTextView.text = @"";
    _myNCTextView.textColor = [UIColor blackColor];
    _myNCTextView.font = [UIFont systemFontOfSize:12];
    [_myNCTextView setBackgroundColor:[UIColor clearColor]];
    _myNCTextView.editable = NO;
    _myNCTextView.scrollEnabled = YES;
    setView((__bridge void *)(_myNCTextView));
    setViewController((__bridge void *)self);
    
    if (!getMic()) {
        [self buttonDisable];
    }
    
    /*-------------------------*/
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
