//
//  IosAudioController.m
//  Aruts
//
//  Created by Simon Epskamp on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IosAudioController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <time.h>
#import "GlobalVariable.h"
#import "TPCircularBuffer.h"
#import "SpeechProcessing.h"




#define kOutputBus 0
#define kInputBus 1

NSDate *start, *stop;
NSTimeInterval executionTime = 0, overallExecutionTime = 0;


IosAudioController* iosAudio;
int count = 0, nFrames = 0;
AudioStreamBasicDescription audioFormat;
long* memoryPointer;
ExtAudioFileRef fileRef;
TPCircularBuffer* inBuffer;
TPCircularBuffer* outBuffer;

void checkStatus(OSStatus error){
    if (error) {
        char errorString[20];
        // See if it appears to be a 4-char-code
        *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
        if (isprint(errorString[1]) && isprint(errorString[2]) &&
            isprint(errorString[3]) && isprint(errorString[4])) {
            errorString[0] = errorString[5] = '\'';
            errorString[6] = '\0';
        } else
            // No, format it as an integer
            sprintf(errorString, "%d", (int)error);
        
        fprintf(stderr, "Error: (%s)\n", errorString);
    }
}

//Error Check Function
static void CheckError (OSStatus error, const char *operation) {
    if (error == noErr) return;
    
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) &&
        isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
    
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    
    exit(1);
}

void initAudio() {
    
    //You can change the file to use by changing the source below with
    
    NSString* source = [[NSBundle mainBundle] pathForResource:(__bridge NSString *)(getFileName()) ofType:@"wav"];
    const char * cString = [source cStringUsingEncoding:NSASCIIStringEncoding];
    CFStringRef str = CFStringCreateWithCString(NULL, cString, kCFStringEncodingMacRoman);
    CFURLRef inputFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, str, kCFURLPOSIXPathStyle, false);
    
    AudioFileID fileID;
    OSStatus err = AudioFileOpenURL(inputFileURL, kAudioFileReadPermission, 0, &fileID);
    CheckError(err, "AudioFileOpenURL");
    
    
    err = ExtAudioFileOpenURL(inputFileURL, &fileRef);
    CheckError(err, "ExtAudioFileOpenURL");
    
    err = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &audioFormat);
    CheckError(err, "ExtAudioFileSetProperty");
}

/**
 This callback is called when new audio data from the microphone is
 available.
 */
static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    
    // Because of the way our audio format (setup below) is chosen:
    // we only need 1 buffer, since it is mono
    // Samples are 16 bits = 2 bytes.
    // 1 frame includes only 1 sample
    
    AudioBuffer buffer;
    
    buffer.mNumberChannels = 1;
    buffer.mDataByteSize = inNumberFrames * 2;
    buffer.mData = malloc( inNumberFrames * 2 );
    
    // Put buffer in a AudioBufferList
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;
    
    // Then:
    // Obtain recorded samples
    
    if (getMic()) {
        OSStatus status;
        
        status = AudioUnitRender([iosAudio audioUnit],
                                 ioActionFlags,
                                 inTimeStamp,
                                 inBusNumber,
                                 inNumberFrames,
                                 &bufferList);
        checkStatus(status);
        
        // Now, we have the samples we just read sitting in buffers in bufferList
        // Process the new data
        TPCircularBufferProduceBytes(inBuffer, (void*)bufferList.mBuffers[0].mData, bufferList.mBuffers[0].mDataByteSize);
        
        if(inBuffer->fillCount >= getStepSize()*sizeof(short)){
            [iosAudio processStream];
        }
    }
    else {
        UInt32 frameCount = inNumberFrames;
        OSStatus err = ExtAudioFileRead(fileRef, &frameCount, &bufferList);
        CheckError(err,"File Read");
        if(frameCount > 0) {
            
            AudioBuffer audioBuffer = bufferList.mBuffers[0];
            
            TPCircularBufferProduceBytes(inBuffer, audioBuffer.mData, audioBuffer.mDataByteSize);
            if (inBuffer->fillCount >= getStepSize()*sizeof(short)) {
                [iosAudio processStream];
            }
        }
        
        else{
            
            [iosAudio stop];
            ViewController* view = (__bridge ViewController *)(getViewController());
            [view changeLabel:-1];
            enableButtons();
        }
    }
    
    
    // release the malloc'ed data in the buffer we created earlier
    free(bufferList.mBuffers[0].mData);
    
    return noErr;
}

