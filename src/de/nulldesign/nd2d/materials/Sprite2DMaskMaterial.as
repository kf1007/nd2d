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

package de.nulldesign.nd2d.materials {

    import com.adobe.utils.AGALMiniAssembler;

    import de.nulldesign.nd2d.geom.Face;
    import de.nulldesign.nd2d.geom.UV;
    import de.nulldesign.nd2d.geom.Vertex;
    import de.nulldesign.nd2d.utils.TextureHelper;

    import flash.display.BitmapData;
    import flash.display3D.Context3D;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.display3D.Program3D;
    import flash.display3D.textures.Texture;
    import flash.geom.Matrix3D;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    public class Sprite2DMaskMaterial extends Sprite2DMaterial {

        protected const DEFAULT_VERTEX_SHADER:String = "m44 vt0, va0, vc0              \n" + // vertex(va0) * clipspace
                "m44 vt1, vt0, vc4              \n" + // clipsace to local pos in mask
                "add vt1.xy, vt1.xy, vc8.xy     \n" + // add half masksize to local pos
                "div vt1.xy, vt1.xy, vc8.zw     \n" + // local pos / masksize
                "mov vt2, va1                   \n" + // copy uv
                "mul vt2.xy, vt2.xy, vc9.zw     \n" + // mult with uv-scale
                "add vt2.xy, vt2.xy, vc9.xy     \n" + // add uv offset
                "mov v0, vt2                    \n" + // copy uv
                "mov v1, vt1                    \n" + // copy mask uv
                "mov op, vt0                    \n";  // output position


        protected const DEFAULT_FRAGMENT_SHADER:String =
                "tex ft0, v0, fs0 <2d,clamp,linear,mipnearest>  \n" + // sample texture
                        "mul ft0, ft0, fc0                              \n" + // mult with colorMultiplier
                        "add ft0, ft0, fc1                              \n" + // mult with colorOffset
                        "tex ft1, v1, fs1 <2d,clamp,linear,mipnearest>  \n" + // sample mask

                        "sub ft2, fc2, ft1                              \n" + // (1 - maskcolor)
                        "mov ft3, fc3                                   \n" + // save maskalpha
                        "sub ft3, fc2, ft3                              \n" + // (1 - maskalpha)
                        "mul ft3, ft2, ft3                              \n" + // (1 - maskcolor) * (1 - maskalpha)
                        "add ft3, ft1, ft3                              \n" + // finalmaskcolor = maskcolor + (1 - maskcolor) * (1 - maskalpha));
                        "mul ft0, ft0, ft3                              \n" + // mult mask color with tex color
//                "mul ft0, ft0, ft1                              \n" + // mult mask color with tex color
                "mov oc, ft0                                    \n";  // output color

        public var maskModelMatrix:Matrix3D;
        public var maskTexture:Texture2D;
        public var maskAlpha:Number;

        protected var maskDimensions:Point;
        protected var maskClipSpaceMatrix:Matrix3D = new Matrix3D();

        protected static var maskProgramData:ProgramData;

        public function Sprite2DMaskMaterial() {
            super();
        }

        override public function handleDeviceLoss():void {
            super.handleDeviceLoss();
            maskTexture.texture = null;
            maskProgramData = null;
        }

        override protected function prepareForRender(context:Context3D):void {

            super.prepareForRender(context);

            context.setTextureAt(0, texture.getTexture(context, true));
            context.setTextureAt(1, maskTexture.getTexture(context, true));
            context.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2); // vertex
            context.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2); // uv

            var uvOffsetAndScale:Rectangle = new Rectangle(0.0, 0.0, 1.0, 1.0);

            if(spriteSheet) {

                uvOffsetAndScale = spriteSheet.getUVRectForFrame(texture.textureWidth, texture.textureHeight);

                var offset:Point = spriteSheet.getOffsetForFrame();

                clipSpaceMatrix.identity();
                clipSpaceMatrix.appendScale(spriteSheet.spriteWidth * 0.5, spriteSheet.spriteHeight * 0.5, 1.0);
                clipSpaceMatrix.appendTranslation(offset.x, offset.y, 0.0);
                clipSpaceMatrix.append(modelMatrix);
                clipSpaceMatrix.append(viewProjectionMatrix);

            } else {
                clipSpaceMatrix.identity();
                clipSpaceMatrix.appendScale(texture.textureWidth * 0.5, texture.textureHeight * 0.5, 1.0);
                clipSpaceMatrix.append(modelMatrix);
                clipSpaceMatrix.append(viewProjectionMatrix);
            }

            maskClipSpaceMatrix.identity();
            maskClipSpaceMatrix.append(maskModelMatrix);
            maskClipSpaceMatrix.append(viewProjectionMatrix);
            maskClipSpaceMatrix.invert();

            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, clipSpaceMatrix, true);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, maskClipSpaceMatrix, true);
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, Vector.<Number>([
                maskTexture.bitmapWidth * 0.5,
                maskTexture.bitmapHeight * 0.5,
                maskTexture.bitmapWidth,
                maskTexture.bitmapHeight ]));

            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 9, Vector.<Number>([ uvOffsetAndScale.x,
                uvOffsetAndScale.y,
                uvOffsetAndScale.width,
                uvOffsetAndScale.height]));

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0,
                    Vector.<Number>([ colorTransform.redMultiplier, colorTransform.greenMultiplier, colorTransform
                            .blueMultiplier, colorTransform.alphaMultiplier ]));

            var offsetFactor:Number = 1.0 / 255.0;
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1,
                    Vector.<Number>([ colorTransform.redOffset * offsetFactor, colorTransform.greenOffset * offsetFactor, colorTransform
                            .blueOffset * offsetFactor, colorTransform.alphaOffset * offsetFactor ]));

            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([ 1.0, 1.0, 1.0, 1.0 ]));
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3,
                    Vector.<Number>([ maskAlpha, maskAlpha, maskAlpha, maskAlpha]));
        }

        override protected function clearAfterRender(context:Context3D):void {
            context.setTextureAt(0, null);
            context.setTextureAt(1, null);
            context.setVertexBufferAt(0, null);
            context.setVertexBufferAt(1, null);
            context.setVertexBufferAt(2, null);
        }

        override protected function addVertex(context:Context3D, buffer:Vector.<Number>, v:Vertex, uv:UV, face:Face):void {

            fillBuffer(buffer, v, uv, face, VERTEX_POSITION, 2);
            fillBuffer(buffer, v, uv, face, VERTEX_UV, 2);
        }

        override protected function initProgram(context:Context3D):void {
            if(!maskProgramData) {
                var vertexShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                vertexShaderAssembler.assemble(Context3DProgramType.VERTEX, DEFAULT_VERTEX_SHADER);

                var colorFragmentShaderAssembler:AGALMiniAssembler = new AGALMiniAssembler();
                colorFragmentShaderAssembler.assemble(Context3DProgramType.FRAGMENT, DEFAULT_FRAGMENT_SHADER);

                var program:Program3D = context.createProgram();
                program.upload(vertexShaderAssembler.agalcode, colorFragmentShaderAssembler.agalcode);

                maskProgramData = new ProgramData(program, 4);
            }

            programData = maskProgramData;
        }

        override public function dispose():void {
            super.dispose();

            if(maskTexture) {
                maskTexture.cleanUp();
                maskTexture = null;
            }
        }
    }
}
