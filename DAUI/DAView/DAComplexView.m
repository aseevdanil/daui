//
//  DAComplexView.m
//  daui
//
//  Created by da on 30.05.13.
//  Copyright (c) 2013 Aseev Danil. All rights reserved.
//

#import "DAComplexView.h"



@implementation DAComplexView


#pragma mark -
#pragma mark Base


static char DAComplexViewContext;


+ (Class)imageViewClass
{
	return [UIImageView class];
}


+ (Class)labelClass
{
	return [UILabel class];
}


+ (Class)sublabelClass
{
	return [UILabel class];
}


@synthesize accessoryView = _accessoryView;
@synthesize boundsInsets = _boundsInsets, labelOffset = _labelOffset, accessoryOffset = _accessoryOffset, accessoryAutoresizingSize = _accessoryAutoresizingSize, labelIndent = _labelindent, sublabelIndent = _sublabelIndent;


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.autoresizesSubviews = NO;
		
		_complexViewFlags.accessoryLayout = DAComplexViewAccessoryLayoutRightBoundsEdge;
		_complexViewFlags.accessoryAutoresizing = DAComplexViewAccessoryAutoresizingNone;
		_complexViewFlags.accessoryAlignment = DAComplexViewAccessoryAlignmentCenter;
		_complexViewFlags.imageViewVerticalAlignment = DAComplexViewImageViewVerticalAlignmentCenter;
		_complexViewFlags.imageViewBoundsTiedToImage = NO;
		_boundsInsets = UIEdgeInsetsZero;
		_labelOffset = CGSizeZero;
		_accessoryOffset = 0.;
		_accessoryAutoresizingSize = CGSizeZero;
		_labelIndent = _sublabelIndent = CGSizeZero;
	}
	return self;
}


- (void)dealloc
{
	if (_imageView)
	{
		[_imageView removeObserver:self forKeyPath:@"bounds" context:&DAComplexViewContext];
		[_imageView removeObserver:self forKeyPath:@"image" context:&DAComplexViewContext];
		_imageView = nil;
	}
	if (_label)
	{
		[_label removeObserver:self forKeyPath:@"text" context:&DAComplexViewContext];
		[_label removeObserver:self forKeyPath:@"attributedText" context:&DAComplexViewContext];
		[_label removeObserver:self forKeyPath:@"font" context:&DAComplexViewContext];
		[_label removeObserver:self forKeyPath:@"textAlignment" context:&DAComplexViewContext];
		[_label removeObserver:self forKeyPath:@"numberOfLines" context:&DAComplexViewContext];
		_label = nil;
	}
	if (_sublabel)
	{
		[_sublabel removeObserver:self forKeyPath:@"text" context:&DAComplexViewContext];
		[_sublabel removeObserver:self forKeyPath:@"attributedText" context:&DAComplexViewContext];
		[_sublabel removeObserver:self forKeyPath:@"font" context:&DAComplexViewContext];
		[_sublabel removeObserver:self forKeyPath:@"textAlignment" context:&DAComplexViewContext];
		[_sublabel removeObserver:self forKeyPath:@"numberOfLines" context:&DAComplexViewContext];
		_sublabel = nil;
	}
	if (_accessoryView)
	{
		[_accessoryView removeObserver:self forKeyPath:@"bounds" context:&DAComplexViewContext];
		if ([_accessoryView isKindOfClass:[UILabel class]])
		{
			[_accessoryView removeObserver:self forKeyPath:@"text" context:&DAComplexViewContext];
			[_accessoryView removeObserver:self forKeyPath:@"attributedText" context:&DAComplexViewContext];
			[_accessoryView removeObserver:self forKeyPath:@"font" context:&DAComplexViewContext];
			[_accessoryView removeObserver:self forKeyPath:@"numberOfLines" context:&DAComplexViewContext];
		}
		_accessoryView = nil;
	}
}


#pragma mark -
#pragma mark Content


