//
//  DACollectionViewController.h
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DAScrollViewController.h"



@interface DACollectionViewController : DAScrollViewController <UICollectionViewDelegate, UICollectionViewDataSource>
{
	UICollectionViewLayout *_collectionViewLayout;
	
	struct
	{
		unsigned int collectionViewReady : 1;
	}
	_daCollectionViewControllerFlags;
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout;
@property (nonatomic, strong, readonly) UICollectionViewLayout *collectionViewLayout;

@property (nonatomic, strong) UICollectionView *collectionView;
- (BOOL)isCollectionViewReady;
- (void)collectionViewDidReady;
- (void)updateCollectionViewLayout;

@end
