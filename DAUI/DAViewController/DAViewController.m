//
//  DAViewController.m
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DAViewController.h"



#pragma mark -
#pragma mark Helpers


@interface DAViewController_WrapperView : UIView
{
	id __weak _layoutSubviewsDelegate;
	SEL _layoutSubviewsSelector;
}

@property (nonatomic, weak) id layoutSubviewsDelegate;
@property (nonatomic, assign) SEL layoutSubviewsSelector;

@end


@implementation DAViewController_WrapperView


@synthesize layoutSubviewsDelegate = _layoutSubviewsDelegate, layoutSubviewsSelector = _layoutSubviewsSelector;


- (void)layoutSubviews
{
	[super layoutSubviews];
	id strongLayoutSubviewsDelegate = _layoutSubviewsDelegate;
	if (strongLayoutSubviewsDelegate && _layoutSubviewsSelector)
		((void (*)(id, SEL))[strongLayoutSubviewsDelegate methodForSelector:_layoutSubviewsSelector])(strongLayoutSubviewsDelegate, _layoutSubviewsSelector);
}


@end



@interface DAViewController_AnchorInsetsMaskLayer : CAShapeLayer
{
	UIEdgeInsets _insets;
	CGFloat _insetsAlpha;
}

@property (nonatomic, assign) UIEdgeInsets insets;
@property (nonatomic, assign) CGFloat insetsAlpha;

@end


@implementation DAViewController_AnchorInsetsMaskLayer


@synthesize insets = _insets, insetsAlpha = _insetsAlpha;


- (instancetype)init
{
	if ((self = [super init]))
	{
		_insets = UIEdgeInsetsZero;
		_insetsAlpha = 1.;
		self.needsDisplayOnBoundsChange = YES;
		self.backgroundColor = [UIColor colorWithWhite:0. alpha:_insetsAlpha].CGColor;
	}
	return self;
}


- (id<CAAction>)actionForKey:(NSString *)event
{
	if (SYSTEM_VERSION_LESS_THAN(@"9.0"))
		return nil;
	return [NSNull null];
}


- (void)display
{
	[super display];
	CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, _insets);
	CGPathRef path = CGPathCreateWithRect(bounds, NULL);
	self.path = path;
	CGPathRelease(path);
}


- (void)setInsetsAlpha:(CGFloat)insetsAlpha
{
	if (insetsAlpha < 0.)
		insetsAlpha = 0.;
	else if (insetsAlpha > 1.)
		insetsAlpha = 1.;
	if (insetsAlpha == _insetsAlpha)
		return;
	_insetsAlpha = insetsAlpha;
	self.backgroundColor = [UIColor colorWithWhite:0. alpha:_insetsAlpha].CGColor;
}


- (void)setInsets:(UIEdgeInsets)insets
{
	if (UIEdgeInsetsEqualToEdgeInsets(insets, _insets))
		return;
	_insets = insets;
	[self setNeedsDisplay];
}


@end


@interface DAViewController_AnchorView : DAViewController_WrapperView

@property (nonatomic, assign) UIEdgeInsets maskInsets;
@property (nonatomic, assign) CGFloat maskInsetsAlpha;

@end


@implementation DAViewController_AnchorView


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		DAViewController_AnchorInsetsMaskLayer *maskLayer = [[DAViewController_AnchorInsetsMaskLayer alloc] init];
		self.layer.mask = maskLayer;
	}
	return self;
}


- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	[super layoutSublayersOfLayer:layer];
	if (layer == self.layer)
	{
		self.layer.mask.frame = self.layer.bounds;
	}
}


- (UIEdgeInsets)maskInsets
{
	return ((DAViewController_AnchorInsetsMaskLayer*) self.layer.mask).insets;
}


- (void)setMaskInsets:(UIEdgeInsets)maskInsets
{
	((DAViewController_AnchorInsetsMaskLayer*) self.layer.mask).insets = maskInsets;
}


- (CGFloat)maskInsetsAlpha
{
	return ((DAViewController_AnchorInsetsMaskLayer*) self.layer.mask).insetsAlpha;
}


- (void)setMaskInsetsAlpha:(CGFloat)maskInsetsAlpha
{
	((DAViewController_AnchorInsetsMaskLayer*) self.layer.mask).insetsAlpha = maskInsetsAlpha;
}


