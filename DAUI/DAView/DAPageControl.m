//
//  DAPageControl.m
//  daui
//
//  Created by da on 29.05.12.
//  Copyright (c) 2012 Aseev Danil. All rights reserved.
//

#import "DAPageControl.h"



@interface DAPageLayer : CALayer
{
	NSMutableArray *_pinsLayers;
	CGSize _pinSize;
}

@property (nonatomic, copy) NSArray *pinsImages;
- (void)updateImage:(CGImageRef)image forPin:(NSUInteger)pinNumber animated:(BOOL)animated;
@property (nonatomic, assign) CGSize pinSize;
- (CGRect)pinFrame:(NSUInteger)pinNumber;

@end


@implementation DAPageLayer


@synthesize pinSize = _pinSize;


- (instancetype)init
{
	if ((self = [super init]))
	{
		_pinSize = CGSizeMake(16., 16.);
	}
	return self;
}


- (void)setContentsScale:(CGFloat)contentsScale
{
	[super setContentsScale:contentsScale];
	for (CALayer *layer in _pinsLayers)
		layer.contentsScale = contentsScale;
}


- (void)layoutSublayers
{
	[super layoutSublayers];
	
	if (_pinsLayers)
	{
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		CGRect bounds = self.bounds;
		CGFloat pinsWidth = 0.;
		for (CALayer *layer in _pinsLayers)
			pinsWidth += layer.bounds.size.width;
		bounds.origin.x += (bounds.size.width - pinsWidth) / 2;
		bounds.size.width = pinsWidth;
		CGRect layerFrame = bounds;
		for (CALayer *layer in _pinsLayers)
		{
			layerFrame.size = layer.bounds.size;
			layerFrame.origin.y += (bounds.size.height - layerFrame.size.height) / 2;
			layer.position = CGRectGetCenter(layerFrame);
			layerFrame.origin.x += layerFrame.size.width;
			layerFrame.origin.y = bounds.origin.y;
		}
		[CATransaction commit];
	}
}


- (void)setPinSize:(CGSize)pinSize
{
	if (CGSizeEqualToSize(pinSize, _pinSize))
		return;
	_pinSize = pinSize;
	if (_pinsLayers)
	{
		for (CALayer *layer in _pinsLayers)
		{
			CGRect bounds = CGRectZero;
			bounds.size = _pinSize;
			CGImageRef image = (__bridge CGImageRef) layer.contents;
			if (bounds.size.width == 0.)
				bounds.size.width = CGImageGetWidth(image) / layer.contentsScale;
			if (bounds.size.height == 0.)
				bounds.size.height = CGImageGetHeight(image) / layer.contentsScale;
			layer.bounds = bounds;
		}
		[self setNeedsLayout];
	}
}


- (CGRect)pinFrame:(NSUInteger)pinNumber
{
	DASSERT(_pinsLayers && pinNumber < _pinsLayers.count);
	return ((CALayer*)[_pinsLayers objectAtIndex:pinNumber]).frame;
}


- (NSArray*)pinsImages
{
	if (!_pinsLayers)
		return nil;
	NSMutableArray *pins = [[NSMutableArray alloc] initWithCapacity:_pinsLayers.count];
	for (CALayer *layer in _pinsLayers)
		[pins addObject:(id) layer.contents];
	return pins;
}


- (void)setPinsImages:(NSArray *)pinsImages
{
	if (_pinsLayers)
	{
		for (CALayer *layer in _pinsLayers)
			[layer removeFromSuperlayer];
		_pinsLayers = nil;
	}
	if (!pinsImages || pinsImages.count == 0)
		return;
	_pinsLayers = [[NSMutableArray alloc] initWithCapacity:pinsImages.count];
	for (id image in pinsImages)
	{
		CALayer *layer = [[CALayer alloc] init];
		layer.opaque = NO;
		layer.contentsScale = self.contentsScale;
		layer.contentsGravity = kCAGravityCenter;
		CGRect bounds = CGRectZero;
		bounds.size = _pinSize;
		if (bounds.size.width == 0.)
			bounds.size.width = CGImageGetWidth((CGImageRef) image) / layer.contentsScale;
		if (bounds.size.height == 0.)
			bounds.size.height = CGImageGetHeight((CGImageRef) image) / layer.contentsScale;
		layer.bounds = bounds;
		layer.contents = image;
		[_pinsLayers addObject:layer];
		[self addSublayer:layer];
	}
	[self setNeedsLayout];
}


