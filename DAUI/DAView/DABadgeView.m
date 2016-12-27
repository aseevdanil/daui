//
//  DABadgeView.m
//  daui
//
//  Created by da on 24.08.12.
//  Copyright (c) 2012 Aseev Danil. All rights reserved.
//

#import "DABadgeView.h"



static const CGFloat DABadgeLayer_FillColorComponents[] = { 255. / 255., 4. / 255., 0. / 255., 1. };
static const CGFloat DABadgeLayer_TextColorComponents[] = { 255. / 255., 255. / 255., 255. / 255., 1. };


@interface DABadgeLayer : CAShapeLayer
{
	NSString *_value;
	CATextLayer *_valueLayer;
}

@property (nonatomic, copy) NSString *value;
- (void)setValue:(NSString*)value animated:(BOOL)animated completion:(void(^)(void))completion;

@property (nonatomic, assign /*retain*/) CGColorRef valueColor;

+ (CGSize)preferredLayerSizeWithValue:(NSString*)value scale:(CGFloat)contentsScale;

@end


@implementation DABadgeLayer


#define kDABadgeLayer_ValueFontName @"HelveticaNeue"
#define kDABadgeLayer_ValueFontSize 15.5


@synthesize value = _value;


- (instancetype)init
{
	if ((self = [super init]))
	{
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGColorRef fillColor = CGColorCreate(colorSpace, DABadgeLayer_FillColorComponents);
		CGColorRef textColor = CGColorCreate(colorSpace, DABadgeLayer_TextColorComponents);

		self.opaque = NO;
		self.fillColor = fillColor;
		self.strokeColor = nil;
		self.lineWidth = 0.;
		
		_valueLayer = [[CATextLayer alloc] init];
		_valueLayer.contentsScale = self.contentsScale;
		_valueLayer.foregroundColor = textColor;
		_valueLayer.font = (__bridge CFTypeRef) kDABadgeLayer_ValueFontName;
		_valueLayer.fontSize = kDABadgeLayer_ValueFontSize;
		_valueLayer.alignmentMode = kCAAlignmentCenter;
		[self addSublayer:_valueLayer];
		
		CGColorRelease(fillColor);
		CGColorRelease(textColor);
		CGColorSpaceRelease(colorSpace);
	}
	return self;
}


- (void)setContentsScale:(CGFloat)contentsScale
{
	[super setContentsScale:contentsScale];
	_valueLayer.contentsScale = self.contentsScale;
}


- (CGColorRef)valueColor
{
	return _valueLayer.foregroundColor;
}


- (void)setValueColor:(CGColorRef)valueColor
{
	_valueLayer.foregroundColor = valueColor;
}


+ (CGSize)pathSizeWithValue:(NSString*)value textSize:(CGSize*)ptextSize scale:(CGFloat)contentsScale
{
	CGSize baseTextSize = [CATextLayer sizeWithString:@"0" font:kDABadgeLayer_ValueFontName :kDABadgeLayer_ValueFontSize];
	CGSize textSize = value ? [CATextLayer sizeWithString:value font:kDABadgeLayer_ValueFontName :kDABadgeLayer_ValueFontSize] : baseTextSize;
	if (baseTextSize.height < textSize.height)
		baseTextSize.height = textSize.height;
	if (textSize.width < baseTextSize.width)
		textSize.width = baseTextSize.width;
	CGFloat d = sqrt(baseTextSize.height * baseTextSize.height + baseTextSize.width * baseTextSize.width);
	CGSize size = CGSizeMake(d, d);
	size.width += textSize.width - baseTextSize.width;
	if (ptextSize)
	{
		textSize.width = ceil(textSize.width * contentsScale) / contentsScale;
		textSize.height = ceil(textSize.height * contentsScale) / contentsScale;
		*ptextSize = textSize;
	}
	size.width += 2.;
	size.height += 2.;
	size.width = ceil(size.width * contentsScale) / contentsScale;
	size.height = ceil(size.height * contentsScale) / contentsScale;
	return size;
}