- (UIImageView*)imageView
{
	if (!_imageView)
	{
		_imageView = [[[[self class] imageViewClass] alloc] init];
		[self addSubview:_imageView];
		[_imageView addObserver:self forKeyPath:@"bounds" options:0 context:&DAComplexViewContext];
		[_imageView addObserver:self forKeyPath:@"image" options:0 context:&DAComplexViewContext];
		[self setNeedsLayout];
	}
	return _imageView;
}


- (UILabel*)label
{
	if (!_label)
	{
		_label = [[[[self class] labelClass] alloc] init];
		_label.opaque = NO;
		_label.backgroundColor = [UIColor clearColor];
		[self addSubview:_label];
		[_label addObserver:self forKeyPath:@"text" options:0 context:&DAComplexViewContext];
		[_label addObserver:self forKeyPath:@"attributedText" options:0 context:&DAComplexViewContext];
		[_label addObserver:self forKeyPath:@"font" options:0 context:&DAComplexViewContext];
		[_label addObserver:self forKeyPath:@"textAlignment" options:0 context:&DAComplexViewContext];
		[_label addObserver:self forKeyPath:@"numberOfLines" options:0 context:&DAComplexViewContext];
		[self setNeedsLayout];
	}
	return _label;
}


- (UILabel*)sublabel
{
	if (!_sublabel)
	{
		_sublabel = [[[[self class] sublabelClass] alloc] init];
		_sublabel.opaque = NO;
		_sublabel.backgroundColor = [UIColor clearColor];
		[self addSubview:_sublabel];
		[_sublabel addObserver:self forKeyPath:@"text" options:0 context:&DAComplexViewContext];
		[_sublabel addObserver:self forKeyPath:@"attributedText" options:0 context:&DAComplexViewContext];
		[_sublabel addObserver:self forKeyPath:@"font" options:0 context:&DAComplexViewContext];
		[_sublabel addObserver:self forKeyPath:@"textAlignment" options:0 context:&DAComplexViewContext];
		[_sublabel addObserver:self forKeyPath:@"numberOfLines" options:0 context:&DAComplexViewContext];
		[self setNeedsLayout];
	}
	return _sublabel;
}


- (void)setAccessoryView:(UIView *)accessoryView
{
	if (accessoryView == _accessoryView)
		return;
	
	if (_accessoryView)
	{
		[_accessoryView removeObserver:self forKeyPath:@"bounds" context:&DAComplexViewContext];
		if ([_accessoryView isKindOfClass:[UILabel class]])
		{
			[_accessoryView removeObserver:self forKeyPath:@"text" context:&DAComplexViewContext];
			[_accessoryView removeObserver:self forKeyPath:@"attributedText" context:&DAComplexViewContext];
			[_accessoryView removeObserver:self forKeyPath:@"font" context:&DAComplexViewContext];
			[_accessoryView removeObserver:self forKeyPath:@"numberOfLines" context:&DAComplexViewContext];
		}
		[_accessoryView removeFromSuperview];
		_accessoryView = nil;
	}
	
	_accessoryView = accessoryView;
	if (_accessoryView)
	{
		[self addSubview:_accessoryView];
		[_accessoryView addObserver:self forKeyPath:@"bounds" options:0 context:&DAComplexViewContext];
		if ([_accessoryView isKindOfClass:[UILabel class]])
		{
			[_accessoryView addObserver:self forKeyPath:@"text" options:0 context:&DAComplexViewContext];
			[_accessoryView addObserver:self forKeyPath:@"attributedText" options:0 context:&DAComplexViewContext];
			[_accessoryView addObserver:self forKeyPath:@"font" options:0 context:&DAComplexViewContext];
			[_accessoryView addObserver:self forKeyPath:@"numberOfLines" options:0 context:&DAComplexViewContext];
		}
	}
	
	[self setNeedsLayout];
}


- (DAComplexViewAccessoryLayout)accessoryLayout
{
	return _complexViewFlags.accessoryLayout;
}


