//
//  DASegmentsControl.m
//  daui
//
//  Created by da on 12.02.13.
//  Copyright (c) 2013 Aseev Danil. All rights reserved.
//

#import "DASegmentsControl.h"

#import "DAButton.h"



#define kDASegmentsControl_DefaultCornerRadius	5.
#define kDASegmentsControl_DefaultBorderThick	1.
#define kDASegmentsControl_DefaultEdgeThick		1.
#define kDASegmentsControl_DefaultTintColor		[UIColor blueColor]



static CGImageRef DACreateSegmentsBackgroundImage(CGSize size, CGFloat scale, CGFloat cornerRadius, CGFloat borderThick, CGFloat edgeThick, CGColorRef borderColor, CGColorRef fillColor);
static CGImageRef DACreateSegmentsSeparatorImage(CGSize size, CGFloat scale, CGFloat edgeThick, CGColorRef color);



@implementation DASegmentItem


@synthesize image = _image, selectedImage = _selectedImage, title = _title;


- (instancetype)init
{
	return [self initWithImage:nil selectedImage:nil title:nil];
}


- (instancetype)initWithImage:(UIImage*)image selectedImage:(UIImage*)selectedImage title:(NSString*)title
{
	if ((self = [super init]))
	{
		_image = image;
		_selectedImage = selectedImage;
		_title = [title copy];
		_enabled = YES;
	}
	return self;
}


- (BOOL)isEnabled
{
	return _enabled;
}


- (void)setEnabled:(BOOL)enabled
{
	_enabled = enabled;
}


@end



@interface DASegmentButton : DAButton
{
	CGFloat _backgroundHeight;
}

@property (nonatomic, assign) CGFloat backgroundHeight;

@end


@implementation DASegmentButton


@synthesize backgroundHeight = _backgroundHeight;


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		_backgroundHeight = 0.;
	}
	return self;
}


- (CGRect)backgroundRectForBounds:(CGRect)bounds
{
	bounds = [super backgroundRectForBounds:bounds];
	if (0. < _backgroundHeight && _backgroundHeight < bounds.size.height)
	{
		bounds.origin.y += (bounds.size.height - _backgroundHeight) / 2;
		bounds.size.height = _backgroundHeight;
		CGFloat scale = UIScreenScale();
		bounds.origin.x *= scale;
		bounds.origin.y *= scale;
		bounds.size.width *= scale;
		bounds.size.height *= scale;
		bounds = CGRectIntegral(bounds);
		bounds.origin.x /= scale;
		bounds.origin.y /= scale;
		bounds.size.width /= scale;
		bounds.size.height /= scale;
	}
	return bounds;
}


@end



@interface UIImage (Disassemble)

- (void)disassembleToResizebleImages:(UIImage*__autoreleasing*)pfullImage :(UIImage*__autoreleasing*)pleftImage :(UIImage*__autoreleasing*)prightImage :(UIImage*__autoreleasing*)pmiddleImage;

@end



@interface DASegmentsControl ()

- (void)regItem:(DASegmentItem*)item;
- (void)unregItem:(DASegmentItem*)item;

- (void)setNeedsUpdateCustomization;
- (void)updateCustomizationIfNeeded;

@end



@implementation DASegmentsControl


#pragma mark -
#pragma mark Base


static char DASegmentsControlContext;


@synthesize items = _items;
@synthesize normalBackgroundImage = _normalBackgroundImage, highlightedBackgroundImage = _highlightedBackgroundImage, selectedBackgroundImage = _selectedBackgroundImage, separatorImage = _separatorImage;
@synthesize normalTitleTextAttributes = _normalTitleTextAttributes, highlightedTitleTextAttributes = _highlightedTitleTextAttributes, selectedTitleTextAttributes = _selectedTitleTextAttributes;
@synthesize segmentSize = _segmentSize, segmentContentPositionAdjustment = _segmentContentPositionAdjustment, segmentImageTitleSpacing = _segmentImageTitleSpacing;


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		self.autoresizesSubviews = NO;
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		_behavior = DASegmentsControlSwitcherBehavior;
		_backgroundImages = NO;
		_needsUpdateCustomization = NO;
		_segmentSize = CGSizeMake(0., 30.);
		_segmentContentPositionAdjustment = UIOffsetZero;
		_segmentImageTitleSpacing = 10.;
	}
	return self;
}


- (void)dealloc
{
	for (DASegmentItem *item in _items)
		[self unregItem:item];
}


