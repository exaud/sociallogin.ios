/*
 *  ProfileScreen.m
 *  Profile screen class
 *  TestAppMacOSX
 *
 *  Facebook, Google+, LinkedIn, Twitter, VK, OK login library test application for Mac OS X
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

#import "ProfileScreen.h"

@interface ProfileScreen ()

@property (nonatomic, retain) NSString *text;
@property (unsafe_unretained) IBOutlet NSTextView *tvProfile;

@end

@implementation ProfileScreen

- (id)initWithText:(NSString *)text
{
    self = [super initWithWindowNibName:@"ProfileScreen"];
    if (self) {
        self.text = text;
    }
    return self;
}

- (IBAction)bnCloseClick:(id)sender
{
    [NSApp stopModal];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    _tvProfile.string = self.text;
    [NSApp runModalForWindow:self.window];
}

- (BOOL)windowShouldClose:(id)sender
{
    [NSApp stopModal];
    return YES;
}

@end