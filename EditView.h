/** @file       EditView.h
 *  @brief      Class that handles the bitmap editor view object.
 *  @copyright  (c) 2006 Alquanto. All Rights Reserved.
 */
#import <Cocoa/Cocoa.h>
#import "NeoFontEditor.h"

@interface EditView : NSView
{
    IBOutlet NeoFontEditor *neoFontEditor;
    bool isFirstResponder;

    struct {
        int pixelState;
        int lastX;
        int lastY;
    } drag;
    
    bool highlightRow[kNeoCharacterMaxHeight];
}

- (BOOL) acceptsFirstResponder;

@end
