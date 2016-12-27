//
//  DAViewController+Helpers.h
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DAViewController.h"



@interface DAViewController (DockedKeyboardSupport)

+ (CGRect)dockedKeyboardFrame;
+ (BOOL)isDockedKeyboardFrameChanging;

NOTIFICATION_DECL(DADockedKeyboardWillChangeFrameNotification)
NOTIFICATION_DECL(DADockedKeyboardDidChangeFrameNotification)

@end


UIKIT_EXTERN NSString *const DAViewControllerStatusBarAppearanceDidUpdateNotification;
