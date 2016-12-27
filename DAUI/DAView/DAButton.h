//
//  DAButton.h
//  daui
//
//  Created by da on 07.04.13.
//  Copyright (c) 2013 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DABadgeView.h"



typedef NS_ENUM(NSUInteger, DAButtonActivityIndicatorLayout)
{
	DAButtonActivityIndicatorLayoutCenter,
	DAButtonActivityIndicatorLayoutImageCenter,
	DAButtonActivityIndicatorLayoutTitleCenter,
};



@interface DAButton : UIButton
{
	UIActivityIndicatorView *_activityIndicatorView;
	DABadgeView *_badgeView;
	NSString *_layoutedBadgeValue;
	unsigned int _activityIndicatorStyle : 2;
	unsigned int _activityIndicatorLayout : 2;
	unsigned int _disableWhenActivity : 1;
}

@property (nonatomic, assign) UIActivityIndicatorViewStyle activityIndicatorStyle;
@property (nonatomic, assign) DAButtonActivityIndicatorLayout activityIndicatorLayout;
@property (nonatomic, assign, getter = isDisableWhenActivity) BOOL disableWhenActivity;

@property (nonatomic, copy) NSDictionary *badgeDrawingAttributes;
@property (nonatomic, copy) NSString *layoutedBadgeValue;
- (CGRect)badgeRectForBoundsRect:(CGRect)bounds;

@property (nonatomic, assign, getter = isActive) BOOL active;
@property (nonatomic, copy) NSString *badgeValue;
- (void)setBadgeValue:(NSString*)badgeValue animated:(BOOL)animated;

@end
