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
    import de.nulldesign.nd2d.materials.ASpriteSheetBase;
    import de.nulldesign.nd2d.materials.Sprite2DMaskMaterial;
    import de.nulldesign.nd2d.materials.Sprite2DMaterial;
    import de.nulldesign.nd2d.materials.SpriteSheet;
    import de.nulldesign.nd2d.materials.Texture2D;
    import de.nulldesign.nd2d.utils.TextureHelper;

    import flash.display.BitmapData;

    import flash.display3D.Context3D;
    import flash.display3D.textures.Texture;

    /**
     * <p>2D sprite class</p>
     * One draw call is used per sprite.
     * If you have a lot of sprites with the same texture / spritesheet try to use a Sprite2DCould, it will be a lot faster.
     */
    public class Sprite2D extends Node2D {

        protected var faceList:Vector.<Face>;
        protected var mask:Sprite2D;

        public var texture:Texture2D;
        public var spriteSheet:ASpriteSheetBase;
        public var material:Sprite2DMaterial;

        /**
         * Constructor of class Sprite2D
         * @param textureObject can be a BitmapData or Texture2D
         */
        public function Sprite2D(textureObject:Object = null) {
            faceList = TextureHelper.generateQuadFromDimensions(2, 2);

            var tex:Texture2D;
            if(textureObject is BitmapData) {
                tex = Texture2D.textureFromBitmapData(textureObject as BitmapData);
				trace("Setting constructor argument in a Sprite2D as a BitmapData is depricated. Please pass a Texture2D object to the constructor. Create Texture2D object from a BitmapData by using the static method: Texture2D.textureFromBitmapData()");
            } else if(textureObject is Texture2D) {
                tex = textureObject as Texture2D;
            } else if(textureObject != null) {
                throw new Error("textureObject has to be a BitmapData or a Texture2D");
            }

            if(textureObject) {
                setMaterial(new Sprite2DMaterial());
                setTexture(tex);
            }
        }

        public function setSpriteSheet(value:ASpriteSheetBase):void {
            this.spriteSheet = value;

            if(spriteSheet) {
                _width = spriteSheet.spriteWidth;
                _height = spriteSheet.spriteHeight;
            }
        }

        public function setTexture(value:Texture2D):void {

            if(texture) {
                texture.cleanUp();
            }

            this.texture = value;

            if(texture && !spriteSheet) {
                _width = texture.bitmapWidth;
                _height = texture.bitmapHeight;
            }
        }

        public function setMaterial(value:Sprite2DMaterial):void {

            if(material) {
                material.dispose();
            }

            this.material = value;
        }

        public function setMask(mask:Sprite2D):void {

            this.mask = mask;

            if(mask) {
                setMaterial(new Sprite2DMaskMaterial());
            } else {
                setMaterial(new Sprite2DMaterial());
            }
        }

        override public function get numTris():uint {
            return 2;
        }

        override public function get drawCalls():uint {
            return material ? material.drawCalls : 0;
        }

        /**
         * @private
         */
        override internal function stepNode(elapsed:Number):void {

            super.stepNode(elapsed);

            if(spriteSheet) {
                spriteSheet.update(timeSinceStartInSeconds);
                _width = spriteSheet.spriteWidth;
                _height = spriteSheet.spriteHeight;
            }
        }

        override public function handleDeviceLoss():void {
            super.handleDeviceLoss();
            if(material)
                material.handleDeviceLoss();
        }

        override protected function draw(context:Context3D, camera:Camera2D):void {

            material.blendMode = blendMode;
            material.modelMatrix = worldModelMatrix;
            material.projectionMatrix = camera.projectionMatrix;
            material.viewProjectionMatrix = camera.getViewProjectionMatrix();
            material.colorTransform = combinedColorTransform;
            material.spriteSheet = spriteSheet;
            material.texture = texture;

            if(mask) {

                if(mask.invalidateMatrix) {
                    mask.updateLocalMatrix();
                }

                var maskMat:Sprite2DMaskMaterial = Sprite2DMaskMaterial(material);
                maskMat.maskTexture = mask.texture;
                maskMat.maskModelMatrix = mask.localModelMatrix;
                maskMat.maskAlpha = mask.alpha;
            }

            material.render(context, faceList, 0, faceList.length);
        }

        override public function dispose():void {
            if(material) {
                material.dispose();
                material = null;
            }

            if(texture) {
                texture.cleanUp();
                texture = null;
            }

            super.dispose();
        }
    }
}