//
//  popoverViewController.m
//  SPP RF+SB
//
//  Created by Sehgal, Abhishek on 5/25/15.
//  Copyright (c) 2015 UT Dallas. All rights reserved.
//

#import "popoverViewController.h"
#import "GlobalVariable.h"
#import "IosAudioController.h"
#import "ViewController.h"

@interface popoverViewController ()



@end

@implementation popoverViewController

NSArray *soundFiles;
NSInteger filesCount;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:bundleRoot error:nil];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.wav'"];
    soundFiles = [dirContents filteredArrayUsingPredicate:fltr];
    filesCount = [soundFiles count];
    [_buttonOk setEnabled:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    return filesCount;
}

- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileName"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FileName"];
    }
    
    cell.textLabel.text = [[(NSString *)[soundFiles objectAtIndex:indexPath.row] componentsSeparatedByString:@"."] objectAtIndex:0];
    return cell;
}

- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* fileName = [[(NSString *)[soundFiles objectAtIndex:indexPath.row] componentsSeparatedByString:@"."] objectAtIndex:0];
    setFileName((__bridge void *)(fileName));
    NSLog(@"%@",getFileName());
    [_buttonOk setEnabled:YES];
}
- (IBAction)buttonOkPress:(id)sender {
    //setTextFile((__bridge NSString *)(getFileName()));
    setMic(NO);
    [iosAudio start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

