
/*
 CDVAdMobAdsRewardedAdListener.m
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

#import <Foundation/Foundation.h>
#include "CDVAdMobAds.h"
#include "CDVAdMobAdsRewardedAdListener.h"

@interface CDVAdMobAdsRewardedAdListener()
- (NSString *) __getErrorReason:(NSInteger) errorCode;
@end


@implementation CDVAdMobAdsRewardedAdListener

@synthesize adMobAds;

- (instancetype)initWithAdMobAds: (CDVAdMobAds *)originalAdMobAds {
    self = [super init];
    if (self) {
        adMobAds = originalAdMobAds;
    }
    return self;
}

- (void)rewardBasedVideoAdDidFailedToShow:(GADRewardedAd *)rewarded {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       NSString *jsString =
        @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdFailedToLoad, "
        @"{ 'adType' : 'rewarded', 'error': %ld, 'reason': '%@' }); }, 1);";
        [self.adMobAds.commandDelegate evalJs:[NSString stringWithFormat:jsString,
                                          0,
                                          @"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."]];
    }];
}

- (void)rewardBasedVideoAd:(GADRewardedAd *)rewardBasedVideoAd didRewardUserWithReward:(GADAdReward *)reward {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.adMobAds.commandDelegate evalJs:@"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onRewardedAd, { 'adType': 'rewarded' }); }, 1);"];
    }];
}

- (void)rewardBasedVideoAdDidReceiveAd:(GADRewardedAd *)rewardBasedVideoAd {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.adMobAds.commandDelegate evalJs:@"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdLoaded, { 'adType': 'rewarded' }); }, 1);"];
    }];
    [adMobAds onRewardedAd:rewardBasedVideoAd adListener:self];
}

- (void)rewardBasedVideoAdDidOpen:(GADRewardedAd *)rewardBasedVideoAd {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.adMobAds.commandDelegate evalJs:@"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdOpened, { 'adType': 'rewarded' }); }, 1);"];
    }];
}

- (void)rewardBasedVideoAdDidStartPlaying:(GADRewardedAd *)rewardBasedVideoAd {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.adMobAds.commandDelegate evalJs:@"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onRewardedAdVideoStarted, { 'adType': 'rewarded' }); }, 1);"];
    }];
}

- (void)rewardBasedVideoAdDidCompletePlaying:(GADRewardedAd *)rewardBasedVideoAd {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.adMobAds.commandDelegate evalJs:@"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onRewardedAdVideoCompleted, { 'adType': 'rewarded' }); }, 1);"];
    }];
}

- (void)rewardBasedVideoAdDidClose:(GADRewardedAd *)rewardBasedVideoAd {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.adMobAds.commandDelegate evalJs:@"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdClosed, { 'adType': 'rewarded' }); }, 1);"];
    }];
}

- (void)rewardBasedVideoAdWillLeaveApplication:(GADRewardedAd *)rewardBasedVideoAd {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.adMobAds.commandDelegate evalJs:@"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdLeftApplication, { 'adType': 'rewarded' }); }, 1);"];
    }];
}

- (void)rewardBasedVideoAd:(GADRewardedAd *)rewardBasedVideoAd didFailToLoadWithError:(NSError *)error {
    adMobAds.isRewardedAvailable = false;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *jsString =
            @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdFailedToLoad, "
            @"{ 'adType' : 'rewarded', 'error': %ld, 'reason': '%@' }); }, 1);";
        [self.adMobAds.commandDelegate evalJs:[NSString stringWithFormat:jsString,
                                          (long)error.code,
                                          [self __getErrorReason:error.code]]];
    }];
}

- (void)adWillPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.adMobAds.commandDelegate evalJs:@"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdOpened, { 'adType': 'rewarded' }); }, 1);"];
    }];
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.adMobAds.commandDelegate evalJs:@"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdClosed, { 'adType': 'rewarded' }); }, 1);"];
    }];
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       NSString *jsString =
        @"setTimeout(function (){ cordova.fireDocumentEvent(admob.events.onAdFailedToLoad, "
        @"{ 'adType' : 'rewarded', 'error': %ld, 'reason': '%@' }); }, 1);";
        [self.adMobAds.commandDelegate evalJs:[NSString stringWithFormat:jsString,
                                          0,
                                          @"Advertising tracking may be disabled. To get test ads on this device, enable advertising tracking."]];
    }];
}

- (NSString *) __getErrorReason:(NSInteger) errorCode {
    switch (errorCode) {
        case GADErrorServerError:
        case GADErrorOSVersionTooLow:
        case GADErrorTimeout:
            return @"Internal error";
            break;
            
        case GADErrorInvalidRequest:
            return @"Invalid request";
            break;
            
        case GADErrorNetworkError:
            return @"Network Error";
            break;
            
        case GADErrorNoFill:
            return @"No fill";
            break;
            
        default:
            return @"Unknown";
            break;
    }
}

#pragma mark -
#pragma mark Cleanup

- (void)dealloc {
    adMobAds = nil;
}

@end
