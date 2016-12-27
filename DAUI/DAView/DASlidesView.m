//
//  DASlidesView.m
//  daui
//
//  Created by da on 22.05.12.
//  Copyright (c) 2012 Aseev Danil. All rights reserved.
//

#import "DASlidesView.h"



@interface DASlidesView () <UIScrollViewDelegate>

- (void)applyUpdates;
- (void)refreshSlidesViews;
- (void)loadSlideAtIndex:(NSUInteger)index;
- (void)unloadSlideAtIndex:(NSUInteger)index;

- (void)layoutSlides;
- (CGRect)calculateFrameOfSlideAtIndex:(NSUInteger)index;

@end


@implementation DASlidesView


#pragma mark -
#pragma mark Base


@synthesize currentSlideIndex = _currentSlideIndex;
@synthesize reusableSlidesCount = _reusableSlidesCount, numberOfPreloadedNeighborsSlides = _numberOfPreloadedNeighborsSlides;
@synthesize scrollView = _scrollView, backgroundView = _backgroundView;
@synthesize slidesViewDelegate = _slidesViewDelegate, slidesViewDataSource = _slidesViewDataSource;


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		_slidesViewFlags.batchUpdates = NO;
		_slidesViewFlags.selfScrolling = NO;
		self.autoresizesSubviews = NO;
		
		_scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
		_scrollView.autoresizesSubviews = NO;
		_scrollView.opaque = NO;
		_scrollView.backgroundColor = [UIColor clearColor];
		
		_scrollView.pagingEnabled = YES;
		_scrollView.scrollEnabled = YES;
		_scrollView.showsHorizontalScrollIndicator = NO;
		_scrollView.showsVerticalScrollIndicator = NO;
		_scrollView.bounces = YES;
		_scrollView.alwaysBounceHorizontal = YES;
		_scrollView.alwaysBounceVertical = NO;
		_scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
		_scrollView.contentSize = CGSizeMake(0., _scrollView.frame.size.height);
		_scrollView.delegate = self;
		[self addSubview:_scrollView];
		
		_slides = [[NSMutableArray alloc] init];
		_currentSlideIndex = NSNotFound;
		_reusableSlides = [[NSMutableSet alloc] init];
		_reusableSlidesCount = 1;
		_numberOfPreloadedNeighborsSlides = 0;
		_slidesViewFlags.updatesReloadData = NO;
		_updatesReloadSlidesIndexes = [[NSMutableIndexSet alloc] init];
		_updatesDeleteSlidesIndexes = [[NSMutableIndexSet alloc] init];
		_updatesInsertSlidesIndexes = [[NSMutableIndexSet alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DASlidesView_ClearNotification:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(DASlidesView_ClearNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
	return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}


- (void)DASlidesView_ClearNotification:(NSNotification*)notification
{
	[_reusableSlides removeAllObjects];
}


- (void)layoutSubviews
{
	[super layoutSubviews];
	_scrollView.frame = self.bounds;
	[self layoutSlides];
}


#pragma mark -
#pragma mark Slides


- (NSUInteger)numberOfSlides
{
	return [_slides count];
}


- (UIView*)slideAtIndex:(NSUInteger)index
{
	if (index == NSNotFound)
		return nil;
	
	DASSERT(index < [_slides count]);
	id slideView = [_slides objectAtIndex:index];
	return slideView == [NSNull null] ? nil : (UIView*) slideView;
}


- (void)setCurrentSlideIndex:(NSUInteger)index
{
	[self setCurrentSlideIndex:index animated:NO];
}


- (void)setCurrentSlideIndex:(NSUInteger)index animated:(BOOL)animated
{
	if (index == _currentSlideIndex)
		return;
	
	_currentSlideIndex = index;
	
	if (!_slidesViewFlags.batchUpdates)
	{
		DASSERT(_currentSlideIndex == NSNotFound || _currentSlideIndex < [_slides count]);
		_slidesViewFlags.selfScrolling = YES;
		[_scrollView setContentOffset:CGPointMake(_currentSlideIndex == NSNotFound ? -self.frame.size.width : _currentSlideIndex * self.frame.size.width, 0.) animated:animated];
		_slidesViewFlags.selfScrolling = NO;
		[self refreshSlidesViews];
	}
}


- (UIView*)dequeueReusableSlideWithIdentifier:(NSString*)identifier
{
	if (!identifier)
		return nil;
	
	for (UIView *s in _reusableSlides)
	{
		if ([identifier isEqualToString:s.slideReuseIdentifier])
		{
			UIView *slide = s;
			[_reusableSlides removeObject:s];
			return slide;
		}
	}
	return nil;
}


- (void)setReusableSlidesCount:(NSUInteger)reusableSlidesCount
{
	_reusableSlidesCount = reusableSlidesCount;
	[_reusableSlides removeAllObjects];
}


#pragma mark -
#pragma mark Update Slides


- (void)reloadData
{
	_slidesViewFlags.updatesReloadData = YES;
	
	if (!_slidesViewFlags.batchUpdates)
		[self applyUpdates];
}


- (void)reloadSlidesAtIndexes:(NSIndexSet*)indexes
{
	[_updatesReloadSlidesIndexes addIndexes:indexes];
	
	if (!_slidesViewFlags.batchUpdates)
		[self applyUpdates];
}


- (void)deleteSlidesAtIndexes:(NSIndexSet*)indexes
{
	[_updatesDeleteSlidesIndexes addIndexes:indexes];
	
	if (!_slidesViewFlags.batchUpdates)
		[self applyUpdates];
}


- (void)insertSlidesAtIndexes:(NSIndexSet*)indexes
{
	[_updatesInsertSlidesIndexes addIndexes:indexes];

	if (!_slidesViewFlags.batchUpdates)
		[self applyUpdates];
}


- (void)beginUpdates
{
	DASSERT(!_slidesViewFlags.batchUpdates);
	if (_slidesViewFlags.batchUpdates)
		return;
	
	_slidesViewFlags.batchUpdates = YES;
}


- (void)endUpdates
{
	DASSERT(_slidesViewFlags.batchUpdates);
	if (!_slidesViewFlags.batchUpdates)
		return;
		
	_slidesViewFlags.batchUpdates = NO;
	
	[self applyUpdates];
}


- (void)applyUpdates
{
	DASSERT(!_slidesViewFlags.batchUpdates);
	NSUInteger currentSlideIndex = _currentSlideIndex;
	if (_slidesViewFlags.updatesReloadData)
	{
		id <DASlidesViewDataSource> strongDataSource = _slidesViewDataSource;
		NSUInteger numberOfSlides = strongDataSource ? [strongDataSource slidesViewNumberOfSlides:self] : 0;
		if (numberOfSlides == 0)
			currentSlideIndex = NSNotFound;
		else if (currentSlideIndex != NSNotFound && currentSlideIndex >= numberOfSlides)
			currentSlideIndex = numberOfSlides - 1;
		
		for (NSUInteger i = 0; i < [_slides count]; ++i)
			[self unloadSlideAtIndex:i];
		[_slides removeAllObjects];
		for (NSUInteger i = 0; i < numberOfSlides; ++i)
			[_slides addObject:[NSNull null]];
	}
	else
	{
		NSUInteger index = [_updatesReloadSlidesIndexes firstIndex];
		while (index != NSNotFound)
		{
			[self unloadSlideAtIndex:index];
			
			index = [_updatesReloadSlidesIndexes indexGreaterThanIndex:index];
		}
		
		index = [_updatesDeleteSlidesIndexes lastIndex];
		while (index != NSNotFound)
		{
			if (currentSlideIndex != NSNotFound && (index < currentSlideIndex || (index == currentSlideIndex && currentSlideIndex == [_slides count] - 1)))
			{
				if (currentSlideIndex > 0)
					--currentSlideIndex;
				else
					currentSlideIndex = NSNotFound;
			}
			
			[self unloadSlideAtIndex:index];
			[_slides removeObjectAtIndex:index];
			
			index = [_updatesDeleteSlidesIndexes indexLessThanIndex:index];
		}
		
		index = [_updatesInsertSlidesIndexes firstIndex];
		while (index != NSNotFound)
		{
			if (currentSlideIndex != NSNotFound && currentSlideIndex >= index)
				++currentSlideIndex;
			
			[_slides insertObject:[NSNull null] atIndex:index];
			
			index = [_updatesInsertSlidesIndexes indexGreaterThanIndex:index];
		}
	}
	_slidesViewFlags.updatesReloadData = NO;
	[_updatesReloadSlidesIndexes removeAllIndexes];
	[_updatesDeleteSlidesIndexes removeAllIndexes];
	[_updatesInsertSlidesIndexes removeAllIndexes];
	
	if (currentSlideIndex == NSNotFound && _currentSlideIndex != NSNotFound && _slides.count > 0)
		currentSlideIndex = MIN(_currentSlideIndex, _slides.count - 1);
	_currentSlideIndex = currentSlideIndex;
	
	CGSize contentSize = _scrollView.frame.size;
	contentSize.width *= [_slides count];
	_slidesViewFlags.selfScrolling = YES;
	_scrollView.contentSize = contentSize;
	_scrollView.contentOffset = CGPointMake(_currentSlideIndex == NSNotFound ? -self.frame.size.width : _currentSlideIndex * self.frame.size.width, 0.);
	_slidesViewFlags.selfScrolling = NO;
	[self refreshSlidesViews];
}


#pragma mark -
#pragma mark Customization


- (void)setBackgroundView:(UIView*)backgroundView
{
	if (_backgroundView)
	{
		[_backgroundView removeFromSuperview];
		_backgroundView = nil;
	}
	
	_backgroundView = backgroundView;
	if (_backgroundView)
	{
		_backgroundView.frame = self.bounds;
		_backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self insertSubview:_backgroundView atIndex:0];
	}
}


#pragma mark -
#pragma mark Private


- (void)refreshSlidesViews
{
	DASSERT(!_slidesViewFlags.batchUpdates);
	
	if ([_slides count] == 0)
		return;
	
	CGRect bounds = _scrollView.bounds;
	CGFloat r = bounds.origin.x / bounds.size.width;
	NSInteger minLoadedSlideIndex = (NSInteger) r;
	NSInteger maxLoadedSlideIndex = minLoadedSlideIndex + (r != rintf(r) ? 1 : 0);
	if (_numberOfPreloadedNeighborsSlides != NSNotFound)
	{
		minLoadedSlideIndex -= _numberOfPreloadedNeighborsSlides;
		maxLoadedSlideIndex += _numberOfPreloadedNeighborsSlides;
	}
	else
	{
		minLoadedSlideIndex = 0;
		maxLoadedSlideIndex = _slides.count - 1;
	}
	for (NSInteger i = 0; i < [_slides count]; ++i)
	{
		if (i < minLoadedSlideIndex || maxLoadedSlideIndex < i)
			[self unloadSlideAtIndex:i];
	}
	for (NSInteger i = 0; i < [_slides count]; ++i)
	{
		if (minLoadedSlideIndex <= i && i <= maxLoadedSlideIndex)
			[self loadSlideAtIndex:i];
	}
}


- (void)loadSlideAtIndex:(NSUInteger)index
{
	DASSERT(!_slidesViewFlags.batchUpdates);
	
	DASSERT(index < [_slides count]);
	UIView *slide = (UIView*)[_slides objectAtIndex:index];
	if (slide != (id)[NSNull null])
		return;
	
	id <DASlidesViewDataSource> strongDataSource = _slidesViewDataSource;
	slide = strongDataSource ? [strongDataSource slidesView:self slideAtIndex:index] : nil;
	DASSERT(slide);
	if (slide)
	{
		slide.frame = [self calculateFrameOfSlideAtIndex:index];
		[_slides replaceObjectAtIndex:index withObject:slide];
		[_scrollView addSubview:slide];
	}
}


- (void)unloadSlideAtIndex:(NSUInteger)index
{
	DASSERT(!_slidesViewFlags.batchUpdates);
	
	DASSERT(index < [_slides count]);
	UIView *slide = (UIView*)[_slides objectAtIndex:index];
	if (slide == (id)[NSNull null])
		return;

	NSString *slideReuseIdentifier = slide.slideReuseIdentifier;
	if (slideReuseIdentifier)
	{
		NSUInteger reusableSlidesNumber = 0;
		for (UIView *s in _reusableSlides)
			if ([slideReuseIdentifier isEqualToString:s.slideReuseIdentifier])
				++reusableSlidesNumber;
		DASSERT(_reusableSlidesCount == NSNotFound || reusableSlidesNumber <= _reusableSlidesCount);
		if (_reusableSlidesCount != NSNotFound && reusableSlidesNumber < _reusableSlidesCount)
			[_reusableSlides addObject:slide];
	}
	[slide removeFromSuperview];
	[_slides replaceObjectAtIndex:index withObject:[NSNull null]];
}


- (void)layoutSlides
{
	DASSERT(!_slidesViewFlags.batchUpdates);
	
	if (_slides.count == 0)
	{
		_scrollView.contentSize = CGSizeMake(0., self.frame.size.height);
		return;
	}
	
	for (NSUInteger i = 0; i < _slides.count; ++i)
	{
		UIView *slideView = (UIView*)[_slides objectAtIndex:i];
		if (slideView != (id)[NSNull null])
			slideView.frame = [self calculateFrameOfSlideAtIndex:i];
	}
	
	CGSize contentSize = _scrollView.frame.size;
	contentSize.width *= [_slides count];
	_slidesViewFlags.selfScrolling = YES;
	_scrollView.contentSize = contentSize;
	_scrollView.contentOffset = CGPointMake(_currentSlideIndex == NSNotFound ? -self.frame.size.width : _currentSlideIndex * self.frame.size.width, 0.);
	_slidesViewFlags.selfScrolling = NO;
	[self refreshSlidesViews];
}


- (CGRect)calculateFrameOfSlideAtIndex:(NSUInteger)index
{
	DASSERT(index < [_slides count]);
	
	CGRect frame = CGRectZero;
	frame.size = _scrollView.frame.size;
	frame.origin.x += index * frame.size.width;
	
	id <DASlidesViewDelegate> strongDelegate = _slidesViewDelegate;
	UIEdgeInsets slideInsets = strongDelegate && [strongDelegate respondsToSelector:@selector(slidesView:insetsForSlideAtIndex:)] ? [strongDelegate slidesView:self insetsForSlideAtIndex:index] : UIEdgeInsetsZero;
	return UIEdgeInsetsInsetRect(frame, slideInsets);
}


#pragma mark -
#pragma mark UIScrollViewDelegate


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (!_slidesViewFlags.selfScrolling)
		[self refreshSlidesViews];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	id <DASlidesViewDelegate> strongDelegate = _slidesViewDelegate;
	if (strongDelegate && [strongDelegate respondsToSelector:@selector(slidesViewWillBeginSliding:)])
		[strongDelegate slidesViewWillBeginSliding:self];
}


