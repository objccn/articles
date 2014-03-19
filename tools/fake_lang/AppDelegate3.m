//
//  AppDelegate.m
//  PlayGround
//
//  Created by 王 巍 on 14-3-11.
//  Copyright (c) 2014年 OneV's Den. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

+ (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
;


    
    __weak NSArray *arr1 = [[NSArray alloc] init];
    
    
    
    
    __weak NSArray *arr2 = [[NSArray alloc] initWithObjects:@1,@2,@3,nil];

    
    
    
    
    __weak UIColor *color = [UIColor whiteColor];
    NSLog(@"%@",arr1);
    NSLog(@"%@",arr2);
    NSLog(@"%@",color);
    
    return YES;
}

- (void) test:(NSArray *)arr {
    NSLog(@"%@",arr); //输出是"(null)"
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
