//
//  DASegmentsControl.h
//  daui
//
//  Created by da on 12.02.13.
//  Copyright (c) 2013 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef NS_ENUM(NSUInteger, DASegmentsControlBehavior)
{
	DASegmentsControlSwitcherBehavior,
	DASegmentsControlMomentaryBehavior,
	DASegmentsControlMultiselectBehavior,
};

enum { DASegmentsControlNoSegment = NSNotFound, };



@interface DASegmentItem : NSObject
{
	UIImage *_image;
	UIImage *_selectedImage;
	NSString *_title;
	unsigned int _enabled : 1;
}

- (instancetype)initWithImage:(UIImage*)image selectedImage:(UIImage*)selectedImage title:(NSString*)title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *selectedImage;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign, getter = isEnabled) BOOL enabled;

@end



@interface DASegmentsControl : UIControl
{
	NSArray<DASegmentItem*> *_items;
	
	NSMutableArray *_buttons;
	NSMutableArray *_separators;
	
	UIImage *_normalBackgroundImage;
	UIImage *_highlightedBackgroundImage;
	UIImage *_selectedBackgroundImage;
	NSDictionary *_normalTitleTextAttributes;
	NSDictionary *_highlightedTitleTextAttributes;
	NSDictionary *_selectedTitleTextAttributes;
	UIImage *_separatorImage;
	CGSize _segmentSize;
	UIOffset _segmentContentPositionAdjustment;
	CGFloat _segmentImageTitleSpacing;
	
	unsigned int _behavior : 2;
	unsigned int _backgroundImages : 1;
		
	unsigned int _needsUpdateCustomization : 1;
}

@property (nonatomic, copy) NSArray<DASegmentItem*> *items;

@property (nonatomic, assign) NSUInteger selectedSegmentIndex;
@property (nonatomic, copy) NSIndexSet *selectedSegmentsIndexes;

@property (nonatomic, assign) DASegmentsControlBehavior behavior;

@property (nonatomic, strong) UIImage *normalBackgroundImage;
@property (nonatomic, strong) UIImage *highlightedBackgroundImage;
@property (nonatomic, strong) UIImage *selectedBackgroundImage;
@property (nonatomic, strong) UIImage *separatorImage;
@property (nonatomic, copy) NSDictionary *normalTitleTextAttributes;
@property (nonatomic, copy) NSDictionary *highlightedTitleTextAttributes;
@property (nonatomic, copy) NSDictionary *selectedTitleTextAttributes;
@property (nonatomic, assign) CGSize segmentSize;
@property (nonatomic, assign) UIOffset segmentContentPositionAdjustment;
@property (nonatomic, assign) CGFloat segmentImageTitleSpacing;

@end
