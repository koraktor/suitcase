//
//  SCClassImageView.h
//  Suitcase
//
//  Copyright (c) 2012, Sebastian Staudt
//

#import <UIKit/UIKit.h>

@interface SCClassImageView : UIView

- (UIImageView *)imageView;
- (void)setClassImageForClass:(NSString *)className;
- (void)setEquippable:(BOOL)equippable;
- (void)setEquipped:(BOOL)equipped;

@end
