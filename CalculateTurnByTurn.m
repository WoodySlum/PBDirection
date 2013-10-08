//
//  CalculateTurnByTurn.m
//  PBDirection
//
//  Created by Guido Naturani on 19/09/13.
//  Copyright (c) 2013 Guido Naturani. All rights reserved.
//

#import "CalculateTurnByTurn.h"

#import "AppDelegate.h"
#import <PebbleKit/PebbleKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@implementation CalculateTurnByTurn

@synthesize _Delegate;
@synthesize mapView;

-(void)calculate{
    
    AppDelegate *theAppDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
    
    if ([theAppDelegate._stringDestination isEqualToString:@""]){
        [_Delegate updateEnd:NO :@"Insert Destination!"];
        return;
    }
    
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:theAppDelegate._stringDestination
                 completionHandler:^(NSArray *placemarks, NSError *error) {
                     
                     // Convert the CLPlacemark to an MKPlacemark
                     // Note: There's no error checking for a failed geocode
                     CLPlacemark *geocodedPlacemark = [placemarks objectAtIndex:0];
                     MKPlacemark *placemark = [[MKPlacemark alloc]
                                               initWithCoordinate:geocodedPlacemark.location.coordinate
                                               addressDictionary:geocodedPlacemark.addressDictionary];
                     
                     // Create a map item for the geocoded address to pass to Maps app
                     MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                     [mapItem setName:geocodedPlacemark.name];
                     
                     // Get the "Current User Location" MKMapItem
                     //MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
                     MKMapItem *currentLocationMapItem = theAppDelegate._startLocation;
                     
                     float currentLangitude = currentLocationMapItem.placemark.coordinate.longitude;
                     float currentLatitude =  currentLocationMapItem.placemark.coordinate.latitude;
                     //NSLog( @"new location lat = %f long = %f", currentLatitude,currentLangitude );
                     
                     
                     // Pass the current location and destination map items to the Maps app
                     // Set the direction mode in the launchOptions dictionary
                     //[MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem] launchOptions:launchOptions];
                     
                     MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
                     [request setSource:currentLocationMapItem];
                     [request setDestination:mapItem];
                     
                     MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
                     
                     [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
                         //NSLog(@"%@",[response description]);
                         
                         theAppDelegate._Steps = [[NSMutableArray alloc] initWithCapacity:0];
                         
                         if (response != nil){
                             if (mapView != nil) {
                                 [mapView removeOverlays:mapView.overlays];
                             }
                             for (MKRoute *actRoute in response.routes) {
                                 //NSLog(@"Distance: %f",actRoute.distance);
                                 
                                 theAppDelegate._Route = actRoute;
                                 
                                 for (MKRouteStep *actStep in actRoute.steps) {
                                     
                                     /*
                                     NSLog(@"Instrction: %@",actStep.instructions);
                                     NSLog(@"Description: %@",actStep.description);
                                     NSLog(@"Distance: %f",actStep.distance);
                                      */
                                     if (mapView != nil) {
                                         [mapView insertOverlay:actStep.polyline atIndex:0 level:MKOverlayLevelAboveRoads];
                                      }
                                     [theAppDelegate._Steps addObject:actStep];
                                 }
                                 if (mapView != nil) {
                                     [self zoomMapViewToFitAnnotations:mapView animated:YES];
                                 }
                             }
                         } else {
                             [_Delegate updateEnd:NO :[error description]];
                             return;
                         }
                         
                         //NSLog(@"%@",[error description]);
                         
                         //MKRouteStep *initialStep = [theAppDelegate._Steps objectAtIndex:0];
                         MKRouteStep *firstStep =[theAppDelegate._Steps objectAtIndex:1];
                         //MKRouteStep *secondStep =[theAppDelegate._Steps objectAtIndex:2];
                         
                         NSString *distance2 = [[NSString alloc] initWithFormat:@"%i m",(int)firstStep.distance];
                         NSString *info2 = firstStep.instructions;
                         
                         NSNumber *infoTextKey1 = @(0);
                         NSNumber *distanceKey1 = @(1);
                         NSNumber *imageKey = @(6);
                         
                         NSString *imageValue = [self getImageFromInstruction:info2];
                         
                         if (![info2 isEqualToString:theAppDelegate._OldInfo]){
                             [theAppDelegate._message_queue enqueue:@{infoTextKey1: info2}];
                             [theAppDelegate._message_queue enqueue:@{imageKey: imageValue}];
                             theAppDelegate._OldInfo = info2;
                         }
                         [theAppDelegate._message_queue enqueue:@{distanceKey1: distance2}];
                         
                         [_Delegate updateEnd:YES :@""];
                         
                         
                     }];
                     
                     
                 }];
    
}

