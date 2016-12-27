//
//  UIViewController+NavigationBarAppearance.h
//  daui
//
//  Created by da on 04.06.15.
//  Copyright (c) 2015 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface UIViewController (NavigationBarAppearance)

- (UIViewController *)childViewControllerForNavigationBarAppearance;
- (UIBarStyle)preferredNavigationBarStyle; // Defaults to UIBarStyleDefault
- (BOOL)prefersNavigationBarTranslucent; // Defaults to YES
- (BOOL)prefersNavigationBarHidden NS_AVAILABLE_IOS(7_0); // Defaults to NO
- (BOOL)prefersHidesNavigationBarOnTap; // Defaults to NO
- (BOOL)prefersHidesNavigationBarOnSwipe; // Defaults to NO
- (BOOL)prefersHidesNavigationBarWhenVerticallyCompact; // Defaults to NO
- (BOOL)prefersHidesNavigationBarWhenKeyboardAppears; // Defaults to NO
- (void)setNeedsNavigationBarAppearanceUpdate:(BOOL)animated;

@end


@interface UINavigationController (NavigationBarAppearance)

@property (nonatomic, assign, readonly, getter = isViewControllerBasedNavigationBarAppearance) BOOL viewControllerBasedNavigationBarAppearance;
- (void)updateNavigationBarAppearance:(BOOL)animated;

@end
