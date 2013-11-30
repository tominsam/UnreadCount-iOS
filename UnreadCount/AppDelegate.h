//
//  AppDelegate.h
//  UnreadCount
//
//  Created by Tom Insam on 2013/11/29.
//  Copyright (c) 2013 Tom Insam. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^BackgroundCompletionHandler)(UIBackgroundFetchResult);

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLSessionDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) BackgroundCompletionHandler backgroundCompletionHandler;

- (void)fetchAndUpload;

@end
