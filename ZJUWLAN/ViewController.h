//
//  ViewController.h
//  ZJUWLAN
//
//  Created by mmm on 14-9-19.
//  Copyright (c) 2014年 yangz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *networkModeSeg;
@property (weak, nonatomic) IBOutlet UISwitch *rememberUserSwitch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *autoLoginSwitch;

- (IBAction)rememberPINChanged:(id)sender;
- (IBAction)autoLoginChanged:(id)sender;
- (IBAction)loginButtonPressed:(id)sender;
- (IBAction)backgroundTouchDown:(id)sender;
@end