-(NSString *)getImageFromInstruction:(NSString *)iInstruction{
    
    if ([[iInstruction lowercaseString] rangeOfString:[@"turn left" lowercaseString]].location!=NSNotFound){
        return @"ARROW_LEFT";
    } else if ([[iInstruction lowercaseString] rangeOfString:[@"turn right" lowercaseString]].location!=NSNotFound){
        return @"ARROW_RIGHT";
    } else {
        
        
    }
    
    
    return @"";
}

#pragma mark - MapView useful function

- (void)recenterMap:(MKMapView *) mv {
    
    NSArray *coordinates = mv.overlays;//[mv valueForKeyPath:@"annotations.coordinate"];
    
    
    
    CLLocationCoordinate2D maxCoord = {-90.0f, -180.0f};
    
    CLLocationCoordinate2D minCoord = {90.0f, 180.0f};
    
    
    
    for(NSValue *value in coordinates) {
        
        CLLocationCoordinate2D coord = {0.0f, 0.0f};
        
        [value getValue:&coord];
        
        if(coord.longitude > maxCoord.longitude) {
            
            maxCoord.longitude = coord.longitude;
            
        }
        
        if(coord.latitude > maxCoord.latitude) {
            
            maxCoord.latitude = coord.latitude;
            
        }
        
        if(coord.longitude < minCoord.longitude) {
            
            minCoord.longitude = coord.longitude;
            
        }
        
        if(coord.latitude < minCoord.latitude) {
            
            minCoord.latitude = coord.latitude;
            
        }
        
    }
    
    MKCoordinateRegion region = {{0.0f, 0.0f}, {0.0f, 0.0f}};
    
    region.center.longitude = (minCoord.longitude + maxCoord.longitude) / 2.0;
    
    region.center.latitude = (minCoord.latitude + maxCoord.latitude) / 2.0;
    
    region.span.longitudeDelta = maxCoord.longitude - minCoord.longitude;
    
    region.span.latitudeDelta = maxCoord.latitude - minCoord.latitude;
    
    [mv setRegion:region animated:YES];
    
}

#define MINIMUM_ZOOM_ARC 0.044 //approximately 1 miles (1 degree of arc ~= 69 miles)
#define ANNOTATION_REGION_PAD_FACTOR 1.15
#define MAX_DEGREES_ARC 360
//size the mapView region to fit its annotations
- (void)zoomMapViewToFitAnnotations:(MKMapView *)mv animated:(BOOL)animated
{
    NSArray *annotations = mv.overlays;
    int count = [mv.annotations count];
    if ( count == 0) { return; } //bail if no annotations
    
    //convert NSArray of id <MKAnnotation> into an MKCoordinateRegion that can be used to set the map size
    //can't use NSArray with MKMapPoint because MKMapPoint is not an id
    MKMapPoint points[count]; //C array of MKMapPoint struct
    for( int i=0; i<count; i++ ) //load points C array by converting coordinates to points
    {
        CLLocationCoordinate2D coordinate = [(id <MKAnnotation>)[annotations objectAtIndex:i] coordinate];
        points[i] = MKMapPointForCoordinate(coordinate);
    }
    //create MKMapRect from array of MKMapPoint
    MKMapRect mapRect = [[MKPolygon polygonWithPoints:points count:count] boundingMapRect];
    //convert MKCoordinateRegion from MKMapRect
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(mapRect);
    
    //add padding so pins aren't scrunched on the edges
    region.span.latitudeDelta  *= ANNOTATION_REGION_PAD_FACTOR;
    region.span.longitudeDelta *= ANNOTATION_REGION_PAD_FACTOR;
    //but padding can't be bigger than the world
    if( region.span.latitudeDelta > MAX_DEGREES_ARC ) { region.span.latitudeDelta  = MAX_DEGREES_ARC; }
    if( region.span.longitudeDelta > MAX_DEGREES_ARC ){ region.span.longitudeDelta = MAX_DEGREES_ARC; }
    
    //and don't zoom in stupid-close on small samples
    if( region.span.latitudeDelta  < MINIMUM_ZOOM_ARC ) { region.span.latitudeDelta  = MINIMUM_ZOOM_ARC; }
    if( region.span.longitudeDelta < MINIMUM_ZOOM_ARC ) { region.span.longitudeDelta = MINIMUM_ZOOM_ARC; }
    //and if there is a sample of 1 we want the max zoom-in instead of max zoom-out
    if( count == 1 )
    {
        region.span.latitudeDelta = MINIMUM_ZOOM_ARC;
        region.span.longitudeDelta = MINIMUM_ZOOM_ARC;
    }
    [mv setRegion:region animated:animated];
}

@end
