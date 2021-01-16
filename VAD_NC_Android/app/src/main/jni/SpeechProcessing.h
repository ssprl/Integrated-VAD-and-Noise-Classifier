//
//  SpeechProcessing.h
//  SPP RF+SB
//
//  Created by Sehgal, Abhishek on 5/4/15.
//  Copyright (c) 2015 UT Dallas. All rights reserved.
//

#ifndef __Speech_Processing_Pipeline__SpeechProcessing__
#define __Speech_Processing_Pipeline__SpeechProcessing__

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "Transforms.h"
#include "SubbandFeatures.h"
#include "VADFeatures.h"
#include "VADRandomForest.h"
#include "NCRandomForest.h"

typedef struct Variables {
    Transform* fft;
    SubbandFeatures* sbf;
    VADFeatures* vf;
    VADRandomForests* vrf;
    NCRandomForests* rf;
    float* inputBuffer;
    float* outputBuffer;
    short* originalInput;
    float* allFeatureList;
    int nFeatures;
    int frequency;
    int stepSize;
    int windowSize;
    int overlap;
    int detectedClass;
    int noiseClass;
    int firstFrame;
    int decisionBufferLength;
    int warmup;
    int warmupNC;
} Variables;

long* initialize(int frequency, int stepsize, int windowSize, int decisionBufferLength, float decisionRate);
void compute(long* memoryPointer, float* input, float* output, int outputType, float quiet);
int getVADClass(long* memoryPointer);
void VADDecisionSmoothing(Variables* vars);
void NCDecisionSmoothing(Variables* vars);
int getNoiseClass(long* memoryPointer);
const char* getNoiseClassLabel(long* memoryPointer);
void copyArray(long* memoryPointer, float* array);
int getElements(long* memoryPointer);
float getdbPower(long* memoryPointer);


#endif /* defined(__Speech_Processing_Pipeline__SpeechProcessing__) */
