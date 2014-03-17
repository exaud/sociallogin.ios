/*
 *  Util.m
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

#import "Util.h"
#import "OAuth.h"
#import "ASIHTTPRequest.h"
#import "Reachability.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>

#if TARGET_OS_MACOS
#import <AppKit/AppKit.h>
#endif

#define TW_CRED @"TWCredentials"
#define ODK_CRED @"ODKCredentials"
#define VK_CRED @"VKCredentials"
#define GPP_CRED @"GPPCredentials"
#define LN_CRED @"LinkedInCredentials"

#define LIFETIME @"expires_in"
#define TOKEN @"access_token"

@implementation Util

+ (BOOL)validateFBToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:FB_TOKEN_LIFETIME])
    {
        long lifetime = [[defaults objectForKey:FB_TOKEN_LIFETIME] longValue];
        long timestamp = [[NSDate date] timeIntervalSince1970];
        if (timestamp < lifetime)
		{
            return YES;
		}
    }
	
    return NO;
}

+ (NSString *)getValidFBToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:FB_TOKEN];
    if (token && [Util validateFBToken])
	{
        return token;
	}
	
    return nil;
}

+ (NSString *)stringBetweenString:(NSString *)start
                       andString:(NSString *)end
                     innerString:(NSString *)str
{
    NSScanner* scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    if ([scanner scanString:start intoString:NULL]) {
        NSString* result = nil;
        if ([scanner scanUpToString:end intoString:&result])
		{
            return result;
        }
    }
	
    return nil;
}

+ (NSString *)genRandString
{
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:19];
    
    for (int i=0; i<19; i++) {
        [randomString appendFormat:@"%C",[letters characterAtIndex:arc4random() % [letters length]]];
	}
    
    return randomString;
}

+ (NSDictionary *)getUrlParams:(NSURL *)uri
{
    NSString *fragment = [uri.fragment stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (!fragment)
	{
        fragment = [uri.query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
    
    NSArray *params = [fragment componentsSeparatedByString:@"&"];
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    for (NSString *param in params) {
        NSArray *kv = [param componentsSeparatedByString:@"="];
        values[kv[0]] = kv[1];
    }
	
    return values;
}

+ (NSDictionary *)getParams:(NSString *)str
{
    NSArray *params = [str componentsSeparatedByString:@"&"];
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    for (NSString *param in params) {
        NSArray *kv = [param componentsSeparatedByString:@"="];
        values[kv[0]] = kv[1];
    }
    
	return values;
}

+ (void)handlingFBLogin:(NSURL *)uri delegate:(id <SocialLoginDelegate>) delegate
{
    NSDictionary *params = [self getUrlParams:uri];
    
    NSString *error = params[@"error"];
    if (!error)
	{
        error = params[@"error_type"];
	}
    if (!error)
	{
        error = params[@"error_code"];
	}
    
    if (error)
    {
        if (([error compare:@"access_denied" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
           ([error compare:@"OAuthAccessDeniedException" options:NSCaseInsensitiveSearch] == NSOrderedSame))
        {
            if ([delegate respondsToSelector:@selector(socialLoginCancel)])
			{
                [delegate socialLoginCancel];
			}
        }
        else
		{
            [delegate socialLoginCompleted:NO credentials:nil loginType:kLoginFacebook];
		}
		
        NSLog(@"%@",params[@"error_message"]);
    }
    else
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:params[TOKEN] forKey:FB_TOKEN];
        int timestamp = [params[LIFETIME] intValue];
        [defaults setObject:[NSNumber numberWithLong:[[NSDate date] timeIntervalSince1970] + timestamp]
                     forKey:FB_TOKEN_LIFETIME];
        [defaults synchronize];
        [delegate socialLoginCompleted:YES credentials:@{@"token":params[TOKEN]} loginType:kLoginFacebook];
    }
}

+ (void)handlingVKLogin:(NSURL *)uri delegate:(id <SocialLoginDelegate>) delegate clientOnly:(BOOL)clientOnly
{
    NSDictionary *params = [self getUrlParams:uri];
    NSString *error = params[@"error"];
    if (error)
	{
        [delegate socialLoginCompleted:NO credentials:nil loginType:kLoginVK];
	}
    else if(clientOnly)
    {
        [Util saveSocialCredentials:kLoginVK credentials:params];
        [delegate socialLoginCompleted:YES credentials:@{@"token": params[TOKEN],@"user_id": params[@"user_id"]} loginType:kLoginVK];
    }
    else
	{
        [delegate socialLoginCompleted:YES credentials:@{@"token": params[@"code"]} loginType:kLoginVK];
	}
}

#if !TARGET_OS_IPHONE
+ (void) twitterLoginLink:(NSDictionary *)params
{
    void (^completion)(NSString *) = params[@"completion"];
    
    ASIHTTPRequest *request = params[@"request"];
    NSError *error = request.error;
    if (!error)
    {
        NSDictionary *dic = [self getParams:request.responseString];
        NSString *link = [NSString stringWithFormat:@"https://api.twitter.com/oauth/authenticate?oauth_token=%@",
                          dic[@"oauth_token"]];
        completion(link);
    }
    else
    {
        completion(nil);
    }
}
#endif

+ (void)twitterLogin:(NSString *)appID consumerSecret:(NSString *)secret completion:(void (^)(NSString *))completion
{
    OAuth *oauth = [[OAuth alloc] initWithConsumerKey:appID
                                    andConsumerSecret:secret];
    
    NSString *url = @"https://api.twitter.com/oauth/request_token";
    NSDictionary *params = @{@"oauth_callback": @""};
	NSString *oauth_header = [oauth oAuthHeaderForMethod:@"POST" andUrl:url andParams:params];
    [oauth release];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    request.requestMethod = @"POST";
    [request addRequestHeader:@"Authorization" value:oauth_header];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [request startSynchronous];
#if !TARGET_OS_IPHONE
        NSDictionary *dic = @{@"request": request,@"completion": completion};
        [[NSRunLoop mainRunLoop] performSelector:@selector(twitterLoginLink:) target:self argument:dic order:0 modes:@[NSDefaultRunLoopMode]];
#else
        dispatch_sync(dispatch_get_main_queue(), ^{
             NSError *error = request.error;
            if (!error)
			{
                NSDictionary *dic = [self getParams:request.responseString];
                NSString *link = [NSString stringWithFormat:@"https://api.twitter.com/oauth/authenticate?oauth_token=%@",
                                  dic[@"oauth_token"]];
                completion(link);
            }
            else
			{
                completion(nil);
			}
        });
#endif
    });
}

+ (NSString *)getE2E
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"{\"init\":%.0f}",interval];
}

#if !TARGET_OS_IPHONE
+ (void) twAccessToken:(NSDictionary *)params
{
    void (^completion)(BOOL,NSDictionary*) = params[@"completion"];
    NSDictionary *dic = params[@"dic"];
    if(dic)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:dic forKey:TW_CRED];
        [defaults synchronize];
        completion(YES,@{@"token": dic[@"oauth_token"], @"token_secret": dic[@"oauth_token_secret"]});
    }
    else
    {
        completion(NO,nil);
    }
}
#endif

+ (void)getTWAccessToken:(NSString *)oauth_token
                 verifier:(NSString *)oauth_verifier
              consumerKey:(NSString *)appID
           consumerSecret:(NSString *)secret
                 completion:(void (^)(BOOL,NSDictionary*)) completion
{
    OAuth *oauth = [[OAuth alloc] initWithConsumerKey:appID
                                    andConsumerSecret:secret];
    
    NSDictionary *params = @{@"oauth_token":oauth_token};
    NSString *url = @"https://api.twitter.com/oauth/access_token";
    NSString *oauth_header = [oauth oAuthHeaderForMethod:@"POST"
                                                  andUrl:url
                                               andParams:params];
    [oauth release];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    request.requestMethod = @"POST";
     [request addRequestHeader:@"Authorization" value:oauth_header];
    [request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    
    NSString *body = [NSString stringWithFormat:@"oauth_verifier=%@", oauth_verifier];
    request.postBody = [NSMutableData dataWithData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    request.contentLength = request.postBody.length;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [request startSynchronous];
		
        if (!request.error)
        {
            NSDictionary *dic = [Util getParams:request.responseString];
#if !TARGET_OS_IPHONE
            [[NSRunLoop mainRunLoop] performSelector:@selector(twAccessToken:) target:self
                                            argument:@{@"dic":dic,
                                                       @"completion":completion}
                                               order:0 modes:@[NSDefaultRunLoopMode]];
#else
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:dic forKey:TW_CRED];
                [defaults synchronize];
                completion(YES,@{@"token": dic[@"oauth_token"], @"token_secret": dic[@"oauth_token_secret"]});
            });
#endif
        }
        else
		{
            NSLog(@"%@", request.error);
#if !TARGET_OS_IPHONE
            [[NSRunLoop mainRunLoop] performSelector:@selector(twAccessToken:) target:self
                                            argument:@{@"completion":completion}
                                               order:0 modes:@[NSDefaultRunLoopMode]];
#else
            dispatch_sync(dispatch_get_main_queue(), ^{
                completion(NO,nil);
            });
#endif
		}
    });
}

+ (NSDictionary *)getTWCredentials
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:TW_CRED];
}

+ (BOOL)checkSocialToken:(long)lifetime
{
    long timestamp = [[NSDate date] timeIntervalSince1970];
    return (timestamp < lifetime);
}

+ (void)getValidGPPToken:(NSString *)appID secretKey:(NSString *)secret completion:(void(^)(NSString *))handler
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   __block NSDictionary *credentials = [defaults objectForKey:GPP_CRED];
    if (credentials)
    {
        if([Util checkSocialToken:[credentials[LIFETIME] longValue]])
		{
            handler(credentials[TOKEN]);
		}
        else
        {
            NSString *link = @"https://accounts.google.com/o/oauth2/token";
            NSString *body = [NSString stringWithFormat:
                    @"&client_id=%@"
                    @"&client_secret=%@"
                    @"&refresh_token=%@"
                    @"&grant_type=refresh_token",appID,secret,credentials[@"refresh_token"]];
            
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:link]];
            request.requestMethod = @"POST";
            [request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
            request.postBody = [NSMutableData dataWithData:[[body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                dataUsingEncoding:NSUTF8StringEncoding]];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [request startSynchronous];
                
                NSError *error = request.error;
                if (!error)
                {
                    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:request.responseData options:NSJSONReadingAllowFragments error:&error];
                    if (!error)
                    {
                        NSString *token = dic[TOKEN];
                        long life = [dic[LIFETIME] longValue];
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:credentials];
                            mDic[TOKEN] = token;
                            mDic[LIFETIME] = @([[NSDate date] timeIntervalSince1970] + life);
                            credentials = mDic;
                            [defaults setObject:credentials forKey:GPP_CRED];
                            [defaults synchronize];
                            handler(token);
                        });
                    }
                    else
                    {
                        NSLog(@"%@", error);
                        handler(nil);
                    }
                }
                else
                {
                    NSLog(@"%@", error);
                    handler(nil);
                }
            });
        }
    }
    else
	{
        handler(nil);
	}
}

+ (NSString *)getValidLNToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *credentials = [defaults objectForKey:LN_CRED];
    if (credentials)
    {
        if ([Util checkSocialToken:[credentials[LIFETIME] longValue]])
		{
            return credentials[TOKEN];
		}
    }
	
    return nil;
}

+ (NSDictionary *)getValidVKCred
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *credentials = [defaults objectForKey:VK_CRED];
    if (credentials)
    {
        if([Util checkSocialToken:[credentials[LIFETIME] longValue]])
		{
            return @{@"token": credentials[TOKEN],@"user_id": credentials[@"user_id"]};
		}
    }
	
    return nil;
}

+ (void)getValidODKToken:(NSString *)appID secretKey:(NSString *)secret completion:(void(^)(NSString *))handler
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *credentials = [defaults objectForKey:ODK_CRED];
    if (credentials)
    {
        if(![Util checkSocialToken:[credentials[@"refresh_token_livetime"] longValue]]) {
            handler(nil);
            return;
        }
        
        if ([Util checkSocialToken:[credentials[LIFETIME] longValue]])
		{
            handler(credentials[TOKEN]);
		}
        else
        {
            NSString *link = @"https://api.odnoklassniki.ru/oauth/token.do";
            NSString *body = [NSString stringWithFormat:
                              @"&client_id=%@"
                              @"&client_secret=%@"
                              @"&refresh_token=%@"
                              @"&grant_type=refresh_token",appID,secret,credentials[@"refresh_token"]];
            
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:link]];
            request.requestMethod = @"POST";
            [request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
            request.postBody = [NSMutableData dataWithData:[[body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                            dataUsingEncoding:NSUTF8StringEncoding]];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [request startSynchronous];
                
                NSError *error = request.error;
                if (!error)
                {
                    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:request.responseData
                                                                        options:NSJSONReadingAllowFragments
                                                                          error:&error];
                    if (!error)
                    {
                        NSString *token = dic[TOKEN];
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithDictionary:credentials];
                            mDic[TOKEN] = token;
                            mDic[LIFETIME] = @([[NSDate date] timeIntervalSince1970] + 1800);
                            [defaults setObject:mDic forKey:ODK_CRED];
                            [defaults synchronize];
                            handler(token);
                        });
                    }
                    else
                    {
                        NSLog(@"%@",error);
                        handler(nil);
                    }
                }
                else
                {
                    NSLog(@"%@",error);
                    handler(nil);
                }
            });
        }
    }
    else
	{
        handler(nil);
	}
}

+ (void)saveSocialCredentials:(int)lType credentials:(NSDictionary *)credentials
{
    NSString *key = nil;
    switch (lType) {
        case kLoginODK: {
            key = ODK_CRED;
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:credentials];
            dic[LIFETIME] = @([[NSDate date] timeIntervalSince1970] + 1800);
            dic[@"refresh_token_livetime"] = @([[NSDate date] timeIntervalSince1970] + 2592000);
            [dic removeObjectForKey:@"token_type"];
            credentials = dic;
            break;
        }
            
        case kLoginVK: {
            key = VK_CRED;
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:credentials];
            dic[LIFETIME] = @([[NSDate date] timeIntervalSince1970] + [credentials[LIFETIME] intValue]);
            credentials = dic;
            break;
        }
            
        case kLoginGPP: {
            key = GPP_CRED;
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:credentials];
            dic[LIFETIME] = @([[NSDate date] timeIntervalSince1970] + [credentials[LIFETIME] longValue]);
            [dic removeObjectForKey:@"id_token"];
            [dic removeObjectForKey:@"token_type"];
            credentials = dic;
            break;
        }
            
        case kLoginLinkedIn: {
            key = LN_CRED;
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:credentials];
            dic[LIFETIME] = @([[NSDate date] timeIntervalSince1970] + [credentials[LIFETIME] longValue]);
            credentials = dic;
            break;
        }
    }
    if (key)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:credentials forKey:key];
        [defaults synchronize];
    }
}

+ (void)getAccessToken:(int)lType
                   code:(NSString *)code
                  appID:(NSString *)appID
              secretKey:(NSString *)secret
            redirectUri:(NSString *)redirectUri
               delegate:(id <SocialLoginDelegate>)delegate
{
    NSString *link = nil;
    NSString *body = nil;
    
    switch (lType) {
        case kLoginODK: {
            link = @"http://api.odnoklassniki.ru/oauth/token.do";
            break;
		}
            
        case kLoginGPP: {
            link = @"https://accounts.google.com/o/oauth2/token";
            break;
		}
            
        case kLoginLinkedIn: {
            link = @"https://www.linkedin.com/uas/oauth2/accessToken";
            break;
		}
    }
    
    body = [NSString stringWithFormat:@"code=%@"
            @"&client_id=%@"
            @"&client_secret=%@"
            @"&redirect_uri=%@"
            @"&grant_type=authorization_code",code,appID,secret,redirectUri];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:link]];
    request.requestMethod = @"POST";
    [request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    request.postBody = [NSMutableData dataWithData:[[body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                    dataUsingEncoding:NSUTF8StringEncoding]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [request startSynchronous];
        
        NSError *error = request.error;
        if (!error)
        {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:request.responseData
                                                                options:NSJSONReadingAllowFragments
                                                                  error:&error];
            if (!error)
            {
                NSString *token = [dic objectForKey:TOKEN];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [Util saveSocialCredentials:lType credentials:dic];
                    [delegate socialLoginCompleted:YES credentials:@{@"token":token} loginType:lType];
                });
            }
            else
			{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    NSLog(@"%@",error);
                    [delegate socialLoginCompleted:NO credentials:nil loginType:lType];
                });
			}
        }
        else
		{
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSLog(@"%@",error);
                [delegate socialLoginCompleted:NO credentials:nil loginType:lType];
            });
		}
        
    });
    
}

+ (void)resetTWAuthorization
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *credentials = [defaults objectForKey:TW_CRED];
    if (credentials)
    {
        [defaults removeObjectForKey:TW_CRED];
        [defaults synchronize];
    }
}

+ (void)resetVKAuthorization
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *credentials = [defaults objectForKey:VK_CRED];
    if (credentials)
    {
        [defaults removeObjectForKey:VK_CRED];
        [defaults synchronize];
    }
}

+ (void)resetODKAuthorization
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *credentials = [defaults objectForKey:ODK_CRED];
    if (credentials)
    {
        [defaults removeObjectForKey:ODK_CRED];
        [defaults synchronize];
    }
}

+ (void)resetFBAuthorization
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:FB_TOKEN];
    if (token)
    {
        [defaults removeObjectForKey:FB_TOKEN];
        [defaults removeObjectForKey:FB_TOKEN_LIFETIME];
        [defaults synchronize];
    }
}

+ (void)resetGPPAuthorization
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *credentials = [defaults objectForKey:GPP_CRED];
    if (credentials)
    {
        [defaults removeObjectForKey:GPP_CRED];
        [defaults synchronize];
    }
}

+ (void)resetLNAuthorization
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *credentials = [defaults objectForKey:LN_CRED];
    if (credentials)
    {
        [defaults removeObjectForKey:LN_CRED];
        [defaults synchronize];
    }
}

+ (BOOL)checkInternetConnction
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    if (![reachability isReachable])
    {
#if TARGET_OS_IPHONE
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:NSLocalizedString(@"No Internet connection", @"")
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
#else
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"No Internet connection", @"")
                                         defaultButton:@"OK"
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@""];
        [alert runModal];
#endif
        return NO;
    }

    return YES;
}

+ (void) twReverseAuth:(NSString*)appKey secretKey:(NSString*)secretKey account:(NSString*)account completion:(void (^)(BOOL,NSDictionary*)) completion
{
    NSString *url = @"https://api.twitter.com/oauth/request_token";
    NSDictionary *params = @{@"x_auth_mode" : @"reverse_auth"};
    OAuth *oauth = [[OAuth alloc] initWithConsumerKey:appKey
                                    andConsumerSecret:secretKey];
    NSString *oauth_header = [oauth oAuthHeaderForMethod:@"POST"
                                                  andUrl:url
                                               andParams:params];
    [oauth release];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    request.requestMethod = @"POST";
    [request addRequestHeader:@"Authorization" value:oauth_header];
    
    [request addRequestHeader:@"Content-Type" value:@"application/x-www-form-urlencoded"];
    NSString *body = @"x_auth_mode=reverse_auth";
    request.postBody = [NSMutableData dataWithData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    request.contentLength = request.postBody.length;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [request startSynchronous];
        
        if(!request.error)
        {
            NSDictionary *stepTwoParams = [[NSMutableDictionary alloc] init];
            [stepTwoParams setValue:appKey forKey:@"x_reverse_auth_target"];
            [stepTwoParams setValue:request.responseString forKey:@"x_reverse_auth_parameters"];
            
            SLRequest *stepTwoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST
                                                                     URL:[NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"]
                                                              parameters:stepTwoParams];
            
            ACAccountStore *accountStore = [[ACAccountStore alloc] init];
            stepTwoRequest.account = [accountStore accountWithIdentifier:account];
            [accountStore release];
            
            [stepTwoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                NSString *response = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                if(([response rangeOfString:@"error"].location != NSNotFound) || error)
                {
                    NSLog(@"%@",response);
                    dispatch_sync(dispatch_get_main_queue(), ^(){
                        completion(NO,nil);
                    });
                }
                else
                {
                    NSDictionary *dic = [Util getParams:response];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setObject:dic forKey:TW_CRED];
                        [defaults synchronize];
                        completion(YES,@{@"token": dic[@"oauth_token"], @"token_secret": dic[@"oauth_token_secret"]});
                    });
                }
                [response release];
            }];
        }
        else
        {
            NSLog(@"%@",request.error);
            completion(NO,nil);
        }
    });
}

@end