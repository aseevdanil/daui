//
//  DABadgeView.h
//  daui
//
//  Created by da on 24.08.12.
//  Copyright (c) 2012 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface DABadgeView : UIView

@property (nonatomic, copy) NSString *value;
- (void)setValue:(NSString*)value animated:(BOOL)animated;
- (void)setValue:(NSString*)value animated:(BOOL)animated completion:(void(^)(void))completion;

// Attributes:
// NSBackgroundColorAttributeName - badge fill color
// NSForegroundColorAttributeName - badge text color
// NSStrokeColorAttributeName - badge stroke color
// NSStrokeWidthAttributeName - badge strokeWidth
@property (nonatomic, copy) NSDictionary *drawingAttributes;
+ (NSDictionary*)defaultDrawingAttributes;

+ (CGSize)preferredViewSizeWithValue:(NSString*)value;
+ (CGRect)preferredViewFrameWithValue:(NSString*)value forBounds:(CGRect)bounds;

@end
