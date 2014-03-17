/*
 *  FBPoster.m
 *  Simple FB feedback class
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

#import "FBPoster.h"
#import "SocialLoginController.h"
#import "SocialLogin.h"
#import "ASIHTTPRequest.h"

@interface FBPoster ()

@property(nonatomic,retain) NSMutableDictionary *params;

@end

@implementation FBPoster

@synthesize params;

- (id)initWithName:(NSString *)name
           address:(NSString *)address
              site:(NSString *)site
            picURL:(NSString *)picURL
           message:(NSString *)message
{
    self = [super init];
    
	if (self)
	{
        self.params = [NSMutableDictionary dictionary];
		
        if ([message length])
		{
            self.params[@"message"] = [message stringByAppendingFormat:@"\r\n",NSLocalizedString(@"Posted from iPhone",@"")];
		}
        else
		{
            self.params[@"message"] = NSLocalizedString(@"Posted from iPhone",@"");
		}
        
        self.params[@"name"] = name;
        self.params[@"caption"] = address;
        self.params[@"description"] = (site != nil) ? site : @"";
        self.params[@"picture"] = picURL;
    }
	
    return self;
}

- (void)showMessage:(NSString *)message
{
#if TARGET_OS_IPHONE
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
#else
    NSAlert *alert = [NSAlert alertWithMessageText:message
                                     defaultButton:@"OK"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    [alert runModal];
#endif
}

- (void)postToFB
{
    static BOOL isPost = NO; // flag for check is Facebook process sending message running

    if (isPost) // If Facebook process sending message already running, stop sending message in Facebook.
                // Until the process is completed
	{
        return;
	}
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        isPost = YES; // Facebook process sending message running
		
        NSMutableString *body = [NSMutableString string];
        NSString *end = @"\r\n";
        NSString *twoHyphens = @"--";
        NSString *boundary = [Util genRandString];
        
        for (NSString *key in [self.params allKeys]) {
            [body appendFormat:@"%@%@%@",twoHyphens,boundary,end];
            [body appendFormat:@"content-disposition: form-data; name=\"%@\"%@%@", key, end, end];
            [body appendFormat:@"%@%@",[self.params objectForKey:key], end];
        }
        [body appendFormat:@"%@%@%@%@", twoHyphens, boundary, twoHyphens, end];
        
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:@"https://graph.facebook.com/me/feed"]];
        request.requestMethod = @"POST";
        [request addRequestHeader:@"connection" value:@"Keep-Alive"];
        [request addRequestHeader:@"charset" value:@"UTF8"];
        [request addRequestHeader:@"content-type" value:[NSString stringWithFormat:@"multipart/form-data;boundary=%@", boundary]];
        
        request.postBody = [NSMutableData dataWithData:
                            [[body stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                             dataUsingEncoding:NSUTF8StringEncoding]];
        request.contentLength = [request.postBody length];
        [request startSynchronous];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            isPost = NO; // Facebook process sending message completed
			
            NSError *error = [request error];
            
			if (!error)
            {
                NSString *responseString = [[NSString alloc] initWithData:request.responseData encoding:NSUTF8StringEncoding];
                if([responseString rangeOfString:@"error"].location != NSNotFound)
				{
                    [self showMessage:[NSString
                                       stringWithFormat:[NSLocalizedString(@"Failed to send to Facebook, error", @"")
                                stringByAppendingString:@" %@"],
                                       responseString]];
				}
                else
				{
                    [self showMessage:NSLocalizedString(@"Successfully sent to Facebook", @"")];
				}
                
				[responseString release];
            }
            else
			{
                [self showMessage:[NSString
                                   stringWithFormat:[NSLocalizedString(@"Failed to send to Facebook, error", @"")
                                                     stringByAppendingString:@" %@"],
                                   [error localizedDescription]]];
			}
        });
    });
}

- (void)postMessage:(NSString*)token appKey:(NSString*)appKey
{
    if (token)
    {
        params[@"access_token"] = token;
        [self postToFB];
    }
    else
	{
        [SocialLogin fbLogin:self];
	}
}

#pragma mark SocialLogin delegate

- (void)socialLoginCompleted:(BOOL)successful credentials:(NSDictionary*)credentials loginType:(socialLoginType)loginType
{
    if (successful)
    {
        params[@"access_token"] = credentials[@"token"];
        [self postToFB];
    }
    else
	{
        [self showMessage:NSLocalizedString(@"Authorisation error", @"")];
	}
}

@end