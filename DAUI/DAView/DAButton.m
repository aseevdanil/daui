//
//  DAButton.m
//  daui
//
//  Created by da on 07.04.13.
//  Copyright (c) 2013 Aseev Danil. All rights reserved.
//

#import "DAButton.h"



@interface DAButton ()

@property (nonatomic, retain, readonly) DABadgeView *badgeView;

@end


@implementation DAButton


#pragma mark -
#pragma mark Base


@synthesize layoutedBadgeValue = _layoutedBadgeValue;


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		_activityIndicatorStyle = UIActivityIndicatorViewStyleGray;
		_activityIndicatorLayout = DAButtonActivityIndicatorLayoutCenter;
		_disableWhenActivity = NO;
	}
	return self;
}


- (void)dealloc
{
	if (_activityIndicatorView)
	{
		[_activityIndicatorView stopAnimating];
		_activityIndicatorView = nil;
	}
}


- (void)layoutSubviews
{
	[super layoutSubviews];
	if (_badgeView)
		_badgeView.frame = [self badgeRectForBoundsRect:self.bounds];
}


- (CGRect)badgeRectForBoundsRect:(CGRect)bounds
{
	return [DABadgeView preferredViewFrameWithValue:_layoutedBadgeValue ?: _badgeView.value forBounds:bounds];
}


#pragma mark -
#pragma mark Activity


- (BOOL)isActive
{
	return _activityIndicatorView != nil;
}


- (void)setActive:(BOOL)active
{
	if (active)
	{
		if (!_activityIndicatorView)
		{
			_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:_activityIndicatorStyle];
			UIView *activityIndicatorSuperview = nil;
			switch (_activityIndicatorLayout)
			{
				case DAButtonActivityIndicatorLayoutImageCenter:
					activityIndicatorSuperview = self.imageView;
					break;
				case DAButtonActivityIndicatorLayoutTitleCenter:
					activityIndicatorSuperview = self.titleLabel;
					break;
				case DAButtonActivityIndicatorLayoutCenter:
				default:
					activityIndicatorSuperview = self;
					break;
			}
			_activityIndicatorView.center = CGRectGetCenter(activityIndicatorSuperview.bounds);
			_activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
			_activityIndicatorView.userInteractionEnabled = NO;
			[activityIndicatorSuperview addSubview:_activityIndicatorView];
			[_activityIndicatorView startAnimating];
			if (_disableWhenActivity)
				self.enabled = NO;
		}
	}
	else
	{
		if (_activityIndicatorView)
		{
			if (_disableWhenActivity)
				self.enabled = YES;
			[_activityIndicatorView stopAnimating];
			[_activityIndicatorView removeFromSuperview];
			_activityIndicatorView = nil;
		}
	}
}


- (UIActivityIndicatorViewStyle)activityIndicatorStyle
{
	return _activityIndicatorStyle;
}


- (void)setActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityIndicatorStyle
{
	if (activityIndicatorStyle == _activityIndicatorStyle)
		return;
	_activityIndicatorStyle = activityIndicatorStyle;
	if (_activityIndicatorView)
		_activityIndicatorView.activityIndicatorViewStyle = _activityIndicatorStyle;
}


- (DAButtonActivityIndicatorLayout)activityIndicatorLayout
{
	return _activityIndicatorLayout;
}


- (void)setActivityIndicatorLayout:(DAButtonActivityIndicatorLayout)activityIndicatorLayout
{
	if (activityIndicatorLayout == _activityIndicatorLayout)
		return;
	_activityIndicatorLayout = activityIndicatorLayout;
	if (_activityIndicatorView)
	{
		UIView *activityIndicatorSuperview = nil;
		switch (_activityIndicatorLayout)
		{
			case DAButtonActivityIndicatorLayoutImageCenter:
				activityIndicatorSuperview = self.imageView;
				break;
			case DAButtonActivityIndicatorLayoutTitleCenter:
				activityIndicatorSuperview = self.titleLabel;
				break;
			case DAButtonActivityIndicatorLayoutCenter:
			default:
				activityIndicatorSuperview = self;
				break;
		}
		_activityIndicatorView.center = CGRectGetCenter(activityIndicatorSuperview.bounds);
		_activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
		[activityIndicatorSuperview addSubview:_activityIndicatorView];
	}
}


- (BOOL)isDisableWhenActivity
{
	return _disableWhenActivity;
}


- (void)setDisableWhenActivity:(BOOL)flag
{
	if (flag == _disableWhenActivity)
		return;
	_disableWhenActivity = flag;
	if (_activityIndicatorView && _disableWhenActivity)
		self.enabled = NO;
}


#pragma mark -
#pragma mark Badge


- (DABadgeView*)badgeView
{
	if (!_badgeView)
	{
		_badgeView = [[DABadgeView alloc] init];
		[self addSubview:_badgeView];
		[self setNeedsLayout];
	}
	return _badgeView;
}


- (void)setLayoutedBadgeValue:(NSString*)layoutedBadgeValue
{
	_layoutedBadgeValue = [layoutedBadgeValue copy];
	if (_badgeView)
		[self setNeedsLayout];
}


- (NSString*)badgeValue
{
	return _badgeView ? _badgeView.value : 0;
}


- (void)setBadgeValue:(NSString*)badgeValue
{
	[self setBadgeValue:badgeValue animated:NO];
}


- (void)setBadgeValue:(NSString*)badgeValue animated:(BOOL)animated
{
	[self.badgeView setValue:badgeValue animated:animated];
	if (!_layoutedBadgeValue)
		[self setNeedsLayout];
}


- (NSDictionary*)badgeDrawingAttributes
{
	return _badgeView ? _badgeView.drawingAttributes : nil;
}


- (void)setBadgeDrawingAttributes:(NSDictionary *)badgeDrawingAttributes
{
	self.badgeView.drawingAttributes = badgeDrawingAttributes;
}


@end
