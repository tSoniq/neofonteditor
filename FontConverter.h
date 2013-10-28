//
//  FontConverter.h
//  NeoFontEditor
//
//  Created by Mark on 19/07/2006.
//  Copyright 2006 Alquanto. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NeoFont.h"

@interface FontConverter : NSObject {

    NSMutableDictionary *textAttributes;                    /**< Font face attributes. */
}

+ (float) pixelHeightOfFont:(NSFont*)font;
+ (void) loadFont:(NeoFont*)neo from:(NSFont*)system;

@end
