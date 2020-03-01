/*
 AdMobAds.java
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

package cc.fovea.admob;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Iterator;
import java.util.Random;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Rect;
import android.os.Bundle;
import android.provider.Settings;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

import cc.fovea.admob.Connectivity.IConnectivityChange;

// import com.google.android.ads.mediationtestsuite.MediationTestSuite;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.InterstitialAd;
import com.google.android.gms.ads.mediation.admob.AdMobExtras;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.initialization.OnInitializationCompleteListener;
import com.google.android.gms.ads.initialization.InitializationStatus;
import com.google.android.gms.ads.reward.RewardedVideoAd;
import com.google.android.gms.ads.AdLoader;

public class AdMobAds extends CordovaPlugin implements IConnectivityChange {
    public static final String ADMOBADS_LOGTAG = "OpenAdMob";
    public static final String INTERSTITIAL = "interstitial";
    public static final String BANNER = "banner";
    public static final String REWARDED = "rewarded";

    private static final boolean CORDOVA_4 = Integer.valueOf(CordovaWebView.CORDOVA_VERSION.split("\\.")[0]) >= 4;

    /* Cordova Actions. */
    private static final String ACTION_SET_OPTIONS = "setOptions";
    private static final String ACTION_CREATE_BANNER_VIEW = "createBannerView";
    private static final String ACTION_SHOW_BANNER_AD = "showBannerAd";
    private static final String ACTION_DESTROY_BANNER_VIEW = "destroyBannerView";
    private static final String ACTION_REQUEST_INTERSTITIAL_AD = "requestInterstitialAd";
    private static final String ACTION_SHOW_INTERSTITIAL_AD = "showInterstitialAd";
    private static final String ACTION_REQUEST_REWARDED_AD = "requestRewardedAd";
    private static final String ACTION_SHOW_REWARDED_AD = "showRewardedAd";

    /* options */
    private static final String OPT_PUBLISHER_ID = "publisherId";
    private static final String OPT_INTERSTITIAL_AD_ID = "interstitialAdId";
    private static final String OPT_REWARDED_AD_ID = "rewardedAdId";
    private static final String OPT_AD_SIZE = "adSize";
    private static final String OPT_BANNER_AT_TOP = "bannerAtTop";
    private static final String OPT_OVERLAP = "overlap";
    private static final String OPT_OFFSET_STATUSBAR = "offsetStatusBar";
    private static final String OPT_IS_TESTING = "isTesting";
    private static final String OPT_AD_EXTRAS = "adExtras";
    private static final String OPT_AUTO_SHOW_BANNER = "autoShowBanner";
    private static final String OPT_AUTO_SHOW_INTERSTITIAL = "autoShowInterstitial";
    private static final String OPT_AUTO_SHOW_REWARDED = "autoShowRewarded";
    protected boolean isBannerAutoShow = true;
    protected boolean isInterstitialAutoShow = true;
    protected boolean isRewardedAutoShow = true;
    private Connectivity connectivity;
    private AdMobAdsAdListener bannerListener = new AdMobAdsAdListener(BANNER, this);
    private AdMobAdsAdListener interstitialListener = new AdMobAdsAdListener(INTERSTITIAL, this);
    private AdMobAdsRewardedAdListener rewardedListener = new AdMobAdsRewardedAdListener(REWARDED, this);
    private boolean isInterstitialAvailable = false;
    private boolean isRewardedAvailable = false;
    private boolean isNetworkActive = false;
    private boolean isBannerRequested = false;
    private boolean isInterstitialRequested = false;
    private boolean isRewardedRequested = false;
    //private View adView;
    //private SearchAdView sadView;
    private ViewGroup parentView;
    /**
     * The adView to display to the user.
     */
    private AdView adView;
    /**
     * if want banner view overlap webview, we will need this layout
     */
    private RelativeLayout adViewLayout = null;
    /**
     * The interstitial ad to display to the user.
     */
    private InterstitialAd interstitialAd;
    private String publisherId = null;
    private String interstitialAdId = null;
    private String rewardedAdId = null;
    private AdSize adSize = AdSize.SMART_BANNER;
    /**
     * The rewarded ad to display to the user.
     */
    private RewardedVideoAd rewardedAd;
    /**
     * Whether or not the ad should be positioned at top or bottom of screen.
     */
    private boolean isBannerAtTop = false;
    /**
     * Whether or not the banner will overlap the webview instead of push it up or down
     */
    private boolean isBannerOverlap = false;
    private boolean isOffsetStatusBar = false;
    private boolean isTesting = false;
    private JSONObject adExtras = null;
    private boolean isBannerVisible = false;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        Log.i(ADMOBADS_LOGTAG, "initialize");
        connectivity = Connectivity.GetInstance(cordova.getActivity(), this);
        connectivity.observeInternetConnection();
    }

    /**
     * Executes the request.
     * <p/>
     * This method is called from the WebView thread.
     * <p/>
     * To do a non-trivial amount of work, use: cordova.getThreadPool().execute(runnable);
     * <p/>
     * To run on the UI thread, use: cordova.getActivity().runOnUiThread(runnable);
     *
     * @param action          The action to execute.
     * @param args            The exec() arguments.
     * @param callbackContext The callback context used when calling back into JavaScript.
     * @return Whether the action was valid.
     */
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        PluginResult result = null;
        Log.i(ADMOBADS_LOGTAG, "execute: " + action);

        if (ACTION_SET_OPTIONS.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeSetOptions(options, callbackContext);

        } else if (ACTION_CREATE_BANNER_VIEW.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeCreateBannerView(options, callbackContext);

        } else if (ACTION_SHOW_BANNER_AD.equals(action)) {
            boolean show = args.optBoolean(0);
            result = executeShowBannerAd(show, callbackContext);

        } else if (ACTION_DESTROY_BANNER_VIEW.equals(action)) {
            result = executeDestroyBannerView(callbackContext);

        } else if (ACTION_REQUEST_INTERSTITIAL_AD.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeRequestInterstitialAd(options, callbackContext);

        } else if (ACTION_SHOW_INTERSTITIAL_AD.equals(action)) {
            result = executeShowInterstitialAd(callbackContext);
        } else if (ACTION_REQUEST_REWARDED_AD.equals(action)) {
            JSONObject options = args.optJSONObject(0);
            result = executeRequestRewardedAd(options, callbackContext);

        } else if (ACTION_SHOW_REWARDED_AD.equals(action)) {
            result = executeShowRewardedAd(callbackContext);
        } else {
            Log.i(ADMOBADS_LOGTAG, String.format("Invalid action passed: %s", action));
            return false;
        }

        if (result != null) {
            callbackContext.sendPluginResult(result);
        }

        return true;
    }

    @Override
    public void onPause(boolean multitasking) {
        super.onPause(multitasking);
        if (adView != null) {
            adView.pause();
        }
        connectivity.stopAllObservers(true);
    }

    @Override
    public void onResume(boolean multitasking) {
        super.onResume(multitasking);
        if (adView != null) {
            adView.resume();
        }
        connectivity.observeInternetConnection();
    }

    @Override
    public void onDestroy() {
        if (adView != null) {
            adView.destroy();
            adView = null;
        }
        if (adViewLayout != null) {
            ViewGroup parentView = (ViewGroup) adViewLayout.getParent();
            if (parentView != null) {
                parentView.removeView(adViewLayout);
            }
            adViewLayout = null;
        }
        connectivity.stopAllObservers(true);
        super.onDestroy();
    }

    public void onAdLoaded(String adType) {
        if (INTERSTITIAL.equalsIgnoreCase(adType)) {
            isInterstitialAvailable = true;
            if (isInterstitialAutoShow) {
                showInterstitialAd(null);
            }
        } else if (BANNER.equalsIgnoreCase(adType)) {
            if (isBannerAutoShow) {
                executeShowBannerAd(true, null);
                bannerListener.onAdOpened();
            }
        } else if (REWARDED.equalsIgnoreCase(adType)) {
            isRewardedAvailable = true;
            if (isRewardedAutoShow) {
                showRewardedAd(null);
            }
        }
    }

    public void onAdOpened(String adType) {
        if (INTERSTITIAL.equalsIgnoreCase(adType)) {
            isInterstitialAvailable = false;
        } else if (REWARDED.equalsIgnoreCase(adType)) {
            isRewardedAvailable = false;
        }
    }

    private PluginResult executeSetOptions(JSONObject options, CallbackContext callbackContext) {
        Log.i(ADMOBADS_LOGTAG, "executeSetOptions");
        this.setOptions(options);
        MobileAds.initialize(cordova.getActivity(), new OnInitializationCompleteListener() {
            @Override
            public void onInitializationComplete(InitializationStatus initializationStatus) {
                callbackContext.success();
                // MediationTestSuite.launch(cordova.getActivity());
            }
        });
        return null;
    }

    private void setOptions(JSONObject options) {
        Log.i(ADMOBADS_LOGTAG, "setOptions");
        if (options == null) {
            return;
        }
        if (options.has(OPT_PUBLISHER_ID)) {
            this.publisherId = options.optString(OPT_PUBLISHER_ID);
        }
        if (options.has(OPT_INTERSTITIAL_AD_ID)) {
            this.interstitialAdId = options.optString(OPT_INTERSTITIAL_AD_ID);
        }
        if (options.has(OPT_REWARDED_AD_ID)) {
            this.rewardedAdId = options.optString(OPT_REWARDED_AD_ID);
        }
        if (options.has(OPT_AD_SIZE)) {
            this.adSize = adSizeFromString(options.optString(OPT_AD_SIZE));
        }
        if (options.has(OPT_BANNER_AT_TOP)) {
            this.isBannerAtTop = options.optBoolean(OPT_BANNER_AT_TOP);
        }
        if (options.has(OPT_OVERLAP)) {
            this.isBannerOverlap = options.optBoolean(OPT_OVERLAP);
        }
        if (options.has(OPT_OFFSET_STATUSBAR)) {
            this.isOffsetStatusBar = options.optBoolean(OPT_OFFSET_STATUSBAR);
        }
        if (options.has(OPT_IS_TESTING)) {
            this.isTesting = options.optBoolean(OPT_IS_TESTING);
        }
        if (options.has(OPT_AD_EXTRAS)) {
            this.adExtras = options.optJSONObject(OPT_AD_EXTRAS);
        }
        if (options.has(OPT_AUTO_SHOW_BANNER)) {
            this.isBannerAutoShow = options.optBoolean(OPT_AUTO_SHOW_BANNER);
        }
        if (options.has(OPT_AUTO_SHOW_INTERSTITIAL)) {
            this.isInterstitialAutoShow = options.optBoolean(OPT_AUTO_SHOW_INTERSTITIAL);
        }
        if (options.has(OPT_AUTO_SHOW_REWARDED)) {
            this.isRewardedAutoShow = options.optBoolean(OPT_AUTO_SHOW_REWARDED);
        }
    }

    @SuppressLint("DefaultLocale")
    private AdRequest buildAdRequest() {
        AdRequest.Builder request_builder = new AdRequest.Builder();
        if (isTesting) {
            // This will request test ads on the emulator and deviceby passing this hashed device ID.
            String ANDROID_ID = Settings.Secure.getString(cordova.getActivity().getContentResolver(), android.provider.Settings.Secure.ANDROID_ID);
            String deviceId = md5(ANDROID_ID).toUpperCase();
            request_builder = request_builder.addTestDevice(deviceId).addTestDevice(AdRequest.DEVICE_ID_EMULATOR);
        }
        Bundle bundle = new Bundle();
        bundle.putInt("cordova", 1);
        if (adExtras != null) {
            Iterator<String> it = adExtras.keys();
            while (it.hasNext()) {
                String key = it.next();
                try {
                    bundle.putString(key, adExtras.get(key).toString());
                } catch (JSONException exception) {
                    Log.i(ADMOBADS_LOGTAG, String.format("Caught JSON Exception: %s", exception.getMessage()));
                }
            }
        }
        AdMobExtras adextras = new AdMobExtras(bundle);
        request_builder = request_builder.addNetworkExtras(adextras);
        AdRequest request = request_builder.build();
        return request;
    }

    private String getPublisherId() {
        return publisherId;
    }

    private void createBannerView(String _pid, AdMobAdsAdListener adListener) {
        if (adView != null && !adView.getAdUnitId().equals(_pid)) {
            if (adView.getParent() != null) {
                ((ViewGroup) adView.getParent()).removeView(adView);
            }
            adView.destroy();
            adView = null;
        }
        if (adView == null) {
            adView = new AdView(cordova.getActivity());
            adView.setAdSize(adSize);
            adView.setAdUnitId(_pid);
            adView.setAdListener(adListener);
            adView.setVisibility(View.GONE);
        }

        if (adView.getParent() != null) {
            ((ViewGroup) adView.getParent()).removeView(adView);
        }
        isBannerVisible = false;
        adView.loadAd(buildAdRequest());
    }

    private PluginResult executeCreateBannerView(JSONObject options, final CallbackContext callbackContext) {
        this.setOptions(options);
        final String _pid = getPublisherId();
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                isBannerRequested = true;
                createBannerView(_pid, bannerListener);
                callbackContext.success();
            }
        });
        return null;
    }

    /**
     * Parses the show ad input parameters and runs the show ad action on the UI thread.
     *
     * @param show indicates if the banner should be shown or not.
     * @param callbackContext Callback to be called when thread finishes.
     * @return A PluginResult representing whether or not an ad was requested succcessfully. Listen for onReceiveAd() and onFailedToReceiveAd() callbacks to see
     * if an ad was successfully retrieved.
     */
    private PluginResult executeShowBannerAd(final boolean show, final CallbackContext callbackContext) {
        if (adView == null) {
            return new PluginResult(Status.ERROR, "adView is null, call createBannerView first.");
        }

        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (show == isBannerVisible) {
                    // no change

                } else if (show) {
                    if (adView.getParent() != null) {
                        ((ViewGroup) adView.getParent()).removeView(adView);
                    }

                    if (isBannerOverlap) {
                        RelativeLayout.LayoutParams params2 = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);

                        if (isOffsetStatusBar) {
                            int titleBarHeight = 0;
                            Rect rectangle = new Rect();
                            Window window = AdMobAds.this.cordova.getActivity().getWindow();
                            window.getDecorView().getWindowVisibleDisplayFrame(rectangle);

                            if (isBannerAtTop) {
                                if (rectangle.top == 0) {
                                    int contentViewTop = window.findViewById(Window.ID_ANDROID_CONTENT).getTop();
                                    titleBarHeight = contentViewTop - rectangle.top;
                                }
                                params2.topMargin = titleBarHeight;

                            } else {
                                if (rectangle.top > 0) {
                                    int contentViewBottom = window.findViewById(Window.ID_ANDROID_CONTENT).getBottom();
                                    titleBarHeight = contentViewBottom - rectangle.bottom;
                                }
                                params2.bottomMargin = titleBarHeight;
                            }

                        } else if (isBannerAtTop) {
                            params2.addRule(RelativeLayout.ALIGN_PARENT_TOP);

                        } else {
                            params2.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM);
                        }

                        if (adViewLayout == null) {
                            adViewLayout = new RelativeLayout(cordova.getActivity());
                            RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);
                            if (CORDOVA_4) {
                                ((ViewGroup) webView.getView().getParent()).addView(adViewLayout, params);
                            } else {
                                ((ViewGroup) webView).addView(adViewLayout, params);
                            }
                        }
                        adViewLayout.addView(adView, params2);
                        adViewLayout.bringToFront();

                    } else {
                        if (CORDOVA_4) {
                            ViewGroup wvParentView = (ViewGroup) webView.getView().getParent();

                            if (parentView == null) {
                                parentView = new LinearLayout(webView.getContext());
                            }

                            if (wvParentView != null && wvParentView != parentView) {
                                wvParentView.removeView(webView.getView());
                                ((LinearLayout) parentView).setOrientation(LinearLayout.VERTICAL);
                                parentView.setLayoutParams(new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, 0.0F));
                                webView.getView().setLayoutParams(new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT, 1.0F));
                                parentView.addView(webView.getView());
                                cordova.getActivity().setContentView(parentView);
                            }

                        } else {
                            parentView = (ViewGroup) ((ViewGroup) webView).getParent();
                        }

                        if (isBannerAtTop) {
                            parentView.addView(adView, 0);
                        } else {
                            parentView.addView(adView);
                        }
                        parentView.bringToFront();
                        parentView.requestLayout();

                    }

                    adView.setVisibility(View.VISIBLE);
                    isBannerVisible = true;

                } else {
                    adView.setVisibility(View.GONE);
                    isBannerVisible = false;
                }

                if (callbackContext != null) {
                    callbackContext.success();
                }
            }
        });
        return null;
    }

    private PluginResult executeDestroyBannerView(CallbackContext callbackContext) {
        Log.i(ADMOBADS_LOGTAG, "executeDestroyBannerView");
        final CallbackContext delayCallback = callbackContext;
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (adView != null) {
                    ViewGroup parentView = (ViewGroup) adView.getParent();
                    if (parentView != null) {
                        parentView.removeView(adView);
                    }
                    adView.destroy();
                    adView = null;
                }
                isBannerVisible = false;
                isBannerRequested = false;
                delayCallback.success();
            }
        });
        return null;
    }

    private String getInterstitialId() {
        return interstitialAdId;
    }

    private void createInterstitialView(String _iid, AdMobAdsAdListener adListener) {
        interstitialAd = new InterstitialAd(cordova.getActivity());
        interstitialAd.setAdUnitId(_iid);
        interstitialAd.setAdListener(adListener);
        interstitialAd.loadAd(buildAdRequest());
    }

    private PluginResult executeCreateInterstitialView(JSONObject options, final CallbackContext callbackContext) {
        this.setOptions(options);
        final String _iid = getInterstitialId();
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                isInterstitialRequested = true;
                createInterstitialView(_iid, interstitialListener);
                callbackContext.success();
            }
        });
        return null;
    }

    private PluginResult executeRequestInterstitialAd(JSONObject options, final CallbackContext callbackContext) {
        if (isInterstitialAvailable) {
            interstitialListener.onAdLoaded();
            callbackContext.success();

        } else {
            this.setOptions(options);
            if (interstitialAd == null) {
                return executeCreateInterstitialView(options, callbackContext);

            } else {
                cordova.getActivity().runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        interstitialAd.loadAd(buildAdRequest());
                        callbackContext.success();
                    }
                });
            }
        }
        return null;
    }

    private PluginResult executeShowInterstitialAd(CallbackContext callbackContext) {
        return showInterstitialAd(callbackContext);
    }

    protected PluginResult showInterstitialAd(final CallbackContext callbackContext) {
        if (interstitialAd == null) {
            return new PluginResult(Status.ERROR, "interstitialAd is null, call createInterstitialView first.");
        }
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (interstitialAd.isLoaded()) {
                    isInterstitialRequested = false;
                    interstitialAd.show();
                }
                if (callbackContext != null) {
                    callbackContext.success();
                }
            }
        });
        return null;
    }

    private String getRewardedId() {
        return rewardedAdId;
    }

    private void createRewardedView(String _rid, AdMobAdsRewardedAdListener rewardedListener) {
        rewardedAd = MobileAds.getRewardedVideoAdInstance(cordova.getActivity());
        rewardedAd.setRewardedVideoAdListener(rewardedListener);
        rewardedAd.loadAd(_rid, buildAdRequest());
    }

    private PluginResult executeCreateRewardedView(JSONObject options, final CallbackContext callbackContext) {
        this.setOptions(options);
        final String _rid = getRewardedId();
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                isRewardedRequested = true;
                createRewardedView(_rid, rewardedListener);
                callbackContext.success();
            }
        });
        return null;
    }

    private PluginResult executeRequestRewardedAd(JSONObject options, final CallbackContext callbackContext) {
        this.setOptions(options);
        if (rewardedAd == null) {
            return executeCreateRewardedView(options, callbackContext);
        } else {
            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    rewardedAd.loadAd(rewardedAdId, buildAdRequest());
                    callbackContext.success();
                }
            });
        }
        return null;
    }

    private PluginResult executeShowRewardedAd(CallbackContext callbackContext) {
        return showRewardedAd(callbackContext);
    }

    protected PluginResult showRewardedAd(final CallbackContext callbackContext) {
        if (rewardedAd == null) {
            return new PluginResult(Status.ERROR, "rewardedAd is null, call requestRewardedAd first.");
        }
        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (rewardedAd.isLoaded()) {
                    isRewardedRequested = false;
                    rewardedAd.show();
                }
                if (callbackContext != null) {
                    callbackContext.success();
                }
            }
        });
        return null;
    }

    @Override
    public void onConnectivityChanged(String interfaceType, boolean isConnected, String observer) {
        if (!isConnected) {
            isNetworkActive = false;
        } else if (!isNetworkActive) {
            isNetworkActive = true;

            if (isBannerRequested) {
                final String _pid = getPublisherId();
                createBannerView(_pid, bannerListener);
            }

            if (isInterstitialRequested) {
                if (isInterstitialAvailable) {
                    interstitialListener.onAdLoaded();
                } else {
                    if (interstitialAd == null) {
                        final String _iid = getInterstitialId();
                        cordova.getActivity().runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                isInterstitialRequested = true;
                                createInterstitialView(_iid, interstitialListener);
                            }
                        });

                    } else {
                        cordova.getActivity().runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                interstitialAd.loadAd(buildAdRequest());
                            }
                        });
                    }
                }
            }

            if (isRewardedRequested) {
                if (isRewardedAvailable) {
                    rewardedListener.onRewardedVideoAdLoaded();
                } else {
                    final String _rid = getRewardedId();
                    if (rewardedAd == null) {
                        cordova.getActivity().runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                isRewardedRequested = true;
                                createRewardedView(_rid, rewardedListener);
                            }
                        });
                    } else {
                        cordova.getActivity().runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                rewardedAd.loadAd(_rid, buildAdRequest());
                            }
                        });
                    }
                }
            }
        }
    }

    /**
     * Gets an AdSize object from the string size passed in from JavaScript. Returns null if an improper string is provided.
     *
     * @param size The string size representing an ad format constant.
     * @return An AdSize object used to create a banner.
     */
    public static AdSize adSizeFromString(String size) {
        if ("BANNER".equals(size)) {
            return AdSize.BANNER;
        } else if ("IAB_MRECT".equals(size)) {
            return AdSize.MEDIUM_RECTANGLE;
        } else if ("IAB_BANNER".equals(size)) {
            return AdSize.FULL_BANNER;
        } else if ("IAB_LEADERBOARD".equals(size)) {
            return AdSize.LEADERBOARD;
        } else if ("SMART_BANNER".equals(size)) {
            return AdSize.SMART_BANNER;
        } else {
            return AdSize.SMART_BANNER;
        }
    }

    public static final String md5(final String s) {
        try {
            MessageDigest digest = java.security.MessageDigest.getInstance("MD5");
            digest.update(s.getBytes());
            byte messageDigest[] = digest.digest();
            StringBuilder hexString = new StringBuilder();
            for (byte i : messageDigest) {
                String h = Integer.toHexString(0xFF & i);
                while (h.length() < 2) {
                    h = "0" + h;
                }
                hexString.append(h);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
        }
        return "";
    }

    public static DisplayMetrics DisplayInfo(Context p_context) {
        DisplayMetrics metrics = null;
        try {
            metrics = new DisplayMetrics();
            ((android.view.WindowManager) p_context.getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay().getMetrics(metrics);
            //p_activity.getWindowManager().getDefaultDisplay().getMetrics(metrics);
        } catch (Exception e) {
        }
        return metrics;
    }

    public static double DeviceInches(Context p_context) {
        double default_value = 4.0f;
        if (p_context == null)
            return default_value;
        try {
            DisplayMetrics metrics = DisplayInfo(p_context);
            return Math.sqrt(Math.pow(metrics.widthPixels / metrics.xdpi, 2.0) + Math.pow(metrics.heightPixels / metrics.ydpi, 2.0));
        } catch (Exception e) {
            return default_value;
        }
    }
}
