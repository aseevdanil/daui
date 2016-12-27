//
//  DATextView.m
//  daui
//
//  Created by da on 03.02.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DATextView.h"



@interface DATextView ()
{
	UILabel *_placeholderLabel;
	
	NSUInteger _minimumDynamicNumberOfLines;
	NSUInteger _maximumDynamicNumberOfLines;
	CGFloat _dynamicHeight;
	
	unsigned int _needCheckDynamicHeight : 1;
	unsigned int _contentOffsetChanging : 1;
}

- (void)scrollToCaret:(BOOL)animated;

- (void)setNeedsCheckDynamicHeight;
- (void)checkDynamicHeight;
- (CGFloat)dynamicHeightForContentHeight:(CGFloat)contentHeight;

@end


@implementation DATextView


#pragma mark -
#pragma mark Base


static char DATextViewContext;


@synthesize minimumDynamicNumberOfLines = _minimumDynamicNumberOfLines, maximumDynamicNumberOfLines = _maximumDynamicNumberOfLines, dynamicHeight = _dynamicHeight;


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		_needCheckDynamicHeight = _contentOffsetChanging = NO;
		_minimumDynamicNumberOfLines = 1;
		_maximumDynamicNumberOfLines = 1;
		_dynamicHeight = [self dynamicHeightForContentHeight:0.];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_DATextView_textViewTextDidChange:) name:UITextViewTextDidChangeNotification object:self];
		[self addObserver:self forKeyPath:@"contentOffset" options:0 context:&DATextViewContext];
	}
	return self;
}


- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"contentOffset" context:&DATextViewContext];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &DATextViewContext)
	{
		if (object == self)
		{
			if ([keyPath isEqualToString:@"contentOffset"])
			{
				if (!_contentOffsetChanging)
				{
					CGRect textRect = [self.layoutManager usedRectForTextContainer:self.textContainer];
					UIEdgeInsets textInset = self.textContainerInset;
					CGFloat contentHeight = textRect.size.height + textInset.top + textInset.bottom;
					CGRect viewFrame = self.frame;
					UIEdgeInsets contentInset = self.contentInset;
					CGFloat viewHeight = viewFrame.size.height - (contentInset.top + contentInset.bottom);
					if (contentHeight <= viewHeight)
					{
						_contentOffsetChanging = YES;
						[self setContentOffset:CGPointZero animated:NO];
						_contentOffsetChanging = NO;
					}
				}
			}
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (void)setNeedsCheckDynamicHeight
{
	if (!_needCheckDynamicHeight)
	{
		_needCheckDynamicHeight = YES;
		[self setNeedsLayout];
	}
}


- (void)layoutSubviews
{
	[super layoutSubviews];
	if (_needCheckDynamicHeight)
	{
		_needCheckDynamicHeight = NO;
		[self checkDynamicHeight];
	}
	if (_placeholderLabel)
	{
		UIEdgeInsets placeholderInsets = self.textContainerInset;
		placeholderInsets.left += 8.;
		placeholderInsets.right += 8.;
		CGRect placeholderLabelFrame = UIEdgeInsetsInsetRect(self.bounds, placeholderInsets);
		placeholderLabelFrame.size.height = [_placeholderLabel sizeThatFits:placeholderLabelFrame.size].height;
		_placeholderLabel.frame = placeholderLabelFrame;
	}
}


- (void)_DATextView_textViewTextDidChange:(NSNotification*)notification
{
	//[self checkDynamicHeight];
	[self textDidChange];
}


- (void)textDidChange
{
	if (_placeholderLabel)
		_placeholderLabel.hidden = self.text.length > 0;
}


- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	[self scrollToCaret:YES];
}


- (void)setContentSize:(CGSize)contentSize
{
	[super setContentSize:contentSize];
	[self setNeedsCheckDynamicHeight];
}


- (void)scrollToCaret:(BOOL)animated
{
	UITextRange *selectedRange = self.selectedTextRange;
	UITextPosition *caretPosition = selectedRange ? selectedRange.end : self.endOfDocument;
	CGRect caretRect = caretPosition ? [self caretRectForPosition:caretPosition] : CGRectZero;
	CGPoint caretPoint = CGRectGetCenter(caretRect);
	CGFloat viewHeight = self.frame.size.height;
	CGPoint contentOffset = self.contentOffset;
	contentOffset.y = caretPoint.y - viewHeight / 2;
	CGRect textRect = [self.layoutManager usedRectForTextContainer:self.textContainer];
	UIEdgeInsets textInset = self.textContainerInset;
	CGFloat contentHeight = textRect.size.height + textInset.top + textInset.bottom;
	if (contentOffset.y < 0.)
		contentOffset.y = 0.;
	else if (contentOffset.y > contentHeight - viewHeight)
		contentOffset.y = contentHeight - viewHeight;
	[self setContentOffset:contentOffset animated:animated];
}


#pragma mark -
#pragma mark Properties


- (void)setFont:(UIFont*)font
{
	[super setFont:font];
	//[self checkDynamicHeight];
	
	if (_placeholderLabel)
	{
		_placeholderLabel.font = self.font;
		[self setNeedsLayout];
	}
}


- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
	[super setTextAlignment:textAlignment];
	
	if (_placeholderLabel)
		_placeholderLabel.textAlignment = self.textAlignment;
}


