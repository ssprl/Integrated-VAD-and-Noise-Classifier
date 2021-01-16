//
//  SpeechProcessing.c
//  SPP RF+SB
//
//  Created by Sehgal, Abhishek on 5/4/15.
//  Copyright (c) 2015 UT Dallas. All rights reserved.
//

#include "SpeechProcessing.h"
#include <unistd.h>
#include <android/log.h>
#define  LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

static int count = 0;
static int countNC = 0;
//
static int* smoothingBuffer;
static int* smoothingBufferNC;
static int smoothingBufferLength;

//

inline int resolution8k(int samplingFrequency, int frameSize){
    int pow2Size = 0x01;
    while (pow2Size < frameSize)
    {
        pow2Size = pow2Size << 1;
    }
    float binResolution = (float) samplingFrequency/pow2Size;
    return (int)lround(16000.0/binResolution);
}


long* initialize(int frequency, int stepsize, int windowsize, int decisionBufferLength, float decisionRate)
{
    Variables* inParam = (Variables*) malloc(sizeof(Variables));
    inParam->fft = newTransform(windowsize, (int)(frequency/stepsize));
    inParam->overlap = windowsize - stepsize;
    inParam->frequency = frequency;
    inParam->stepSize = stepsize;
    inParam->windowSize = windowsize;
    inParam->inputBuffer = (float*)calloc(windowsize,sizeof(float));
    inParam->outputBuffer = (float*)malloc(stepsize*sizeof(float));
    inParam->originalInput = (short*)malloc(stepsize*sizeof(short));
    
    // initialize SubbandFeatures
    //inParam->sbf = initSubbandFeatures(inParam->fft->points, stepsize, decisionBufferLength);
    //inParam->vf  = initVADFeatures(inParam->fft->points, decisionBufferLength);
    inParam->sbf = initSubbandFeatures(resolution8k(frequency,windowsize), stepsize, decisionBufferLength);
    inParam->vf  = initVADFeatures(resolution8k(frequency,windowsize), decisionBufferLength);

    inParam->vrf = initVADRandomForest(decisionBufferLength);
    inParam->rf = initNCRandomForest();
    inParam->detectedClass = -1;
    inParam->noiseClass = -1;
    inParam->firstFrame = 1;
    inParam->decisionBufferLength = decisionBufferLength;
    count = 0;
    countNC = 0;
    
    inParam->nFeatures = 2 * inParam->sbf->nBands + inParam->vf->nFeatures - 2 - 6;
    inParam->allFeatureList = (float*)calloc(inParam->nFeatures, sizeof(float));
    
    inParam->warmup = 2 * decisionBufferLength;
    inParam->warmupNC = 2 * decisionBufferLength;
    
    //
    smoothingBufferLength = (int)(decisionRate*frequency)/(stepsize*decisionBufferLength);
    smoothingBuffer = calloc(sizeof(int), smoothingBufferLength);
    smoothingBufferNC = calloc(sizeof(int), smoothingBufferLength);
    //
    
    return (long*)inParam;
}

int getVADClass(long* memoryPointer)
{
    Variables* inParam = (Variables*)memoryPointer;
    
    return inParam->detectedClass;
}

int getNoiseClass(long* memoryPointer) {
    Variables* inParam = (Variables*)memoryPointer;
    return inParam->noiseClass;
}

const char* getNoiseClassLabel(long* memoryPointer) {
    Variables* inParam = (Variables*)memoryPointer;
    return returnNCClassLabel(inParam->noiseClass);
}


