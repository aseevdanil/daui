//
//  DAComplexView.h
//  daui
//
//  Created by da on 30.05.13.
//  Copyright (c) 2013 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef NS_ENUM(NSUInteger, DAComplexViewImageViewVerticalAlignment)
{
	DAComplexViewImageViewVerticalAlignmentCenter,
	DAComplexViewImageViewVerticalAlignmentTop,
	DAComplexViewImageViewVerticalAlignmentBottom,
};


typedef NS_ENUM(NSUInteger, DAComplexViewAccessoryLayout)
{
	DAComplexViewAccessoryLayoutRightBoundsEdge,
	DAComplexViewAccessoryLayoutToRightOfLabel,
	DAComplexViewAccessoryLayoutToBottomOfLabel,
	DAComplexViewAccessoryLayoutToTopOfSublabel,
};


typedef NS_ENUM(NSUInteger, DAComplexViewAccessoryAutoresizing)
{
	DAComplexViewAccessoryAutoresizingNone,
	DAComplexViewAccessoryAutoresizingFixibleSizeToFit,
	DAComplexViewAccessoryAutoresizingFlexibleSizeToFit,
};


typedef NS_ENUM(NSUInteger, DAComplexViewAccessoryAlignment)
{
	DAComplexViewAccessoryAlignmentCenter,
	DAComplexViewAccessoryAlignmentTopOrLeft,
	DAComplexViewAccessoryAlignmentBottomOrRight,
};



@interface DAComplexView : UIView
{
	UIImageView *_imageView;
	UILabel *_label;
	UILabel *_sublabel;
	UIView *_accessoryView;
	
	UIEdgeInsets _boundsInsets;
	CGSize _labelOffset;
	CGFloat _accessoryOffset;
	CGSize _accessoryAutoresizingSize;
	CGSize _labelIndent;
	CGSize _sublabelIndent;
	
	struct
	{
		unsigned int imageViewVerticalAlignment : 2;
		unsigned int imageViewBoundsTiedToImage : 1;
		unsigned int accessoryLayout : 2;
		unsigned int accessoryAutoresizing : 2;
		unsigned int accessoryAlignment : 2;
	}
	_complexViewFlags;
}

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) UILabel *sublabel;
@property (nonatomic, strong) UIView *accessoryView;

@property (nonatomic, assign) UIEdgeInsets boundsInsets;
@property (nonatomic, assign) DAComplexViewImageViewVerticalAlignment imageViewVerticalAlignment;
@property (nonatomic, assign, getter = isImageViewBoundsTiedToImage) BOOL imageViewBoundsTiedToImage;
@property (nonatomic, assign) CGSize labelOffset;
@property (nonatomic, assign) CGSize labelIndent;
@property (nonatomic, assign) CGSize sublabelIndent;
@property (nonatomic, assign) CGFloat accessoryOffset;
@property (nonatomic, assign) DAComplexViewAccessoryLayout accessoryLayout;
@property (nonatomic, assign) DAComplexViewAccessoryAutoresizing accessoryAutoresizing;
@property (nonatomic, assign) CGSize accessoryAutoresizingSize;
@property (nonatomic, assign) DAComplexViewAccessoryAlignment accessoryAlignment;

+ (Class)imageViewClass;
+ (Class)labelClass;
+ (Class)sublabelClass;

@end