- (void)updateCurrentSlideIfNeed
{
	CGRect bounds = _scrollView.bounds;
	NSUInteger visibleSlideIndex = lroundf(bounds.origin.x / bounds.size.width);
	DASSERT(_currentSlideIndex == NSNotFound ? visibleSlideIndex == 0 : visibleSlideIndex < [_slides count]);
	if (_currentSlideIndex != visibleSlideIndex && visibleSlideIndex < [_slides count])
	{
		NSUInteger oldCurrentSlideIndex = _currentSlideIndex;
		_currentSlideIndex = visibleSlideIndex;
		id <DASlidesViewDelegate> strongDelegate = _slidesViewDelegate;
		if (strongDelegate && [strongDelegate respondsToSelector:@selector(slidesView:didChangeCurrentSlideFromIndex:toIndex:)])
			[strongDelegate slidesView:self didChangeCurrentSlideFromIndex:oldCurrentSlideIndex toIndex:_currentSlideIndex];
	}
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate)
	{
		[self updateCurrentSlideIfNeed];
		id <DASlidesViewDelegate> strongDelegate = _slidesViewDelegate;
		if (strongDelegate && [strongDelegate respondsToSelector:@selector(slidesViewDidEndSliding:)])
			[strongDelegate slidesViewDidEndSliding:self];
	}
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self updateCurrentSlideIfNeed];
	id <DASlidesViewDelegate> strongDelegate = _slidesViewDelegate;
	if (strongDelegate && [strongDelegate respondsToSelector:@selector(slidesViewDidEndSliding:)])
		[strongDelegate slidesViewDidEndSliding:self];
}


@end



#include <objc/runtime.h>


@implementation UIView (DASlidesView)


static char DASlidesView_SlideReuseIdentifierKey;


- (void)setSlideReuseIdentifier:(NSString *)slideReuseIdentifier
{
	objc_setAssociatedObject(self, &DASlidesView_SlideReuseIdentifierKey, slideReuseIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}


- (NSString*)slideReuseIdentifier
{
	return (NSString*) objc_getAssociatedObject(self, &DASlidesView_SlideReuseIdentifierKey);
}


@end