- (void)setTextColor:(UIColor *)textColor
{
	[super setTextColor:textColor];
	
	if (_placeholderLabel)
		_placeholderLabel.textColor = [self.textColor colorWithAlphaComponent:.7];
}


- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset
{
	[super setTextContainerInset:textContainerInset];
	//[self checkDynamicHeight];

	if (_placeholderLabel)
		[self setNeedsLayout];
}


#pragma mark -
#pragma mark Placeholder


- (UILabel*)placeholderLabel
{
	if (!_placeholderLabel)
	{
		_placeholderLabel = [[UILabel alloc] init];
		_placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_placeholderLabel.opaque = NO;
		_placeholderLabel.backgroundColor = [UIColor clearColor];
		_placeholderLabel.font = self.font;
		_placeholderLabel.textAlignment = self.textAlignment;
		_placeholderLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		_placeholderLabel.textColor = [self.textColor colorWithAlphaComponent:.5];
		_placeholderLabel.hidden = [self.text length] > 0;
		[self addSubview:_placeholderLabel];
		[self setNeedsLayout];
	}
	return _placeholderLabel;
}


- (NSString*)placeholder
{
	return self.placeholderLabel.text;
}


- (void)setPlaceholder:(NSString*)placeholder
{
	self.placeholderLabel.text = placeholder;
	[self setNeedsLayout];
}


- (NSAttributedString*)attributedPlaceholder
{
	return self.placeholderLabel.attributedText;
}


- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
	self.placeholderLabel.attributedText = attributedPlaceholder;
	[self setNeedsLayout];
}


- (void)setText:(NSString *)text
{
	[super setText:text];
	//[self checkDynamicHeight];
	
	if (_placeholderLabel)
		_placeholderLabel.hidden = self.text.length > 0;
}


#pragma mark -
#pragma mark Dynamic Height


- (void)checkDynamicHeight
{
	CGRect textRect = [self.layoutManager usedRectForTextContainer:self.textContainer];
	UIEdgeInsets textInset = self.textContainerInset;
	CGFloat contentHeight = textRect.size.height + textInset.top + textInset.bottom;
	CGFloat dynamicHeight = [self dynamicHeightForContentHeight:contentHeight];
	if (_dynamicHeight != dynamicHeight)
	{
		[self willChangeValueForKey:@"dynamicHeight"];
		_dynamicHeight = dynamicHeight;
		[self didChangeValueForKey:@"dynamicHeight"];
	}
}


- (void)setMinimumDynamicNumberOfLines:(NSUInteger)minimumDynamicNumberOfLines
{
	if (minimumDynamicNumberOfLines == _minimumDynamicNumberOfLines)
		return;
	
	_minimumDynamicNumberOfLines = minimumDynamicNumberOfLines;
	[self checkDynamicHeight];
}


- (void)setMaximumDynamicNumberOfLines:(NSUInteger)maximumDynamicNumberOfLines
{
	if (maximumDynamicNumberOfLines == _maximumDynamicNumberOfLines)
		return;
	
	_maximumDynamicNumberOfLines = maximumDynamicNumberOfLines;
	[self checkDynamicHeight];
}


- (CGFloat)dynamicHeightForContentHeight:(CGFloat)contentHeight
{
	CGFloat minHeight = [UITextView heightForNumberOfLines:_minimumDynamicNumberOfLines font:self.font textContainerInset:self.textContainerInset];
	CGFloat maxHeight = [UITextView heightForNumberOfLines:_maximumDynamicNumberOfLines font:self.font textContainerInset:self.textContainerInset];
	if (_minimumDynamicNumberOfLines > 0 && contentHeight < minHeight)
		contentHeight = minHeight;
	else if (_maximumDynamicNumberOfLines > 0 && contentHeight > maxHeight)
		contentHeight = maxHeight;
	return contentHeight;
}


@end
