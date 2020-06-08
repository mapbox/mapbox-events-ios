//
//  TodayViewController.m
//  MapboxMobileEventsTodayExtension
//
//  Created by Dane Miluski on 6/8/20.
//  Copyright © 2020 Mapbox. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import <MapboxMobileEvents/MapboxMobileEvents.h>
#import "MMEUIApplicationWrapper.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface TodayViewController () <NCWidgetProviding, CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) MKMapView *mapView;
@end

@implementation TodayViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.mapView = [[MKMapView alloc] init];
        self.mapView.translatesAutoresizingMaskIntoConstraints = false;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [MMEEventsManager.sharedManager initializeWithAccessToken:@"foo" userAgentBase:@"bar" hostSDKVersion:@"host"];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];

    // Include MKMapView as demonstration for including map in extension
    [self.view addSubview:self.mapView];
    [NSLayoutConstraint activateConstraints:@[
        [self.mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.mapView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.mapView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [MMEEventsManager.sharedManager sendTurnstileEvent];
    [MMEEventsManager.sharedManager flush];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    // For Demo Purposes, assume new data
    completionHandler(NCUpdateResultNewData);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [manager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    NSLog(@"Location updated: %@",locations);
}

@end