- (void)updateImage:(CGImageRef)image forPin:(NSUInteger)pinNumber animated:(BOOL)animated
{
	DASSERT(image);
	DASSERT(_pinsLayers && pinNumber < _pinsLayers.count);
	[CATransaction begin];
	[CATransaction setDisableActions:!animated];
	CALayer *layer = (CALayer*)[_pinsLayers objectAtIndex:pinNumber];
	layer.contents = (__bridge id) image;
	[CATransaction commit];
}


@end



#pragma mark -


@interface DAPageControl ()

- (void)updatePinsImages;
- (BOOL)setDefaultPageImageIfNeed;

@end


@implementation DAPageControl


#pragma mark Base


+ (Class)layerClass
{
	return [DAPageLayer class];
}


#define _pageLayer ((DAPageLayer*) self.layer)


@synthesize numberOfPages = _numberOfPages, currentPage = _currentPage;


- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
	{
		_numberOfPages = 0;
		_currentPage = NSNotFound;
		_hidesForSinglePage = NO;
		_customPageImage = _customCurrentPageImage = NO;
		
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];
    }
    return self;
}


- (void)tintColorDidChange
{
	[super tintColorDidChange];
	if (!_customPageImage)
		_pageImage = nil;
	if (!_customCurrentPageImage)
		_currentPageImage = nil;
	if ([self setDefaultPageImageIfNeed])
		[self updatePinsImages];
}


- (CGSize)sizeThatFits:(CGSize)size
{
	CGSize pinsSize = _pageLayer.pinSize;
	pinsSize.width *= _numberOfPages;
	if (_numberOfPages > 0 && _pageImage)
	{
		if (pinsSize.width == 0.)
			pinsSize.width = _pageImage.size.width * _numberOfPages;
		if (pinsSize.height == 0.)
			pinsSize.height = _pageImage.size.height;
	}
	if (size.width == 0. || pinsSize.width < size.width)
		size.width = pinsSize.width;
	if (size.height == 0. || pinsSize.height < size.height)
		size.height = pinsSize.height;
	return size;
}


- (void)updatePinsImages
{
	if (_numberOfPages == 0 || !_pageImage)
	{
		_pageLayer.pinsImages = nil;
	}
	else
	{
		NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:_numberOfPages];
		for (NSUInteger i = 0; i < _numberOfPages; ++i)
			[images addObject:(id) _pageImage.CGImage];
		_pageLayer.pinsImages = images;
		if (_currentPage != NSNotFound && _currentPageImage)
			[_pageLayer updateImage:_currentPageImage.CGImage forPin:_currentPage animated:NO];
	}
}


- (void)setNumberOfPages:(NSUInteger)numberOfPages
{
	if (numberOfPages == _numberOfPages)
		return;
	_currentPage = NSNotFound;
	_numberOfPages = numberOfPages;
	self.hidden = _hidesForSinglePage && _numberOfPages < 2;
	[self updatePinsImages];
}


- (void)setCurrentPage:(NSUInteger)currentPage
{
	[self setCurrentPage:currentPage animated:NO];
}


- (void)setCurrentPage:(NSUInteger)currentPage animated:(BOOL)animated
{
	DASSERT(currentPage == NSNotFound || currentPage < _numberOfPages);
	if (currentPage == _currentPage)
		return;
	if (_currentPage != NSNotFound && _pageImage && _currentPageImage)
		[_pageLayer updateImage:_pageImage.CGImage forPin:_currentPage animated:animated];
	_currentPage = currentPage;
	if (_currentPage != NSNotFound && _pageImage && _currentPageImage)
		[_pageLayer updateImage:_currentPageImage.CGImage forPin:_currentPage animated:animated];
}


- (void)handleTap:(UITapGestureRecognizer*)gesture
{
	if (_numberOfPages == 0 || !_pageImage)
		return;
	NSUInteger newPage = _currentPage;
	if (newPage == NSNotFound)
	{
		newPage = 0;
	}
	else
	{
		CGPoint tapPoint = [gesture locationInView:self];
		CGRect currentPageFrame = [_pageLayer pinFrame:newPage];
		if (tapPoint.x <= currentPageFrame.origin.x)
		{
			if (newPage > 0)
				--newPage;
		}
		else if (tapPoint.x >= currentPageFrame.origin.x + currentPageFrame.size.width)
		{
			if (newPage < _numberOfPages - 1)
				++newPage;
		}
	}
	if (newPage == NSNotFound || newPage == _currentPage)
		return;
	if (_currentPage != NSNotFound && _currentPageImage)
		[_pageLayer updateImage:_pageImage.CGImage forPin:_currentPage animated:YES];
	_currentPage = newPage;
	if (_currentPage != NSNotFound && _currentPageImage)
		[_pageLayer updateImage:_currentPageImage.CGImage forPin:_currentPage animated:YES];
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}