/**
 This callback is called when the audioUnit needs new data to play through the
 speakers. If you don't have any, just don't write anything in the buffers
 */
static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData) {
    // Notes: ioData contains buffers (may be more than one!)
    // Fill them up as much as you can. Remember to set the size value in each buffer to match how
    // much data is in the buffer.
    if (!getPlayAudio()) {
        void* emptyBuffer = calloc(inNumberFrames,sizeof(short));
        memcpy(ioData->mBuffers[0].mData, emptyBuffer, ioData->mBuffers[0].mDataByteSize);
        free(emptyBuffer);
        return noErr;
    }
    
    
    for (int i=0; i < ioData->mNumberBuffers; i++) { // in practice we will only ever have 1 buffer, since audio format is mono
        AudioBuffer buffer = ioData->mBuffers[i];
        
        if (outBuffer->fillCount > ioData->mBuffers[0].mDataByteSize) {
            
            int32_t availableBytes;
            short *tail = TPCircularBufferTail(outBuffer, &availableBytes);
            memcpy(buffer.mData, tail, buffer.mDataByteSize);
            TPCircularBufferConsume(outBuffer, buffer.mDataByteSize);
            
        }
    }
    
    return noErr;
}

@implementation IosAudioController

@synthesize audioUnit;

/**
 Initialize the audioUnit and allocate our own temporary buffer.
 The temporary buffer will hold the latest data coming in from the microphone,
 and will be copied to the output when this is requested.
 */
- (id) init {
    self = [super init];
    
    OSStatus status;
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkStatus(status);
    
    // Enable IO for recording
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Enable IO for playback
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Describe format
    //AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= getValue();
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 1;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 2;
    audioFormat.mBytesPerFrame		= 2;
   
    

    
    // Apply format
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Set output callback
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
    flag = 0;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    
    
    // Initialise
    status = AudioUnitInitialize(audioUnit);
    checkStatus(status);
    
    return self;
}

- (void) initAudioUnit {
    OSStatus status;
    NSError* nsErr;
    CheckError(AudioUnitUninitialize(audioUnit), "AudioUnit Uninitialization");
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                     withOptions:AVAudioSessionCategoryOptionAllowBluetooth
                                           error:&nsErr];
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVoiceChat error:&nsErr];
    [[AVAudioSession sharedInstance] setPreferredSampleRate:getValue() error:&nsErr];
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:64.0/((float)getValue()) error:&nsErr];
    
    
    // Describe audio component
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_RemoteIO;
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // Get component
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
    
    // Get audio units
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    checkStatus(status);
    
    // Enable IO for recording
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Enable IO for playback
    flag = getPlayAudio();
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Output,
                                  kOutputBus,
                                  &flag,
                                  sizeof(flag));
    checkStatus(status);
    
    // Describe format
    //AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= getValue();
    // Apply format
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  kOutputBus,
                                  &audioFormat,
                                  sizeof(audioFormat));
    checkStatus(status);
    
    
    // Set input callback
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = recordingCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Global,
                                  kInputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Set output callback
    callbackStruct.inputProc = playbackCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)(self);
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Global,
                                  kOutputBus,
                                  &callbackStruct,
                                  sizeof(callbackStruct));
    checkStatus(status);
    
    // Disable buffer allocation for the recorder (optional - do this if we want to pass in our own)
    flag = 0;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_ShouldAllocateBuffer,
                                  kAudioUnitScope_Output,
                                  kInputBus,
                                  &flag,
                                  sizeof(flag));
    // Initialise
    status = AudioUnitInitialize(audioUnit);
    checkStatus(status);
}

