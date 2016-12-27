//
//  UIViewController+NavigationBarAppearance.m
//  daui
//
//  Created by da on 04.06.15.
//  Copyright (c) 2015 Aseev Danil. All rights reserved.
//

#import "UIViewController+NavigationBarAppearance.h"



@implementation UIViewController (NavigationBarAppearance)


- (UIViewController *)childViewControllerForNavigationBarAppearance
{
	return nil;
}


- (UIBarStyle)preferredNavigationBarStyle
{
	return UIBarStyleDefault;
}


- (BOOL)prefersNavigationBarTranslucent
{
	return YES;
}


- (BOOL)prefersNavigationBarHidden
{
	return NO;
}


- (BOOL)prefersHidesNavigationBarOnTap
{
	return NO;
}


- (BOOL)prefersHidesNavigationBarOnSwipe
{
	return NO;
}


- (BOOL)prefersHidesNavigationBarWhenVerticallyCompact
{
	return NO;
}


- (BOOL)prefersHidesNavigationBarWhenKeyboardAppears
{
	return NO;
}


- (void)setNeedsNavigationBarAppearanceUpdate:(BOOL)animated
{
	UINavigationController *navigationController = self.navigationController;
	UIViewController *topViewController = navigationController ? navigationController.topViewController : nil;
	if (topViewController)
	{
		UIViewController *parentViewController = self;
		while (parentViewController && parentViewController != navigationController)
		{
			if (parentViewController == topViewController)
				break;
			parentViewController = self.parentViewController;
		}
		if (parentViewController == topViewController)
		{
			UIViewController *appearancedViewController = topViewController.childViewControllerForNavigationBarAppearance ?: topViewController;
			if (appearancedViewController == self)
				[navigationController updateNavigationBarAppearance:animated];
		}
	}
}


@end



@implementation UINavigationController (NavigationBarAppearance)


- (BOOL)isViewControllerBasedNavigationBarAppearance
{
	return NO;
}


- (UIViewController *)childViewControllerForNavigationBarAppearance
{
	UIViewController *topViewController = self.isViewControllerBasedNavigationBarAppearance ? self.topViewController : nil;
	return topViewController ? (topViewController.childViewControllerForNavigationBarAppearance ?: topViewController) : nil;
}


- (void)updateNavigationBarAppearance:(BOOL)animated
{
	UIViewController *appearancedViewController = [self childViewControllerForNavigationBarAppearance];
	if (appearancedViewController)
	{
		self.navigationBar.barStyle = appearancedViewController.preferredNavigationBarStyle;
		self.navigationBar.translucent = appearancedViewController.prefersNavigationBarTranslucent;
		if ([self respondsToSelector:@selector(setHidesBarsOnTap:)])
		{
			self.hidesBarsOnTap = appearancedViewController.prefersHidesNavigationBarOnTap;
			self.hidesBarsOnSwipe = appearancedViewController.prefersHidesNavigationBarOnSwipe;
			self.hidesBarsWhenVerticallyCompact = appearancedViewController.prefersHidesNavigationBarWhenVerticallyCompact;
			self.hidesBarsWhenKeyboardAppears = appearancedViewController.prefersHidesNavigationBarWhenKeyboardAppears;
		}
		[self setNavigationBarHidden:appearancedViewController.prefersNavigationBarHidden animated:animated];
		[self.navigationBar setNeedsLayout];
	}
}


@end
