/*
 *  SocialLoginController.m
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

#import "SocialLoginController.h"
#import "OAuth.h"

@interface SocialLoginController ()

@property (nonatomic, retain) NSString *appID;

@end

@implementation SocialLoginController

#define TW_CRED @"TWCredentials"

@synthesize delegate;
@synthesize webView;
@synthesize appID;
@synthesize secretKey;
@synthesize isClientOnly;
@synthesize redirectUri;

BOOL isTwitterLoginSuccess = NO;

- (id)initWithLogin:(socialLoginType)l appKey:(NSString *)appKey
{
    self = [super initWithWindowNibName:@"SocialLoginController"];
    if (self) {
        lType = l;
        self.appID = appKey;
    }
    return self;
}

- (id)initWithTWLogin:(NSString *)appKey secretKey:(NSString *)twSKey
{
    self = [super initWithWindowNibName:@"SocialLoginController"];
    if (self) {
        lType = kLoginTwitter;
        self.appID = appKey;
        self.secretKey = twSKey;
    }
    return self;
}

- (void) cancel
{
    [self.window close];
    [NSApp stopModal];
    
    if([delegate respondsToSelector:@selector(socialLoginCancel)])
        [delegate socialLoginCancel];
}

- (void) error:(NSError*)error
{
    if (error.code == NSURLErrorCancelled) {
        return;
	}
    
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]) {
        return;
	}
    
    NSLog(@"login Error: %@", [error localizedDescription]);
    
    [self.window close];
    [NSApp stopModal];
    
	[delegate socialLoginCompleted:NO credentials:nil loginType:lType];
}

- (void) startModal
{
    self.shouldCloseDocument = YES;
    NSModalSession session = [NSApp beginModalSessionForWindow:self.window];
    
    NSInteger result = NSRunContinuesResponse;
    while (result == NSRunContinuesResponse)
    {
        @autoreleasepool {
            result = [NSApp runModalSession:session];
            [[NSRunLoop currentRunLoop] limitDateForMode:NSDefaultRunLoopMode];
            
            [NSThread sleepForTimeInterval:0.05];
        }
    }
    [NSApp endModalSession:session];
}

- (void) twitterLogin
{
    [Util twitterLogin:self.appID consumerSecret:self.secretKey completion:^(NSString* link){
        if (link) {
            [webView setMainFrameURL:link];
        }
        else {
            [self.delegate socialLoginCompleted:NO credentials:nil loginType:kLoginTwitter];
            [self.window close];
            [NSApp stopModal];
        }
    }];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    if (!self.appID) {
        return;
    }
    
    NSString *urlStr = nil;
    
    switch (lType) {
            
        case kLoginTwitter: {
            [[NSRunLoop mainRunLoop] performSelector:@selector(twitterLogin) target:self argument:nil order:0 modes:@[NSDefaultRunLoopMode]];
            [self startModal];
            return;
		}
            
        case kLoginVK: {
            NSString *rType = (isClientOnly) ? @"token" : @"code";
            urlStr = [NSString stringWithFormat:@"https://oauth.vk.com/authorize?client_id=%@&redirect_uri=%@&display=mobile&response_type=%@", self.appID,self.redirectUri,rType];
            break;
        }
            
        case kLoginODK: {
            urlStr = [NSString stringWithFormat:@"https://www.odnoklassniki.ru/oauth/authorize?client_id=%@&response_type=code&redirect_uri=%@&layout=m",self.appID,self.redirectUri];
            break;
		}
            
        case kLoginGPP: {
            self.redirectUri = @"http://localhost";
            urlStr = [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/auth?"
                      @"response_type=code&client_id=%@"
                      @"&scope=https://www.googleapis.com/auth/plus.login&redirect_uri=%@",self.appID,self.redirectUri];
            break;
		}
            
        case kLoginLinkedIn: {
            self.redirectUri = @"http://localhost";
            urlStr = [NSString stringWithFormat:
                      @"https://www.linkedin.com/uas/oauth2/authorization?response_type=code"
                      @"&client_id=%@"
                      @"&state=%@"
                      @"&redirect_uri=%@",self.appID,[Util genRandString],self.redirectUri];
            break;
		}
            
        case kLoginFacebook: {
            self.redirectUri = @"fbconnect://success";
            urlStr = [NSString stringWithFormat:@"https://m.facebook.com/dialog/oauth?display=touch&e2e=%@"
                      @"&client_id=%@&type=user_agent&redirect_uri=%@"
                      @"&state=%@&response_type=token&scope=publish_actions",[Util getE2E],
                      self.appID,self.redirectUri,[Util genRandString]];
            break;
		}
    }
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [webView setMainFrameURL:urlStr];
    [self startModal];
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener {
    
    NSURL *URL = [request URL];
    NSString *absoluteString = [URL absoluteString];
    
    if (self.redirectUri && [absoluteString hasPrefix:self.redirectUri])
    {
        switch (lType) {
            case kLoginFacebook: {
                [listener ignore];
                [self cancel];
                [Util handlingFBLogin:URL delegate:self.delegate];
                return;
			}
                
            case kLoginVK: {
                [listener ignore];
                [self cancel];
                [Util handlingVKLogin:URL delegate:self.delegate clientOnly:isClientOnly];
                return;
			}
        }
        if ([absoluteString rangeOfString:@"code="].location != NSNotFound) {
            NSString *code = [Util stringBetweenString:@"code="
                                             andString:@"&"
                                           innerString:absoluteString];
            NSLog(@"login response: %@",absoluteString);
            if (code) {
                NSLog(@"Code: %@",code);
                if (isClientOnly) {
                    [listener ignore];
                    [self cancel];
                    [Util getAccessToken:lType
                                    code:code
                                   appID:self.appID
                               secretKey:self.secretKey
                             redirectUri:self.redirectUri
                                delegate:delegate];
                }
                else {
                    [listener ignore];
                    [self cancel];
                    [delegate socialLoginCompleted:YES credentials:@{@"token":code} loginType:lType];
				}
            }
            else {
                NSLog(@"login zero code: %@", absoluteString);
                [listener ignore];
                [self cancel];
                [delegate socialLoginCompleted:NO credentials:nil loginType:lType];
            }
            
        } else if ([absoluteString rangeOfString:@"error"].location != NSNotFound) {
            NSLog(@"login error: %@", absoluteString);
            [listener ignore];
            [self cancel];
            [delegate socialLoginCompleted:NO credentials:nil loginType:lType];
        }
        
    }
    else
        switch (lType) {
            case kLoginTwitter:
                if([[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] == WebNavigationTypeFormSubmitted) {
                    NSString *Body = [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] autorelease];
                    if ([Body rangeOfString:@"&cancel"].location != NSNotFound) {
                        [listener ignore];
                        [self cancel];
                        if([delegate respondsToSelector:@selector(socialLoginCancel)])
                            [delegate socialLoginCancel];
                    }
                }
                else if (([absoluteString rangeOfString:@"oauth_token="].location != NSNotFound) &&
                         [absoluteString rangeOfString:@"&oauth_verifier="].location != NSNotFound) {
                    NSDictionary *dic = [Util getUrlParams:URL];
                    NSString *oauth_token = dic[@"oauth_token"];
                    NSString *oauth_verifier = dic[@"oauth_verifier"];
                    
                    isTwitterLoginSuccess = YES;
                    
                    if (isClientOnly) {
                        [listener ignore];
                        [Util getTWAccessToken:oauth_token
                                      verifier:oauth_verifier
                                   consumerKey:self.appID
                                consumerSecret:self.secretKey
                                    completion:^(BOOL isSuccess, NSDictionary *credentials) {
                                        [self cancel];
                                        [delegate socialLoginCompleted:isSuccess
                                                           credentials:credentials
                                                             loginType:lType];
                                    }];
                    }
                    
                    else {
                        [listener ignore];
                        [self cancel];
                        [delegate socialLoginCompleted:YES credentials:@{@"token":oauth_token,@"oauth_verifier":oauth_verifier}
                                             loginType:lType];
                    }
                    return;
                }
                break;
                
            case kLoginVK:
                if ([absoluteString rangeOfString:@"cancel=1"].location != NSNotFound) {
                    [listener ignore];
                    [self cancel];
                }
                break;
                
            default:
                break;
        }
    [listener use];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    [self error:error];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    [self error:error];
}

- (BOOL)windowShouldClose:(id)sender
{
    [NSApp stopModal];
    return YES;
}

- (void)dealloc
{
    [delegate release];
    [appID release];
    [webView release];
    [super dealloc];
}

@end