@end



@interface DAViewController_ContentView : DAViewController_WrapperView

@end


@implementation DAViewController_ContentView


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView *hitView = [super hitTest:point withEvent:event];
	return hitView != self ? hitView : nil;
}


@end



#pragma mark -


@interface DAViewController ()

- (void)layoutHeaderBar;
- (void)layoutFooterBar;
- (void)layoutContentView;
- (void)updateAnchorInsets;

@end


@implementation DAViewController


#pragma mark -
#pragma mark Base


#define NAVIGATION_BAR_PRESENTED (self.navigationController && !(self.navigationController.isViewControllerBasedNavigationBarAppearance ? (self.navigationController.childViewControllerForNavigationBarAppearance ? self.navigationController.childViewControllerForNavigationBarAppearance.prefersNavigationBarHidden : self.prefersNavigationBarHidden) : self.navigationController.isNavigationBarHidden))


@synthesize anchorView = _anchorView, contentView = _contentView;
@synthesize backgroundView = _backgroundView, headerBar = _headerBar, footerBar = _footerBar;
@synthesize additionalBarsInsets = _additionalBarsInsets;
@synthesize anchorInsetsMaskAlpha = _anchorInsetsMaskAlpha;
@synthesize hideShowBarsDuration = _hideShowBarsDuration, hideShowHeaderFooterBarDuration = _hideShowHeaderFooterBarDuration;


- (instancetype)init
{
	if ((self = [super init]))
	{
		_daViewControllerFlags.anchorInsetsIsValid = NO;
		_daViewControllerFlags.anchorInsetsWithKeyboardIsValid = NO;
		_daViewControllerFlags.headerBarHidden = NO;
		_daViewControllerFlags.footerBarHidden = NO;
		_daViewControllerFlags.headerBarAlignment = DAViewControllerHeaderFooterBarAlignmentFill;
		_daViewControllerFlags.footerBarAlignment = DAViewControllerHeaderFooterBarAlignmentFill;
		_daViewControllerFlags.barsHidden = NO;
		_daViewControllerFlags.ignoredStatusBar = NO;
		_anchorInsets = _anchorInsetsWithKeyboard = UIEdgeInsetsZero;
		_additionalBarsInsets = UIEdgeInsetsZero;
		_anchorInsetsMaskAlpha = 1.;
		_hideShowBarsDuration = _hideShowHeaderFooterBarDuration = DAViewControllerHideShowBarDuration;
		
		if ([self respondsToSelector:@selector(setExtendedLayoutIncludesOpaqueBars:)])
			self.extendedLayoutIncludesOpaqueBars = YES;
		if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)])
			self.automaticallyAdjustsScrollViewInsets = NO;
		
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		
		[center addObserver:self selector:@selector(dockedKeyboardWillChangeFrame:) name:DADockedKeyboardWillChangeFrameNotification object:nil];
		[center addObserver:self selector:@selector(dockedKeyboardDidChangeFrame:) name:DADockedKeyboardDidChangeFrameNotification object:nil];
		
		[center addObserver:self selector:@selector(applicationDidUpdateStatusBar:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
		[center addObserver:self selector:@selector(applicationDidUpdateStatusBar:) name:DAViewControllerStatusBarAppearanceDidUpdateNotification object:nil];
	}
	return self;
}


