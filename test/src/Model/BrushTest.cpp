/*
 Copyright (C) 2010-2013 Kristian Duske
 
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

#include <gtest/gtest.h>

#include "Model/Brush.h"
#include "Model/BrushFace.h"
#include "Model/Picker.h"

namespace TrenchBroom {
    namespace Model {
        TEST(BrushTest, constructFromBrushFaces) {
            const BBox3 worldBounds(Vec3(-4096.0, -4096.0, -4096.0),
                                    Vec3( 4096.0,  4096.0,  4096.0));
            
            BrushFace::List faces;
            faces.push_back(BrushFace::newBrushFace(Vec3(0.0, 0.0, 0.0),
                                                    Vec3(1.0, 0.0, 0.0),
                                                    Vec3(0.0, 1.0, 0.0)));
            faces.push_back(BrushFace::newBrushFace(Vec3(0.0, 0.0, 0.0),
                                                    Vec3(1.0, 0.0, 0.0),
                                                    Vec3(0.0, 1.0, 0.0)));
            faces.push_back(BrushFace::newBrushFace(Vec3(0.0, 0.0, 0.0),
                                                    Vec3(1.0, 0.0, 0.0),
                                                    Vec3(0.0, 1.0, 0.0)));
            
            Brush::Ptr brush = Brush::newBrush(worldBounds, faces);
            const BrushFace::List& brushBrushFaces = brush->faces();
            ASSERT_EQ(faces.size(), brushBrushFaces.size());
            for (size_t i = 0; i < faces.size(); i++)
                ASSERT_EQ(faces[i], brushBrushFaces[i]);
        }
        
        TEST(BrushTest, pick) {
            const BBox3 worldBounds(Vec3(-4096.0, -4096.0, -4096.0),
                                    Vec3( 4096.0,  4096.0,  4096.0));
            
            // build a cube with length 16 at the origin
            BrushFace::Ptr left = BrushFace::newBrushFace(Vec3(0.0, 0.0, 0.0),
                                                          Vec3(0.0, 1.0, 0.0),
                                                          Vec3(0.0, 0.0, 1.0));
            BrushFace::Ptr right = BrushFace::newBrushFace(Vec3(16.0, 0.0, 0.0),
                                                           Vec3(16.0, 0.0, 1.0),
                                                           Vec3(16.0, 1.0, 0.0));
            BrushFace::Ptr front = BrushFace::newBrushFace(Vec3(0.0, 0.0, 0.0),
                                                           Vec3(0.0, 0.0, 1.0),
                                                           Vec3(1.0, 0.0, 0.0));
            BrushFace::Ptr back = BrushFace::newBrushFace(Vec3(0.0, 16.0, 0.0),
                                                          Vec3(1.0, 16.0, 0.0),
                                                          Vec3(0.0, 16.0, 1.0));
            BrushFace::Ptr top = BrushFace::newBrushFace(Vec3(0.0, 0.0, 16.0),
                                                         Vec3(0.0, 1.0, 16.0),
                                                         Vec3(1.0, 0.0, 16.0));
            BrushFace::Ptr bottom = BrushFace::newBrushFace(Vec3(0.0, 0.0, 0.0),
                                                            Vec3(1.0, 0.0, 0.0),
                                                            Vec3(0.0, 1.0, 0.0));
            
            BrushFace::List faces;
            faces.push_back(left);
            faces.push_back(right);
            faces.push_back(front);
            faces.push_back(back);
            faces.push_back(top);
            faces.push_back(bottom);

            Brush::Ptr brush = Brush::newBrush(worldBounds, faces);
            
            PickResult pickResult1;
            brush->pick(Ray3(Vec3(8.0, -8.0, 8.0), Vec3::PosY), pickResult1);
            ASSERT_EQ(1u, pickResult1.allHits().size());
            
            Hit hit1 = pickResult1.allHits().front();
            ASSERT_DOUBLE_EQ(8.0, hit1.distance());
            BrushFace::Ptr face1 = hit1.object<BrushFace::Ptr>();
            ASSERT_EQ(front, face1);
            
            PickResult pickResult2;
            brush->pick(Ray3(Vec3(8.0, -8.0, 8.0), Vec3::NegY), pickResult2);
            ASSERT_TRUE(pickResult2.allHits().empty());
        }
    }
}
