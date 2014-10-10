//
//  ViewController.m
//  ZJUWLAN
//
//  Created by mmm on 14-9-19.
//  Copyright (c) 2014年 yangz. All rights reserved.
//
#import "ZJUNetworkManager.h"
#import <Reachability.h>

#import "ViewController.h"

#define DEFAULTS_KEY_USERNAME @"vpn_username"
#define DEFAULTS_KEY_PASSWORD @"vpn_password"
#define DEFAULTS_KEY_REMEMBER_USER @"remember_user"
#define DEFAULTS_KEY_AUTO_LOGIN @"auto_login"

@interface ViewController (){
}
@property (nonatomic,strong) Reachability *reachiability;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self loadSwitch];
    [self loadInfo];
    [_indicator startAnimating];
    _indicator.transform = CGAffineTransformMakeScale(0, 0);
    [self.view bringSubviewToFront:self.loginButton];
    
     self.reachiability = [Reachability reachabilityWithHostname:@"net.zju.edu.cn"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    [self.reachiability startNotifier];
    
}
- (void)viewDidAppear:(BOOL)animated {
    //[self freshNetworkStatus];
}
-(void)reachabilityChanged:(NSNotification *)note {
    [self freshNetworkStatus];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)rememberPINChanged:(id)sender {
    if (self.rememberUserSwitch.isOn) {
        NSString *username = self.usernameTextField.text;
        NSString *password = self.passwordField.text;
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:DEFAULTS_KEY_USERNAME];
        [[NSUserDefaults standardUserDefaults] setObject:password forKey:DEFAULTS_KEY_PASSWORD];
        
    }
    else {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:DEFAULTS_KEY_USERNAME];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:DEFAULTS_KEY_PASSWORD];
    }
    [[NSUserDefaults standardUserDefaults] setBool:self.rememberUserSwitch.isOn forKey:DEFAULTS_KEY_REMEMBER_USER];
}

- (IBAction)autoLoginChanged:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:self.autoLoginSwitch.isOn forKey:DEFAULTS_KEY_AUTO_LOGIN];
}

- (IBAction)loginButtonPressed:(id)sender {
    [self startConnectNetwork];
}

- (IBAction)backgroundTouchDown:(id)sender {
    [self.usernameTextField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

- (void)loadSwitch {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_REMEMBER_USER] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULTS_KEY_REMEMBER_USER];
    }
    if ([[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_KEY_AUTO_LOGIN] == nil) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DEFAULTS_KEY_AUTO_LOGIN];
    }
    [self.rememberUserSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_KEY_REMEMBER_USER]];
    [self.autoLoginSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_KEY_AUTO_LOGIN]];
}
- (void)loadInfo {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:DEFAULTS_KEY_REMEMBER_USER]) {
        self.usernameTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULTS_KEY_USERNAME];
        self.passwordField.text = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULTS_KEY_PASSWORD];
    }
}

- (void)startConnectNetwork {
    NSString *username = self.usernameTextField.text;
    NSString *password = self.passwordField.text;
    if (username && password) {
        ZJUNetworkManager *ZJUNetwork = [ZJUNetworkManager sharedManager];
        [ZJUNetwork useUsername:username Password:password];
        [ZJUNetwork connectWifiOnComplete:^(BOOL suc,BOOL networkError,NSString *description){
            [self performSelectorOnMainThread:@selector(freshNetworkStatus) withObject:nil waitUntilDone:NO];
            NSLog(@"%@",description);
        }];
        //[self freshNetworkStatus];
        if (self.rememberUserSwitch.isOn) {
            [[NSUserDefaults standardUserDefaults] setObject:username forKey:DEFAULTS_KEY_USERNAME];
            [[NSUserDefaults standardUserDefaults] setObject:password forKey:DEFAULTS_KEY_PASSWORD];
        }
    }
    else {
        
    }
}

- (void)freshNetworkStatus{
    if (![self.usernameTextField.text length] || ![self.passwordField.text length]) {
        self.statusLabel.text = @"";
        return;
    }
    
    [self displayIndicator];
    
    CGAffineTransform transform = CGAffineTransformMakeScale(0, 0);
    if (!CGAffineTransformEqualToTransform(_loginButton.transform, transform)) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        _loginButton.transform = transform;
        [UIView commitAnimations];
    }
    [[ZJUNetworkManager sharedManager] setUsername:self.usernameTextField.text];
    [[ZJUNetworkManager sharedManager] setPassword:self.passwordField.text];
    [[ZJUNetworkManager sharedManager] getStatusOnComplete:^(NET_STATUS status){
        switch (status) {
            case ZJUWLAN_DISCONNECTED:
                [self performSelectorOnMainThread:@selector(ZJUDisconnectAnimation) withObject:nil waitUntilDone:NO];
                break;
            case NOT_LOGIN:
                [self performSelectorOnMainThread:@selector(notLoginAnimation) withObject:nil waitUntilDone:NO];
                break;
            case VPN_LOGGEDIN:
                [self performSelectorOnMainThread:@selector(wifiLogedinAnimation) withObject:nil waitUntilDone:NO];
                break;
            case WIFI_LOGGEDIN:
                [self performSelectorOnMainThread:@selector(wifiLogedinAnimation) withObject:nil waitUntilDone:NO];
                break;
            case CONNECTING:
                [self performSelectorOnMainThread:@selector(connectingAnimation) withObject:nil waitUntilDone:NO];
                break;
            default:
                [self performSelectorOnMainThread:@selector(ZJUDisconnectAnimation) withObject:nil waitUntilDone:NO];
                break;
        }
    }];
    
}
- (void)ZJUDisconnectAnimation {
    self.statusLabel.text = @"尚未连接到ZJUWLAN:(";
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    _indicator.transform = CGAffineTransformMakeScale(0, 0);
    [UIView commitAnimations];
}
- (void)notLoginAnimation {
    self.statusLabel.text = @"已经连接到ZJUWLAN，尚未登录:)";
    [self.loginButton setTitle:@"登录" forState:UIControlStateNormal];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.loginButton.transform = CGAffineTransformMakeScale(1, 1);
    _indicator.transform = CGAffineTransformMakeScale(0, 0);
    [UIView commitAnimations];
}
- (void)wifiLogedinAnimation {
    self.statusLabel.text = @"已经可以上网了:)";
    [self.loginButton setTitle:@"注销" forState:UIControlStateNormal];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.loginButton.transform = CGAffineTransformMakeScale(1, 1);
    _indicator.transform = CGAffineTransformMakeScale(0, 0);
    [UIView commitAnimations];
}
- (void)connectingAnimation {
    self.statusLabel.text = @"连接中...";
}
- (void)displayIndicator {
    _indicator.transform = CGAffineTransformMakeScale(1, 1);
}
- (void)hideIndicator {
    _indicator.transform = CGAffineTransformMakeScale(0, 0);
}
@end
