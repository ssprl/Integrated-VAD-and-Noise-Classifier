//
//  main.m
//  SPP RF+SB
//
//  Created by Sehgal, Abhishek on 5/1/15.
//  Copyright (c) 2015 UT Dallas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "IosAudioController.h"

int main(int argc, char * argv[]) {
    
    iosAudio = [[IosAudioController alloc] init];
    
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
