#include <jni.h>
#include <stdlib.h>
#include <SuperpoweredFrequencyDomain.h>
#include <AndroidIO/SuperpoweredAndroidAudioIO.h>
#include <SuperpoweredAdvancedAudioPlayer.h>
#include <SuperpoweredSimple.h>
#include <SLES/OpenSLES.h>
#include <SLES/OpenSLES_AndroidConfiguration.h>
#include <fstream>
#include <sstream>
extern "C" {
#include "SpeechProcessing.h"
#include "Timer.h"
#include <string.h>
}



static SuperpoweredFrequencyDomain *frequencyDomain;
static float  *inputBufferFloat;

//Changes made by Abhishek Sehgal
//Modified by Tahsin Ahmed Chowdhury for integration

static float *left, *right, *features;
SuperpoweredAndroidAudioIO *audioIO;
SuperpoweredAdvancedAudioPlayer *audioPlayer;
long* memoryPointer;
Timer *timer;
static float quiet;
const char* filePath;
const char* audioFilePath;
bool featureStore = false;
bool outputEnabled;
bool isReadingFromFIle = false;
FILE* featureStoreFile;

std::string Convert (float number){
    std::ostringstream buff;
    buff<<number;
    return buff.str();
}

static void playerEventCallback(void * __unused clientData, SuperpoweredAdvancedAudioPlayerEvent event, void *value) {
    switch (event) {
        case SuperpoweredAdvancedAudioPlayerEvent_LoadSuccess: audioPlayer->play(false); break;
        case SuperpoweredAdvancedAudioPlayerEvent_LoadError: __android_log_print(ANDROID_LOG_DEBUG,
                                                                                 "VAD_NCAndroid",
                                                                                 "Open error: %s",
                                                                                 (char *)value); break;
        case SuperpoweredAdvancedAudioPlayerEvent_EOF: audioPlayer->togglePlayback(); break;
        default:;
    };
}

// This is called periodically by the media server.
static bool audioProcessing(void * __unused clientdata, short int *audioInputOutput, int numberOfSamples, int __unused samplerate) {

    start(timer);
    SuperpoweredShortIntToFloat(audioInputOutput, inputBufferFloat, (unsigned int)numberOfSamples); // Converting the 16-bit integer samples to 32-bit floating point.
    SuperpoweredDeInterleave(inputBufferFloat, left, right, (unsigned int)numberOfSamples);
    compute(memoryPointer, left, right, 0, quiet);
    stop(timer);
    if(featureStore && getVADClass(memoryPointer) > 0){
        std::ofstream out;
        out.open(filePath,std::ios::app);
        copyArray(memoryPointer,features);
        for (int i = 0; i < getElements(memoryPointer); i++) {
            out << Convert(features[i]);
            out << ",";
        }
        out << "\n";
        out.close();
    }
    return true;
}

static bool audioFileProcessing(void * __unused clientdata, short int *audioInputOutput, int numberOfSamples, int __unused samplerate){

    if (audioPlayer->process(inputBufferFloat, false, (unsigned int) numberOfSamples)){
        start(timer);
        SuperpoweredFloatToShortInt(inputBufferFloat, audioInputOutput, (unsigned int)numberOfSamples);
        SuperpoweredDeInterleave(inputBufferFloat, left, right, (unsigned int)numberOfSamples);
        compute(memoryPointer, left, right, 0, quiet);
        stop(timer);

        //Storing Features
        if(featureStore && getVADClass(memoryPointer) > 0){
            std::ofstream out;
            out.open(filePath,std::ios::app);
            copyArray(memoryPointer,features);
            for (int i = 0; i < getElements(memoryPointer); i++) {
                out << Convert(features[i]);
                out << ",";
            }
            out << "\n";
            out.close();
        }
        if(outputEnabled){
            return true;
        }
        else {
            return false;
        }

    } else {

        return false;
    }

}