- (void)setAccessoryLayout:(DAComplexViewAccessoryLayout)accessoryLayout
{
	if (accessoryLayout == _complexViewFlags.accessoryLayout)
		return;
	
	_complexViewFlags.accessoryLayout = accessoryLayout;
	
	if (_accessoryView)
		[self setNeedsLayout];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &DAComplexViewContext)
	{
		if (object == _imageView)
		{
			if ([keyPath isEqualToString:@"bounds"])
			{
				[self setNeedsLayout];
			}
			else if ([keyPath isEqualToString:@"image"])
			{
				if (_complexViewFlags.imageViewBoundsTiedToImage)
				{
					_imageView.contentMode = UIViewContentModeCenter;
					CGRect imageViewBounds = CGRectZero;
					if (_imageView.image)
						imageViewBounds.size = _imageView.image.size;
					_imageView.bounds = imageViewBounds;
				}
			}
		}
		else if (object == _label || object == _sublabel)
		{
			if ([keyPath isEqualToString:@"text"] || [keyPath isEqualToString:@"attributedText"] || [keyPath isEqualToString:@"font"] || [keyPath isEqualToString:@"textAlignment"] || [keyPath isEqualToString:@"numberOfLines"])
				[self setNeedsLayout];
		}
		else if (object == _accessoryView)
		{
			if (_complexViewFlags.accessoryAutoresizing == DAComplexViewAccessoryAutoresizingNone)
			{
				if ([keyPath isEqualToString:@"bounds"])
					[self setNeedsLayout];
			}
			else
			{
				if ([keyPath isEqualToString:@"text"] || [keyPath isEqualToString:@"attributedText"] || [keyPath isEqualToString:@"font"] || [keyPath isEqualToString:@"numberOfLines"])
					[self setNeedsLayout];
			}
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


#pragma mark -
#pragma mark Layout


- (void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, _boundsInsets);
	CGSize accessoryViewSize = CGSizeZero;
	if (_accessoryView)
	{
		CGSize fitsSize = CGSizeZero;
		switch (_complexViewFlags.accessoryAutoresizing)
		{
			case DAComplexViewAccessoryAutoresizingFixibleSizeToFit:
				fitsSize = CGSizeEqualToSize(_accessoryAutoresizingSize, CGSizeZero) ? bounds.size : _accessoryAutoresizingSize;
				accessoryViewSize = [_accessoryView sizeThatFits:fitsSize];
				break;
			case DAComplexViewAccessoryAutoresizingFlexibleSizeToFit:
				fitsSize = CGSizeMake(bounds.size.width - _accessoryAutoresizingSize.width, bounds.size.height - _accessoryAutoresizingSize.height);
				accessoryViewSize = [_accessoryView sizeThatFits:fitsSize];
				break;
			case DAComplexViewAccessoryAutoresizingNone:
			default:
				fitsSize = _accessoryView.bounds.size;
				accessoryViewSize = fitsSize;
				break;
		}
		if (accessoryViewSize.width > fitsSize.width)
			accessoryViewSize.width = fitsSize.width;
		if (accessoryViewSize.height > fitsSize.height)
			accessoryViewSize.height = fitsSize.height;
	}
	
	if (_imageView)
	{
		CGRect imageViewFrame = bounds;
		imageViewFrame.size = _imageView.bounds.size;
		if (CGSizeEqualToSize(imageViewFrame.size, CGSizeZero))
		{
			_imageView.frame = CGRectZero;
		}
		else
		{
			switch (_complexViewFlags.imageViewVerticalAlignment)
			{
				
				case DAComplexViewImageViewVerticalAlignmentBottom:
					imageViewFrame.origin.y += bounds.size.height - imageViewFrame.size.height;
					break;
				case DAComplexViewImageViewVerticalAlignmentCenter:
					imageViewFrame.origin.y += (bounds.size.height - imageViewFrame.size.height) / 2;
					break;
				case DAComplexViewImageViewVerticalAlignmentTop:
				default:
					break;
			}
			_imageView.frame = imageViewFrame;
			bounds.origin.x += imageViewFrame.size.width + _labelOffset.width;
			bounds.size.width -= imageViewFrame.size.width + _labelOffset.width;
		}
	}
	
	if (_accessoryView && _complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutRightBoundsEdge)
	{
		CGRect accessoryViewFrame = bounds;
		accessoryViewFrame.size = accessoryViewSize;
		accessoryViewFrame.origin.x += bounds.size.width - accessoryViewFrame.size.width;
		switch (_complexViewFlags.accessoryAlignment)
		{
			case DAComplexViewAccessoryAlignmentCenter:
				accessoryViewFrame.origin.y += (bounds.size.height - accessoryViewFrame.size.height) / 2;
				break;
			case DAComplexViewAccessoryAlignmentBottomOrRight:
				accessoryViewFrame.origin.y += bounds.size.height - accessoryViewFrame.size.height;
				break;
			case DAComplexViewAccessoryAlignmentTopOrLeft:
			default:
				break;
		}
		_accessoryView.frame = accessoryViewFrame;
		bounds.size.width -= accessoryViewFrame.size.width + (accessoryViewFrame.size.width > 0. ? _accessoryOffset : 0.);
	}
	
	CGFloat additionalAccessoryHeight = 0.;
	BOOL labelNotEmpty = _label && _label.text && [_label.text length] > 0;
	BOOL sublabelNotEmpty = _sublabel && _sublabel.text && [_sublabel.text length] > 0;
	BOOL accessoryToLabel = _accessoryView && (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToRightOfLabel || _complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToBottomOfLabel);
	BOOL accessoryToSublabel = _accessoryView && (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToTopOfSublabel);
	if (_label || accessoryToLabel)
	{
		CGSize titleLabelSize = bounds.size;
		if (accessoryToLabel)
		{
			if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToRightOfLabel)
				titleLabelSize.width -= accessoryViewSize.width + (labelNotEmpty ? _accessoryOffset : 0.);
			else if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToBottomOfLabel)
				additionalAccessoryHeight = accessoryViewSize.height + (labelNotEmpty ? _accessoryOffset : 0.);
		}
		CGFloat maxTitleLabelWidth = titleLabelSize.width;
		titleLabelSize = labelNotEmpty ? [_label sizeThatFits:titleLabelSize] : CGSizeZero;
		if (titleLabelSize.width > maxTitleLabelWidth)
			titleLabelSize.width = maxTitleLabelWidth;
		
		CGRect titleAreaFrame = bounds;
		titleAreaFrame.size = titleLabelSize;
		if (accessoryToLabel)
		{
			if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToRightOfLabel)
			{
				titleAreaFrame.size.width += accessoryViewSize.width + (labelNotEmpty ? _accessoryOffset : 0.);
				if (titleAreaFrame.size.height < accessoryViewSize.height)
					titleAreaFrame.size.height = accessoryViewSize.height;
			}
			else if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToBottomOfLabel)
			{
				titleAreaFrame.size.height += additionalAccessoryHeight;
				if (titleAreaFrame.size.width < accessoryViewSize.width)
					titleAreaFrame.size.width = accessoryViewSize.width;
			}
		}
		if (_label)
		{
			switch (_label.textAlignment)
			{
				case NSTextAlignmentCenter:
					titleAreaFrame.origin.x += (bounds.size.width - titleAreaFrame.size.width) / 2;
					break;
				case NSTextAlignmentRight:
					titleAreaFrame.origin.x += bounds.size.width - titleAreaFrame.size.width;
				default:
					break;
			}
		}
		titleAreaFrame.origin.y += bounds.size.height / 2 - (sublabelNotEmpty || accessoryToSublabel ? (titleAreaFrame.size.height - (labelNotEmpty ? _label.font.lineHeight - _label.font.ascender : 0.) - (accessoryToLabel ? additionalAccessoryHeight / 2 : 0.)) : (titleAreaFrame.size.height / 2));
		titleAreaFrame.origin.x += _labelIndent.width;
		titleAreaFrame.origin.y += _labelIndent.height;
		
		CGRect titleLabelFrame = titleAreaFrame;
		titleLabelFrame.size = titleLabelSize;
		if (accessoryToLabel)
		{
			CGRect accessoryViewFrame = titleAreaFrame;
			accessoryViewFrame.size = accessoryViewSize;
			if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToRightOfLabel)
			{
				switch (_complexViewFlags.accessoryAlignment)
				{
					case DAComplexViewAccessoryAlignmentCenter:
						titleLabelFrame.origin.y += (titleAreaFrame.size.height - titleLabelFrame.size.height) / 2;
						accessoryViewFrame.origin.y += (titleAreaFrame.size.height - accessoryViewFrame.size.height) / 2;
						break;
					case DAComplexViewAccessoryAlignmentBottomOrRight:
						titleLabelFrame.origin.y += titleAreaFrame.size.height - titleLabelFrame.size.height;
						accessoryViewFrame.origin.y += titleAreaFrame.size.height - accessoryViewFrame.size.height;
						break;
					case DAComplexViewAccessoryAlignmentTopOrLeft:
					default:
						break;
				}
				accessoryViewFrame.origin.x += titleAreaFrame.size.width - accessoryViewFrame.size.width;
			}
			else if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToBottomOfLabel)
			{
				accessoryViewFrame.origin.y += titleAreaFrame.size.height - accessoryViewFrame.size.height;
				switch (_complexViewFlags.accessoryAlignment)
				{
					case DAComplexViewAccessoryAlignmentCenter:
						accessoryViewFrame.origin.x += (titleAreaFrame.size.width - accessoryViewFrame.size.width) / 2;
						break;
					case DAComplexViewAccessoryAlignmentBottomOrRight:
						accessoryViewFrame.origin.x += titleAreaFrame.size.width - accessoryViewFrame.size.width;
						break;
					case DAComplexViewAccessoryAlignmentTopOrLeft:
					default:
						break;
				}
				if (_label)
				{
					switch (_label.textAlignment)
					{
						case NSTextAlignmentCenter:
							titleLabelFrame.origin.x += (titleAreaFrame.size.width - titleLabelFrame.size.width) / 2;
							break;
						case NSTextAlignmentRight:
							titleLabelFrame.origin.x += titleAreaFrame.size.width - titleLabelFrame.size.width;
							break;
						default:
							break;
					}
				}
			}
			_accessoryView.frame = accessoryViewFrame;
		}
		if (_label)
			_label.frame = titleLabelFrame;
	}
	
	if (_sublabel || accessoryToSublabel)
	{
		CGSize sublabelSize = bounds.size;
		if (accessoryToSublabel)
		{
			if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToTopOfSublabel)
				additionalAccessoryHeight = accessoryViewSize.height + (sublabelNotEmpty ? _accessoryOffset : 0.);
		}
		CGFloat maxSublabelWidth = sublabelSize.width;
		sublabelSize = sublabelNotEmpty ? [_sublabel sizeThatFits:sublabelSize] : CGSizeZero;
		if (sublabelSize.width > maxSublabelWidth)
			sublabelSize.width = maxSublabelWidth;
		
		CGRect sublabelAreaFrame = bounds;
		sublabelAreaFrame.size = sublabelSize;
		if (accessoryToSublabel)
		{
			if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToTopOfSublabel)
			{
				sublabelAreaFrame.size.height += additionalAccessoryHeight;
				if (sublabelAreaFrame.size.width < accessoryViewSize.width)
					sublabelAreaFrame.size.width = accessoryViewSize.width;
			}
		}
		if (_sublabel)
		{
			switch (_sublabel.textAlignment)
			{
				case NSTextAlignmentCenter:
					sublabelAreaFrame.origin.x += (bounds.size.width - sublabelAreaFrame.size.width) / 2;
					break;
				case NSTextAlignmentRight:
					sublabelAreaFrame.origin.x += bounds.size.width - sublabelAreaFrame.size.width;
				default:
					break;
			}
		}
		sublabelAreaFrame.origin.y += bounds.size.height / 2 + (labelNotEmpty || accessoryToLabel ? ((labelNotEmpty ? _label.font.lineHeight - _label.font.ascender : 0.) + (accessoryToLabel ? additionalAccessoryHeight / 2 : 0.) + _labelOffset.height) : (-sublabelAreaFrame.size.height / 2));
		sublabelAreaFrame.origin.x += _sublabelIndent.width;
		sublabelAreaFrame.origin.y += _sublabelIndent.height;
		
		CGRect sublabelFrame = sublabelAreaFrame;
		sublabelFrame.size = sublabelSize;
		if (accessoryToSublabel)
		{
			CGRect accessoryViewFrame = sublabelAreaFrame;
			accessoryViewFrame.size = accessoryViewSize;
			if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToTopOfSublabel)
			{
				switch (_complexViewFlags.accessoryAlignment)
				{
					case DAComplexViewAccessoryAlignmentCenter:
						accessoryViewFrame.origin.x += (sublabelAreaFrame.size.width - accessoryViewFrame.size.width) / 2;
						break;
					case DAComplexViewAccessoryAlignmentBottomOrRight:
						accessoryViewFrame.origin.x += sublabelAreaFrame.size.width - accessoryViewFrame.size.width;
						break;
					case DAComplexViewAccessoryAlignmentTopOrLeft:
					default:
						break;
				}
				if (_sublabel)
				{
					sublabelFrame.origin.y += sublabelAreaFrame.size.height - sublabelFrame.size.height;
					switch (_sublabel.textAlignment)
					{
						case NSTextAlignmentCenter:
							sublabelFrame.origin.x += (sublabelAreaFrame.size.width - sublabelFrame.size.width) / 2;
							break;
						case NSTextAlignmentRight:
							sublabelFrame.origin.x += sublabelAreaFrame.size.width - sublabelFrame.size.width;
							break;
						default:
							break;
					}
				}
			}
			_accessoryView.frame = accessoryViewFrame;
		}
		if (_sublabel)
			_sublabel.frame = sublabelFrame;
	}
}


