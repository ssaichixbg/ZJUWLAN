//
//  FullWidthTextField.m
//  ZJUWLAN
//
//  Created by mmm on 14-9-21.
//  Copyright (c) 2014年 yangz. All rights reserved.
//

#import "FullWidthTextField.h"

@implementation FullWidthTextField

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.textColor = [UIColor whiteColor];
        self.tintColor = [UIColor whiteColor];
        self.font = [UIFont systemFontOfSize:20];
    }
    return self;
}
- (void)drawPlaceholderInRect:(CGRect)rect
{
    
    [self.placeholder drawInRect:CGRectOffset(rect, 0, (rect.size.height - 22)/2) withAttributes:@{
                                                       NSFontAttributeName: [UIFont systemFontOfSize:20],
                                                       NSForegroundColorAttributeName:
                                                           [[UIColor whiteColor] colorWithAlphaComponent:0.7],
                                                       }];
}
- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    return CGRectOffset(bounds, 10, 0);
}
- (CGRect)textRectForBounds:(CGRect)bounds
{
    return CGRectOffset(bounds, 10, 0);
}
- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return CGRectOffset(bounds, 10, 0);
}
@end
