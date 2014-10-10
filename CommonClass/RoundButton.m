//
//  RoundButton.m
//  ZJUWLAN
//
//  Created by mmm on 14-9-21.
//  Copyright (c) 2014年 yangz. All rights reserved.
//

#import "RoundButton.h"

@implementation RoundButton


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        CGFloat radius = (self.frame.size.height + self.frame.size.width) / 2;
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, radius, radius);
        self.layer.cornerRadius = radius/2;
    }
    
    return self;
}

@end