- (CGSize)sizeThatFits:(CGSize)size
{
	CGSize imageViewSize = _imageView ? _imageView.bounds.size : CGSizeZero;
	CGSize labelsAreaSize = size;
	labelsAreaSize.width -= _boundsInsets.left + _boundsInsets.right;
	labelsAreaSize.height -= _boundsInsets.top + _boundsInsets.bottom;
	CGSize accessoryViewSize = CGSizeZero;
	if (_accessoryView)
	{
		CGSize fitsSize = CGSizeZero;
		switch (_complexViewFlags.accessoryAutoresizing)
		{
			case DAComplexViewAccessoryAutoresizingFixibleSizeToFit:
				fitsSize = CGSizeEqualToSize(_accessoryAutoresizingSize, CGSizeZero) ? labelsAreaSize : _accessoryAutoresizingSize;
				accessoryViewSize = [_accessoryView sizeThatFits:fitsSize];
				break;
			case DAComplexViewAccessoryAutoresizingFlexibleSizeToFit:
				fitsSize = CGSizeMake(labelsAreaSize.width - _accessoryAutoresizingSize.width, labelsAreaSize.height - _accessoryAutoresizingSize.height);
				accessoryViewSize = [_accessoryView sizeThatFits:fitsSize];
				break;
			case DAComplexViewAccessoryAutoresizingNone:
			default:
				fitsSize = _accessoryView.bounds.size;
				accessoryViewSize = fitsSize;
				break;
		}
		if (accessoryViewSize.width > fitsSize.width)
			accessoryViewSize.width = fitsSize.width;
		if (accessoryViewSize.height > fitsSize.height)
			accessoryViewSize.height = fitsSize.height;
	}
	if (!CGSizeEqualToSize(imageViewSize, CGSizeZero))
		labelsAreaSize.width -= imageViewSize.width + _labelOffset.width;
	if (!CGSizeEqualToSize(accessoryViewSize, CGSizeZero) && _complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutRightBoundsEdge)
		labelsAreaSize.width -= accessoryViewSize.width + _accessoryOffset;
	CGSize titleLabelSize = CGSizeZero, subtitleLabelSize = CGSizeZero;
	BOOL labelNotEmpty = _label && _label.text && [_label.text length] > 0;
	BOOL sublabelNotEmpty = _sublabel && _sublabel.text && [_sublabel.text length] > 0;
	BOOL accessoryToLabel = _accessoryView && (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToRightOfLabel || _complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToBottomOfLabel);
	BOOL accessoryToSublabel = _accessoryView && (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToTopOfSublabel);
	CGFloat additionalAccessoryHeight = 0.;
	if (labelNotEmpty || accessoryToLabel)
	{
		titleLabelSize = labelsAreaSize;
		if (accessoryToLabel)
		{
			if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToRightOfLabel)
			{
				titleLabelSize.width -= accessoryViewSize.width + (labelNotEmpty ? _accessoryOffset : 0.);
			}
			//else if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToBottomOfLabel)
			//{
			//}
		}
		titleLabelSize = labelNotEmpty ? [_label sizeThatFits:titleLabelSize] : CGSizeZero;
		if (accessoryToLabel)
		{
			if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToRightOfLabel)
			{
				titleLabelSize.width += accessoryViewSize.width + (labelNotEmpty ? _accessoryOffset : 0.);
				if (titleLabelSize.height < accessoryViewSize.height)
					titleLabelSize.height = accessoryViewSize.height;
			}
			else if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToBottomOfLabel)
			{
				if (titleLabelSize.width < accessoryViewSize.width)
					titleLabelSize.width = accessoryViewSize.width;
				titleLabelSize.height += (labelNotEmpty ? _accessoryOffset : 0.) + accessoryViewSize.height;
				additionalAccessoryHeight += (labelNotEmpty ? _accessoryOffset : 0.) + accessoryViewSize.height;
			}
		}
		if (sublabelNotEmpty || accessoryToSublabel)
		{
			if (labelNotEmpty)
				titleLabelSize.height -= _label.font.lineHeight - _label.font.ascender;
			if (accessoryToLabel)
				titleLabelSize.height -= additionalAccessoryHeight / 2;
		}
	}
	if (sublabelNotEmpty || accessoryToSublabel)
	{
		subtitleLabelSize = labelsAreaSize;
		//if (accessoryToSublabel)
		//{
		//	if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToTopOfSublabel)
		//	{
		//	}
		//}
		subtitleLabelSize = sublabelNotEmpty ? [_sublabel sizeThatFits:subtitleLabelSize] : CGSizeZero;
		if (accessoryToSublabel)
		{
			if (_complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutToTopOfSublabel)
			{
				if (subtitleLabelSize.width < accessoryViewSize.width)
					subtitleLabelSize.width = accessoryViewSize.width;
				subtitleLabelSize.height += accessoryViewSize.height;
			}
		}
		if (labelNotEmpty || accessoryToLabel)
		{
			subtitleLabelSize.height += _labelOffset.height;
			if (labelNotEmpty)
				subtitleLabelSize.height += _label.font.lineHeight - _label.font.ascender;
			if (accessoryToLabel)
				subtitleLabelSize.height += additionalAccessoryHeight / 2;
		}
	}
	labelsAreaSize.width = MAX(titleLabelSize.width, subtitleLabelSize.width);
	labelsAreaSize.height = MAX(titleLabelSize.height, subtitleLabelSize.height);
	if (titleLabelSize.height > 0. && subtitleLabelSize.height > 0.)
		labelsAreaSize.height *= 2;

	CGSize contentSize = labelsAreaSize;
	if (!CGSizeEqualToSize(imageViewSize, CGSizeZero))
	{
		contentSize.width += imageViewSize.width + _labelOffset.width;
		if (contentSize.height < imageViewSize.height)
			contentSize.height = imageViewSize.height;
	}
	if (!CGSizeEqualToSize(accessoryViewSize, CGSizeZero) && _complexViewFlags.accessoryLayout == DAComplexViewAccessoryLayoutRightBoundsEdge)
	{
		contentSize.width += accessoryViewSize.width + _accessoryOffset;
		if (contentSize.height < accessoryViewSize.height)
			contentSize.height = accessoryViewSize.height;
	}
	if (!CGSizeEqualToSize(contentSize, CGSizeZero))
	{
		contentSize.width += _boundsInsets.left + _boundsInsets.right;
		contentSize.height += _boundsInsets.top + _boundsInsets.bottom;
	}
	if (contentSize.width < size.width)
		size.width = contentSize.width;
	if (contentSize.height < size.height)
		size.height = contentSize.height;
	return size;
}


