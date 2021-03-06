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

package tests {

    import de.nulldesign.nd2d.display.Node2D;
    import de.nulldesign.nd2d.display.Sprite2D;
    import de.nulldesign.nd2d.display.TextureRenderer;
    import de.nulldesign.nd2d.events.TextureEvent;
    import materials.Sprite2DDizzyMaterial;
    import de.nulldesign.nd2d.materials.Texture2D;

    import flash.events.Event;

    public class PostProcessingTest extends SideScrollerTest {

        protected var sceneNode:Node2D;
        protected var textureRenderer:TextureRenderer;
        protected var postProcessedScene:Sprite2D;

        public function PostProcessingTest() {
            super();
        }

        override protected function addedToStage(e:Event):void {
            super.addedToStage(e);

            sceneNode = new Node2D();

            while(children.length > 0) {
                sceneNode.addChild(getChildAt(0));
                removeChildAt(0);
            }

            addChild(sceneNode);
            sceneNode.visible = false;

            textureRenderer = new TextureRenderer(sceneNode, stage.stageWidth, stage.stageHeight, 0.0, 0.0);
            textureRenderer.addEventListener(TextureEvent.READY, textureCreated);
            addChild(textureRenderer);
        }

        private function textureCreated(e:TextureEvent):void {

            if(postProcessedScene) {
                removeChild(postProcessedScene);
                postProcessedScene.dispose();
                postProcessedScene = null;
            }

            //textureRenderer.removeEventListener(TextureEvent.READY, textureCreated);

            postProcessedScene = new Sprite2D(textureRenderer.texture);
            postProcessedScene.setMaterial(new Sprite2DDizzyMaterial());
            //postProcessedScene.blendMode = BlendModePresets.ADD;
            postProcessedScene.tint = 0xAA99FF;
            postProcessedScene.x = textureRenderer.width * 0.5;
            postProcessedScene.y = textureRenderer.height * 0.5;
            addChild(postProcessedScene);
        }

        override protected function step(elapsed:Number):void {

            super.step(elapsed);
        }
    }
}
