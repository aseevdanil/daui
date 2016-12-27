//
//  DARefreshView.h
//  daui
//
//  Created by da on 26.03.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface DARefreshView : UIView

@property (nonatomic, assign) UIRectEdge attachEdge;

@property (nonatomic, assign, getter = isDisabled) BOOL disabled;
- (void)setDisabled:(BOOL)disabled animated:(BOOL)animated;
@property (nonatomic, assign) CGFloat level;
- (void)setLevel:(CGFloat)level animated:(BOOL)animated;
@property (nonatomic, assign, getter = isRefreshing) BOOL refreshing;
- (void)setRefreshing:(BOOL)refreshing animated:(BOOL)animated;

+ (UIColor*)defaultTintColor;

+ (CGSize)preferredViewSize:(BOOL)compact;
+ (CGSize)preferredMinimumContentSizeForNonCompactViewSize;
+ (CGFloat)preferredLevelForContentShift:(CGFloat)shift compact:(BOOL)compact;

@end