- (BOOL)isHideForSinglePage
{
	return _hidesForSinglePage;
}


- (void)setHidesForSinglePage:(BOOL)hidesForSinglePage
{
	_hidesForSinglePage = hidesForSinglePage;
	self.hidden = _hidesForSinglePage && _numberOfPages < 2;
}


#pragma mark -
#pragma mark Customization


@synthesize pageImage = _pageImage, currentPageImage = _currentPageImage;


- (CGSize)pageSize
{
	return _pageLayer.pinSize;
}


- (void)setPageSize:(CGSize)pageSize
{
	_pageLayer.pinSize = pageSize;
}


- (UIImage*)pageImage
{
	return _customPageImage ? _pageImage : nil;
}


- (void)setPageImage:(UIImage *)pageImage
{
	_pageImage = nil;
	_customPageImage = NO;
	if (pageImage)
	{
		_customPageImage = YES;
		_pageImage = pageImage;
		self.layer.contentsScale = _pageImage.scale;
		if (!_customCurrentPageImage)
		{
			_currentPageImage = nil;
			_customCurrentPageImage = YES;
		}
	}
	else
	{
		[self setDefaultPageImageIfNeed];
	}
	[self updatePinsImages];
}


- (UIImage*)currentPageImage
{
	return _customCurrentPageImage ? _currentPageImage : nil;
}


- (void)setCurrentPageImage:(UIImage *)currentPageImage
{
	_currentPageImage = nil;
	_customCurrentPageImage = NO;
	if (currentPageImage)
	{
		_customCurrentPageImage = YES;
		_currentPageImage = currentPageImage;
	}
	else
	{
		if (_customPageImage)
		{
			_customCurrentPageImage = YES;
		}
		else
		{
			[self setDefaultPageImageIfNeed];
		}
	}
	if (_currentPage != NSNotFound)
		[_pageLayer updateImage:_currentPageImage ? _currentPageImage.CGImage : _pageImage.CGImage forPin:_currentPage animated:NO];
}


static CGImageRef DAPageControlCreateDefaultPageImage(CGSize size, CGColorRef color)
{
	CGImageRef image = NULL;
	CGColorSpaceRef space = NULL;
	CGContextRef context = NULL;
	
	size = CGSizeIntegral(size);
	
	space = CGColorSpaceCreateDeviceRGB();
	if (!space)
		goto cleanup;
	
	context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, space, (CGBitmapInfo) kCGImageAlphaPremultipliedLast);
	if (!context)
		goto cleanup;
	
	CGContextSetFillColorWithColor(context, color);
	CGRect rect = (CGRect){.origin = CGPointZero, .size = size};
	CGContextFillEllipseInRect(context, rect);
	
	image = CGBitmapContextCreateImage(context);
	
cleanup:
	if (context)
		CGContextRelease(context);
	if (space)
		CGColorSpaceRelease(space);
	
	return image;

}


- (BOOL)setDefaultPageImageIfNeed
{
	BOOL update = NO;
	if (!_customPageImage && !_pageImage)
	{
		CGImageRef imageref = DAPageControlCreateDefaultPageImage(CGSizeMultiply(CGSizeMake(7., 7.), UIScreenScale()), [self.tintColor colorWithAlphaComponent:.5].CGColor);
		if (imageref)
		{
			_pageImage = [[UIImage alloc] initWithCGImage:imageref scale:UIScreenScale() orientation:UIImageOrientationUp];
			self.layer.contentsScale = _pageImage.scale;
			CGImageRelease(imageref);
			update = YES;
		}
	}
	if (!_customCurrentPageImage && !_currentPageImage)
	{
		CGImageRef imageref = DAPageControlCreateDefaultPageImage(CGSizeMultiply(CGSizeMake(7., 7.), UIScreenScale()), self.tintColor.CGColor);
		if (imageref)
		{
			_currentPageImage = [[UIImage alloc] initWithCGImage:imageref scale:UIScreenScale() orientation:UIImageOrientationUp];
			CGImageRelease(imageref);
			update = YES;
		}
	}
	return update;
}


@end
