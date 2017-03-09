// Copyright 2016-present 650 Industries. All rights reserved.

#import "ABI15_0_0EXLocationRequester.h"

#import <ReactABI15_0_0/ABI15_0_0RCTUtils.h>

#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

@interface ABI15_0_0EXLocationRequester () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locMgr;
@property (nonatomic, strong) ABI15_0_0RCTPromiseResolveBlock resolve;
@property (nonatomic, strong) ABI15_0_0RCTPromiseRejectBlock reject;
@property (nonatomic, weak) id<ABI15_0_0EXPermissionRequesterDelegate> delegate;

@end

@implementation ABI15_0_0EXLocationRequester

+ (NSDictionary *)permissions
{
  ABI15_0_0EXPermissionStatus status;
  NSString *scope = @"none";
  
  CLAuthorizationStatus systemStatus;
  NSString *alwaysUsageDescription = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"];
  NSString *whenInUseUsageDescription = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"];
  if (!(alwaysUsageDescription || whenInUseUsageDescription)) {
    ABI15_0_0RCTFatal(ABI15_0_0RCTErrorWithMessage(@"This app is missing NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription, so location services will fail. Add one of these keys to your bundle's Info.plist."));
    systemStatus = kCLAuthorizationStatusDenied;
  } else {
    systemStatus = [CLLocationManager authorizationStatus];
  }
  
  switch (systemStatus) {
    case kCLAuthorizationStatusAuthorizedWhenInUse: {
      status = ABI15_0_0EXPermissionStatusGranted;
      scope = @"whenInUse";
      break;
    }
    case kCLAuthorizationStatusAuthorizedAlways: {
      status = ABI15_0_0EXPermissionStatusGranted;
      scope = @"always";
      break;
    }
    case kCLAuthorizationStatusDenied: case kCLAuthorizationStatusRestricted: {
      status = ABI15_0_0EXPermissionStatusDenied;
      break;
    }
    case kCLAuthorizationStatusNotDetermined: default: {
      status = ABI15_0_0EXPermissionStatusUndetermined;
      break;
    }
  }
  
  return @{
           @"status": [ABI15_0_0EXPermissions permissionStringForStatus:status],
           @"expires": ABI15_0_0EXPermissionExpiresNever,
           @"ios": @{
               @"scope": scope,
               },
           };
}

- (void)requestPermissionsWithResolver:(ABI15_0_0RCTPromiseResolveBlock)resolve rejecter:(ABI15_0_0RCTPromiseRejectBlock)reject
{
  NSDictionary *existingPermissions = [[self class] permissions];
  if (existingPermissions && ![existingPermissions[@"status"] isEqualToString:[ABI15_0_0EXPermissions permissionStringForStatus:ABI15_0_0EXPermissionStatusUndetermined]]) {
    // since permissions are already determined, the iOS request methods will be no-ops.
    // just resolve with whatever existing permissions.
    resolve(existingPermissions);
    if (_delegate) {
      [_delegate permissionRequesterDidFinish:self];
    }
  } else {
    _resolve = resolve;
    _reject = reject;

    _locMgr = [[CLLocationManager alloc] init];
    _locMgr.delegate = self;

    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] &&
        [_locMgr respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_locMgr requestAlwaysAuthorization];
    } else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] &&
               [_locMgr respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locMgr requestWhenInUseAuthorization];
    } else {
      _reject(@"E_LOCATION_INFO_PLIST", @"Either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription key must be present in Info.plist to use geolocation.", nil);
      if (_delegate) {
        [_delegate permissionRequesterDidFinish:self];
      }
    }
  }
}

- (void)setDelegate:(id<ABI15_0_0EXPermissionRequesterDelegate>)delegate
{
  _delegate = delegate;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
  if (_reject) {
    _reject(@"E_LOCATION_ERROR_UNKNOWN", error.localizedDescription, error);
    _resolve = nil;
    _reject = nil;
  }
  if (_delegate) {
    [_delegate permissionRequesterDidFinish:self];
  }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
  if (status == kCLAuthorizationStatusNotDetermined) {
    // CLLocationManager calls this delegate method once on start with kCLAuthorizationNotDetermined even before the user responds
    // to the "Don't Allow" / "Allow" dialog box. This isn't the event we care about so we skip it. See:
    // http://stackoverflow.com/questions/30106341/swift-locationmanager-didchangeauthorizationstatus-always-called/30107511#30107511
    return;
  }
  if (_resolve) {
    _resolve([[self class] permissions]);
    _resolve = nil;
    _reject = nil;
  }
  if (_delegate) {
    [_delegate permissionRequesterDidFinish:self];
  }
}

@end
