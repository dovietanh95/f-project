///////////////////////////////////////////////////////////////////////////////
//
// © Copyright f-project.net 2010-present.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
///////////////////////////////////////////////////////////////////////////////
package net.fproject.ui.autoComplete.supportClasses
{
	import spark.components.Image;
	import spark.components.Label;
	import spark.components.supportClasses.ItemRenderer;
	import spark.components.supportClasses.TextBase;
	import spark.layouts.HorizontalLayout;
	import spark.layouts.supportClasses.LayoutBase;
	
	import net.fproject.utils.ResourceUtil;

	[Style(name="icon", inherit="no", type="Class")]
	public class CreateNewButtonRenderer extends ItemRenderer
	{
		protected var imageDisplay:Image;
		public function CreateNewButtonRenderer()
		{
			this.autoDrawBackground = true;
			this.percentWidth = 100;
			this.height = 20;
			this.mxmlContent = [createImageDisplay(), createLabelDisplay()];
			this.layout = createLayout();
		}
		
		protected function createImageDisplay():Image
		{
			this.imageDisplay = new Image;
			imageDisplay.height = 16;
			imageDisplay.width = 16;
			return this.imageDisplay
		}
		
		protected function createLabelDisplay():TextBase
		{
			this.labelDisplay = new Label;
			return this.labelDisplay;
		}
		
		protected function createLayout():LayoutBase
		{
			var hl:HorizontalLayout = new HorizontalLayout;
			hl.gap = 3;
			hl.paddingLeft = 5;
			hl.verticalAlign = "middle";
			return hl;
		}
		
		private var iconChanged:Boolean;
		
		override public function styleChanged(styleName:String):void
		{
			super.styleChanged(styleName);
			if(styleName == null || styleName == "icon")
			{
				iconChanged = true;
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			if(iconChanged)
			{
				iconChanged = false;
				imageDisplay.source = this.getStyle("icon");
				labelDisplay.text = ResourceUtil.getString('autocomplete.createNew.label','fprjui');
			}
		}
	}
}