/**
 Start the audioUnit. This means data will be provided from
 the microphone, and requested for feeding to the speakers, by
 use of the provided callbacks.
 */
- (void) start {
        
    memoryPointer = initialize(getValue(),
                               getStepSize(),
                               getFrameSize(),
                               16,
                               getDecisionRate());
    inBuffer = malloc(sizeof(TPCircularBuffer));
    outBuffer = malloc(sizeof(TPCircularBuffer));
    TPCircularBufferInit(inBuffer, 2048);
    TPCircularBufferInit(outBuffer, 2048);
    [self initAudioUnit];
    if (!getMic()) {
        initAudio();
    }
    audioFormat.mSampleRate = getValue();
    OSStatus status = AudioUnitSetProperty(audioUnit,
                                           kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Output,
                                           kInputBus,
                                           &audioFormat,
                                           sizeof(audioFormat));
    checkStatus(status);
    status = AudioOutputUnitStart(audioUnit);
    checkStatus(status);
}

/**
 Stop the audioUnit
 */
- (void) stop {
    setMic(YES);
    OSStatus status = AudioOutputUnitStop(audioUnit);
    checkStatus(status);
    AudioUnitUninitialize(audioUnit);
}

-(void) processStream {
    start = [NSDate date];
    //Frame Size
    UInt32 frameSize = getStepSize() * sizeof(short);
    int32_t availableBytes;
    
    //Initialize Temporary buffers for processing
    short *tail = TPCircularBufferTail(inBuffer, &availableBytes);
    
    if (availableBytes > frameSize)
    {
        short *buffer = malloc(frameSize), *output = malloc(frameSize);
        
        memcpy(buffer, tail, frameSize);
        
        TPCircularBufferConsume(inBuffer, frameSize);
        
       // start = [NSDate date];
        compute(memoryPointer, buffer, output, getOutputType(), getQuietAdjustment());
        //stop = [NSDate date];
        memcpy(output, buffer, frameSize);
        
        TPCircularBufferProduceBytes(outBuffer, buffer, frameSize);
        free(output);
        free(buffer);
        
        stop = [NSDate date];
        executionTime += [stop timeIntervalSinceDate:start];
        count++;
        
        ViewController* view = (__bridge ViewController *)(getViewController());
        if (view.debugClassification.isOn && getVADClass(memoryPointer) > 0) { //Testing this
            NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString* documentsDirectory = [paths objectAtIndex:0];
            NSString* path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt",getTextFile()]];
            
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
            [fileHandle seekToEndOfFile];
            float* array;
            int elements;
            elements = getElements(memoryPointer);
            array = malloc(elements * sizeof(float));
            copyArray(memoryPointer, array);
            NSMutableArray *copiedArray = [NSMutableArray arrayWithCapacity:elements];
            
            for (int i = 0; i < elements; i++) {
                NSNumber *number = [[NSNumber alloc] initWithFloat:array[i]];
                [copiedArray addObject:number];
            }
            NSString *joinedComponents = [copiedArray componentsJoinedByString:@","];
            
            [fileHandle writeData:[[@"\n" stringByAppendingString:joinedComponents] dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
        
        if(count > getValue()/(getFrameSize()) && getVADClass(memoryPointer) > -1) {
            
            
            overallExecutionTime = executionTime/count;
            nFrames++;
            executionTime = 0;
            count = 0;
            printTime(overallExecutionTime, getVADClass(memoryPointer), getNoiseClass(memoryPointer),getNoiseClassLabel(memoryPointer), getdbPower(memoryPointer));
            
        }
        
    }
    
    
    
}





@end
