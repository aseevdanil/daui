//
//  UIClosedViewController.h
//  daui
//
//  Created by da on 08.02.12.
//  Copyright (c) 2012 Aseev Danil. All rights reserved.
//



@protocol UIClosedViewController
@property (nonatomic, weak) id closeDelegate;
@property (nonatomic, assign) SEL closeSelector;
@end
