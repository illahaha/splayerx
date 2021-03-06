/*
 * MPlayerX - TitleView.m
 *
 * Copyright (C) 2009 Zongyao QU
 * 
 * MPlayerX is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * MPlayerX is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with MPlayerX; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "TitleView.h"

NSString *kStringDots = @"...";

@interface TitleView (TitleViewInternal)
-(void) windowDidBecomKey:(NSNotification*) notif;
-(void) windowDidResignKey:(NSNotification*) notif;
@end

@implementation TitleView

@synthesize title;

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	
    if (self) {
		NSUInteger styleMask = NSTitledWindowMask|NSResizableWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
		
		closeButton = [[NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:styleMask] retain];
		miniButton  = [[NSWindow standardWindowButton:NSWindowMiniaturizeButton forStyleMask:styleMask] retain];
		zoomButton  = [[NSWindow standardWindowButton:NSWindowZoomButton forStyleMask:styleMask] retain];
			
		title = nil;
		titleAttr = [[NSDictionary alloc]
					 initWithObjectsAndKeys:
					 [NSColor whiteColor], NSForegroundColorAttributeName,
					 [NSFont titleBarFontOfSize:12], NSFontAttributeName,
					 nil];
		frame.size.width = 64;
		frame.size.height = 20;
		frame.origin.x = 1;
		frame.origin.y = 1;
      
    
    trackArea = [[NSTrackingArea alloc] initWithRect:frame
                                               options:(NSTrackingMouseEnteredAndExited |
                                                        NSTrackingActiveAlways)
                                                 owner:self
                                              userInfo:nil];
		//[self addTrackingArea:trackArea];
    }
    return self;
}

- (void)mouseEntered:(NSEvent *)theEvent
{
  [self enableButtons];
 
  
}

- (void)mouseExited:(NSEvent *)theEvent
{
  
}
-(void) dealloc
{
	// [self removeTrackingArea:trackArea];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[trackArea release];
	
	[title release];
	[titleAttr release];
	
	[closeButton release];
	[miniButton release];
	[zoomButton release];
	
	[tbCornerLeft release];
	[tbCornerRight release];
	[tbMiddle release];
	
	[super dealloc];
}
#define BUTTONALPHA 1
-(void) awakeFromNib
{
	[self addSubview:closeButton];
	[closeButton setFrameOrigin:NSMakePoint(9.0, 2.0)];
	[closeButton setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];
	[closeButton setAlphaValue:BUTTONALPHA];
  
	[self addSubview:miniButton];
	[miniButton setFrameOrigin:NSMakePoint(30.0, 2.0)];
	[miniButton setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];
	[miniButton setAlphaValue:BUTTONALPHA];
	
	[self addSubview:zoomButton];
	[zoomButton setFrameOrigin:NSMakePoint(51.0, 2.0)];
	[zoomButton setAutoresizingMask:NSViewMaxXMargin|NSViewMaxYMargin];
	[zoomButton setAlphaValue:BUTTONALPHA];
  
  [closeButton setEnabled:NO];
	[miniButton setEnabled:NO];
	[zoomButton setEnabled:NO];
	
	tbCornerLeft = [[NSImage imageNamed:@"titlebar-corner-left.png"] retain];
	tbCornerRight= [[NSImage imageNamed:@"titlebar-corner-right.png"] retain];
	tbMiddle = [[NSImage imageNamed:@"titlebar-middle.png"] retain];

  [self enableButtons];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidBecomKey:)
												 name:NSWindowDidBecomeKeyNotification
											   object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidResignKey:)
												 name:NSWindowDidResignKeyNotification
											   object:[self window]];
  [self display];
}

-(void) mouseUp:(NSEvent *)theEvent
{
	if ([theEvent clickCount] == 2) {
		[[self window] performMiniaturize:self];
	}
}

- (void)drawRect:(NSRect)dirtyRect
{	
	NSSize leftSize = [tbCornerLeft size];
	NSSize rightSize = [tbCornerRight size];
	NSSize titleSize = [self bounds].size;
	NSPoint drawPos;
	
	drawPos.x = 0;
	drawPos.y = 0;
	
	dirtyRect.origin.x = 0;
	dirtyRect.origin.y = 0;

	dirtyRect.size = leftSize;
	[tbCornerLeft drawAtPoint:drawPos fromRect:dirtyRect operation:NSCompositeCopy fraction:0.9];
	
	drawPos.x = titleSize.width - rightSize.width;
	dirtyRect.size = rightSize;
	[tbCornerRight drawAtPoint:drawPos fromRect:dirtyRect operation:NSCompositeCopy fraction:0.9];
	
	dirtyRect.size = [tbMiddle size];
	[tbMiddle drawInRect:NSMakeRect(leftSize.width, 0, titleSize.width-leftSize.width-rightSize.width, titleSize.height)
				fromRect:dirtyRect
			   operation:NSCompositeCopy
				fraction:0.9];

	if (title) {
		NSMutableString *renderStr = [title mutableCopy];
		NSSize dotSize = [kStringDots sizeWithAttributes:titleAttr];
		NSSize strSize = [renderStr sizeWithAttributes:titleAttr];
		float widthMax = titleSize.width - 80;
		
		if (strSize.width > widthMax) {
			// the title less than 3 characters should be never longer than widMax,
			// so it is safe to delete the first three chars, without checking
			[renderStr deleteCharactersInRange:NSMakeRange(0, 2)];
			
			while (dotSize.width + strSize.width > widthMax) {
				[renderStr deleteCharactersInRange:NSMakeRange(0, 1)];
				strSize = [renderStr sizeWithAttributes:titleAttr];
			}
			[renderStr insertString:kStringDots	atIndex:0];
		}

		dirtyRect.size = [renderStr sizeWithAttributes:titleAttr];
		
		drawPos.x = MAX(70, (titleSize.width -dirtyRect.size.width)/2);
		drawPos.y = (titleSize.height - dirtyRect.size.height)/2;
		
		[renderStr drawAtPoint:drawPos withAttributes:titleAttr];
		[renderStr release];
	}
}

-(void)enableButtons
{
  [closeButton setEnabled:YES];
	[miniButton setEnabled:YES];
	[zoomButton setEnabled:YES];
  [closeButton highlight:YES];
  [closeButton highlight:NO];
  [miniButton highlight:YES];
  [miniButton highlight:NO];
  [zoomButton highlight:YES];
  [zoomButton highlight:NO];
  
  [closeButton setNeedsDisplay];
  [closeButton needsPanelToBecomeKey];
}

-(void) windowDidBecomKey:(NSNotification*) notif
{
	[self enableButtons];
}

-(void) windowDidResignKey:(NSNotification*) notif
{
  [closeButton setEnabled:NO];
	[miniButton setEnabled:NO];
	[zoomButton setEnabled:NO];
}

@end