extern "C" JNIEXPORT void Java_com_superpowered_VADNCAndroid_MainActivity_FrequencyDomain(JNIEnv *javaEnvironment,
                                                                                             jobject __unused obj,
                                                                                             jint samplerate,
                                                                                             jint buffersize,
                                                                                             jfloat decisionRate,
                                                                                             jfloat quietThreshold,
                                                                                             jboolean playAudio,
                                                                                             jboolean storeFeatures,
                                                                                             jstring fileName) {

    memoryPointer = initialize(samplerate, buffersize,2*buffersize,16,decisionRate);
    timer = newTimer();
    inputBufferFloat = (float *)malloc(buffersize * sizeof(float) * 2 + 128);
    left = (float *)malloc(buffersize * sizeof(float) + 128);
    right = (float *)malloc(buffersize * sizeof(float) + 128);
    quiet = quietThreshold;
    featureStore = storeFeatures;
    if (storeFeatures) {
        filePath = javaEnvironment->GetStringUTFChars(fileName,JNI_FALSE);
        features = (float *)calloc((size_t) getElements(memoryPointer), sizeof(float));
    }
    audioIO = new SuperpoweredAndroidAudioIO(samplerate, buffersize, true, playAudio, audioProcessing, javaEnvironment, -1, SL_ANDROID_STREAM_MEDIA, buffersize * 2); // Start audio input/output.

}

extern "C" JNIEXPORT void Java_com_superpowered_VADNCAndroid_MainActivity_ReadFile(JNIEnv *javaEnvironment,
                                                                                jobject __unused obj,
                                                                                jint samplerate,
                                                                                jint buffersize,
                                                                                jfloat decisionRate,
                                                                                jfloat quietThreshold,
                                                                                jboolean playAudio,
                                                                                jboolean storeFeatures,
                                                                                jstring fileName,
                                                                                jstring audioFileName, jboolean readFromFileStatus) {

    memoryPointer = initialize(samplerate, (int)(buffersize/2),buffersize,16,decisionRate);
    timer = newTimer();
    inputBufferFloat = (float *)malloc(buffersize * sizeof(float) * 2 + 128);
    left = (float *)malloc(buffersize * sizeof(float) + 128);
    right = (float *)malloc(buffersize * sizeof(float) + 128);
    quiet = quietThreshold;
    featureStore = storeFeatures;
    if (storeFeatures) {
        filePath = javaEnvironment->GetStringUTFChars(fileName, JNI_FALSE);
        features = (float *) calloc((size_t) getElements(memoryPointer), sizeof(float));
    }

    outputEnabled = playAudio;
    isReadingFromFIle = readFromFileStatus;
    audioPlayer = new SuperpoweredAdvancedAudioPlayer(NULL, playerEventCallback, (unsigned int)samplerate, 0);
    audioIO = new SuperpoweredAndroidAudioIO(samplerate, buffersize, false, true, audioFileProcessing, javaEnvironment, -1, SL_ANDROID_STREAM_MEDIA, buffersize * 2); // Start audio input/output.
    audioFilePath = javaEnvironment->GetStringUTFChars(audioFileName, JNI_FALSE);
    audioPlayer->open(audioFilePath);

}

extern "C" JNIEXPORT void Java_com_superpowered_VADNCAndroid_MainActivity_StopAudio(JNIEnv * javaEnvironment, jobject __unused obj, jstring fileName, jstring audioFile){

    if(inputBufferFloat != nullptr){
        delete audioIO;
        free(inputBufferFloat);
        free(left);
        free(right);
        destroy(&timer);
        inputBufferFloat = nullptr;
        if(featureStore) {
            javaEnvironment->ReleaseStringUTFChars(fileName, filePath);
        }
        if(isReadingFromFIle){
            javaEnvironment->ReleaseStringUTFChars(audioFile, audioFilePath);
            isReadingFromFIle = false;
        }
    }
}

extern "C" JNIEXPORT float Java_com_superpowered_VADNCAndroid_MainActivity_getExecutionTime(JNIEnv * __unused javaEnvironment, jobject __unused obj) {
    return getMS(timer);
}

extern "C" JNIEXPORT int Java_com_superpowered_VADNCAndroid_MainActivity_getDetectedClass(JNIEnv * __unused javaEnvironment, jobject __unused obj) {
    return getVADClass(memoryPointer);
}

extern "C" JNIEXPORT float Java_com_superpowered_VADNCAndroid_MainActivity_getdbPower(JNIEnv * __unused javaEnvironment, jobject __unused obj) {
    return getdbPower(memoryPointer);
}

extern "C" JNIEXPORT jstring Java_com_superpowered_VADNCAndroid_MainActivity_getDetectedNoiseClassLabel(JNIEnv * __unused javaEnvironment, jobject __unused obj) {
    return javaEnvironment->NewStringUTF(getNoiseClassLabel(memoryPointer));
}
extern "C" JNIEXPORT int Java_com_superpowered_VADNCAndroid_MainActivity_getDetectedNoiseClass(JNIEnv * __unused javaEnvironment, jobject __unused obj) {
    return getNoiseClass(memoryPointer);
}