void compute(long* memoryPointer, float* input, float* output, int outputType, float quiet)
{
    Variables* inParam = (Variables*)memoryPointer;
    
    int i;
    
    for (i = 0; i < inParam->overlap; i++) {
        inParam->inputBuffer[i] = inParam->inputBuffer[inParam->stepSize + i];
    }
    
    for (i=0; i<inParam->stepSize; i++) {
        inParam->originalInput[i] = (short)(input[i] * 32768);
        inParam->inputBuffer[inParam->overlap + i] = input[i];
        //__android_log_print(ANDROID_LOG_DEBUG,"AudioInput","%f",inParam->inputBuffer[i]);
    }
    
    
    ForwardFFT(inParam->fft, inParam->inputBuffer);
    //__android_log_print(ANDROID_LOG_ERROR,"AudioIO","DB Log Power %f", inParam->fft->dbpower);

    if (inParam->fft->dbpower > (quiet)) {


/***....................Feature Extraction Starts...................***/

        computeSubbandFeatures(inParam->sbf, inParam->fft->power, inParam->firstFrame);
        computeVADFeatures(inParam->vf, inParam->fft->power);
        //Combine the features for VAD decision
        for (i = 0; i < 2 * inParam->sbf->nBands; i++) {
            inParam->allFeatureList[i] = inParam->sbf->subbandFeatureList[i];

        }
        for (i = 2 * inParam->sbf->nBands; i < inParam->vf->nFeatures - 1; i++) {
            //Changes for 11 features
            inParam->allFeatureList[i] = inParam->vf->VADFeatureList[i - (2 * inParam->sbf->nBands)];
        }
        //Changes for 11 features
        inParam->allFeatureList[inParam->nFeatures - 1] = inParam->vf->VADFeatureList[inParam->vf->nFeatures - 1];

/***....................Feature Extraction Ends.......................***/

        count++;

        if (count > inParam->warmup - 1) {

/***....................RF1:VAD Starts............................***/

            evalVADTrees(inParam->vrf, inParam->allFeatureList);
            VADDecisionSmoothing(inParam);

/***.....................RF1:VAD ENDs.............................***/


/***.....................RF2: Noise Classifier Starts.............***/

            if(inParam->detectedClass == 1){
                evalNCTrees(inParam->rf, inParam->sbf->subbandFeatureList);
                NCDecisionSmoothing(inParam);
            }

/***...................RF2: Noise Classifer Ends..................***/

            count = 0;
            inParam->warmup = inParam->decisionBufferLength;
        }
    }
    else {
        inParam->detectedClass = 0;
        inParam->noiseClass = 0;
        count = 0;
    }


}

void VADDecisionSmoothing(Variables* vars) {
    Variables* inParam = vars;
    inParam->detectedClass = inParam->vrf->vadClassDecision;

    int i, noise = 0, speech = 0;

    for (i = smoothingBufferLength - 1; i > 0; i--) {
        smoothingBuffer[i] = smoothingBuffer[i-1];
    }
    smoothingBuffer[0] = inParam->vrf->vadClassDecision;

    for (i = 0; i < smoothingBufferLength; i++) {
        switch (smoothingBuffer[i]) {
            case 1:
                noise++;
                break;
            case 2:
                speech++;
                break;
            default:
                break;
        }
    }

    if(noise > speech){
        inParam->detectedClass = 1;
    }
    else if (speech > noise) {
        inParam->detectedClass = 2;
    }
    else {
        inParam->detectedClass = 1;
    }
}

void NCDecisionSmoothing(Variables* vars) {
    Variables* inParam = vars;
    inParam->noiseClass = inParam->rf->classDecision;

    //Smoothing buffer: The decision is averaged over
    // a duration of 5 * Decision Buffer Length * step size
    int i = 0,class1 = 0, class2 = 0, class3 = 0;

    for (i = smoothingBufferLength - 1; i > 0; i--) {
        smoothingBufferNC[i] = smoothingBufferNC[i-1];
    }
    smoothingBufferNC[0] = inParam->rf->classDecision;

    for (i = 0; i < smoothingBufferLength; i++) {
        switch (smoothingBufferNC[i]) {
            case 1:
                class1++;
                break;
            case 2:
                class2++;
                break;
            case 3:
                class3++;
                break;
            default:
                break;
        }
    }

    if (class1 > class2) {
        if (class1 > class3) {
            inParam->noiseClass = 1;
        }
        else {
            inParam->noiseClass = 3;
        }
    }
    else if (class1 < class2){
        if (class2 > class3) {
            inParam->noiseClass = 2;
        }
        else {
            inParam->noiseClass = 3;
        }
    }
}

void copyArray(long* memoryPointer, float* array) {
    Variables* inParam = (Variables*)memoryPointer;
    
    int i;
    for (i = 0; i < inParam->nFeatures; i++)
    {
        array[i] = inParam->allFeatureList[i];
    }
    array[inParam->nFeatures] = inParam->detectedClass;
    array[inParam->nFeatures + 1] = inParam->vrf->vadClassDecision;
    array[inParam->nFeatures + 2] = inParam->noiseClass;
    array[inParam->nFeatures + 3] = inParam->rf->classDecision;
    
}

int getElements(long* memoryPointer) {
    Variables* inParam = (Variables*)memoryPointer;
    return inParam->nFeatures + 2 + 2;
}

float getdbPower(long* memoryPointer) {
    Variables* inParam = (Variables*)memoryPointer;
    return inParam->fft->dbpower;
}