- (void)regItem:(DASegmentItem*)item
{
	DASSERT(item);
	[item addObserver:self forKeyPath:@"image" options:0 context:&DASegmentsControlContext];
	[item addObserver:self forKeyPath:@"selectedImage" options:0 context:&DASegmentsControlContext];
	[item addObserver:self forKeyPath:@"title" options:0 context:&DASegmentsControlContext];
	[item addObserver:self forKeyPath:@"enabled" options:0 context:&DASegmentsControlContext];
}


- (void)unregItem:(DASegmentItem*)item
{
	DASSERT(item);
	[item removeObserver:self forKeyPath:@"image" context:&DASegmentsControlContext];
	[item removeObserver:self forKeyPath:@"selectedImage" context:&DASegmentsControlContext];
	[item removeObserver:self forKeyPath:@"title" context:&DASegmentsControlContext];
	[item removeObserver:self forKeyPath:@"enabled" context:&DASegmentsControlContext];
}


- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if (!_items)
		return;
	
	CGRect bounds = self.bounds;
	CGRect separatorFrame = bounds;
	separatorFrame.size.width = _backgroundImages ? (_separatorImage ? _separatorImage.size.width : 0.) : kDASegmentsControl_DefaultBorderThick;
	CGRect segmentFrame = bounds;
	segmentFrame.size.width = (bounds.size.width - separatorFrame.size.width * ([_buttons count] - 1)) / [_buttons count];
	if (0. < _segmentSize.width && _segmentSize.width < segmentFrame.size.width)
	{
		segmentFrame.size.width = _segmentSize.width;
		CGFloat segmentsWidth = (segmentFrame.size.width + separatorFrame.size.width) * [_buttons count] - separatorFrame.size.width;
		segmentFrame.origin.x += (bounds.size.width - segmentsWidth) / 2;
		separatorFrame.origin.x = segmentFrame.origin.x;
	}
	if (0. < _segmentSize.height && _segmentSize.height < segmentFrame.size.height)
	{
		separatorFrame.size.height = _segmentSize.height;
		separatorFrame.origin.y += (bounds.size.height - separatorFrame.size.height) / 2;
	}
	CGFloat scale = UIScreenScale();
	separatorFrame.origin.x *= scale;
	separatorFrame.origin.y *= scale;
	separatorFrame.size.width *= scale;
	separatorFrame.size.height *= scale;
	separatorFrame = CGRectIntegral(separatorFrame);
	separatorFrame.origin.x /= scale;
	separatorFrame.origin.y /= scale;
	separatorFrame.size.width /= scale;
	separatorFrame.size.height /= scale;
	segmentFrame.origin.x *= scale;
	segmentFrame.origin.y *= scale;
	segmentFrame.size.width *= scale;
	segmentFrame.size.height *= scale;
	segmentFrame = CGRectIntegral(segmentFrame);
	segmentFrame.origin.x /= scale;
	segmentFrame.origin.y /= scale;
	segmentFrame.size.width /= scale;
	segmentFrame.size.height /= scale;
	separatorFrame.origin.x += segmentFrame.size.width;
	for (DASegmentButton *button in _buttons)
	{
		button.frame = segmentFrame;
		segmentFrame.origin.x += segmentFrame.size.width + separatorFrame.size.width;
	}
	for (UIImageView *separator in _separators)
	{
		separator.frame = separatorFrame;
		separatorFrame.origin.x += separatorFrame.size.width + segmentFrame.size.width;
	}
}


- (CGSize)sizeThatFits:(CGSize)size
{
	if (_segmentSize.width > 0. || size.width == 0.)
	{
		CGFloat separatorWidth = _backgroundImages ? (_separatorImage ? _separatorImage.size.width : 0.) : kDASegmentsControl_DefaultBorderThick;
		CGFloat segmentWidth = (size.width - separatorWidth * ([_buttons count] - 1)) / [_buttons count];
		if (_segmentSize.width < segmentWidth)
			size.width = (_segmentSize.width + separatorWidth) * [_buttons count] - separatorWidth;
	}
	if (_segmentSize.height > 0. || size.height == 0.)
	{
		if (_segmentSize.height < size.height)
			size.height = _segmentSize.height;
	}
	return size;
}


#pragma mark -
#pragma mark Items