- (void)dealloc
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	[center removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	[center removeObserver:self name:DADockedKeyboardWillChangeFrameNotification object:nil];
	[center removeObserver:self name:DADockedKeyboardDidChangeFrameNotification object:nil];
	
	[center removeObserver:self name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
	[center removeObserver:self name:DAViewControllerStatusBarAppearanceDidUpdateNotification object:nil];
}


- (void)didReceiveMemoryWarning
{
	BOOL clearView = [self isViewLoaded] && !self.view.window && !self.presentedViewController && !self.presentingViewController;
	if (clearView)
		[self viewWillClear];
	
	[super didReceiveMemoryWarning];
	
	if (clearView)
		self.view = nil;
	
	if (clearView)
		[self viewDidClear];
}


- (void)applicationDidEnterBackground:(NSNotification*)notification
{
	BOOL clearView = [self isViewLoaded] && !self.view.window && !self.presentedViewController && !self.presentingViewController;
	if (clearView)
	{
		[self viewWillClear];
		self.view = nil;
		[self viewDidClear];
	}
}


- (void)dockedKeyboardWillChangeFrame:(NSNotification*)notification
{
	if ([self isViewVisible])
	{
		_daViewControllerFlags.anchorInsetsWithKeyboardIsValid = NO;
		NSTimeInterval duration = [(NSNumber*)[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
		UIViewAnimationCurve curve = [(NSNumber*)[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
		[self dockedKeyboardFrameWillChangeWithDuration:duration curve:curve];
	}
}


- (void)dockedKeyboardDidChangeFrame:(NSNotification*)notification
{
	if ([self isViewVisible])
	{
		[self dockedKeyboardFrameDidChange];
	}
}


- (void)dockedKeyboardFrameWillChangeWithDuration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve
{
}


- (void)dockedKeyboardFrameDidChange
{
}


- (void)setNeedsStatusBarAppearanceUpdate
{
	[super setNeedsStatusBarAppearanceUpdate];
	[[NSNotificationCenter defaultCenter] postNotificationName:DAViewControllerStatusBarAppearanceDidUpdateNotification object:self userInfo:nil];
}


- (void)applicationDidUpdateStatusBar:(NSNotification*)notification
{
	if (notification.object != self)
	{
		if ([self isViewVisible])
		{
			if (!_daViewControllerFlags.ignoredStatusBar)
				[self.view setNeedsLayout];
		}
	}
}


- (BOOL)isIgnoredStatusBar
{
	return _daViewControllerFlags.ignoredStatusBar;
}


- (void)setIgnoredStatusBar:(BOOL)ignoredStatusBar
{
	if (ignoredStatusBar == _daViewControllerFlags.ignoredStatusBar)
		return;
	_daViewControllerFlags.ignoredStatusBar = ignoredStatusBar;
	if ([self isViewVisible])
	{
		[self layoutHeaderBar];
		[self layoutFooterBar];
		[self layoutContentView];
		[self updateAnchorInsets];
	}
}


- (void)setAdditionalBarsInsets:(UIEdgeInsets)additionalBarsInsets
{
	if (UIEdgeInsetsEqualToEdgeInsets(additionalBarsInsets, _additionalBarsInsets))
		return;
	_additionalBarsInsets = additionalBarsInsets;
	if ([self isViewVisible])
	{
		[self layoutHeaderBar];
		[self layoutFooterBar];
		[self layoutContentView];
		[self updateAnchorInsets];
	}
}


#pragma mark -
#pragma mark View Management


- (void)loadView
{
	DAViewController_WrapperView *view = [[DAViewController_WrapperView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	view.layoutSubviewsDelegate = self;
	view.layoutSubviewsSelector = @selector(handleViewLayoutSubviews);
	self.view = view;
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self loadBackgroundView];
	
	_anchorView = [[DAViewController_AnchorView alloc] initWithFrame:self.view.bounds];
	_anchorView.layoutSubviewsDelegate = self;
	_anchorView.layoutSubviewsSelector = @selector(handleAnchorViewLayoutSubviews);
	_anchorView.maskInsetsAlpha = _anchorInsetsMaskAlpha;
	[self.view addSubview:_anchorView];
	
	_contentView = [[DAViewController_ContentView alloc] initWithFrame:self.view.bounds];
	_contentView.layoutSubviewsDelegate = self;
	_contentView.layoutSubviewsSelector = @selector(handleContentViewLayoutSubviews);
	_contentView.opaque = NO;
	_contentView.backgroundColor = [UIColor clearColor];
	[self.view addSubview:_contentView];
	
	if (_headerBar)
	{
		_headerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.headerBarHidden ? 0. : 1.;
		[self.view addSubview:_headerBar];
	}
	if (_footerBar)
	{
		_footerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.footerBarHidden ? 0. : 1.;
		[self.view addSubview:_footerBar];
	}
}


- (void)viewWillClear
{
	[super viewWillClear];
	((DAViewController_WrapperView*) self.view).layoutSubviewsDelegate = nil;
	((DAViewController_WrapperView*) self.view).layoutSubviewsSelector = NULL;
	_anchorView.layoutSubviewsDelegate = nil;
	_anchorView.layoutSubviewsSelector = NULL;
	_contentView.layoutSubviewsDelegate = nil;
	_contentView.layoutSubviewsSelector = NULL;
	if (_headerBar)
		[_headerBar removeFromSuperview];
	if (_footerBar)
		[_footerBar removeFromSuperview];
}


- (void)viewDidClear
{
	[super viewDidClear];
	_contentView = nil;
	_anchorView = nil;
	_backgroundView = nil;
}


- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
}


- (void)handleViewLayoutSubviews
{
	if (![self isViewVisible])
		return;

	CGRect bounds = self.view.bounds;
	CGFloat extra = 0.;
	if (NAVIGATION_BAR_PRESENTED)
	{
		CGRect navigationBarFrame = [self.view convertRect:self.navigationController.navigationBar.bounds fromView:self.navigationController.navigationBar];
		if (DELTA_COMPARE(navigationBarFrame.origin.y + navigationBarFrame.size.height, ==, bounds.origin.y, UIScreenPixel()))
			extra += navigationBarFrame.size.height;
	}
	CGRect statusBarFrame =
#ifndef DA_APP_EXTENSIONS
	//[[UIApplication sharedApplication] statusBarFrameInView:self.view];
	[self.view convertRect:[UIApplication sharedApplication].statusBarFrame fromView:nil];
#else
	CGRectZero;
#endif
	if (DELTA_COMPARE(statusBarFrame.origin.y + statusBarFrame.size.height, ==, bounds.origin.y - extra, UIScreenPixel()))
		extra += statusBarFrame.size.height;
	bounds.size.height += extra;
	bounds.origin.y -= extra;
	if (_backgroundView)
		_backgroundView.frame = bounds;
	_anchorView.frame = bounds;
	[_anchorView setNeedsLayout];
	[self layoutHeaderBar];
	[self layoutFooterBar];
	[self layoutContentView];
}


- (void)handleAnchorViewLayoutSubviews
{
	if (![self isViewVisible])
		return;
	[self anchorViewDidLayoutSubviews];
	[self updateAnchorInsets];
}


- (void)handleContentViewLayoutSubviews
{
	if (![self isViewVisible])
		return;
	[self contentViewDidLayoutSubviews];
}


- (UIEdgeInsets)calculateOuterBarsViewInsets
{
	DASSERT([self isViewVisible]);
	CGRect bounds = self.view.bounds;
	UIEdgeInsets outerBarsViewInsets = UIEdgeInsetsZero;
	if (!_daViewControllerFlags.barsHidden)
	{
		outerBarsViewInsets = _additionalBarsInsets;
		CGFloat statusAndNavigationBarIntersection = 0.;
		if (!_daViewControllerFlags.ignoredStatusBar)
		{
			CGRect statusBarFrame =
#ifndef DA_APP_EXTENSIONS
			[self.view convertRect:[UIApplication sharedApplication].statusBarFrame fromView:nil];
#else
			CGRectZero;
#endif
			CGFloat statusBarIntersection = statusBarFrame.origin.y + statusBarFrame.size.height - bounds.origin.y;
			if (DELTA_COMPARE(0., <, statusBarIntersection, UIScreenPixel()) && DELTA_COMPARE(statusBarIntersection, <, bounds.size.height, UIScreenPixel()))
				if (statusAndNavigationBarIntersection < statusBarIntersection)
					statusAndNavigationBarIntersection = statusBarIntersection;
		}
		if (NAVIGATION_BAR_PRESENTED)
		{
			CGRect navigationBarFrame = [self.view convertRect:self.navigationController.navigationBar.bounds fromView:self.navigationController.navigationBar];
			CGFloat navigatioBarIntersection = navigationBarFrame.origin.y + navigationBarFrame.size.height - bounds.origin.y;
			if (DELTA_COMPARE(0., <, navigatioBarIntersection, UIScreenPixel()) && DELTA_COMPARE(navigatioBarIntersection, <, bounds.size.height, UIScreenPixel()))
				if (statusAndNavigationBarIntersection < navigatioBarIntersection)
					statusAndNavigationBarIntersection = navigatioBarIntersection;
		}
		outerBarsViewInsets.top += statusAndNavigationBarIntersection;
	}
	return outerBarsViewInsets;
}


- (void)setAnchorInsetsMaskAlpha:(CGFloat)anchorInsetsMaskAlpha
{
	if (anchorInsetsMaskAlpha < 0.)
		anchorInsetsMaskAlpha = 0.;
	else if (anchorInsetsMaskAlpha > 1.)
		anchorInsetsMaskAlpha = 1.;
	_anchorInsetsMaskAlpha = anchorInsetsMaskAlpha;
	if ([self isViewLoaded])
		_anchorView.maskInsetsAlpha = _anchorInsetsMaskAlpha;
}


#pragma mark -
#pragma mark Anchor View


- (void)anchorViewDidLayoutSubviews
{
	DASSERT([self isViewVisible]);
}


- (void)updateAnchorInsets
{
	DASSERT([self isViewVisible]);
	_daViewControllerFlags.anchorInsetsIsValid = NO;
	_daViewControllerFlags.anchorInsetsWithKeyboardIsValid = NO;
	[self anchorInsetsChanged];
}


- (void)anchorInsetsChanged
{
	DASSERT([self isViewVisible]);
	_anchorView.maskInsets = self.anchorInsets;
}


- (UIEdgeInsets)anchorInsets
{
	if (!_daViewControllerFlags.anchorInsetsIsValid && [self isViewVisible])
	{
		UIEdgeInsets diffs = UIEdgeInsetsBetweenRects(self.view.bounds, _anchorView.frame);
		_anchorInsets = UIEdgeInsetsMinus([self calculateOuterBarsViewInsets], diffs);
		CGRect bounds = UIEdgeInsetsInsetRect(_anchorView.bounds, _anchorInsets);
		CGRect userBounds = bounds;
		if (_headerBar && (!_daViewControllerFlags.barsHidden && !_daViewControllerFlags.headerBarHidden))
		{
			CGRect headerBarFrame = [_anchorView convertRect:_headerBar.frame fromView:self.view];
			CGFloat headerBarIntersection = headerBarFrame.origin.y + headerBarFrame.size.height - userBounds.origin.y;
			if (DELTA_COMPARE(0., <, headerBarIntersection, UIScreenPixel()) && DELTA_COMPARE(headerBarIntersection, <, userBounds.size.height, UIScreenPixel()))
			{
				userBounds.size.height -= headerBarIntersection;
				userBounds.origin.y += headerBarIntersection;
			}
		}
		if (_footerBar && (!_daViewControllerFlags.barsHidden && !_daViewControllerFlags.footerBarHidden))
		{
			CGRect footerBarFrame = [_anchorView convertRect:_footerBar.frame fromView:self.view];
			CGFloat footerBarIntersection = userBounds.origin.y + userBounds.size.height - footerBarFrame.origin.y;
			if (DELTA_COMPARE(0., <, footerBarIntersection, UIScreenPixel()) && DELTA_COMPARE(footerBarIntersection, <, userBounds.size.height, UIScreenPixel()))
			{
				userBounds.size.height -= footerBarIntersection;
			}
		}
		_anchorInsets.top += userBounds.origin.y - bounds.origin.y;
		_anchorInsets.bottom += bounds.origin.y + bounds.size.height - (userBounds.origin.y + userBounds.size.height);
		_daViewControllerFlags.anchorInsetsIsValid = YES;
	}
	return _anchorInsets;
}


- (UIEdgeInsets)anchorInsetsWithKeyboard
{
	if (!_daViewControllerFlags.anchorInsetsWithKeyboardIsValid && [self isViewVisible])
	{
		_anchorInsetsWithKeyboard = self.anchorInsets;
		if (!CGRectIsNull([DAViewController dockedKeyboardFrame]))
		{
			CGRect bounds = _anchorView.bounds;
			CGRect keyboardRect = [_anchorView convertRect:[DAViewController dockedKeyboardFrame] fromView:nil];
			CGFloat keyboardIntersection = bounds.origin.y + bounds.size.height - keyboardRect.origin.y;
			if (DELTA_COMPARE(0., <, keyboardIntersection, UIScreenPixel()) && DELTA_COMPARE(keyboardIntersection, <, bounds.size.height, UIScreenPixel()))
			{
				if (DELTA_COMPARE(_anchorInsetsWithKeyboard.bottom, <, keyboardIntersection, UIScreenPixel()))
					_anchorInsetsWithKeyboard.bottom = keyboardIntersection;
			}
		}
		_daViewControllerFlags.anchorInsetsWithKeyboardIsValid = YES;
	}
	return _anchorInsetsWithKeyboard;
}


- (void)setBackgroundView:(UIView *)backgroundView
{
	DASSERT(self.isViewLoaded);
	DASSERT(!_backgroundView);
	_backgroundView = backgroundView;
	if (_backgroundView)
	{
		_backgroundView.frame = self.view.bounds;
		[self.view insertSubview:_backgroundView atIndex:0];
	}
}


- (void)reloadBackgroundView
{
	if (self.isViewLoaded)
	{
		if (_backgroundView)
		{
			[_backgroundView removeFromSuperview];
			_backgroundView = nil;
		}
		[self loadBackgroundView];
	}
}


- (void)loadBackgroundView
{
}


- (void)layoutContentView
{
	DASSERT([self isViewVisible]);
	CGRect bounds = UIEdgeInsetsInsetRect(self.view.bounds, [self calculateOuterBarsViewInsets]);
	if (_headerBar)
	{
		CGRect headerBarFrame = _headerBar.frame;
		bounds.origin.y += headerBarFrame.size.height;
		bounds.size.height -= headerBarFrame.size.height;
	}
	if (_footerBar)
	{
		CGRect footerBarFrame = _footerBar.frame;
		bounds.size.height -= footerBarFrame.size.height;
	}
	_contentView.frame = bounds;
}


- (void)contentViewDidLayoutSubviews
{
	DASSERT([self isViewVisible]);
}


#pragma mark -
#pragma mark Bars


- (void)setHeaderBar:(UIView*)headerBar
{
	if (headerBar == _headerBar)
		return;
	if (_headerBar)
		[_headerBar removeFromSuperview];
	_headerBar = headerBar;
	if ([self isViewLoaded])
	{
		if (self.view.window)
		{
			[self layoutHeaderBar];
			[self layoutContentView];
			[self updateAnchorInsets];
		}
		if (_headerBar)
		{
			_headerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.headerBarHidden ? 0. : 1.;
			[self.view addSubview:_headerBar];
		}
	}
}


- (void)setFooterBar:(UIView*)footerBar
{
	if (footerBar == _footerBar)
		return;
	if (_footerBar)
		[_footerBar removeFromSuperview];
	_footerBar = footerBar;
	if ([self isViewLoaded])
	{
		if (self.view.window)
		{
			[self layoutFooterBar];
			[self layoutContentView];
			[self updateAnchorInsets];
		}
		if (_footerBar)
		{
			_footerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.footerBarHidden ? 0. : 1.;
			[self.view addSubview:_footerBar];
		}
	}
}


- (void)layoutHeaderBar
{
	DASSERT([self isViewVisible]);
	if (!_headerBar)
		return;
	
	CGRect bounds = UIEdgeInsetsInsetRect(self.view.bounds, [self calculateOuterBarsViewInsets]);
	CGRect barFrame = bounds;
	barFrame.size = _headerBar.bounds.size;
	switch (_daViewControllerFlags.headerBarAlignment)
	{
		case DAViewControllerHeaderFooterBarAlignmentFill:
			barFrame.size.width = bounds.size.width;
			break;
		case DAViewControllerHeaderFooterBarAlignmentCenter:
			barFrame.origin.x += (bounds.size.width - barFrame.size.width) / 2;
			break;
		case DAViewControllerHeaderFooterBarAlignmentLeft:
			break;
		case DAViewControllerHeaderFooterBarAlignmentRight:
			barFrame.origin.x += bounds.size.width - barFrame.size.width;
			break;
	}
	if (_daViewControllerFlags.headerBarHidden)
		barFrame.origin.y -= barFrame.size.height;
	_headerBar.frame = barFrame;
}


- (void)layoutFooterBar
{
	DASSERT([self isViewVisible]);
	if (!_footerBar)
		return;
	
	CGRect bounds = UIEdgeInsetsInsetRect(self.view.bounds, [self calculateOuterBarsViewInsets]);
	CGRect barFrame = bounds;
	barFrame.size = _footerBar.bounds.size;
	barFrame.origin.y += bounds.size.height - barFrame.size.height;
	switch (_daViewControllerFlags.footerBarAlignment)
	{
		case DAViewControllerHeaderFooterBarAlignmentFill:
			barFrame.size.width = bounds.size.width;
			break;
		case DAViewControllerHeaderFooterBarAlignmentCenter:
			barFrame.origin.x += (bounds.size.width - barFrame.size.width) / 2;
			break;
		case DAViewControllerHeaderFooterBarAlignmentLeft:
			break;
		case DAViewControllerHeaderFooterBarAlignmentRight:
			barFrame.origin.x += bounds.size.width - barFrame.size.width;
			break;
	}
	if (_daViewControllerFlags.footerBarHidden)
		barFrame.origin.y += barFrame.size.height;
	_footerBar.frame = barFrame;
}


- (DAViewControllerHeaderFooterBarAlignment)headerBarAlignment
{
	return _daViewControllerFlags.headerBarAlignment;
}


- (void)setHeaderBarAlignment:(DAViewControllerHeaderFooterBarAlignment)headerBarAlignment
{
	if (headerBarAlignment == _daViewControllerFlags.headerBarAlignment)
		return;
	_daViewControllerFlags.headerBarAlignment = headerBarAlignment;
	if ([self isViewVisible])
		[self layoutHeaderBar];
}


- (DAViewControllerHeaderFooterBarAlignment)footerBarAlignment
{
	return _daViewControllerFlags.footerBarAlignment;
}


- (void)setFooterBarAlignment:(DAViewControllerHeaderFooterBarAlignment)footerBarAlignment
{
	if (footerBarAlignment == _daViewControllerFlags.footerBarAlignment)
		return;
	_daViewControllerFlags.footerBarAlignment = footerBarAlignment;
	if ([self isViewVisible])
		[self layoutFooterBar];
}


#pragma mark -
#pragma mark Bars Properties


- (BOOL)prefersStatusBarHidden
{
	if (!_daViewControllerFlags.ignoredStatusBar)
	{
		return _daViewControllerFlags.barsHidden || [super prefersStatusBarHidden];
	}
	return NO;
}


- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
	return UIStatusBarAnimationFade;
}


- (BOOL)prefersNavigationBarHidden
{
	return _daViewControllerFlags.barsHidden || [super prefersNavigationBarHidden];
}


- (BOOL)isBarsHidden
{
	return _daViewControllerFlags.barsHidden;
}


- (void)setBarsHidden:(BOOL)barsHidden
{
	[self setBarsHidden:barsHidden animated:NO];
}


- (void)setBarsHidden:(BOOL)barsHidden animated:(BOOL)animated
{
	if (barsHidden == _daViewControllerFlags.barsHidden)
		return;
	_daViewControllerFlags.barsHidden = barsHidden;
	if (_daViewControllerFlags.barsHidden)
		[self willAnimateBarsHidden:YES];
	[UIView animateWithDuration:animated ? _hideShowBarsDuration : 0.
					 animations:^()
	 {
		 if (!_daViewControllerFlags.ignoredStatusBar)
			[self setNeedsStatusBarAppearanceUpdate];
		 [self setNeedsNavigationBarAppearanceUpdate:animated];
		 if ([self isViewVisible])
			 [self updateAnchorInsets];
		 if (_headerBar)
			 _headerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.headerBarHidden ? 0. : 1.;
		 if (_footerBar)
			 _footerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.footerBarHidden ? 0. : 1.;
	 }];
	if (!_daViewControllerFlags.barsHidden)
		[self willAnimateBarsHidden:NO];
}


- (void)willAnimateBarsHidden:(BOOL)hidden
{
}


- (BOOL)isHeaderBarHidden
{
	return _daViewControllerFlags.headerBarHidden;
}


- (void)setHeaderBarHidden:(BOOL)hidden
{
	[self setHeaderBarHidden:hidden withAnimation:DAViewControllerHeaderFooterBarAnimationNone completion:nil];
}


- (void)setHeaderBarHidden:(BOOL)hidden withAnimation:(DAViewControllerHeaderFooterBarAnimation)animation completion:(void (^)(BOOL finished))completion
{
	if (hidden == _daViewControllerFlags.headerBarHidden)
	{
		if (completion)
			completion(YES);
		return;
	}
	_daViewControllerFlags.headerBarHidden = hidden;
	if (!_headerBar || ![self isViewVisible])
	{
		if (_headerBar)
			_headerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.headerBarHidden ? 0. : 1.;
		if (completion)
			completion(YES);
		return;
	}
	switch (animation)
	{
		case DAViewControllerHeaderFooterBarAnimationFade:
		{
			if (_daViewControllerFlags.headerBarHidden)
				[self updateAnchorInsets];
			else
				[self layoutHeaderBar];
			[UIView animateWithDuration:_hideShowHeaderFooterBarDuration
							 animations:^{ _headerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.headerBarHidden ? 0. : 1.; }
							 completion:^(BOOL finished)
			 {
				 if (_daViewControllerFlags.headerBarHidden)
					 [self layoutHeaderBar];
				 else
					 [self updateAnchorInsets];
				 if (completion)
					 completion(finished);
			 }];
		}
			break;
		case DAViewControllerHeaderFooterBarAnimationSlide:
		{
			if (_daViewControllerFlags.headerBarHidden)
				[self updateAnchorInsets];
			else
				_headerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.headerBarHidden ? 0. : 1.;
			[UIView animateWithDuration:_hideShowHeaderFooterBarDuration
							 animations:^{ [self layoutHeaderBar]; }
							 completion:^(BOOL finished)
			 {
				 if (_daViewControllerFlags.headerBarHidden)
					 _headerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.headerBarHidden ? 0. : 1.;
				 else
					 [self updateAnchorInsets];
				 if (completion)
					 completion(finished);
			 }];
		}
			break;
		case DAViewControllerHeaderFooterBarAnimationNone:
		default:
		{
			_headerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.headerBarHidden ? 0. : 1.;
			[self layoutHeaderBar];
			[self updateAnchorInsets];
			if (completion)
				completion(YES);
		}
			break;
	}
}


- (BOOL)isFooterBarHidden
{
	return _daViewControllerFlags.footerBarHidden;
}


- (void)setFooterBarHidden:(BOOL)hidden
{
	[self setFooterBarHidden:hidden withAnimation:DAViewControllerHeaderFooterBarAnimationNone completion:nil];
}


- (void)setFooterBarHidden:(BOOL)hidden withAnimation:(DAViewControllerHeaderFooterBarAnimation)animation completion:(void (^)(BOOL finished))completion
{
	if (hidden == _daViewControllerFlags.footerBarHidden)
	{
		if (completion)
			completion(YES);
		return;
	}
	_daViewControllerFlags.footerBarHidden = hidden;
	if (!_footerBar || ![self isViewVisible])
	{
		if (_footerBar)
			_footerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.footerBarHidden ? 0. : 1.;
		if (completion)
			completion(YES);
		return;
	}
	switch (animation)
	{
		case DAViewControllerHeaderFooterBarAnimationFade:
		{
			if (_daViewControllerFlags.footerBarHidden)
				[self updateAnchorInsets];
			else
				[self layoutFooterBar];
			[UIView animateWithDuration:_hideShowHeaderFooterBarDuration
							 animations:^{ _footerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.footerBarHidden ? 0. : 1.; }
							 completion:^(BOOL finished)
			 {
				 if (_daViewControllerFlags.footerBarHidden)
					 [self layoutFooterBar];
				 else
					 [self updateAnchorInsets];
				 if (completion)
					 completion(finished);
			 }];
		}
			break;
		case DAViewControllerHeaderFooterBarAnimationSlide:
		{
			if (_daViewControllerFlags.footerBarHidden)
				[self updateAnchorInsets];
			else
				_footerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.footerBarHidden ? 0. : 1.;
			[UIView animateWithDuration:_hideShowHeaderFooterBarDuration
							 animations:^{ [self layoutFooterBar]; }
							 completion:^(BOOL finished)
			 {
				 if (_daViewControllerFlags.footerBarHidden)
					 _footerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.footerBarHidden ? 0. : 1.;
				 else
					 [self updateAnchorInsets];
				 if (completion)
					 completion(finished);
			 }];
		}
			break;
		case DAViewControllerHeaderFooterBarAnimationNone:
		default:
		{
			_footerBar.alpha = _daViewControllerFlags.barsHidden || _daViewControllerFlags.footerBarHidden ? 0. : 1.;
			[self layoutFooterBar];
			[self updateAnchorInsets];
			if (completion)
				completion(YES);
		}
			break;
	}
}


@end
