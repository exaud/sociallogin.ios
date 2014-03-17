/*
 *  SocialLogin.h
 *  Main class
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

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#else
#import <Foundation/Foundation.h>
#endif

#import "SocialLoginDelegate.h"

@interface SocialLogin : NSObject

+ (void)publishFBAppKey:(NSString *)key;
+ (void)publishVKAppKey:(NSString *)key;
+ (void)publishODKAppKey:(NSString *)key;
+ (void)publishTWAppKey:(NSString *)key secretKey:(NSString *)secretKey;
+ (void)publishGPPAppKey:(NSString *)key;
+ (void)publishLNAppKey:(NSString *)key;
+ (void)publishODKSecretKey:(NSString *)key;
+ (void)publishGPPSecretKey:(NSString *)key;
+ (void)publishLNSecretKey:(NSString *)key;

+ (void)publishODKRedirectUri:(NSString *)uri;
+ (void)publishVKRedirectUri:(NSString *)uri;

+ (void)fbLogin:(id <SocialLoginDelegate>)delegate;
+ (void)vkLogin:(id <SocialLoginDelegate>)delegate clientOnly:(BOOL)clientOnly;
+ (void)odkLogin:(id <SocialLoginDelegate>)delegate clientOnly:(BOOL)clientOnly;
+ (void)twLogin:(id <SocialLoginDelegate>)delegate clientOnly:(BOOL)clientOnly;
+ (void)closeLoginSession;
+ (void)postOnFacebook:(NSString *)name address:(NSString *)address site:(NSString *)site
                picURL:(NSString *)picURL message:(NSString *)message;

+ (void)gppLogin:(id <SocialLoginDelegate>) delegate clientOnly:(BOOL)clientOnly;
+ (void)lnLogin:(id <SocialLoginDelegate>) delegate clientOnly:(BOOL)clientOnly;

+ (BOOL)handleFBLogin:(NSURL *)uri;

+ (void)resetAuthorization;

@end