- (void)setItems:(NSArray<DASegmentItem*>*)items
{
	if (_items)
	{
		for (DASegmentButton *button in _buttons)
			[button removeFromSuperview];
		_buttons = nil;
		for (UIImageView *separator in _separators)
			[separator removeFromSuperview];
		_separators = nil;
		for (DASegmentItem *item in _items)
			[self unregItem:item];
		_items = nil;
	}
	
	if (items && items.count > 0)
		_items = [items copy];
	if (_items)
	{
		_buttons = [[NSMutableArray alloc] initWithCapacity:[_items count]];
		for (NSUInteger i = 0; i < [_items count]; ++i)
		{
			DASegmentItem *item = (DASegmentItem*)[_items objectAtIndex:i];
			[self regItem:item];
			DASegmentButton *button = [[DASegmentButton alloc] init];
			button.adjustsImageWhenHighlighted = NO;
			button.imageEdgeInsets = UIEdgeInsetsMake(0., item.title ? -_segmentImageTitleSpacing : 0., 0., 0.);
			button.backgroundHeight = _segmentSize.height;
			[button setImage:item.image forState:UIControlStateNormal];
			[button setImage:item.selectedImage forState:UIControlStateSelected];
			[button setImage:item.selectedImage forState:UIControlStateHighlighted];
			[button setImage:item.selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
			[button setTitle:item.title forState:UIControlStateNormal];
			button.enabled = item.isEnabled;
			button.tag = i;
			[button addTarget:self action:@selector(handleSegmentButtonTap:) forControlEvents:UIControlEventTouchUpInside];
			[_buttons addObject:button];
			[self addSubview:button];
		}
		_separators = [[NSMutableArray alloc] initWithCapacity:[_items count] - 1];
		for (NSUInteger i = 0; i < [_items count] - 1; ++i)
		{
			UIImageView *separator = [[UIImageView alloc] init];
			[_separators addObject:separator];
			[self addSubview:separator];
		}
		[self setNeedsUpdateCustomization];
		[self updateCustomizationIfNeeded];
	}

	[self setNeedsLayout];
}


- (void)handleSegmentButtonTap:(UIButton*)button
{
	if (_behavior != DASegmentsControlMomentaryBehavior)
	{
		if (_behavior == DASegmentsControlSwitcherBehavior)
		{
			for (NSUInteger i = 0; i < [_buttons count]; ++i)
			{
				DASegmentButton *b = (DASegmentButton*)[_buttons objectAtIndex:i];
				b.selected = NO;
			}
		}
		button.selected = _behavior == DASegmentsControlSwitcherBehavior ? YES : !button.isSelected;
	}
	
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}


- (NSUInteger)selectedSegmentIndex
{
	DASSERT(_behavior != DASegmentsControlMomentaryBehavior);
	for (NSUInteger i = 0; i < [_buttons count]; ++i)
	{
		UIButton *button = (DASegmentButton*)[_buttons objectAtIndex:i];
		if (button.isSelected)
			return i;
	}
	return DASegmentsControlNoSegment;
}


- (void)setSelectedSegmentIndex:(NSUInteger)selectedSegmentIndex
{
	DASSERT(_behavior != DASegmentsControlMomentaryBehavior);
	for (NSUInteger i = 0; i < [_buttons count]; ++i)
	{
		DASegmentButton *button = (DASegmentButton*)[_buttons objectAtIndex:i];
		if (button.isSelected)
		{
			button.selected = NO;
			break;
		}
	}
	if (selectedSegmentIndex != DASegmentsControlNoSegment)
	{
		DASegmentButton *button = (DASegmentButton*)[_buttons objectAtIndex:selectedSegmentIndex];
		button.selected = YES;
	}
}


- (NSIndexSet*)selectedSegmentsIndexes
{
	DASSERT(_behavior != DASegmentsControlMomentaryBehavior);
	NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
	for (NSUInteger i = 0; i < [_buttons count]; ++i)
	{
		DASegmentButton *button = (DASegmentButton*)[_buttons objectAtIndex:i];
		if (button.isSelected)
			[indexes addIndex:i];
	}
	return indexes;
}


- (void)setSelectedSegmentsIndexes:(NSIndexSet *)selectedSegmentsIndexes
{
	DASSERT(_behavior != DASegmentsControlMomentaryBehavior);
	for (NSUInteger i = 0; i < [_buttons count]; ++i)
	{
		DASegmentButton *button = (DASegmentButton*)[_buttons objectAtIndex:i];
		button.selected = [selectedSegmentsIndexes containsIndex:i];
	}
}


- (DASegmentsControlBehavior)behavior
{
	return _behavior;
}


- (void)setBehavior:(DASegmentsControlBehavior)behavior
{
	if (behavior == _behavior)
		return;
	
	_behavior = behavior;
	
	for (NSUInteger i = 0; i < [_buttons count]; ++i)
	{
		DASegmentButton *button = (DASegmentButton*)[_buttons objectAtIndex:i];
		if (button.isSelected)
		{
			button.selected = NO;
			break;
		}
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &DASegmentsControlContext)
	{
		DASegmentItem *item = (DASegmentItem*) object;
		NSUInteger index = [_items indexOfObjectIdenticalTo:object];
		if (index != NSNotFound)
		{
			DASegmentButton *button = (DASegmentButton*)[_buttons objectAtIndex:index];
			if ([keyPath isEqualToString:@"image"])
			{
				[button setImage:item.image forState:UIControlStateNormal];
			}
			else if ([keyPath isEqualToString:@"selectedImage"])
			{
				[button setImage:item.selectedImage forState:UIControlStateSelected];
				[button setImage:item.selectedImage forState:UIControlStateHighlighted];
				[button setImage:item.selectedImage forState:UIControlStateSelected | UIControlStateHighlighted];
			}
			else if ([keyPath isEqualToString:@"title"])
			{
				button.imageEdgeInsets = UIEdgeInsetsMake(0., item.title ? -_segmentImageTitleSpacing : 0., 0., 0.);
				[button setTitle:item.title forState:UIControlStateNormal];
			}
			else if ([keyPath isEqualToString:@"enabled"])
			{
				button.enabled = item.isEnabled;
			}
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


#pragma mark -
#pragma mark Customization


- (void)setNeedsUpdateCustomization
{
	if (!_needsUpdateCustomization)
	{
		_needsUpdateCustomization = YES;
		[self performSelector:@selector(updateCustomization) withObject:nil afterDelay:0.];
	}
}


- (void)updateCustomizationIfNeeded
{
	if (_needsUpdateCustomization)
	{
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCustomization) object:nil];
		[self updateCustomization];
	}
}


- (void)updateCustomization
{
	DASSERT(_needsUpdateCustomization);
	_needsUpdateCustomization = NO;
	
	if (!_items)
		return;
	
	UIImage *normalBackgroundImage = nil, *selectedBackgroundImage = nil, *highlightedBackgroundImage = nil, *separatorImage = nil;
	if (_backgroundImages)
	{
		normalBackgroundImage = _normalBackgroundImage;
		selectedBackgroundImage = _selectedBackgroundImage;
		highlightedBackgroundImage = _highlightedBackgroundImage;
		separatorImage = _separatorImage;
	}
	else
	{
		UIColor *tintColor = [self respondsToSelector:@selector(tintColor)] ? self.tintColor : kDASegmentsControl_DefaultTintColor;
		if (tintColor)
		{
			CGColorRef borderCGColor = tintColor.CGColor;
			CGColorRef fillCGColor = [UIColor clearColor].CGColor;
			CGColorRef translucentCGColor = [tintColor colorWithAlphaComponent:.5].CGColor;
			CGFloat inset = kDASegmentsControl_DefaultCornerRadius + kDASegmentsControl_DefaultEdgeThick + kDASegmentsControl_DefaultBorderThick;
			CGSize backgroundCGImageSize = CGSizeMake(2 * inset + 1., 2 * inset + 1.);
			CGFloat scale = UIScreenScale();
			UIEdgeInsets backroundImageInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
			CGImageRef normalBackgroundCGImage = DACreateSegmentsBackgroundImage(backgroundCGImageSize, scale, kDASegmentsControl_DefaultCornerRadius, kDASegmentsControl_DefaultBorderThick, kDASegmentsControl_DefaultEdgeThick, borderCGColor, fillCGColor);
			CGImageRef highlightedBackgroundCGImage = DACreateSegmentsBackgroundImage(backgroundCGImageSize, scale, kDASegmentsControl_DefaultCornerRadius, kDASegmentsControl_DefaultBorderThick, kDASegmentsControl_DefaultEdgeThick, borderCGColor, translucentCGColor);
			CGImageRef selectedBackgroundCGImage = DACreateSegmentsBackgroundImage(backgroundCGImageSize, scale, kDASegmentsControl_DefaultCornerRadius, kDASegmentsControl_DefaultBorderThick, kDASegmentsControl_DefaultEdgeThick, borderCGColor, borderCGColor);
			CGImageRef separatorCGImage = DACreateSegmentsSeparatorImage(CGSizeMake(kDASegmentsControl_DefaultBorderThick, 2 * inset + 1.), scale, kDASegmentsControl_DefaultEdgeThick, borderCGColor);
			if (normalBackgroundCGImage)
			{
				normalBackgroundImage = [[UIImage imageWithCGImage:normalBackgroundCGImage scale:scale orientation:UIImageOrientationUp] resizableImageWithCapInsets:backroundImageInsets];
				CGImageRelease(normalBackgroundCGImage);
			}
			if (selectedBackgroundCGImage)
			{
				selectedBackgroundImage = [[UIImage imageWithCGImage:selectedBackgroundCGImage scale:scale orientation:UIImageOrientationUp] resizableImageWithCapInsets:backroundImageInsets];
				CGImageRelease(selectedBackgroundCGImage);
			}
			if (highlightedBackgroundCGImage)
			{
				highlightedBackgroundImage = [[UIImage imageWithCGImage:highlightedBackgroundCGImage scale:scale orientation:UIImageOrientationUp] resizableImageWithCapInsets:backroundImageInsets];
				CGImageRelease(highlightedBackgroundCGImage);
			}
			if (separatorCGImage)
			{
				separatorImage = [[UIImage imageWithCGImage:separatorCGImage scale:scale orientation:UIImageOrientationUp] resizableImageWithCapInsets:UIEdgeInsetsMake(inset, 0., inset, 0.)];
				CGImageRelease(separatorCGImage);
			}
		}
	}
	UIImage *segmentNormalBackgroundFull = nil, *segmentNormalBackgroundLeft = nil, *segmentNormalBackgroundRight = nil, *segmentNormalBackgroundMiddle = nil;
	UIImage *segmentHighlightedBackgroundFull = nil, *segmentHighlightedBackgroundLeft = nil, *segmentHighlightedBackgroundRight = nil, *segmentHighlightedBackgroundMiddle = nil;
	UIImage *segmentSelectedBackgroundFull = nil, *segmentSelectedBackgroundLeft = nil, *segmentSelectedBackgroundRight = nil, *segmentSelectedBackgroundMiddle = nil;
	if (normalBackgroundImage)
		[normalBackgroundImage disassembleToResizebleImages:&segmentNormalBackgroundFull :&segmentNormalBackgroundLeft :&segmentNormalBackgroundRight :&segmentNormalBackgroundMiddle];
	if (selectedBackgroundImage)
		[selectedBackgroundImage disassembleToResizebleImages:&segmentSelectedBackgroundFull :&segmentSelectedBackgroundLeft :&segmentSelectedBackgroundRight :&segmentSelectedBackgroundMiddle];
	if (highlightedBackgroundImage)
	{
		[highlightedBackgroundImage disassembleToResizebleImages:&segmentHighlightedBackgroundFull :&segmentHighlightedBackgroundLeft :&segmentHighlightedBackgroundRight :&segmentHighlightedBackgroundMiddle];
	}
	else
	{
		segmentHighlightedBackgroundFull = segmentSelectedBackgroundFull;
		segmentHighlightedBackgroundLeft = segmentSelectedBackgroundLeft;
		segmentHighlightedBackgroundRight = segmentSelectedBackgroundRight;
		segmentHighlightedBackgroundMiddle = segmentSelectedBackgroundMiddle;
	}
	UIFont *titleNormalFont = _normalTitleTextAttributes ? (UIFont*)[_normalTitleTextAttributes objectForKey:NSFontAttributeName] : nil;
	UIColor *titleNormalTextColor = _normalTitleTextAttributes ? (UIColor*)[_normalTitleTextAttributes objectForKey:NSForegroundColorAttributeName] : nil;
	NSShadow *titleNormalShadow = _normalTitleTextAttributes ? (NSShadow*)[_normalTitleTextAttributes objectForKey:NSShadowAttributeName] : nil;
	UIColor *titleNormalTextShadowColor = titleNormalShadow ? titleNormalShadow.shadowColor : nil;
	if (!titleNormalFont)
		titleNormalFont =  [UIFont systemFontOfSize:12.];
	if (!titleNormalTextColor)
		titleNormalTextColor = [self respondsToSelector:@selector(tintColor)] ? self.tintColor : kDASegmentsControl_DefaultTintColor;
	UIColor *titleSelectedTextColor = _selectedTitleTextAttributes ? (UIColor*)[_selectedTitleTextAttributes objectForKey:NSForegroundColorAttributeName] : nil;
	NSShadow *titleSelectedShadow = _selectedTitleTextAttributes ? (NSShadow*)[_selectedTitleTextAttributes objectForKey:NSShadowAttributeName] : nil;
	UIColor *titleSelectedTextShadowColor = titleSelectedShadow ? titleSelectedShadow.shadowColor : titleNormalTextShadowColor;
	if (!titleSelectedTextColor)
		titleSelectedTextColor = titleNormalTextColor;
	UIColor *titleHighlightedTextColor = _highlightedTitleTextAttributes ? (UIColor*)[_highlightedTitleTextAttributes objectForKey:NSForegroundColorAttributeName] : titleSelectedTextColor;
	NSShadow *titleHighlightedShadow = _highlightedTitleTextAttributes ? (NSShadow*)[_highlightedTitleTextAttributes objectForKey:NSShadowAttributeName] : nil;
	UIColor *titleHighlightedTextShadowColor = titleHighlightedShadow ? titleHighlightedShadow.shadowColor : titleSelectedTextShadowColor;
	for (NSUInteger i = 0; i < [_buttons count]; ++i)
	{
		UIButton *button = (UIButton*)[_buttons objectAtIndex:i];
		UIImage *normalBackground = [_buttons count] == 1 ? segmentNormalBackgroundFull : (i == 0 ? segmentNormalBackgroundLeft : (i == [_buttons count] - 1 ? segmentNormalBackgroundRight : segmentNormalBackgroundMiddle));
		UIImage *selectedBackground = [_buttons count] == 1 ? segmentSelectedBackgroundFull : (i == 0 ? segmentSelectedBackgroundLeft : (i == [_buttons count] - 1 ? segmentSelectedBackgroundRight : segmentSelectedBackgroundMiddle));
		UIImage *highlightedBackground = [_buttons count] == 1 ? segmentHighlightedBackgroundFull : (i == 0 ? segmentHighlightedBackgroundLeft : (i == [_buttons count] - 1 ? segmentHighlightedBackgroundRight : segmentHighlightedBackgroundMiddle));
		[button setBackgroundImage:normalBackground forState:UIControlStateNormal];
		[button setBackgroundImage:selectedBackground forState:UIControlStateSelected];
		[button setBackgroundImage:highlightedBackground forState:UIControlStateHighlighted];
		[button setBackgroundImage:selectedBackground forState:UIControlStateSelected | UIControlStateHighlighted];
		[button setTitleColor:titleNormalTextColor forState:UIControlStateNormal];
		[button setTitleColor:titleSelectedTextColor forState:UIControlStateSelected];
		[button setTitleColor:titleHighlightedTextColor forState:UIControlStateHighlighted];
		[button setTitleColor:titleHighlightedTextColor forState:UIControlStateSelected | UIControlStateHighlighted];
		[button setTitleShadowColor:titleNormalTextShadowColor forState:UIControlStateNormal];
		[button setTitleShadowColor:titleSelectedTextShadowColor forState:UIControlStateSelected];
		[button setTitleShadowColor:titleHighlightedTextShadowColor forState:UIControlStateHighlighted];
		[button setTitleShadowColor:titleHighlightedTextShadowColor forState:UIControlStateSelected | UIControlStateHighlighted];
		button.titleLabel.shadowOffset = titleNormalShadow ? titleNormalShadow.shadowOffset : CGSizeZero;
		button.titleLabel.font = titleNormalFont;
		button.contentEdgeInsets = UIEdgeInsetsMake(_segmentContentPositionAdjustment.vertical, _segmentContentPositionAdjustment.horizontal, 0., 0.);
	}
	for (UIImageView *separator in _separators)
		separator.image = separatorImage;
}


- (void)setNormalBackgroundImage:(UIImage *)normalBackgroundImage
{
	_normalBackgroundImage = normalBackgroundImage;
	if (!_backgroundImages)
	{
		_backgroundImages = YES;
		[self setNeedsLayout]; // так как изменяется separator
	}
	[self setNeedsUpdateCustomization];
}


- (void)setHighlightedBackgroundImage:(UIImage*)highlightedBackgroundImage
{
	_highlightedBackgroundImage = highlightedBackgroundImage;
	if (!_backgroundImages)
	{
		_backgroundImages = YES;
		[self setNeedsLayout]; // так как изменяется separator
	}
	[self setNeedsUpdateCustomization];
}


- (void)setSelectedBackgroundImage:(UIImage *)selectedBackgroundImage
{
	_selectedBackgroundImage = selectedBackgroundImage;
	if (!_backgroundImages)
	{
		_backgroundImages = YES;
		[self setNeedsLayout]; // так как изменяется separator
	}
	[self setNeedsUpdateCustomization];
}


- (void)setSeparatorImage:(UIImage *)separatorImage
{
	_separatorImage = separatorImage;
	if (!_backgroundImages)
	{
		_backgroundImages = YES;
		[self setNeedsLayout]; // так как изменяется separator
	}
	[self setNeedsUpdateCustomization];
}


- (void)setTintColor:(UIColor *)tintColor
{
	if (_backgroundImages)
	{
		_backgroundImages = NO;
		_normalBackgroundImage = nil;
		_highlightedBackgroundImage = nil;
		_selectedBackgroundImage = nil;
		CGFloat oldSeparatorWidth = _separatorImage ? _separatorImage.size.width : 0.;
		_separatorImage = nil;
		if (oldSeparatorWidth != 1. && [_separators count] > 0)
			[self setNeedsLayout];
	}
	[super setTintColor:tintColor];
}


- (void)tintColorDidChange
{
	[super tintColorDidChange];
	if (!_backgroundImages)
		[self setNeedsUpdateCustomization];
}


- (void)setNormalTitleTextAttributes:(NSDictionary *)normalTitleTextAttributes
{
	_normalTitleTextAttributes = [normalTitleTextAttributes copy];
	[self setNeedsUpdateCustomization];
}


- (void)setHighlightedTitleTextAttributes:(NSDictionary *)highlightedTitleTextAttributes
{
	_highlightedTitleTextAttributes = [highlightedTitleTextAttributes copy];
	[self setNeedsUpdateCustomization];
}


- (void)setSelectedTitleTextAttributes:(NSDictionary *)selectedTitleTextAttributes
{
	_selectedTitleTextAttributes = [selectedTitleTextAttributes copy];
	[self setNeedsUpdateCustomization];
}


- (void)setSegmentSize:(CGSize)segmentSize
{
	if (CGSizeEqualToSize(segmentSize, _segmentSize))
		return;
	
	_segmentSize = segmentSize;
	if (_buttons)
	{
		for (DASegmentButton *button in _buttons)
			button.backgroundHeight = _segmentSize.height;
	}
	[self setNeedsLayout];
}


- (void)setSegmentContentPositionAdjustment:(UIOffset)adjustment
{
	if (UIOffsetEqualToOffset(adjustment, _segmentContentPositionAdjustment))
		return;
	
	_segmentContentPositionAdjustment = adjustment;
	[self setNeedsUpdateCustomization];
}


- (void)setSegmentImageTitleSpacing:(CGFloat)segmentImageTitleSpacing
{
	if (segmentImageTitleSpacing == _segmentImageTitleSpacing)
		return;
	
	_segmentImageTitleSpacing = segmentImageTitleSpacing;
	if (_buttons)
	{
		for (DASegmentButton *button in _buttons)
		{
			if ([button titleForState:UIControlStateNormal] != nil)
				button.imageEdgeInsets = UIEdgeInsetsMake(0., -_segmentImageTitleSpacing, 0., 0.);
		}
	}
}


@end



@implementation UIImage (Disassemble)


- (void)disassembleToResizebleImages:(UIImage*__autoreleasing*)pfullImage :(UIImage*__autoreleasing*)pleftImage :(UIImage*__autoreleasing*)prightImage :(UIImage*__autoreleasing*)pmiddleImage
{
	CGSize size = self.size;
	if (size.width == 0. || size.height == 0.)
	{
		if (pfullImage)
			*pfullImage = nil;
		if (pleftImage)
			*pleftImage = nil;
		if (prightImage)
			*prightImage = nil;
		if (pmiddleImage)
			*pmiddleImage = nil;
		return;
	}
	
	UIEdgeInsets capInsets = self.capInsets;
	if (pfullImage)
		*pfullImage = self;
	if (UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero))
	{
		capInsets.left = capInsets.right = (size.width - 1.) / 2;
		capInsets.top = capInsets.bottom = (size.height - 1.) / 2;
		if (pfullImage)
			*pfullImage = [self resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeTile];
	}
	CGFloat nonresizebleWidth = size.width - (capInsets.left + capInsets.right);
	
	if (pleftImage)
	{
		CGRect leftImageRect = CGRectMake(0., 0., capInsets.left + nonresizebleWidth, size.height);
		UIEdgeInsets leftImageCapInsets = capInsets;
		leftImageCapInsets.right = 0.;
		*pleftImage = [self croppedImage:leftImageRect];
		if ([*pleftImage respondsToSelector:@selector(resizableImageWithCapInsets:resizingMode:)])
			*pleftImage = [*pleftImage resizableImageWithCapInsets:leftImageCapInsets resizingMode:self.resizingMode];
		else
			*pleftImage = [*pleftImage resizableImageWithCapInsets:leftImageCapInsets];
	}
	if (prightImage)
	{
		CGRect rightImageRect = CGRectMake(capInsets.left, 0., nonresizebleWidth + capInsets.right, size.height);
		UIEdgeInsets rightImageCapInsets = capInsets;
		rightImageCapInsets.left = 0.;
		*prightImage = [self croppedImage:rightImageRect];
		if ([*prightImage respondsToSelector:@selector(resizableImageWithCapInsets:resizingMode:)])
			*prightImage = [*prightImage resizableImageWithCapInsets:rightImageCapInsets resizingMode:self.resizingMode];
		else
			*prightImage = [*prightImage resizableImageWithCapInsets:rightImageCapInsets];
	}
	if (pmiddleImage)
	{
		CGRect middleImageRect = CGRectMake(capInsets.left, 0., nonresizebleWidth, size.height);
		UIEdgeInsets middleImageCapInsets = capInsets;
		middleImageCapInsets.left = middleImageCapInsets.right = 0.;
		*pmiddleImage = [self croppedImage:middleImageRect];
		if ([*pmiddleImage respondsToSelector:@selector(resizableImageWithCapInsets:resizingMode:)])
			*pmiddleImage = [*pmiddleImage resizableImageWithCapInsets:middleImageCapInsets resizingMode:self.resizingMode];
		else
			*pmiddleImage = [*pmiddleImage resizableImageWithCapInsets:middleImageCapInsets];
	}
}


@end



static CGImageRef DACreateSegmentsBackgroundImage(CGSize size, CGFloat scale, CGFloat cornerRadius, CGFloat borderThick, CGFloat edgeThick, CGColorRef borderColor, CGColorRef fillColor)
{
	CGImageRef image = NULL;
	CGColorSpaceRef space = NULL;
	CGContextRef context = NULL;
	
	size.width *= scale;
	size.height *= scale;
	cornerRadius *= scale;
	borderThick *= scale;
	edgeThick *= scale;
	
	unsigned char *buf = (unsigned char*) calloc(size.width * size.height, 4);
	if (!buf)
		goto cleanup;
	
	space = CGColorSpaceCreateDeviceRGB();
	if (!space)
		goto cleanup;
	
	context = CGBitmapContextCreate(buf, size.width, size.height, 8, size.width * 4, space, (CGBitmapInfo) kCGImageAlphaPremultipliedLast);
	if (!context)
		goto cleanup;
	
	CGFloat halfBorderThick = borderThick / 2;
	CGFloat minx = edgeThick + halfBorderThick;
	CGFloat midx = size.width / 2;
	CGFloat maxx = size.width - (edgeThick + halfBorderThick);
	CGFloat miny = edgeThick + halfBorderThick;
	CGFloat midy = size.height / 2;
	CGFloat maxy = size.height - (edgeThick + halfBorderThick);
	cornerRadius -= halfBorderThick;
	
	CGContextMoveToPoint(context, minx, midy);
	CGContextAddArcToPoint(context, minx, miny, midx, miny, cornerRadius);
	CGContextAddArcToPoint(context, maxx, miny, maxx, midy, cornerRadius);
	CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, cornerRadius);
	CGContextAddArcToPoint(context, minx, maxy, minx, midy, cornerRadius);
	CGContextClosePath(context);
	CGContextSetFillColorWithColor(context, fillColor);
	CGContextSetStrokeColorWithColor(context, borderColor);
	CGContextSetLineWidth(context, borderThick);
	CGContextDrawPath(context, kCGPathFillStroke);
	
	image = CGBitmapContextCreateImage(context);
	
cleanup:
	if (context)
		CGContextRelease(context);
	if (space)
		CGColorSpaceRelease(space);
	if (buf)
		free(buf);
	
	return image;
}


static CGImageRef DACreateSegmentsSeparatorImage(CGSize size, CGFloat scale, CGFloat edgeThick, CGColorRef color)
{
	CGImageRef image = NULL;
	CGColorSpaceRef space = NULL;
	CGContextRef context = NULL;
	
	size.width *= scale;
	size.height *= scale;
	edgeThick *= scale;
	
	unsigned char *buf = (unsigned char*) calloc(size.width * size.height, 4);
	if (!buf)
		goto cleanup;
	
	space = CGColorSpaceCreateDeviceRGB();
	if (!space)
		goto cleanup;
	
	context = CGBitmapContextCreate(buf, size.width, size.height, 8, size.width * 4, space, (CGBitmapInfo) kCGImageAlphaPremultipliedLast);
	if (!context)
		goto cleanup;
	
	CGContextSetFillColorWithColor(context, color);
	CGContextFillRect(context, CGRectMake(0., edgeThick, size.width, size.height - 2 * edgeThick));
	
	image = CGBitmapContextCreateImage(context);
	
cleanup:
	if (context)
		CGContextRelease(context);
	if (space)
		CGColorSpaceRelease(space);
	if (buf)
		free(buf);
	
	return image;
}
