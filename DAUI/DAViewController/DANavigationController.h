//
//  DANavigationController.h
//  daui
//
//  Created by da on 16.03.12.
//  Copyright (c) 2012 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface DANavigationController : UINavigationController <UINavigationControllerDelegate>
{
	NSMutableArray *_invocationQueue;
	
	id <UINavigationControllerDelegate> __weak _navigationControllerDelegate;
	
	id <UIGestureRecognizerDelegate> __weak _standardInteractivePopGestureRecognizerDelegate;
	
	struct
	{
		unsigned int navigationBarObserving : 1;
		unsigned int transitioning : 1;
		unsigned int animationTransitioning : 1;
		unsigned int popViewController : 1;
		unsigned int nestedPopViewController : 1;
	}
	_daNavigationControllerFlags;
}

@property (nonatomic, weak) id <UINavigationControllerDelegate> navigationControllerDelegate;

@end


@protocol DANavigationControllerDelegate <UINavigationControllerDelegate>

@optional
- (void)navigationController:(UINavigationController*)navigationController didUpdateNavigationStackWithPopedViewControllers:(NSArray*)popedViewControllers andPushedViewControllers:(NSArray*)pushedViewControllers;

@end
