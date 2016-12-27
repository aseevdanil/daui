//
//  DATextView.h
//  daui
//
//  Created by da on 03.02.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface DATextView : UITextView <UIDynamicDimensionsItem>

@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, copy) NSAttributedString *attributedPlaceholder;

@property (nonatomic, assign) NSUInteger minimumDynamicNumberOfLines;
@property (nonatomic, assign) NSUInteger maximumDynamicNumberOfLines;
@property (nonatomic, assign, readonly) CGFloat dynamicHeight;

- (void)textDidChange;

@end
