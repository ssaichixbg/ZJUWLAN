//
//  ZJUNetworkManager.h
//  ZJUWLAN
//
//  Created by mmm on 14-9-19.
//  Copyright (c) 2014年 yangz. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum NET_STATUS{
    ZJUWLAN_DISCONNECTED = 0,
    NOT_LOGIN,
    WIFI_LOGGEDIN,
    VPN_LOGGEDIN,
    CONNECTING,
}NET_STATUS;

@interface ZJUNetworkManager : NSObject

@property (nonatomic,strong) NSString *Username;
@property (nonatomic,strong) NSString *Password;

+ (instancetype)sharedManager;
+ (NSString *)getSSID;
- (void)useUsername:(NSString *)username Password:(NSString *)pin;
- (void)getStatusOnComplete:(void (^)(NET_STATUS status))block;
- (void)connectWifiOnComplete:(void (^)(BOOL isSuccess,BOOL isNetworkError,NSString *tintText))block;
- (void)connectVPNOnComplete:(void (^)(BOOL isSuccess,BOOL isNetworkError))block;

@end
