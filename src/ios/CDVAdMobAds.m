/*
 CDVAdMobAds.m
 Copyright 2015 AppFeel. All rights reserved.
 http://www.appfeel.com
 
 AdMobAds Cordova Plugin (cordova-admob)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to
 deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 sell copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#define ADMOB_MEDIATION_MOPUB 1

#import <AdSupport/ASIdentifierManager.h>
#import <CommonCrypto/CommonDigest.h>
#import "CDVAdMobAds.h"
#import "MainViewController.h"

#if ADMOB_MEDIATION_MOPUB
#import <MoPub.h>
#endif

static BOOL showAppAdmob() {
  return YES;
  // return (rand() % 100) > 2;
}

@interface CDVAdMobAds()

@property (assign) BOOL isBannerRequested;
@property (assign) BOOL isInterstitialRequested;
@property (assign) BOOL isRewardedRequested;
@property (assign) BOOL isNetworkActive;

@property (nonatomic) AppFeelReachability *hostReachability;
@property (nonatomic) AppFeelReachability *internetReachability;

- (void) __reachabilityChanged:(NSNotification*)aNote;
- (void) __setOptions:(NSDictionary*) options;
- (BOOL) __createBanner:(NSString *)_pid;
- (BOOL) __showBannerAd:(BOOL)show;
- (BOOL) __createInterstitial:(NSString *)_iid;
- (BOOL) __showInterstitial:(BOOL)show;
- (BOOL) __createRewarded:(NSString *)_rid;
- (BOOL) __showRewarded:(BOOL)show;
- (GADRequest*) __buildAdRequest;
- (NSString*) __md5: (NSString*) s;
- (NSString *) __admobDeviceID;

- (void)resizeViews;

- (GADAdSize)__adSizeFromString:(NSString *)string;

- (void)deviceOrientationChange:(NSNotification *)notification;

@end

@implementation CDVAdMobAds

#define INTERSTITIAL                @"interstitial";
#define BANNER                      @"banner";
#define REWARDED                    @"rewarded";

#define DEFAULT_AD_PUBLISHER_ID                 @"INVALID"
#define DEFAULT_INTERSTITIAL_PUBLISHER_ID       @"INVALID"
#define DEFAULT_REWARDED_PUBLISHER_ID           @"INVALID"

#define OPT_PUBLISHER_ID            @"publisherId"
#define OPT_INTERSTITIAL_AD_ID      @"interstitialAdId"
#define OPT_REWARDED_AD_ID          @"rewardedAdId"
#define OPT_AD_SIZE                 @"adSize"
#define OPT_BANNER_AT_TOP           @"bannerAtTop"
#define OPT_OVERLAP                 @"overlap"
#define OPT_OFFSET_STATUSBAR        @"offsetStatusBar"
#define OPT_IS_TESTING              @"isTesting"
#define OPT_AD_EXTRAS               @"adExtras"
#define OPT_AUTO_SHOW_BANNER        @"autoShowBanner"
#define OPT_AUTO_SHOW_INTERSTITIAL  @"autoShowInterstitial"
#define OPT_AUTO_SHOW_REWARDED      @"autoShowRewarded"
#define OPT_MOPUB_AD_UNIT_ID        @"mopubAdUnitId"

@synthesize isInterstitialAvailable;
@synthesize isRewardedAvailable;

@synthesize bannerView;
@synthesize interstitialView;
@synthesize adsListener;
@synthesize rewardedAdsListener;

@synthesize publisherId, interstitialAdId, rewardedAdId, adSize;
@synthesize isBannerAtTop, isBannerOverlap, isOffsetStatusBar;
@synthesize isTesting, adExtras;

@synthesize isBannerVisible, isBannerInitialized, isBannerRequested, isInterstitialRequested, isRewardedRequested, isNetworkActive;
@synthesize isBannerShow, isBannerAutoShow, isInterstitialAutoShow, isRewardedAutoShow;
@synthesize mopubAdUnitId;

#pragma mark Cordova JS bridge

- (void)pluginInitialize {
    // These notifications are required for re-placing the ad on orientation
    // changes. Start listening for notifications here since we need to
    // translate the Smart Banner constants according to the orientation.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(deviceOrientationChange:)
         name:UIDeviceOrientationDidChangeNotification
         object:nil];
    
    isBannerShow = true;
    publisherId = @"";
    interstitialAdId = @"";
    rewardedAdId = @"";
    adSize = [self __adSizeFromString:@"SMART_BANNER"];
    
    isBannerAtTop = false;
    isBannerOverlap = false;
    isOffsetStatusBar = false;
    isTesting = false;
    
    isBannerAutoShow = true;
    isInterstitialAutoShow = true;
    isRewardedAutoShow = true;
    
    isBannerInitialized = false;
    isBannerVisible = false;
    
    isBannerRequested = false;
    isInterstitialRequested = false;
    isRewardedRequested = false;
    
    isNetworkActive = false;
    
    adsListener = [[CDVAdMobAdsAdListener alloc] initWithAdMobAds:self];
    rewardedAdsListener = [[CDVAdMobAdsRewardedAdListener alloc] initWithAdMobAds:self];
    
    srand((unsigned)time(NULL));
    
    // Check for network state changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(__reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    NSString *remoteHostName = @"www.google.com";
    
    self.hostReachability = [AppFeelReachability reachabilityWithHostName:remoteHostName];
    [self.hostReachability startNotifier];
    
    self.internetReachability = [AppFeelReachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
}

- (void) __reachabilityChanged:(NSNotification*)aNote {
    AppFeelReachability *curReach = [aNote object];
    NetworkStatus remoteHostStatus = [curReach currentReachabilityStatus];
    
    if (remoteHostStatus == NotReachable) {
        isNetworkActive = false;
    } else if (!isNetworkActive) {
        isNetworkActive = true;
        if (isBannerRequested) {
            [self.commandDelegate runInBackground:^{
                [self __createBanner:publisherId];
            }];
        }
        
        if (isInterstitialRequested) {
            [self.commandDelegate runInBackground:^{
                isInterstitialRequested = true;
                
                if (!isInterstitialAvailable && interstitialView) {
                    self.interstitialView.delegate = nil;
                    self.interstitialView = nil;
                }
                
                if (isInterstitialAvailable) {
                    [adsListener interstitialDidReceiveAd:interstitialView];
                    
                } else if (!self.interstitialView) {
                    NSString *_pid = publisherId;
                    NSString *_iid = interstitialAdId;
                    [self __createInterstitial:_iid];
                }
            }];
        }

        if (isRewardedRequested) {
            [self.commandDelegate runInBackground:^{
                isRewardedRequested = true;
                
                if (!isRewardedAvailable && [GADRewardBasedVideoAd sharedInstance]) {
                    [GADRewardBasedVideoAd sharedInstance].delegate = nil;
                }

                if (isRewardedAvailable) {
                    [rewardedAdsListener rewardBasedVideoAdDidReceiveAd:[GADRewardBasedVideoAd sharedInstance]];
                } else if (![GADRewardBasedVideoAd sharedInstance]) {
                    NSString *_pid = publisherId;
                    NSString *_rid = rewardedAdId;
                    [self __createRewarded:_rid];
                }
            }];
        }
    }
}

- (void)setOptions:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }

    // If you are using mediation, you may wish to wait until the
    // completion handler is called before loading ads, as this will ensure
    // that all mediation adapters are initialized.
    NSLog(@"GADMobileAds: Starting\n");

    [self initMoPubWithCompletion:^{
        [[GADMobileAds sharedInstance] startWithCompletionHandler:^(GADInitializationStatus *status){
            NSLog(@"GADMobileAds: Start Completed: %@\n", status.adapterStatusesByClassName);
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }];
    }];
}

- (void)initMoPubWithCompletion:(void(^_Nullable)(void))completionBlock {
#if ADMOB_MEDIATION_MOPUB
    MPMoPubConfiguration *sdkConfig = [[MPMoPubConfiguration alloc]
      initWithAdUnitIdForAppInitialization:mopubAdUnitId];
    // see https://developers.mopub.com/publishers/ios/initialize/
    [[MoPub sharedInstance] initializeSdkWithConfiguration:sdkConfig completion:completionBlock];
#else
    completionBlock();
#endif
}

- (void)createBannerView:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        isBannerRequested = true;
        NSString *_pid = publisherId;
        
        if (![self __createBanner:_pid]) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                             messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
        }
        
        isBannerShow = isBannerAutoShow;
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)destroyBannerView:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
        if (self.bannerView) {
            [self.bannerView setDelegate:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.bannerView removeFromSuperview];
                self.bannerView = nil;
                [self resizeViews];
            });
        }
        
        isBannerRequested = false;
        // Call the success callback that was passed in through the javascript.
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)showBannerAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray* arguments = command.arguments;
    
    BOOL show = YES;
    NSUInteger argc = [arguments count];
    if (argc >= 1) {
        NSString* showValue = [arguments objectAtIndex:0];
        show = (showValue != nil) ? [showValue boolValue] : YES;
    }
    isBannerShow = show;
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
        if (!self.bannerView) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"adView is null, call createBannerView first."];
            
        } else {
            if (![self __showBannerAd:show]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)showInterstitialAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
        
        if (!isInterstitialAvailable && interstitialView) {
            self.interstitialView.delegate = nil;
            self.interstitialView = nil;
        }
        
        if (!self.interstitialView) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"interstitialAd is null, call requestInterstitialAd first."];
            
        } else {
            if (![self __showInterstitial:YES]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)showRewardedAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;
        
        if (!isRewardedAvailable && [GADRewardBasedVideoAd sharedInstance]) {
            [GADRewardBasedVideoAd sharedInstance].delegate = nil;
        }
        
        if (![GADRewardBasedVideoAd sharedInstance]) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"rewardedAd is null, call requestRewardedAd first."];
        } else {
            if (![self __showRewarded:YES]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)onBannerAd:(GADBannerView *)adView adListener:(CDVAdMobAdsAdListener *)adListener {
    if (self.isBannerShow) {
        [self.commandDelegate runInBackground:^{
            if (![self __showBannerAd:YES]) {
                [adListener adViewDidFailedToShow:adView];
            } else {
                [adListener adViewWillPresentScreen:adView];
            }
        }];
    }
}

- (void)onInterstitialAd:(GADInterstitial *)interstitial adListener:(CDVAdMobAdsAdListener *)adListener {
    self.isInterstitialAvailable = true;
    if (self.isInterstitialAutoShow) {
        [self.commandDelegate runInBackground:^{
            if (![self __showInterstitial:YES]) {
                [adListener interstitialDidFailedToShow:interstitial];
            }
        }];
    }
}

- (void)onRewardedAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd adListener:(CDVAdMobAdsRewardedAdListener *)adListener {
    self.isRewardedAvailable = true;
    if (self.isRewardedAutoShow) {
        [self.commandDelegate runInBackground:^{
            if (![self __showRewarded:YES]) {
                [adListener rewardBasedVideoAdDidFailedToShow:[GADRewardBasedVideoAd sharedInstance]];
            }
        }];
    }
}

- (void)requestInterstitialAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;
    
    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        isInterstitialRequested = true;
        
        if (!isInterstitialAvailable && interstitialView) {
            self.interstitialView.delegate = nil;
            self.interstitialView = nil;
        }
        
        if (isInterstitialAvailable) {
            [adsListener interstitialDidReceiveAd:interstitialView];
            
        } else if (!self.interstitialView) {
            NSString *_pid = publisherId;
            NSString *_iid = interstitialAdId;
            
            if (![self __createInterstitial:_iid]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)requestRewardedAd:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray* args = command.arguments;

    NSUInteger argc = [args count];
    if (argc >= 1) {
        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        [self __setOptions:options];
    }

    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        isRewardedRequested = true;
        
        if (isRewardedAvailable) {
            [rewardedAdsListener rewardBasedVideoAdDidReceiveAd:[GADRewardBasedVideoAd sharedInstance]];
        } else {
            NSString *_pid = publisherId;
            NSString *_rid = rewardedAdId;
            
            if (![self __createRewarded:_rid]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."];
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];

}

- (GADAdSize)__adSizeFromString:(NSString *)string {
    if ([string isEqualToString:@"BANNER"]) {
        return kGADAdSizeBanner;
        
    } else if ([string isEqualToString:@"IAB_MRECT"]) {
        return kGADAdSizeMediumRectangle;
        
    } else if ([string isEqualToString:@"IAB_BANNER"]) {
        return kGADAdSizeFullBanner;
        
    } else if ([string isEqualToString:@"IAB_LEADERBOARD"]) {
        return kGADAdSizeLeaderboard;
        
    } else if ([string isEqualToString:@"SMART_BANNER"]) {
        CGRect pr = self.webView.superview.bounds;
        if (pr.size.width > pr.size.height) {
            return kGADAdSizeSmartBannerLandscape;
        }
        else {
            return kGADAdSizeSmartBannerPortrait;
        }
        
    } else {
        return kGADAdSizeInvalid;
    }
}

- (NSString*) __md5:(NSString *) s {
    const char *cstr = [s UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (NSString *)__admobDeviceID {
    NSUUID* adid = [[ASIdentifierManager sharedManager] advertisingIdentifier];
    NSString *output = [self __md5:adid.UUIDString];
    
    return output;
}

#pragma mark Ad Banner logic

- (void) __setOptions:(NSDictionary*) options {
    if ((NSNull *)options == [NSNull null]) {
        return;
    }
    
    NSString* str = nil;
    
    str = [options objectForKey:OPT_PUBLISHER_ID];
    if (str && ![str isEqual:[NSNull null]] && [str length] > 0) {
        publisherId = str;
    }
    
    str = [options objectForKey:OPT_INTERSTITIAL_AD_ID];
    if (str && ![str isEqual:[NSNull null]] && [str length] > 0) {
        interstitialAdId = str;
    }

    str = [options objectForKey:OPT_REWARDED_AD_ID];
    if (str && ![str isEqual:[NSNull null]] && [str length] > 0) {
        rewardedAdId = str;
    }
    
    str = [options objectForKey:OPT_AD_SIZE];
    if (str && ![str isEqual:[NSNull null]]) {
        adSize = [self __adSizeFromString:str];
    }
    
    str = [options objectForKey:OPT_BANNER_AT_TOP];
    if (str && ![str isEqual:[NSNull null]]) {
        isBannerAtTop = [str boolValue];
    }
    
    str = [options objectForKey:OPT_OVERLAP];
    if (str && ![str isEqual:[NSNull null]] ) {
        isBannerOverlap = [str boolValue];
    }
    
    str = [options objectForKey:OPT_OFFSET_STATUSBAR];
    if (str && ![str isEqual:[NSNull null]]) {
        isOffsetStatusBar = [str boolValue];
    }
    
    str = [options objectForKey:OPT_IS_TESTING];
    if (str && ![str isEqual:[NSNull null]]) {
        isTesting = [str boolValue];
    }
    
    NSDictionary* dict = [options objectForKey:OPT_AD_EXTRAS];
    if (dict && ![dict isEqual:[NSNull null]]) {
        adExtras = dict;
    }
    
    str = [options objectForKey:OPT_AUTO_SHOW_BANNER];
    if (str && ![str isEqual:[NSNull null]]) {
        isBannerAutoShow = [str boolValue];
    }
    
    str = [options objectForKey:OPT_AUTO_SHOW_INTERSTITIAL];
    if (str && ![str isEqual:[NSNull null]]) {
        isInterstitialAutoShow = [str boolValue];
    }

    str = [options objectForKey:OPT_AUTO_SHOW_REWARDED];
    if (str && ![str isEqual:[NSNull null]]) {
        isRewardedAutoShow = [str boolValue];
    }

    str = [options objectForKey:OPT_MOPUB_AD_UNIT_ID];
    if (str && ![str isEqual:[NSNull null]]) {
      mopubAdUnitId = str;
    }
}

- (BOOL) __createBanner:(NSString *)_pid {
    BOOL succeeded = false;
    __block NSString *__pid = _pid;
    
    if (self.bannerView && ![self.bannerView.adUnitID isEqualToString:_pid]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.bannerView removeFromSuperview];
            self.bannerView = nil;
            // [self resizeViews];
        });
    }
    
    if (!self.bannerView) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.bannerView = [[GADBannerView alloc] initWithAdSize:adSize];
        });
        self.bannerView.rootViewController = self.viewController;
        
        self.isBannerInitialized = YES;
        self.isBannerVisible = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resizeViews];
        });
    }
    
    self.bannerView.adUnitID = __pid;
    self.bannerView.delegate = adsListener;
    
    GADRequest *request = [self __buildAdRequest];
    if (!request) {
        succeeded = false;
        if (self.bannerView) {
            [self.bannerView setDelegate:nil];
            [self.bannerView removeFromSuperview];
            self.bannerView = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self resizeViews];
            });
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.bannerView loadRequest:request];
        });
        succeeded = true;
    }
    
    return succeeded;
}

- (GADRequest*) __buildAdRequest {
    GADRequest *request = [GADRequest request];
    
    if (self.isTesting) {
        ASIdentifierManager *am = [ASIdentifierManager sharedManager];
        if (!am.advertisingTrackingEnabled) {
            return nil;
        }
        
        // Make the request for a test ad. Put in an identifier for the simulator as
        // well as any devices you want to receive test ads.
        // @"02b0ce0fda9a1f681188ca40e7fa71e1"
        // @"9a6658d2afbc898171e38c6e8080e20de4e4dc42",
        // @"9A6658D2AFBC898171E38C6E8080E20DE4E4DC42",
        NSString *admobDeviceId = [[self __admobDeviceID] lowercaseString];
        request.testDevices = [NSArray arrayWithObjects:
                               admobDeviceId,
                               kGADSimulatorID,
                               nil];
    }
    
    if (self.adExtras) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            GADExtras *extras = [[GADExtras alloc] init];
            NSMutableDictionary *modifiedExtrasDict =
            [[NSMutableDictionary alloc] initWithDictionary:self.adExtras];
            
            [modifiedExtrasDict removeObjectForKey:@"cordova"];
            [modifiedExtrasDict setValue:@"1" forKey:@"cordova"];
            extras.additionalParameters = modifiedExtrasDict;
            [request registerAdNetworkExtras:extras];
        });
    }
    
    return request;
}

- (BOOL) __showBannerAd:(BOOL)show {
    BOOL succeeded = false;
    
    if (!self.isBannerInitialized) {
        NSString *_pid = publisherId;
        succeeded = [self __createBanner:_pid];
        self.isBannerAutoShow = true; // Banner will be shown when loaded
        
    } else if (show == self.isBannerVisible) { // same state, nothing to do
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resizeViews];
        });
        succeeded = true;
        
    } else if (show) {
        UIView* parentView;
        if (self.isBannerOverlap) {
            parentView = self.webView;
        } else {
            parentView = [self.webView superview];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [parentView addSubview:self.bannerView];
            [parentView bringSubviewToFront:self.bannerView];
            [self resizeViews];
            self.isBannerVisible = YES;
        });
        succeeded = true;

    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.bannerView removeFromSuperview];
            [self resizeViews];
            
            self.isBannerVisible = NO;
        });
        
        succeeded = true;
    }
    
    return succeeded;
}

- (BOOL) __createInterstitial:(NSString *)_iid {
    BOOL succeeded = false;
    
    // Clean up the old interstitial...
    if (self.interstitialView) {
        self.interstitialView.delegate = nil;
        self.interstitialView = nil;
    }
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.interstitialView = [[GADInterstitial alloc] initWithAdUnitID:_iid];
    });
    self.interstitialView.delegate = adsListener;
    
    GADRequest *request = [self __buildAdRequest];
    if (!request) {
        succeeded = false;
        if (self.interstitialView) {
            [self.interstitialView setDelegate:nil];
            self.interstitialView = nil;
        }
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.interstitialView loadRequest:request];
        });
        succeeded = true;
        self.isInterstitialAvailable = false;
    }
    
    
    return succeeded;
}

- (BOOL) __createRewarded:(NSString *)_rid {
    BOOL succeeded = false;
    
    [GADRewardBasedVideoAd sharedInstance].delegate = rewardedAdsListener;
    
    GADRequest *request = [self __buildAdRequest];
    if (!request) {
        succeeded = false;
        [GADRewardBasedVideoAd sharedInstance].delegate = nil;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[GADRewardBasedVideoAd sharedInstance] loadRequest:request withAdUnitID:_rid ];
        });
        succeeded = true;
        self.isRewardedAvailable = false;
    }
    
    
    return succeeded;
}

- (BOOL) __showInterstitial:(BOOL)show {
    BOOL succeeded = false;
    
    if (!self.interstitialView) {
        NSString *_iid = interstitialAdId;
        succeeded = [self __createInterstitial:_iid];
        isInterstitialRequested = true;
    } else {
        succeeded = true;
    }
    
    if (self.interstitialView && self.interstitialView.isReady) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.interstitialView presentFromRootViewController:self.viewController];
            isInterstitialRequested = false;
        });
    }
    
    return succeeded;
}

- (BOOL) __showRewarded:(BOOL)show {
    BOOL succeeded = false;
    
    if (![GADRewardBasedVideoAd sharedInstance]) {
        NSString *_rid = rewardedAdId;
        succeeded = [self __createRewarded:_rid];
        isRewardedRequested = true;
    } else {
        succeeded = true;
    }
    
    if ([GADRewardBasedVideoAd sharedInstance] && [[GADRewardBasedVideoAd sharedInstance] isReady]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[GADRewardBasedVideoAd sharedInstance] presentFromRootViewController:self.viewController];
            isRewardedRequested = false;
            isRewardedAvailable = false;
        });
    }
    
    return succeeded;
}
    
- (void)resizeViews {
    // Frame of the main container view that holds the Cordova webview.
    CGRect pr = self.webView.superview.bounds;
    CGRect wf = pr;
    //NSLog(@"super view: %d x %d", (int)pr.size.width, (int)pr.size.height);
    
    // iOS7 Hack, handle the Statusbar
    BOOL isIOS7 = ([[UIDevice currentDevice].systemVersion floatValue] >= 7);
    CGRect sf = [[UIApplication sharedApplication] statusBarFrame];
    CGFloat top;
    
    if (isIOS7 && self.isOffsetStatusBar) {
        top = MIN(sf.size.height, sf.size.width);
    } else {
        top = 0.0;
    }
    
    wf.origin.y = top;
    wf.size.height = pr.size.height - top;
    
    if (self.bannerView) {
        
        // Rotate banner if screen has rotated
        if (pr.size.width > pr.size.height) {
            if (GADAdSizeEqualToSize(self.bannerView.adSize, kGADAdSizeSmartBannerPortrait)) {
                self.bannerView.adSize = kGADAdSizeSmartBannerLandscape;
            }
        } else {
            if (GADAdSizeEqualToSize(self.bannerView.adSize, kGADAdSizeSmartBannerLandscape)) {
                self.bannerView.adSize = kGADAdSizeSmartBannerPortrait;
            }
        }
        
        CGRect bf = self.bannerView.frame;
        UIView* parentView;
        
        if (self.isBannerOverlap) {
            parentView = self.webView;
        } else {
            parentView = [self.webView superview];
        }
        
        // If the ad is not showing or the ad is hidden, we don't want to resize anything.
        BOOL isAdShowing = ([self.bannerView isDescendantOfView:parentView]) && (!self.bannerView.hidden);
        if (isAdShowing) {
            if (isBannerAtTop) {
                if (isBannerOverlap) {
                    wf.origin.y = top;
                    bf.origin.y = 0; // banner is subview of webview
                } else {
                    bf.origin.y = top;
                    //Apply bottom safe area for iPhone X
                    if (@available(iOS 11.0, *)) {
                        bf.origin.y += self.webView.superview.safeAreaInsets.top;
                    }
                    wf.origin.y = bf.origin.y + bf.size.height;
                }
                
            } else {
                // move webview to top
                wf.origin.y = top;
                
                if (isBannerOverlap) {
                    bf.origin.y = wf.size.height - bf.size.height; // banner is subview of webview
                } else {
                    bf.origin.y = pr.size.height - bf.size.height;
                    //Apply bottom safe area for iPhone X
                    if (@available(iOS 11.0, *)) {
                        bf.origin.y -= self.webView.superview.safeAreaInsets.bottom;
                    }
                }
                //Set background to black if banner is at bottom (looks better on iPhone X than white border)
                self.webView.superview.backgroundColor = [UIColor blackColor];
            }
            
            if (!isBannerOverlap) {
                wf.size.height -= bf.size.height;
                if (@available(iOS 11.0, *)) {
                    //Remove safe area from web view
                    if (isBannerAtTop) {
                        wf.size.height -= self.webView.superview.safeAreaInsets.top;
                    } else {
                        wf.size.height -= self.webView.superview.safeAreaInsets.bottom;
                    }
                    //Apply left / right safe area for iPhone X
                    bf.size.width = wf.size.width - self.webView.superview.safeAreaInsets.right - self.webView.superview.safeAreaInsets.left;
                }
            }
            
            bf.origin.x = (pr.size.width - bf.size.width) * 0.5f;
            
            self.bannerView.frame = bf;
            
            //NSLog(@"x,y,w,h = %d,%d,%d,%d", (int) bf.origin.x, (int) bf.origin.y, (int) bf.size.width, (int) bf.size.height );
        }
    }
    
    self.webView.frame = wf;
    
    //NSLog(@"superview: %d x %d, webview: %d x %d", (int) pr.size.width, (int) pr.size.height, (int) wf.size.width, (int) wf.size.height );
}

- (void)deviceOrientationChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resizeViews];
    });
}

#pragma mark -
#pragma mark Cleanup

- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIDeviceOrientationDidChangeNotification
     object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    self.hostReachability = nil;
    self.internetReachability = nil;
    
    bannerView.delegate = nil;
    bannerView = nil;
    interstitialView.delegate = nil;
    interstitialView = nil;
    
    adsListener = nil;
    rewardedAdsListener = nil;

    adExtras = nil;
}

@end
