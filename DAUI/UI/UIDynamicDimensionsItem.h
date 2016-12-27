//
//  UIDynamicDimensionsItem.h
//  daui
//
//  Created by da on 30.09.13.
//  Copyright (c) 2013 Aseev Danil. All rights reserved.
//



@protocol UIDynamicDimensionsItem
@optional
@property (nonatomic, assign, readonly) CGFloat dynamicWidth;
@property (nonatomic, assign, readonly) CGFloat dynamicHeight;
@property (nonatomic, assign, readonly) CGSize dynamicSize;
@end