+ (CGRect)pathRectForValue:(NSString*)value layerBounds:(CGRect)layerBounds scale:(CGFloat)layerScale textRect:(CGRect*)ptextRect
{
	CGSize pathSize = [self pathSizeWithValue:value textSize:ptextRect ? &(ptextRect->size) : NULL scale:layerScale];
	CGRect pathRect = layerBounds;
	pathRect.size = pathSize;
	pathRect.origin.x += layerBounds.size.width - pathRect.size.width;
	if (ptextRect)
	{
		ptextRect->origin = pathRect.origin;
		ptextRect->origin.x += (pathRect.size.width - ptextRect->size.width) / 2;
		ptextRect->origin.y += (pathRect.size.height - ptextRect->size.height) / 2;
	}
	return pathRect;
}


+ (CGSize)preferredLayerSizeWithValue:(NSString*)value scale:(CGFloat)contentsScale
{
	return [self pathSizeWithValue:value textSize:NULL scale:contentsScale];
}


+ (CGPathRef)createPathInRect:(CGRect)rect empty:(BOOL)empty
{
	rect = CGRectInset(rect, 1., 1.);
	if (empty)
	{
		rect.origin.x += rect.size.width / 2;
		rect.origin.y += rect.size.height / 2;
		rect.size.width = rect.size.height = 0.;
	}
	CGFloat radius = MIN(rect.size.width, rect.size.height) / 2;
	return CGPathCreateWithRoundedRect(rect, radius, radius, NULL);
}


- (void)layoutSublayers
{
	[super layoutSublayers];
	
	CGRect textRect;
	CGRect pathRect = [DABadgeLayer pathRectForValue:_value layerBounds:self.bounds scale:self.contentsScale textRect:&textRect];
	CGPathRef path = [DABadgeLayer createPathInRect:pathRect empty:!self.value];
	self.path = path;
	CGPathRelease(path);
	_valueLayer.frame = textRect;
}


- (NSString*)value
{
	return _valueLayer.string;
}


- (void)setValue:(NSString *)value
{
	[self setValue:value animated:NO completion:nil];
}


- (void)setValue:(NSString *)value animated:(BOOL)animated completion:(void(^)(void))completion
{
	if (DA_COMPARE_STRINGS(value, _value))
	{
		if (completion)
			completion();
		return;
	}
	
	[self removeAllAnimations];
	[_valueLayer removeAllAnimations];
	
	_value = [value copy];

#define kDABadgeLayer_ValueAnimationDuration .25
	CGRect textRect;
	CGRect pathRect = [DABadgeLayer pathRectForValue:_value layerBounds:self.bounds scale:self.contentsScale textRect:&textRect];
	CGPathRef path = [DABadgeLayer createPathInRect:pathRect empty:!_value];
	if (animated)
	{
		CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
		pathAnimation.fromValue = (__bridge id) self.path;
		pathAnimation.toValue = (__bridge id) path;
		pathAnimation.duration = kDABadgeLayer_ValueAnimationDuration;
		pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
		if (completion)
		{
			pathAnimation.delegate = (id<CAAnimationDelegate>) self;
			[pathAnimation setValue:[completion copy] forKey:@"completion"];
		}
		[self addAnimation:pathAnimation forKey:@"path"];
		self.path = path;
		CABasicAnimation *frameAnimation = [CABasicAnimation animationWithKeyPath:@"frame"];
		pathAnimation.fromValue = [NSValue valueWithCGRect:_valueLayer.frame];
		pathAnimation.toValue = [NSValue valueWithCGRect:textRect];
		pathAnimation.duration = kDABadgeLayer_ValueAnimationDuration;
		pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
		[_valueLayer addAnimation:frameAnimation forKey:@"frame"];
		_valueLayer.frame = textRect;
		CATransition *valueTransition = [CATransition animation];
		valueTransition.type = kCATransitionFade;
		valueTransition.duration = kDABadgeLayer_ValueAnimationDuration;
		[_valueLayer addAnimation:valueTransition forKey:@"value"];
		_valueLayer.string = _value;
	}
	else
	{
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		[CATransaction setCompletionBlock:completion];
		self.path = path;
		_valueLayer.string = _value;
		_valueLayer.frame = textRect;
		[CATransaction commit];
	}
	CGPathRelease(path);
}


