//
//  ZJUNetworkManager.m
//  ZJUWLAN
//
//  Created by mmm on 14-9-19.
//  Copyright (c) 2014年 yangz. All rights reserved.
//

#import "ZJUNetworkManager.h"

#import <MKNetworkKit.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <time.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

@interface ZJUNetworkManager()

@property (nonatomic) time_t lastUpdate;
@property (nonatomic) NET_STATUS status;
@property (nonatomic,strong) MKNetworkEngine *ZJUNetworkEngine;
@property (nonatomic,strong) NSMutableDictionary *loginParams;
@property (nonatomic,strong) NSMutableDictionary *logoutParams;
@end
static ZJUNetworkManager *staticInstance = nil;

@implementation ZJUNetworkManager
@synthesize status = _status;

+ (instancetype)sharedManager
{
    @synchronized(self){
        if (staticInstance == nil) {
            staticInstance = [[self alloc] init];
            staticInstance.loginParams = [NSMutableDictionary dictionaryWithDictionary:@{@"action":@"login",
                                                                                         @"username":@"",
                                                                                         @"password":@"",
                                                                                         @"ac_id":@"3",
                                                                                         @"type":@"1",
                                                                                         @"wbaredirect":@"http://www.zju.edu.cn/",
                                                                                         @"mac":@"undefined",
                                                                                         @"user_ip":@"",
                                                                                         @"is_ldap":@"1",
                                                                                         @"local_auth":@"1",
                                                                                         }];
            staticInstance.logoutParams = [NSMutableDictionary dictionaryWithDictionary:@{@"action":@"auto_dm",
                                                                                          @"username":@"",
                                                                                          @"password":@"",
                                                                                          }];
            staticInstance.lastUpdate = -1;
            staticInstance.ZJUNetworkEngine = [[MKNetworkEngine alloc] initWithHostName:@"net.zju.edu.cn"];
            
        }
    }
    return staticInstance;
}
- (void)useUsername:(NSString *)username Password:(NSString *)pin
{
    self.Username = username;
    self.Password = pin;
}
- (void)getStatusOnComplete:(void (^)(NET_STATUS status))block
{
    time_t current_time = time(NULL);
    double interval = difftime(current_time, self.lastUpdate);
    if (interval > 1) {
        self.lastUpdate = current_time;
        if ([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable) {
            if ([[ZJUNetworkManager getSSID] isEqualToString:@"ZJUWLAN"]) {
                MKNetworkOperation *operation = [_ZJUNetworkEngine operationWithPath:@"rad_online.php" params:@{@"action":@"logout",@"username":self.Username,@"password":self.Password} httpMethod:@"POST" ssl:YES];
                [operation addCompletionHandler:^(MKNetworkOperation *operation){
                    NSData *responseData = operation.responseData;
                    NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
                    if (!([responseStr rangeOfString:@"IP"].location > 0)) {
                        self.status = ZJUWLAN_DISCONNECTED;
                    }
                    if ([responseStr rangeOfString:[ZJUNetworkManager getIPAddress]].location > 0) {
                        self.status = WIFI_LOGGEDIN;
                    }
                    else {
                        self.status = NOT_LOGIN;
                    }
                    block(self.status);
                }errorHandler:^(MKNetworkOperation *operation,NSError *error){
                    self.status = ZJUWLAN_DISCONNECTED;
                    block(self.status);
                }];
                [_ZJUNetworkEngine enqueueOperation:operation];
            }
            else {
                self.status = ZJUWLAN_DISCONNECTED;
                block(self.status);
            }
        }
        else {
            self.status = ZJUWLAN_DISCONNECTED;
            block(self.status);
        }
    }
    else {
        block(self.status);
    }
}
+ (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}

+ (NSString *)getSSID {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSString *ssid = nil;

    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"SSID"]) {
            ssid = info[@"SSID"];
            
        }
    }
    return ssid;
}
- (void)setUsername:(NSString *)Username
{
    _Username = Username;
    [self.loginParams setObject:Username forKey:@"username"];
    [self.logoutParams setObject:Username forKey:@"username"];
    NSLog(@"Use username:%@",Username);
}
- (void)setPassword:(NSString *)Password
{
    _Password = Password;
    [self.loginParams setObject:Password forKey:@"password"];
    [self.logoutParams setObject:Password forKey:@"password"];
    NSLog(@"Use password:%@",Password);
}
- (void)connectWifiOnComplete:(void (^)(BOOL isSuccess,BOOL isNetworkError,NSString *tintText))block
{
    MKNetworkOperation *loginOperation = [_ZJUNetworkEngine operationWithPath:@"cgi-bin/srun_portal" params:self.loginParams httpMethod:@"POST" ssl:YES];
    loginOperation.shouldContinueWithInvalidCertificate = YES;
    [loginOperation addCompletionHandler:^(MKNetworkOperation *operation){
        NSString *responseStr = operation.responseString;
        if (![self isLoginSuccessfulWithResponse:responseStr]) {
            if ([responseStr isEqualToString:@"您已在线，请注销后再登录。"]) {
                //force to logout
                NSLog(@"Logged in.Force to logout...");
                MKNetworkOperation *logoutOperation = [_ZJUNetworkEngine operationWithPath:@"rad_online.php" params:self.logoutParams httpMethod:@"POST" ssl:YES];
                logoutOperation.shouldContinueWithInvalidCertificate = YES;
                [logoutOperation addCompletionHandler:^(MKNetworkOperation *operation){
                                                        NSString *responseStr = operation.responseString;
                                                        if ([responseStr isEqualToString:@"ok"]) {
                                                               MKNetworkOperation *loginOperation = [_ZJUNetworkEngine operationWithPath:@"cgi-bin/srun_portal" params:self.loginParams httpMethod:@"POST" ssl:YES];
                                                               loginOperation.shouldContinueWithInvalidCertificate = YES;
                                                               [loginOperation addCompletionHandler:^(MKNetworkOperation *operation){
                                                                   NSString *responseStr = operation.responseString;
                                                                //Successful login
                                                                   if ([self isLoginSuccessfulWithResponse:responseStr]) {
                                                                       block(YES,NO,responseStr);
                                                                   }
                                                                   else {
                                                                       block(NO,NO,responseStr);
                                                                   }
                                                               }errorHandler:^(MKNetworkOperation *operation,NSError *error){
                                                                   block(NO,YES,[error description]);
                                                               }];
                                                               [_ZJUNetworkEngine enqueueOperation:loginOperation];
                                                           }
                                                           else {
                                                               block(NO,NO,responseStr);
                                                           }
                                                       }errorHandler:^(MKNetworkOperation *operation,NSError *error){
                                                           block(NO,YES,[error description]);
                                                       }];
                [_ZJUNetworkEngine enqueueOperation:logoutOperation];
            }
            else {
                block(NO,NO,responseStr);
            }
        }
        //Successful login
        else {
            block(YES,NO,responseStr);
        }
        
    }
     errorHandler:^(MKNetworkOperation *operation,NSError *error){
         block(NO,YES,[error description]);
     }];
    NSLog(@"Connecting to ZJUWLAN auth server...");
    [_ZJUNetworkEngine enqueueOperation:loginOperation];
}
- (BOOL)isLoginSuccessfulWithResponse:(NSString *)responseStr
{
    //NSLog(@"Server response:%@",responseStr);
    return ([responseStr rangeOfString:@"help.html"].location > 0 || [responseStr rangeOfString:@"login_ok"].location) ? YES : NO;
}
- (void)connectVPNOnComplete:(void (^)(BOOL isSuccess,BOOL isNetworkError))block
{
    
}

@end
