/*
 * ND2D - A Flash Molehill GPU accelerated 2D engine
 *
 * Author: Lars Gerckens
 * Copyright (c) nulldesign 2011
 * Repository URL: http://github.com/nulldesign/nd2d
 * Getting started: https://github.com/nulldesign/nd2d/wiki
 *
 *
 * Licence Agreement
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package de.nulldesign.nd2d.display {

    import de.nulldesign.nd2d.geom.Face;
    import de.nulldesign.nd2d.geom.UV;
    import de.nulldesign.nd2d.geom.Vertex;
    import de.nulldesign.nd2d.materials.Sprite2DMaterial;

    import flash.display.BitmapData;
    import flash.display3D.textures.Texture;

    public class Grid2D extends Sprite2D {

        protected var stepsX:uint;
        protected var stepsY:uint;
        protected var vertexList:Vector.<Vertex>;

        public function Grid2D(stepsX:uint, stepsY:uint, textureObject:Object = null) {
            this.stepsX = stepsX;
            this.stepsY = stepsY;
            super(textureObject);
            generateGrid();
        }

        override public function get numTris():uint {
            return faceList.length;
        }

        protected function generateGrid():void {
            faceList = new Vector.<Face>();
            vertexList = new Vector.<Vertex>();

            var i:uint;
            var j:uint;

            var ar:Array = [];
            var v:Vertex;

            var uv:Array = [];
            var u:UV;

            for(i = 0; i <= stepsX; i++) {
                ar.push([]);
                uv.push([]);
                for(j = 0; j <= stepsY; j++) {
                    var x:Number = i * (2 / stepsX) - 2 / 2;
                    var y:Number = j * (2 / stepsY) - 2 / 2;

                    v = new Vertex(x, y, 0.0);
                    vertexList.push(v);
                    ar[i].push(v);

                    u = new UV((x + 2 * 0.5) / 2, (y + 2 * 0.5) / 2);
                    //uvList.push(u);
                    uv[i].push(u);
                }
            }

            for(i = 1; i < ar.length; i++) {
                for(j = 1; j < ar[i].length; j++) {
                    faceList.push(new Face(ar[i - 1][j - 1], ar[i - 1][j], ar[i][j], uv[i - 1][j - 1], uv[i - 1][j],
                                           uv[i][j]));

                    faceList.push(new Face(ar[i - 1][j - 1], ar[i][j], ar[i][j - 1], uv[i - 1][j - 1], uv[i][j],
                                           uv[i][j - 1]));
                }
            }
        }
    }
}
