//
//  FaceOffsetTool.m
//  TrenchBroom
//
//  Created by Kristian Duske on 05.02.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FaceOffsetTool.h"
#import "Face.h"
#import "Vector2f.h"
#import "Vector3f.h"
#import "Math.h"
#import "SelectionManager.h"
#import "Ray3D.h"
#import "HalfSpace3D.h"
#import "Plane3D.h"
#import "FaceOffsetFigure.h"
#import "Options.h"
#import "Math.h"

static NSString* MoveLeftKey = @"Move Texture Left";
static NSString* MoveRightKey = @"Move Texture Right";
static NSString* MoveUpKey = @"Move Texture Up";
static NSString* MoveDownKey = @"Move Texture Down";

@implementation FaceOffsetTool

- (void)updateDefaults:(NSDictionary *)defaults {
    moveLeftKey = [[defaults objectForKey:MoveLeftKey] intValue];
    moveRightKey = [[defaults objectForKey:MoveRightKey] intValue];
    moveUpKey = [[defaults objectForKey:MoveUpKey] intValue];
    moveDownKey = [[defaults objectForKey:MoveDownKey] intValue];
}

- (BOOL)face:(Face *)theFace hitByRay:(Ray3D *)theRay {
    Plane3D* plane = [[theFace halfSpace] boundary];
    Vector3f* is = [plane intersectWithRay:theRay];
    if (is == nil)
        return NO;
    
    [is sub:[theFace center]];
    return flte([is lengthSquared], 121);
}

- (void)drag:(Ray3D *)theRay {
    Plane3D* plane = [[draggedFace halfSpace] boundary];
    Vector3f* is = [plane intersectWithRay:theRay];
    if (is == nil)
        return;
    
    int d = [options gridSize];
    if (![options snapToGrid] ^ ([NSEvent modifierFlags] & NSShiftKeyMask) != 0)
        d = 1;
    
    Vector3f* surfacePos = [draggedFace surfaceCoordsOf:is];
    int dx = ((int)([surfacePos x] - [lastSurfacePos x])) / d;
    int dy = ((int)([surfacePos y] - [lastSurfacePos y])) / d;

    if (dx != 0 || dy != 0) {
        NSEnumerator* faceEn = [faces objectEnumerator];
        Face* face;
        while ((face = [faceEn nextObject]))
            [face translateOffsetsX:dx * d y:dy * d];
    }

    if (dx != 0)
        [lastSurfacePos setX:[surfacePos x]];
    
    if (dy != 0)
        [lastSurfacePos setY:[surfacePos y]];
    
}

- (void)keyDown:(NSEvent *)theEvent {
    int keyCode = [theEvent keyCode];
    int d = [options gridSize];

    if (![options snapToGrid] ^ ([theEvent modifierFlags] & NSShiftKeyMask) != 0)
        d = 1;
    
    NSEnumerator* faceEn = [faces objectEnumerator];
    Face* face;
    if (keyCode == moveLeftKey)
        while ((face = [faceEn nextObject]))
            [face translateOffsetsX:-d y:0];
    else if (keyCode == moveRightKey)
        while ((face = [faceEn nextObject]))
            [face translateOffsetsX:d y:0];
    else if (keyCode == moveUpKey)
        while ((face = [faceEn nextObject]))
            [face translateOffsetsX:0 y:d];
    else if (keyCode == moveDownKey)
        while ((face = [faceEn nextObject]))
            [face translateOffsetsX:0 y:-d];
    else
        NSLog(@"unknown key code: %i", [theEvent keyCode]);
}

- (id)createFigure:(Face *)face {
    return [[[FaceOffsetFigure alloc] initWithFace:face] autorelease];
}

@end
