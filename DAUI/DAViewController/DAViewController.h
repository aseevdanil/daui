//
//  DAViewController.h
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



@class DAViewController_WrapperView, DAViewController_AnchorView, DAViewController_ContentView;


#define DAViewControllerHideShowBarDuration UINavigationControllerHideShowBarDuration


typedef NS_ENUM(NSUInteger, DAViewControllerHeaderFooterBarAnimation)
{
	DAViewControllerHeaderFooterBarAnimationNone,
	DAViewControllerHeaderFooterBarAnimationFade,
	DAViewControllerHeaderFooterBarAnimationSlide,
};


typedef NS_ENUM(NSUInteger, DAViewControllerHeaderFooterBarAlignment)
{
	DAViewControllerHeaderFooterBarAlignmentFill,
	DAViewControllerHeaderFooterBarAlignmentCenter,
	DAViewControllerHeaderFooterBarAlignmentLeft,
	DAViewControllerHeaderFooterBarAlignmentRight,
};



@interface DAViewController : UIViewController
{
	DAViewController_AnchorView *_anchorView;
	DAViewController_ContentView *_contentView;
	UIEdgeInsets _anchorInsets, _anchorInsetsWithKeyboard;
	UIEdgeInsets _additionalBarsInsets;
	CGFloat _anchorInsetsMaskAlpha;
	
	UIView *_backgroundView;
	UIView *_headerBar;
	UIView *_footerBar;
	
	NSTimeInterval _hideShowBarsDuration;
	NSTimeInterval _hideShowHeaderFooterBarDuration;
	
	struct
	{
		unsigned int anchorInsetsIsValid : 1;
		unsigned int anchorInsetsWithKeyboardIsValid : 1;
		
		unsigned int headerBarHidden : 1;
		unsigned int footerBarHidden : 1;
		unsigned int headerBarAlignment : 2;
		unsigned int footerBarAlignment : 2;
		
		unsigned int barsHidden : 1;
		unsigned int ignoredStatusBar : 1;
	}
	_daViewControllerFlags;
}

@property (nonatomic, strong, readonly) UIView *anchorView;
- (void)anchorViewDidLayoutSubviews;
@property (nonatomic, assign, readonly) UIEdgeInsets anchorInsets;
- (void)anchorInsetsChanged;
@property (nonatomic, assign) CGFloat anchorInsetsMaskAlpha;

@property (nonatomic, strong, readonly) UIView *contentView;
- (void)contentViewDidLayoutSubviews;

@property (nonatomic, retain) UIView *backgroundView;

@property (nonatomic, strong) UIView *headerBar;
@property (nonatomic, strong) UIView *footerBar;
@property (nonatomic, assign) DAViewControllerHeaderFooterBarAlignment headerBarAlignment;
@property (nonatomic, assign) DAViewControllerHeaderFooterBarAlignment footerBarAlignment;

@property (nonatomic, assign, getter = isHeaderBarHidden) BOOL headerBarHidden;
@property (nonatomic, assign, getter = isFooterBarHidden) BOOL footerBarHidden;
- (void)setHeaderBarHidden:(BOOL)hidden withAnimation:(DAViewControllerHeaderFooterBarAnimation)animation completion:(void (^)(BOOL finished))completion;
- (void)setFooterBarHidden:(BOOL)hidden withAnimation:(DAViewControllerHeaderFooterBarAnimation)animation completion:(void (^)(BOOL finished))completion;
@property (nonatomic, assign) NSTimeInterval hideShowHeaderFooterBarDuration;

@property (nonatomic, assign, getter = isBarsHidden) BOOL barsHidden;
- (void)setBarsHidden:(BOOL)barsHidden animated:(BOOL)animated;
- (void)willAnimateBarsHidden:(BOOL)hidden;
@property (nonatomic, assign) NSTimeInterval hideShowBarsDuration;

- (void)dockedKeyboardFrameWillChangeWithDuration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve;
- (void)dockedKeyboardFrameDidChange;
@property (nonatomic, assign, readonly) UIEdgeInsets anchorInsetsWithKeyboard;
@property (nonatomic, assign, readonly) UIEdgeInsets contentInsetsWithKeyboard;

@property (nonatomic, assign, getter = isIgnoredStatusBar) BOOL ignoredStatusBar;
@property (nonatomic, assign) UIEdgeInsets additionalBarsInsets;

@end
