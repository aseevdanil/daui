//
//  UIClosedViewController.h
//  daui
//
//  Created by da on 08.02.12.
//  Copyright (c) 2012 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol UIClosedViewController
@property (nonatomic, weak) id closeDelegate;
@property (nonatomic, assign) SEL closeSelector;
@end
