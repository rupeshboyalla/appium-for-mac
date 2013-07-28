//
//  AppiumMacController.m
//  AppiumAppleScriptProxy
//
//  Created by Dan Cuellar on 7/28/13.
//  Copyright (c) 2013 Appium. All rights reserved.
//

#import "AppiumMacHandler.h"
#import "NSData+Base64.h"
#import "Utility.h"

@implementation AppiumMacHandler
- (id)init
{
    self = [super init];
    if (self) {
        [self setSessions:[NSMutableDictionary new]];
        [self setSystemEvents:[SBApplication applicationWithBundleIdentifier:@"com.apple.systemevents"]];
    }
    return self;
}

-(GCDWebServerDataResponse*) respondWithJson:(id)json status:(int)status session:(NSString*)session
{
    NSDictionary *responseJson = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:status], @"status", session, @"session", json, @"data", nil];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseJson
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (!jsonData)
    {
        NSLog(@"Got an error: %@", error);
        jsonData = [NSJSONSerialization dataWithJSONObject:
                    [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:-1], @"status", session, @"session", [NSString stringWithFormat:@"%@", error], @"data" , nil]
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    }
    return [GCDWebServerDataResponse responseWithData:jsonData contentType:@"application/json"];
}

// GET /status
-(GCDWebServerDataResponse*) getStatus
{
    NSDictionary *buildJson = [NSDictionary dictionaryWithObjectsAndKeys:[Utility bundleVersion], @"version", [Utility bundleRevision], @"revision", [NSNumber numberWithInt:[Utility unixTimestamp]], @"time", nil];
    NSDictionary *osJson = [NSDictionary dictionaryWithObjectsAndKeys:[Utility arch], @"arch", @"Mac OS X", @"name", [Utility version], @"version", nil];
    NSDictionary *json = [NSDictionary dictionaryWithObjectsAndKeys:buildJson, @"build", osJson, @"os", nil];
    return [self respondWithJson:json status:0 session:@""];
}

// POST /session
-(GCDWebServerDataResponse*) postSession:(GCDWebServerRequest*)request
{
    // generate new session key
    NSString *newSession = [Utility randomStringOfLength:8];
    while ([self.sessions objectForKey:newSession] != nil)
    {
        newSession = [Utility randomStringOfLength:8];
    }
    
    // TODO: Add capabilities support
    // set empty capabilities for now
    [self.sessions setValue:@"" forKey:newSession];
    
    // respond with the session
    return [self respondWithJson:[self.sessions objectForKey:newSession] status:0 session: newSession];
}

// GET /sessions
-(GCDWebServerDataResponse*) getSessions
{
    // respond with the session
    NSMutableArray *json = [NSMutableArray new];
    for(id key in self.sessions)
    {
        [json addObject:[NSDictionary dictionaryWithObjectsAndKeys:key, @"id", [self.sessions objectForKey:key], @"capabilities", nil]];
    }
    
    return [self respondWithJson:json status:0 session: @""];
}

// GET /session/:sessionId
-(GCDWebServerDataResponse*) getSession:(GCDWebServerRequest*)request
{
    NSString *sessionId = [Utility getSessionFromRequest:request];
    // TODO: show error if session does not exist
    return [self respondWithJson:[self.sessions objectForKey:sessionId] status:0 session:sessionId];
}

// DELETE /session/:sessionId
-(GCDWebServerDataResponse*) deleteSession:(GCDWebServerRequest*)request
{
    NSString *sessionId = [Utility getSessionFromRequest:request];
    [self.sessions removeObjectForKey:sessionId];
    return [self respondWithJson:nil status:0 session: sessionId];
}

// /session/:sessionId/timeouts
// /session/:sessionId/timeouts/async_script
// /session/:sessionId/timeouts/implicit_wait
// /session/:sessionId/window_handle
// /session/:sessionId/window_handles
// /session/:sessionId/url
// /session/:sessionId/forward
// /session/:sessionId/back
// /session/:sessionId/refresh
// /session/:sessionId/execute
// /session/:sessionId/execute_async

// GET /session/:sessionId/screenshot
-(GCDWebServerDataResponse*) getScreenshot:(GCDWebServerRequest*)request
{
    system([@"/usr/sbin/screencapture -c" UTF8String]);
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSArray *classArray = [NSArray arrayWithObject:[NSImage class]];
    NSDictionary *options = [NSDictionary dictionary];
    
    BOOL foundImage = [pasteboard canReadObjectForClasses:classArray options:options];
    if (foundImage)
    {
        NSArray *objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        NSImage *image = [objectsToPaste objectAtIndex:0];
        NSString *base64Image = [[image TIFFRepresentation] base64EncodedString];
        return [self respondWithJson:base64Image status:0 session: [Utility getSessionFromRequest:request]];
    }
    else
    {
        return [self respondWithJson:nil status:0 session: [Utility getSessionFromRequest:request]];   
    }
}

// /session/:sessionId/ime/available_engines
// /session/:sessionId/ime/active_engine
// /session/:sessionId/ime/activated
// /session/:sessionId/ime/deactivate
// /session/:sessionId/ime/activate
// /session/:sessionId/frame
// /session/:sessionId/window
// /session/:sessionId/window/:windowHandle/size
// /session/:sessionId/window/:windowHandle/position
// /session/:sessionId/window/:windowHandle/maximize
// /session/:sessionId/cookie
// /session/:sessionId/cookie/:name
// /session/:sessionId/source
// /session/:sessionId/title
// /session/:sessionId/element
// /session/:sessionId/elements
// /session/:sessionId/element/active
// /session/:sessionId/element/:id
// /session/:sessionId/element/:id/element
// /session/:sessionId/element/:id/elements
// /session/:sessionId/element/:id/click
// /session/:sessionId/element/:id/submit
// /session/:sessionId/element/:id/text
// /session/:sessionId/element/:id/value
// /session/:sessionId/keys
// /session/:sessionId/element/:id/name
// /session/:sessionId/element/:id/clear
// /session/:sessionId/element/:id/selected
// /session/:sessionId/element/:id/enabled
// /session/:sessionId/element/:id/attribute/:name
// /session/:sessionId/element/:id/equals/:other
// /session/:sessionId/element/:id/displayed
// /session/:sessionId/element/:id/location
// /session/:sessionId/element/:id/location_in_view
// /session/:sessionId/element/:id/size
// /session/:sessionId/element/:id/css/:propertyName
// /session/:sessionId/orientation
// /session/:sessionId/alert_text
// /session/:sessionId/accept_alert
// /session/:sessionId/dismiss_alert
// /session/:sessionId/moveto
// /session/:sessionId/click
// /session/:sessionId/buttondown
// /session/:sessionId/buttonup
// /session/:sessionId/doubleclick
// /session/:sessionId/touch/click
// /session/:sessionId/touch/down
// /session/:sessionId/touch/up
// /session/:sessionId/touch/move
// /session/:sessionId/touch/scroll
// /session/:sessionId/touch/scroll
// /session/:sessionId/touch/doubleclick
// /session/:sessionId/touch/longclick
// /session/:sessionId/touch/flick
// /session/:sessionId/touch/flick
// /session/:sessionId/location
// /session/:sessionId/local_storage
// /session/:sessionId/local_storage/key/:key
// /session/:sessionId/local_storage/size
// /session/:sessionId/session_storage
// /session/:sessionId/session_storage/key/:key
// /session/:sessionId/session_storage/size
// /session/:sessionId/log
// /session/:sessionId/log/types
// /session/:sessionId/application_cache/status

@end