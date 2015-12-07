//
//  ViewController.m
//  UpdateLogManager
//
//  Created by AnarL on 12/4/15.
//  Copyright © 2015 AnarL. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)showPanel:(NSButton *)sender {
    DisplayLogViewer();
}
- (IBAction)writeDateLog:(NSButton *)sender {
    
    FLog(@"abcde");
}

- (IBAction)writeLog:(NSButton *)sender {
    
    FPrint(@"abcd");
    
}

- (IBAction)setupLogDir:(NSButton *)sender {
    
    NSOpenPanel * openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.directoryURL = [NSURL URLWithString:NSHomeDirectory()];
    openPanel.allowsMultipleSelection = NO;
    if ([openPanel runModal]) {
        SetLogsDirectory([[[openPanel URLs] objectAtIndex:0] path]);
    }
}
@end
