//
//  DASlidesViewController.m
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DASlidesViewController.h"



@implementation DASlidesViewController


#pragma mark -
#pragma mark Base


@synthesize slidesView = _slidesView;


- (instancetype)init
{
	if ((self = [super init]))
	{
		_daSlidesViewController.slidesViewReady = NO;
	}
	return self;
}


- (void)dealloc
{
	if (_daSlidesViewController.slidesViewReady)
	{
		_daSlidesViewController.slidesViewReady = NO;
		_slidesView.slidesViewDataSource = nil;
		_slidesView.slidesViewDelegate = nil;
	}
}


#pragma mark -
#pragma mark View Management


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_slidesView = [[DASlidesView alloc] initWithFrame:self.anchorView.bounds];
	_slidesView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_slidesView.opaque = NO;
	_slidesView.backgroundColor = [UIColor clearColor];
	[self.anchorView addSubview:_slidesView];
}


- (void)viewWillClear
{
	[super viewWillClear];
	
	if (_daSlidesViewController.slidesViewReady)
	{
		_daSlidesViewController.slidesViewReady = NO;
		_slidesView.slidesViewDataSource = nil;
		_slidesView.slidesViewDelegate = nil;
	}
}


- (void)viewDidClear
{
	[super viewDidClear];
	
	_slidesView = nil;
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (!_daSlidesViewController.slidesViewReady)
	{
		_daSlidesViewController.slidesViewReady = YES;
		_slidesView.slidesViewDataSource = self;
		_slidesView.slidesViewDelegate = self;
		[_slidesView reloadData];
		[self slidesViewDidReady];
	}
}


- (void)anchorViewDidLayoutSubviews
{
	[super anchorViewDidLayoutSubviews];
	
	if (!_daSlidesViewController.slidesViewReady)
	{
		_daSlidesViewController.slidesViewReady = YES;
		_slidesView.slidesViewDataSource = self;
		_slidesView.slidesViewDelegate = self;
		[_slidesView reloadData];
		[self slidesViewDidReady];
	}
}


- (BOOL)isSlidesViewReady
{
	return _daSlidesViewController.slidesViewReady;
}


- (void)slidesViewDidReady
{
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if (self.navigationController && [self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)])
		[_slidesView.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
}


#pragma mark -
#pragma mark DASlidesViewDataSource


- (NSUInteger)slidesViewNumberOfSlides:(DASlidesView*)slidesView
{
	DASSERT(NO);
	return 0;
}


- (UIView*)slidesView:(DASlidesView*)slidesView slideAtIndex:(NSUInteger)index
{
	DASSERT(NO);
	return nil;
}


@end