- (void)setBoundsInsets:(UIEdgeInsets)boundsInsets
{
	if (UIEdgeInsetsEqualToEdgeInsets(boundsInsets, _boundsInsets))
		return;
	
	_boundsInsets = boundsInsets;
	
	[self setNeedsLayout];
}


- (void)setLabelOffset:(CGSize)labelOffset
{
	if (CGSizeEqualToSize(labelOffset, _labelOffset))
		return;
	
	_labelOffset = labelOffset;
	
	[self setNeedsLayout];
}


- (void)setAccessoryOffset:(CGFloat)accessoryOffset
{
	if (accessoryOffset == _accessoryOffset)
		return;
	
	_accessoryOffset = accessoryOffset;
	
	[self setNeedsLayout];
}


- (DAComplexViewAccessoryAutoresizing)accessoryAutoresizing
{
	return _complexViewFlags.accessoryAutoresizing;
}


- (void)setAccessoryAutoresizing:(DAComplexViewAccessoryAutoresizing)accessoryAutoresizing
{
	if (accessoryAutoresizing == _complexViewFlags.accessoryAutoresizing)
		return;
	
	_complexViewFlags.accessoryAutoresizing = accessoryAutoresizing;
	
	[self setNeedsLayout];
}


- (void)setAccessoryAutoresizingSize:(CGSize)accessoryAutoresizingSize
{
	if (CGSizeEqualToSize(accessoryAutoresizingSize, _accessoryAutoresizingSize))
		return;
	
	_accessoryAutoresizingSize = accessoryAutoresizingSize;
	
	[self setNeedsLayout];
}


