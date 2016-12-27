//
//  DAViewController+Helpers.m
//  loveplanet
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 RBC. All rights reserved.
//

#import "DAViewController+Helpers.h"



@implementation DAViewController (DockedKeyboardSupport)


static BOOL DAViewController_DockedKeyboardInitialized = NO;
static BOOL DAViewController_IsDockedKeyboardFrameChanging = NO;
static CGRect DAViewController_DockedKeyboardFrame;


+ (void)initialize
{
	if (!DAViewController_DockedKeyboardInitialized)
	{
		DAViewController_DockedKeyboardInitialized = YES;
		DAViewController_IsDockedKeyboardFrameChanging = NO;
		DAViewController_DockedKeyboardFrame = CGRectNull;
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center addObserver:self selector:@selector(DAViewController_keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[center addObserver:self selector:@selector(DAViewController_keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
		[center addObserver:self selector:@selector(DAViewController_keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
		[center addObserver:self selector:@selector(DAViewController_keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
	}
}


+ (void)DAViewController_keyboardWillChangeFrame:(NSNotification*)notification
{
}


+ (void)DAViewController_keyboardDidChangeFrame:(NSNotification*)notification
{
}


+ (void)DAViewController_keyboardWillShow:(NSNotification*)notification
{
	if (!DAViewController_IsDockedKeyboardFrameChanging)
	{
		DAViewController_IsDockedKeyboardFrameChanging = YES;
		DAViewController_DockedKeyboardFrame = [(NSValue*)[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
		[[NSNotificationCenter defaultCenter] postNotificationName:DADockedKeyboardWillChangeFrameNotification object:nil userInfo:[notification userInfo]];
	}
}


+ (void)DAViewController_keyboardDidShow:(NSNotification*)notification
{
	if (DAViewController_IsDockedKeyboardFrameChanging)
	{
		DAViewController_IsDockedKeyboardFrameChanging = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:DADockedKeyboardDidChangeFrameNotification object:nil userInfo:[notification userInfo]];
	}
}


+ (void)DAViewController_keyboardWillHide:(NSNotification*)notification
{
	if (!DAViewController_IsDockedKeyboardFrameChanging)
	{
		DAViewController_IsDockedKeyboardFrameChanging = YES;
		DAViewController_DockedKeyboardFrame = CGRectNull;
		[[NSNotificationCenter defaultCenter] postNotificationName:DADockedKeyboardWillChangeFrameNotification object:nil userInfo:[notification userInfo]];
	}
}


+ (void)DAViewController_keyboardDidHide:(NSNotification*)notification
{
	if (DAViewController_IsDockedKeyboardFrameChanging)
	{
		DAViewController_IsDockedKeyboardFrameChanging = NO;
		[[NSNotificationCenter defaultCenter] postNotificationName:DADockedKeyboardDidChangeFrameNotification object:nil userInfo:[notification userInfo]];
	}
}


+ (BOOL)isDockedKeyboardFrameChanging
{
	return DAViewController_IsDockedKeyboardFrameChanging;
}


+ (CGRect)dockedKeyboardFrame
{
	return DAViewController_DockedKeyboardFrame;
}


NOTIFICATION_IMPL(DADockedKeyboardWillChangeFrameNotification)
NOTIFICATION_IMPL(DADockedKeyboardDidChangeFrameNotification)


@end



NSString *const DAViewControllerStatusBarAppearanceDidUpdateNotification = @"DAViewControllerStatusBarAppearanceDidUpdateNotification";