- (void)animationDidStop:(CABasicAnimation *)theAnimation finished:(BOOL)flag
{
	void (^completion)(void) = (void (^)(void))[theAnimation valueForKey:@"completion"];
	if (completion)
		completion();
}


@end



@implementation DABadgeView


#define _badgeLayer ((DABadgeLayer*) self.layer)


+ (Class)layerClass
{
	return [DABadgeLayer class];
}


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		self.userInteractionEnabled = NO;
		self.layer.contentsScale = UIScreenScale();
	}
	return self;
}


- (CGSize)sizeThatFits:(CGSize)size
{
	return [DABadgeView preferredViewSizeWithValue:self.value];
}


- (NSString*)value
{
	return _badgeLayer.value;
}


- (void)setValue:(NSString *)value
{
	[self setValue:value animated:NO completion:nil];
}


- (void)setValue:(NSString*)value animated:(BOOL)animated
{
	[self setValue:value animated:animated completion:nil];
}


- (void)setValue:(NSString*)value animated:(BOOL)animated completion:(void(^)(void))completion
{
	[_badgeLayer setValue:value animated:animated completion:completion];
}


+ (NSDictionary*)defaultDrawingAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[UIColor colorWithRGBAComponents:DABadgeLayer_FillColorComponents], NSBackgroundColorAttributeName,
			[UIColor colorWithRGBAComponents:DABadgeLayer_TextColorComponents], NSForegroundColorAttributeName,
			nil];
}


- (NSDictionary*)drawingAttributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:4];
	if (_badgeLayer.fillColor)
		[attributes setObject:[UIColor colorWithCGColor:_badgeLayer.fillColor] forKey:NSBackgroundColorAttributeName];
	if (_badgeLayer.valueColor)
		[attributes setObject:[UIColor colorWithCGColor:_badgeLayer.valueColor] forKey:NSForegroundColorAttributeName];
	if (_badgeLayer.strokeColor)
		[attributes setObject:[UIColor colorWithCGColor:_badgeLayer.strokeColor] forKey:NSStrokeColorAttributeName];
	if (_badgeLayer.lineWidth > 0.)
		[attributes setObject:[NSNumber numberWithCGFloat:_badgeLayer.lineWidth] forKey:NSStrokeWidthAttributeName];
	return attributes;
}


- (void)setDrawingAttributes:(NSDictionary *)drawingAttributes
{
	if (!drawingAttributes)
		drawingAttributes = [DABadgeView defaultDrawingAttributes];
	UIColor *backgroundColor = (UIColor*)[drawingAttributes objectForKey:NSBackgroundColorAttributeName];
	UIColor *foregroundColor = (UIColor*)[drawingAttributes objectForKey:NSForegroundColorAttributeName];
	UIColor *strokeColor = (UIColor*)[drawingAttributes objectForKey:NSStrokeColorAttributeName];
	NSNumber *strokeWidth = (NSNumber*)[drawingAttributes objectForKey:NSStrokeWidthAttributeName];
	_badgeLayer.fillColor = backgroundColor ? backgroundColor.CGColor : nil;
	_badgeLayer.valueColor = foregroundColor ? foregroundColor.CGColor : nil;
	_badgeLayer.strokeColor = strokeColor ? strokeColor.CGColor : nil;
	_badgeLayer.lineWidth = strokeWidth ? [strokeWidth CGFloatValue] : 0.;
}


+ (CGSize)preferredViewSizeWithValue:(NSString*)value
{
	return [DABadgeLayer preferredLayerSizeWithValue:value scale:UIScreenScale()];
}


+ (CGRect)preferredViewFrameWithValue:(NSString*)value forBounds:(CGRect)bounds
{
	CGSize baseViewSize = [self preferredViewSizeWithValue:nil];
	CGSize viewSize = value ? [self preferredViewSizeWithValue:value] : baseViewSize;
	CGRect frame = bounds;
	frame.size = viewSize;
	frame.origin.x += bounds.size.width - frame.size.width + baseViewSize.width / 2;
	frame.origin.y -= baseViewSize.height / 2;
	return frame;
}


@end
