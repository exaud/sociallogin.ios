/*
 *  Util.h
 *  Utilities
 *  SocialLogin
 *
 *  Facebook, Google+, LinkedIn, Twitter, VK, OK login library for iOS and Mac OS X
 *
 *  Copyright (c) 2013 Exaud, Lda. All rights reserved.
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 *
 */

#import <Foundation/Foundation.h>
#import "SocialLoginDelegate.h"

#define FB_TOKEN @"fb_access_token"
#define FB_TOKEN_LIFETIME @"fb_token_lifetime"

@interface Util : NSObject

+ (NSString *)stringBetweenString:(NSString *)start andString:(NSString *)end innerString:(NSString *)str;
+ (NSString *) genRandString;
+ (NSDictionary *) getUrlParams:(NSURL *)uri;
+ (NSDictionary *) getParams:(NSString *)str;

+ (NSString *)getValidFBToken;
+ (void)getValidGPPToken:(NSString *)appID secretKey:(NSString *)secret completion:(void(^)(NSString *))handler;
+ (NSString *)getValidLNToken;
+ (NSDictionary *)getValidVKCred;
+ (NSDictionary *)getTWCredentials;
+ (void)getValidODKToken:(NSString *)appID secretKey:(NSString *)secret completion:(void(^)(NSString *))handler;

+ (void)handlingVKLogin:(NSURL *)uri delegate:(id <SocialLoginDelegate>) delegate clientOnly:(BOOL)clientOnly;
+ (void)handlingFBLogin:(NSURL *)uri delegate:(id <SocialLoginDelegate>) delegate;
+ (void)twitterLogin:(NSString *)appID consumerSecret:(NSString *)secret completion:(void(^)(NSString *))completion;
+ (NSString *)getE2E;

+ (void)getTWAccessToken:(NSString*)oauth_token
                 verifier:(NSString*)oauth_verifier
              consumerKey:(NSString*)appID
           consumerSecret:(NSString*)secret
              completion:(void (^)(BOOL,NSDictionary*)) completion;

+ (void)getAccessToken:(int)lType
                   code:(NSString*)code
                  appID:(NSString*)appID
              secretKey:(NSString*)secret
            redirectUri:(NSString*)redirectUri
               delegate:(id <SocialLoginDelegate>) delegate;

+ (void) twReverseAuth:(NSString*)appKey secretKey:(NSString*)secretKey account:(NSString*)account completion:(void (^)(BOOL,NSDictionary*)) completion;

+ (void)resetTWAuthorization;
+ (void)resetVKAuthorization;
+ (void)resetODKAuthorization;
+ (void)resetFBAuthorization;
+ (void)resetGPPAuthorization;
+ (void)resetLNAuthorization;
+ (BOOL)checkInternetConnction;

@end