//
//  ViewController.m
//  UnreadCount
//
//  Created by Tom Insam on 2013/11/29.
//  Copyright (c) 2013 Tom Insam. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSLog(@"view did load");
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"view did appear");
    
}
@end
