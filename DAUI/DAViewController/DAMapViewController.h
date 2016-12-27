//
//  DAMapViewController.h
//  DAUI
//
//  Created by da on 27.12.16.
//  Copyright © 2016 Aseev Danil. All rights reserved.
//

#import "DAViewController.h"

#import <MapKit/MapKit.h>



@interface DAMapViewController : DAViewController <MKMapViewDelegate>
{
	MKMapView *_mapView;
	unsigned int _mapViewReady : 1;
	unsigned int _disabledMapLongPress : 1;
}

@property (nonatomic, strong, readonly) MKMapView *mapView;
- (BOOL)isMapViewReady;
- (void)mapViewDidReady;

@property (nonatomic, assign, getter = isDisabledMapLongPress) BOOL disabledMapLongPress;

@end
