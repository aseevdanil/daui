//
//  DACollectionViewController.m
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DACollectionViewController.h"



@implementation DACollectionViewController


#pragma mark -
#pragma mark Base


#define _collectionView ((UICollectionView*) self.scrollView)


@synthesize collectionViewLayout = _collectionViewLayout;


- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
	DASSERT(layout);
	if ((self = [super init]))
	{
		_collectionViewLayout = layout;
		_daCollectionViewControllerFlags.collectionViewReady = NO;
	}
	return self;
}


- (void)dealloc
{
	if (_daCollectionViewControllerFlags.collectionViewReady)
	{
		_daCollectionViewControllerFlags.collectionViewReady = NO;
		_collectionView.dataSource = nil;
		_collectionView.delegate = nil;
	}
}


#pragma mark -
#pragma mark View


- (UICollectionView*)collectionView
{
	return _collectionView;
}


- (void)loadScrollView
{
	self.scrollView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_collectionViewLayout];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (!_daCollectionViewControllerFlags.collectionViewReady)
	{
		[self updateCollectionViewLayout];
		_daCollectionViewControllerFlags.collectionViewReady = YES;
		_collectionView.dataSource = self;
		_collectionView.delegate = self;
		[UIView performWithoutAnimation:^
		 {
			 [_collectionView reloadData];
			 [_collectionView performBatchUpdates:nil completion:nil];
		 }];
		[self collectionViewDidReady];
	}
}


- (void)didLayoutScrollView
{
	[super didLayoutScrollView];
	
	if (!_daCollectionViewControllerFlags.collectionViewReady)
	{
		[self updateCollectionViewLayout];
		_daCollectionViewControllerFlags.collectionViewReady = YES;
		_collectionView.dataSource = self;
		_collectionView.delegate = self;
		[UIView performWithoutAnimation:^
		 {
			 [_collectionView reloadData];
			 [_collectionView performBatchUpdates:nil completion:nil];
		 }];
		[self collectionViewDidReady];
	}
}


- (BOOL)isCollectionViewReady
{
	return _daCollectionViewControllerFlags.collectionViewReady;
}


- (void)collectionViewDidReady
{
}


- (void)updateCollectionViewLayout
{
}


- (void)viewWillClear
{
	[super viewWillClear];

	if (_daCollectionViewControllerFlags.collectionViewReady)
	{
		_daCollectionViewControllerFlags.collectionViewReady = NO;
		_collectionView.dataSource = nil;
		_collectionView.delegate = nil;
	}
}


#pragma mark -
#pragma mark UICollectionViewDataSource & UICollectionViewDelegate


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 0;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	DASSERT(NO);
	return 0;
}


- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	DASSERT(NO);
	return nil;
}


@end
