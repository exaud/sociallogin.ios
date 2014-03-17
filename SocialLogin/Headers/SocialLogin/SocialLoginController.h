/*
 *  SocialLoginController.h
 *  Login UIViewController
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

#import "Util.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

    @interface SocialLoginController : UIViewController <UIWebViewDelegate> {
#else
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
        
    @interface SocialLoginController : NSWindowController {
#endif
        id delegate;
        BOOL isTwitter;
        BOOL isClientOnly;
        int lType;
        NSString *redirectUri;
        NSString *secretKey;
    }
        
#if TARGET_OS_IPHONE
        @property (nonatomic, retain) UIWebView *webView;
#else
        @property (nonatomic, retain) IBOutlet WebView *webView;
#endif
        
    @property (nonatomic, retain) id <SocialLoginDelegate> delegate;
    @property (nonatomic, retain) NSString *redirectUri;
    @property (nonatomic, readwrite) BOOL isClientOnly;
    @property (nonatomic, retain) NSString *secretKey;
    
    - (id)initWithLogin:(socialLoginType)loginType appKey:(NSString *)appKey;
    - (id)initWithTWLogin:(NSString *)appKey secretKey:(NSString *)twSKey;
        
#if TARGET_OS_IPHONE
    - (void)showModal;
#endif
        
@end