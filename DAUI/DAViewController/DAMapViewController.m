//
//  DAMapViewController.m
//  DAUI
//
//  Created by da on 27.12.16.
//  Copyright © 2016 Aseev Danil. All rights reserved.
//

#import "DAMapViewController.h"



@interface MKMapView (DAMapViewController_MKMapView)

- (void)handleLongPress:(id)sender;

@end


@interface DAMapViewController_MKMapView : MKMapView
{
	unsigned int _disabledLongPress : 1;
}

@property (nonatomic, assign, getter = isDisabledLongPress) BOOL disabledLongPress;

@end


@implementation DAMapViewController_MKMapView


- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		DASSERT([super respondsToSelector:@selector(handleLongPress:)]);
		_disabledLongPress = NO;
	}
	return self;
}


- (BOOL)isDisabledLongPress
{
	return _disabledLongPress;
}


- (void)setDisabledLongPress:(BOOL)disabledLongPress
{
	_disabledLongPress = disabledLongPress;
}


- (void)handleLongPress:(id)sender
{
	if (_disabledLongPress)
		return;
	if ([super respondsToSelector:@selector(handleLongPress:)])
		[super handleLongPress:sender];
}


@end



@implementation DAMapViewController


@synthesize mapView = _mapView;


- (instancetype)init
{
	if ((self = [super init]))
	{
		_mapViewReady = NO;
		_disabledMapLongPress = NO;
	}
	return self;
}


- (void)dealloc
{
	if (_mapViewReady)
	{
		_mapViewReady = NO;
		_mapView.delegate = nil;
	}
}


- (BOOL)isDisabledMapLongPress
{
	return _disabledMapLongPress;
}


- (void)setDisabledMapLongPress:(BOOL)disabledMapLongPress
{
	_disabledMapLongPress = disabledMapLongPress;
	if ([self isViewLoaded])
		((DAMapViewController_MKMapView*) _mapView).disabledLongPress = _disabledMapLongPress;
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_mapView = [[DAMapViewController_MKMapView alloc] initWithFrame:self.view.bounds];
	_mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.anchorView addSubview:_mapView];
	
	((DAMapViewController_MKMapView*) _mapView).disabledLongPress = _disabledMapLongPress;
}


- (void)viewWillClear
{
	[super viewWillClear];
	if (_mapViewReady)
	{
		_mapViewReady = NO;
		_mapView.delegate = nil;
	}
}


- (void)viewDidClear
{
	[super viewDidClear];
	_mapView = nil;
}


- (void)anchorViewDidLayoutSubviews
{
	[super anchorViewDidLayoutSubviews];
	if (!_mapViewReady)
	{
		_mapViewReady = YES;
		_mapView.delegate = self;
		[self mapViewDidReady];
	}
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if (!_mapViewReady)
	{
		_mapViewReady = YES;
		_mapView.delegate = self;
		[self mapViewDidReady];
	}
}


- (BOOL)isMapViewReady
{
	return _mapViewReady;
}


- (void)mapViewDidReady
{
}


@end
