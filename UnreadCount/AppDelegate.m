//
//  AppDelegate.m
//  UnreadCount
//
//  Created by Tom Insam on 2013/11/29.
//  Copyright (c) 2013 Tom Insam. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreMotion/CoreMotion.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"application wakes");
    [application setMinimumBackgroundFetchInterval:3600 * 6];
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    NSLog(@"woken for background fetch");
    self.backgroundCompletionHandler = completionHandler;
    [self fetchAndUpload];
}

- (void)fetchAndUpload;
{
    NSAssert([CMStepCounter isStepCountingAvailable], @"step counting available");
    
    CMStepCounter *stepCounter = [[CMStepCounter alloc] init];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;

    // crop a date to the beginning of the current day
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
    NSDate *today = [calendar dateFromComponents:components];
    
    NSMutableArray *data = [NSMutableArray arrayWithCapacity:10];
    
    for (NSUInteger i=0; i<4; i++) {
        NSDateComponents *offset = [[NSDateComponents alloc] init];
        offset.day = -1 * i;
        NSDate *finish = [calendar dateByAddingComponents:offset toDate:today options:0];
        offset.day = -1 * (i + 1);
        NSDate *start = [calendar dateByAddingComponents:offset toDate:today options:0];
        
        NSLog(@"getting steps from %@ to %@", start, finish);
        [stepCounter queryStepCountStartingFrom:start to:finish toQueue:queue withHandler:^(NSInteger numberOfSteps, NSError *error) {
            if (numberOfSteps > 0) {
                NSLog(@"got %ld steps", (long)numberOfSteps);
                [data addObject:@[start, @(numberOfSteps)]];
            }
        }];
    }
    [queue addOperationWithBlock:^{
        // on the queue after all the step count queries
        [self uploadDataPointFrom:data];
    }];
}

- (void)uploadDataPointFrom:(NSMutableArray *)dataPoints;
{
    if (dataPoints.count == 0) {
        NSLog(@"Finished!!");
        if (self.backgroundCompletionHandler) {
            self.backgroundCompletionHandler(UIBackgroundFetchResultNewData);
            return;
        }
    }
    
    // The data upload API needs a secret token in the post, unique to the data source name.
    // I use identifierForVendor because it won't change, and is secret, so I don't have to
    // commit anything secret to a public github.
    NSString *secret = [[UIDevice currentDevice] identifierForVendor].UUIDString;

    NSDate *date = dataPoints[0][0];
    NSNumber *count = dataPoints[0][1];

    NSURL *endpoint = [NSURL URLWithString:@"https://movieos.org/unreadcount/update/"];
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.allowsCellularAccess = YES;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:endpoint];
    request.HTTPMethod = @"POST";
    NSUInteger when = [date timeIntervalSince1970];
    NSString *body = [NSString stringWithFormat:@"slug=%@&value=%@&when=%ld&secret=%@", @"steps", count, (long)when, secret];
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      NSLog(@"post complete");
                                      [dataPoints removeObjectAtIndex:0];
                                      [self uploadDataPointFrom:dataPoints];
                                  }];
    
    [task resume];
    
}

@end
