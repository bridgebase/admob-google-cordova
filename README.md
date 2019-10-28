# Cordova Plugin AdMob (Ethical)

## Why this fork?

The original plugin hasn't been touched by the authors since 2016, but they
still try to get a "2% donation" from all revenues of all apps that install
it. This "donation scheme" is only mentioned very last in the original README
file; a dark pattern hiding a quite questionable practice.

Apart from getting rid of this, this forks aims at modernizing the plugin
installation and add support to AdMob Mediation.

Main changes:

 - Use cocoapod for installing dependencies
 - Disable the "donation scheme"
 - Remove dependencies over deprecated plugins

[license]: http://img.shields.io/badge/license-MIT-blue.svg?style=flat

_Note_: I don't say the original authors don't deserve donations. I myself am
the author of several cordova plugin and I'm glad when I receive back some
donations for support of my work. I just say that asking for 2% all ad
revenue is obviously a lot. The right thing is to be upfront about it and
make it easy to disable (at least provide some instructions).

**IMPORTANT**: the Android code hasn't been cleaned up yet! I'm focusing on iOS for now.

## It simply works

Monetize your Cordova/Phonegap/XDK HTML5 hybrid apps and games with AdMob ads, **using latest Google AdMob SDK**.

 - Now available with Ionic Native too
 - Supports banner, interstitials and rewarded
 - Optional [Tappx](http://www.tappx.com/) backfill

With this Cordova/Phonegap/XDK plugin you can show AdMob ads as easy as:

```js
    admob.createBannerView({publisherId: "ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB"});
```

## Plugin update (phonegap/cordova cli)

To update the plugin you should remove the plugin and add it again:

```
$ cordova plugin rm cordova-open-admob
$ npm cache clear
$ cordova plugin add cordova-open-admob
```

## Platform SDK supported

 - iOS, using AdMob SDK for iOS.

## Mediation

You can setup additional AdMob mediation adapters:

#### Facebook for iOS

Add this to your `config.xml`:

```xml
<pod name="GoogleMobileAdsMediationFacebook" />
```

Follow the instructions here: https://developers.google.com/admob/ios/mediation/facebook

## Quick start ##

To install this plugin, follow the [Command-line Interface Guide](http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-line%20Interface). You can use one of the following command lines:

* `cordova plugin add cordova-open-admob`
* `cordova plugin add https://github.com/j3k0/admob-google-cordova.git`

To use in [Phonegap Build](https://build.phonegap.com), place the following tag in your `config.xml` file:

```xml
<gap:plugin name="cordova-open-admob" source="npm"/>
```

To start showing ads, place the following code in your `onDeviceReady` callback. Replace corresponding id's with yours:

*Note: ensure you have a proper [AdMob](https://apps.admob.com/admob/signup) and [tappx](http://www.tappx.com/) accounts and get your publisher id's*.

```javascript
    
    function onDeviceReady() {
      document.removeEventListener('deviceready', onDeviceReady, false);
      
      // Set AdMobAds options:
      admob.setOptions({
        publisherId:           "ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB",  // Required
        interstitialAdId:      "ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII",  // Optional
        autoShowBanner:        true,                                      // Optional
        autoShowRInterstitial: false,                                     // Optional
        autoShowRewarded:      false,                                     // Optional
        tappxIdiOS:            "/XXXXXXXXX/Pub-XXXX-iOS-IIII",            // Optional
        tappxIdAndroid:        "/XXXXXXXXX/Pub-XXXX-Android-AAAA",        // Optional
        tappxShare:            0.5                                        // Optional
      });
      
      // Start showing banners (atomatic when autoShowBanner is set to true)
      admob.createBannerView();
      
      // Request interstitial ad (will present automatically when autoShowInterstitial is set to true)
      admob.requestInterstitialAd();

      // Request rewarded ad (will present automatically when autoShowRewarded is set to true)
      admob.requestRewardedAd();
    }
    
    document.addEventListener("deviceready", onDeviceReady, false);
```

If you don't specify tappxId, no tappx requests will be placed (even if you specify a tappxShare). [See Tappx configuration](https://github.com/appfeel/admob-google-cordova/wiki/Tappx-configuration) for more detailed info.

:warning: Be sure to start ads on "deviceready" event otherwise, the plugin would not work.

---
## Full documentation ##

Visit the [wiki](https://github.com/appfeel/admob-google-cordova/wiki) of Google AdMob Cordova plugin. Table of contents:

* [Home](https://github.com/appfeel/admob-google-cordova/wiki)
* [Table of contents](https://github.com/appfeel/admob-google-cordova/wiki/Table-of-contents)
* [Change Log](https://github.com/appfeel/admob-google-cordova/wiki/Change-Log)
* [Testimonials](https://github.com/appfeel/admob-google-cordova/wiki/Testimonials)
* [Setup](https://github.com/appfeel/admob-google-cordova/wiki/Setup)
* [Angular.js, Ionic apps](https://github.com/appfeel/admob-google-cordova/wiki/Angular.js,-Ionic-apps)
* [Tappx configuration](https://github.com/appfeel/admob-google-cordova/wiki/Tappx-configuration)
* [Javascript API](https://github.com/appfeel/admob-google-cordova/wiki/Javascript-API)
  * [setOptions](https://github.com/appfeel/admob-google-cordova/wiki/setOptions)
  * Banners
    * [createBannerView](https://github.com/appfeel/admob-google-cordova/wiki/createBannerView)
    * [showBannerAd](https://github.com/appfeel/admob-google-cordova/wiki/showBannerAd)
    * [destroyBannerView](https://github.com/appfeel/admob-google-cordova/wiki/destroyBannerView)
  * Interstitials
    * [requestInterstitialAd](https://github.com/appfeel/admob-google-cordova/wiki/requestInterstitialAd)
    * [showInterstitialAd](https://github.com/appfeel/admob-google-cordova/wiki/showInterstitialAd)
  * Rewarded
    * [requestRewardedAd](https://github.com/appfeel/admob-google-cordova/wiki/requestRewardedAd)
    * [showRewardedAd](https://github.com/appfeel/admob-google-cordova/wiki/showRewardedAd)
  * [Events](https://github.com/appfeel/admob-google-cordova/wiki/Events)
    * [onAdLoaded](https://github.com/appfeel/admob-google-cordova/wiki/Events#admobeventsonadloaded)
    * [onAdFailedToLoad](https://github.com/appfeel/admob-google-cordova/wiki/Events#admobeventsonadfailedtoload)
    * [onAdOpened](https://github.com/appfeel/admob-google-cordova/wiki/Events#admobeventsonadopened)
    * [onAdClosed](https://github.com/appfeel/admob-google-cordova/wiki/Events#admobeventsonadclosed)
    * [onAdLeftApplication](https://github.com/appfeel/admob-google-cordova/wiki/Events#admobeventsonadleftapplication)
* [Complete example code](https://github.com/appfeel/admob-google-cordova/wiki/Complete-example-code)
* [Contributing](https://github.com/appfeel/admob-google-cordova/wiki/Contributing)
* [Screenshots](https://github.com/appfeel/admob-google-cordova/wiki/Screenshots)

---
## Complete example code ##
Note that the admob ads are configured inside `onDeviceReady()`. This is because only after device ready the AdMob Cordova plugin will be working.

```javascript

    var isAppForeground = true;
    
    function initAds() {
      if (admob) {
        var adPublisherIds = {
          ios : {
            banner : "ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB",
            interstitial : "ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII"
          },
          android : {
            banner : "ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB",
            interstitial : "ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII"
          }
        };
    	  
        var admobid = (/(android)/i.test(navigator.userAgent)) ? adPublisherIds.android : adPublisherIds.ios;
            
        admob.setOptions({
          publisherId:          admobid.banner,
          interstitialAdId:     admobid.interstitial,
          autoShowBanner:       true,
          autoShowInterstitial: false,
          autoShowRewarded:     false,
          tappxIdiOS:           "/XXXXXXXXX/Pub-XXXX-iOS-IIII",
          tappxIdAndroid:       "/XXXXXXXXX/Pub-XXXX-Android-AAAA",
          tappxShare:           0.5,
        });

        registerAdEvents();
        
      } else {
        alert('AdMobAds plugin not ready');
      }
    }
    
    function onAdLoaded(e) {
      if (isAppForeground) {
        if (e.adType === admob.AD_TYPE.AD_TYPE_BANNER) {
          console.log("New banner received");
          console.log("Using adapter " + e.adapter);
        } else if (e.adType === admob.INTERSTITIAL) {
          console.log("An interstitial has been loaded and autoshown. If you want to automatically show the interstitial ad, set 'autoShowInterstitial: true' in admob.setOptions() or remove it");
          console.log("Using adapter " + e.adapter);
          admob.showInterstitialAd();
        } else if (e.adType === admob.AD_TYPE_REWARDED) {
          console.log("New rewarded ad received");
          admob.showRewardedAd();
        }
      }
    }
    
    function onPause() {
      if (isAppForeground) {
        admob.destroyBannerView();
        isAppForeground = false;
      }
    }
    
    function onResume() {
      if (!isAppForeground) {
        setTimeout(admob.createBannerView, 1);
        setTimeout(admob.requestInterstitialAd, 1);
        isAppForeground = true;
      }
    }
    
    // optional, in case respond to events
    function registerAdEvents() {
      document.addEventListener(admob.events.onAdLoaded, onAdLoaded);
      document.addEventListener(admob.events.onAdFailedToLoad, function (e) {});
      document.addEventListener(admob.events.onAdOpened, function (e) {});
      document.addEventListener(admob.events.onAdClosed, function (e) {});
      document.addEventListener(admob.events.onAdLeftApplication, function (e) {});
      
      document.addEventListener("pause", onPause, false);
      document.addEventListener("resume", onResume, false);
    }
        
    function onDeviceReady() {
      document.removeEventListener('deviceready', onDeviceReady, false);
      initAds();

      // display a banner at startup
      admob.createBannerView();
        
      // request an interstitial ad
      admob.requestInterstitialAd();

      // request a rewarded ad
      admob.requestRewardedAd();
    }
    
    document.addEventListener("deviceready", onDeviceReady, false);
```

---
## Screenshots ##

#### iPhone:

<img src="https://github.com/appfeel/admob-google-cordova/wiki/demo/iphone.png" border="10" alt="Phonegp Cordova admob plugin in iPhone" />

#### iPad Banner Portrait:

<img src="https://github.com/appfeel/admob-google-cordova/wiki/demo/banner-ipad.png" border="10" alt="Phonegp Cordova admob plugin in iPad" />

#### iPad Banner Landscape:

<img src="https://raw.githubusercontent.com/wiki/appfeel/admob-google-cordova/demo/banner-landscape-ipad.png" border="10" alt="Phonegp Cordova banner admob plugin" />

---
## License ##
```
The MIT License

Copyright (c) 2014 AppFeel

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---
## Credits ##

* [appFeel](http://www.appfeel.com)
* Contributors

