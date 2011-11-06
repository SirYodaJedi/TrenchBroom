/*
Copyright (C) 2010-2011 Kristian Duske

This file is part of TrenchBroom.

TrenchBroom is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

TrenchBroom is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with TrenchBroom.  If not, see <http://www.gnu.org/licenses/>.
*/

#import "MoveTool.h"
#import "Grid.h"
#import "Options.h"
#import "Camera.h"
#import "MapWindowController.h"
#import "MapDocument.h"
#import "SelectionManager.h"
#import "PickingHit.h"
#import "PickingHitList.h"
#import "Face.h"
#import "Brush.h"
#import "Entity.h"
#import "MutableBrush.h"
#import "math.h"
#import "Renderer.h"
#import "MapView3D.h"
#import "ControllerUtils.h"
#import "EditingSystem.h"
#import "MoveToolFeedbackFigure.h"
#import "CameraOrbitAnimation.h"

@interface MoveTool (private)

- (BOOL)isAlternatePlaneModifierPressed;
- (void)updateMoveDirectionWithRay:(const TRay *)theRay;

@end

@implementation MoveTool (private)

- (BOOL)isAlternatePlaneModifierPressed {
    return [NSEvent modifierFlags] == NSAlternateKeyMask;
}

- (void)updateMoveDirectionWithRay:(const TRay *)theRay {
    [editingSystem release];
    
    Camera* camera = [windowController camera];
    if (fabsf(theRay->direction.z) > 0.3f) {
        if ([self isAlternatePlaneModifierPressed]) {
            moveDirection = MD_LR_UD;
            editingSystem = [[camera verticalEditingSystem] retain];
        } else {
            moveDirection = MD_LR_FB;
            editingSystem = [[camera horizontalEditingSystem] retain];
        }
    } else {
        if ([self isAlternatePlaneModifierPressed]) {
            moveDirection = MD_LR_FB;
            editingSystem = [[camera horizontalEditingSystem] retain];
        } else {
            moveDirection = MD_LR_UD;
            editingSystem = [[camera verticalEditingSystem] retain];
        }
    }
}

@end

@implementation MoveTool

- (id)initWithWindowController:(MapWindowController *)theWindowController {
    if ((self = [self init])) {
        windowController = theWindowController;
    }
    return self;
}

# pragma mark -
# pragma mark @implementation Tool

- (void)handleFlagsChanged:(NSEvent *)event ray:(TRay *)ray hits:(PickingHitList *)hits {
    [self updateMoveDirectionWithRay:ray];
    
    float dist = [editingSystem intersectWithRay:ray planePosition:&editingPoint];
    rayPointAtDistance(ray, dist, &lastPoint);
    
    [feedbackFigure setEditingSystem:editingSystem];
    [feedbackFigure setPoint:&lastPoint];
    [feedbackFigure setMoveDirection:moveDirection];

    [[windowController view3D] setNeedsDisplay:YES];
}

- (void)beginLeftDrag:(NSEvent *)event ray:(TRay *)ray hits:(PickingHitList *)hits {
    PickingHit* hit = [hits firstHitOfType:HT_ENTITY | HT_FACE ignoreOccluders:YES];
    if (hit == nil)
        return;
    
    SelectionManager* selectionManager = [windowController selectionManager];
    if ([hit type] == HT_FACE) {
        id <Face> face = [hit object];
        id <Brush> brush = [face brush];
        
        if (![selectionManager isBrushSelected:brush])
            return;
    } else {
        id <Entity> entity = [hit object];
        
        if (![selectionManager isEntitySelected:entity])
            return;
    }

    [self updateMoveDirectionWithRay:ray];
    
    lastPoint = *[hit hitPoint];
    editingPoint = lastPoint;
    
    Grid* grid = [[windowController options] grid];
    feedbackFigure = [[MoveToolFeedbackFigure alloc] initWithArrowLength:[grid actualSize]];
    
    [feedbackFigure setEditingSystem:editingSystem];
    [feedbackFigure setPoint:&lastPoint];
    [feedbackFigure setMoveDirection:moveDirection];
    
    Renderer* renderer = [windowController renderer];
    [renderer addFeedbackFigure:feedbackFigure];
    
    MapDocument* map = [windowController document];
    NSUndoManager* undoManager = [map undoManager];
    [undoManager setGroupsByEvent:NO];
    [undoManager beginUndoGrouping];

    drag = YES;
}

- (void)leftDrag:(NSEvent *)event ray:(TRay *)ray hits:(PickingHitList *)hits {
    if (!drag)
        return;
    
    float dist = [editingSystem intersectWithRay:ray planePosition:&editingPoint];
    if (isnan(dist))
        return;
    
    TVector3f point;
    rayPointAtDistance(ray, dist, &point);
    
    TVector3f deltaf;
    subV3f(&point, &lastPoint, &deltaf);
    
    Options* options = [windowController options];
    Grid* grid = [options grid];
    
    MapDocument* map = [windowController document];
    TBoundingBox* worldBounds = [map worldBounds];

    TBoundingBox bounds;
    SelectionManager* selectionManager = [map selectionManager];
    [selectionManager selectionBounds:&bounds];

    calculateMoveDelta(grid, &bounds, worldBounds, &deltaf, &lastPoint);
    
    if (nullV3f(&deltaf))
        return;
    
    TVector3i deltai;
    roundV3f(&deltaf, &deltai);
    
    [map translateBrushes:[selectionManager selectedBrushes] delta:deltai lockTextures:[options lockTextures]];
    [map translateEntities:[selectionManager selectedEntities] delta:deltai];

    if (feedbackFigure != nil)
        [feedbackFigure setPoint:&lastPoint];
}

- (void)endLeftDrag:(NSEvent *)event ray:(TRay *)ray hits:(PickingHitList *)hits {
    if (!drag)
        return;
    
    MapDocument* map = [windowController document];
    NSUndoManager* undoManager = [map undoManager];
    [undoManager setActionName:[self actionName]];
    [undoManager endUndoGrouping];
    [undoManager setGroupsByEvent:YES];
    
    if (feedbackFigure != nil) {
        Renderer* renderer = [windowController renderer];
        [renderer removeFeedbackFigure:feedbackFigure];
        [feedbackFigure release];
        feedbackFigure = nil;
    }
    
    [editingSystem release];
    editingSystem = nil;

    drag = NO;
}

- (NSString *)actionName {
    return @"Move Objects";
}

@end