- (DAComplexViewAccessoryAlignment)accessoryAlignment
{
	return _complexViewFlags.accessoryAlignment;
}


- (void)setAccessoryAlignment:(DAComplexViewAccessoryAlignment)accessoryAlignment
{
	if (accessoryAlignment == _complexViewFlags.accessoryAlignment)
		return;
	
	_complexViewFlags.accessoryAlignment = accessoryAlignment;
	
	[self setNeedsLayout];
}


- (void)setLabelIndent:(CGSize)labelIndent
{
	if (CGSizeEqualToSize(labelIndent, _labelIndent))
		return;
	
	_labelIndent = labelIndent;
	
	[self setNeedsLayout];
}


- (void)setSublabelIndent:(CGSize)sublabelIndent
{
	if (CGSizeEqualToSize(sublabelIndent, _sublabelIndent))
		return;
	
	_sublabelIndent = sublabelIndent;
	
	[self setNeedsLayout];
}


- (BOOL)isImageViewBoundsTiedToImage
{
	return _complexViewFlags.imageViewBoundsTiedToImage;
}


- (void)setImageViewBoundsTiedToImage:(BOOL)imageViewBoundsTiedToImage
{
	_complexViewFlags.imageViewBoundsTiedToImage = imageViewBoundsTiedToImage;
}


- (DAComplexViewImageViewVerticalAlignment)imageViewVerticalAlignment
{
	return _complexViewFlags.imageViewVerticalAlignment;
}


- (void)setImageViewVerticalAlignment:(DAComplexViewImageViewVerticalAlignment)imageViewVerticalAlignment
{
	if (imageViewVerticalAlignment == _complexViewFlags.imageViewVerticalAlignment)
		return;
	
	_complexViewFlags.imageViewVerticalAlignment = imageViewVerticalAlignment;
	
	[self setNeedsLayout];
}


@end
