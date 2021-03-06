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
package net.fproject.ui.datetime
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import mx.collections.IList;
	import mx.collections.ISort;
	import mx.collections.ISortField;
	import mx.core.IVisualElementContainer;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	
	import spark.collections.Sort;
	import spark.collections.SortField;
	import spark.components.ComboBox;
	import spark.core.NavigationUnit;
	import spark.events.DropDownEvent;
	import spark.events.IndexChangeEvent;
	import spark.events.TextOperationEvent;
	import spark.layouts.VerticalLayout;
	
	import net.fproject.collection.AdvancedArrayCollection;
	import net.fproject.ui.datetime.supportClasses.Time;
	
	use namespace mx_internal;
	
	[Style(name="hintedTextColor", inherit="yes", type="uint", format="Color")]
	/**
	 * 
	 * The TimeField allow users to select a time, specific to the minute.
	 * 
	 * @author Bui Sy Nguyen
	 * 
	 */
	public class TimeField extends ComboBox
	{
		protected var dataGroupDirty:Boolean;
		
		protected var textInputDirty:Boolean;
		
		protected var collection:AdvancedArrayCollection;
		
		protected var userSelectedMinutes:int = -1;
		
		protected var hintedIndex:int = -1;
		
		protected var textInputHasFocus:Boolean;
		
		protected var invalid:Boolean;
		
		private var _requireSelection:Boolean = false;
		
		private var _defaultDropDownTime:Number = 480;
		
		/**
		 * <p>
		 * Indicates whether the drop down will open on focus.
		 * </p>
		 * @default true
		 */
		public var openOnFocus:Boolean = true;
		
		/**
		 * <p>
		 * The filter function indicates which item should be enabled and which item should be disabled.
		 * </p>
		 * @default null
		 */
		public var itemEnabledFunction:Function;
		
		/**
		 * <p>
		 * The validation error message.
		 * A validation error occurs when the user entered a string that could not be converted to a valid minutes value.
		 * </p>
		 * @default <code>"Invalid time. You should input values like: 7p, 7pm, 7:00pm, 700p, 19:00p, 19PM etc."</code>
		 */
		public var validationErrorMessage:String = "Invalid time. You should input values like: 7p, 7pm, 7:00pm, 700p, 19:00p, 19PM etc.";
		
		protected var selectedMinutesDirty:Boolean;
		
		private var _selectedMinutes:int = -1;
		
		protected var snapIntervalDirty:Boolean;
		
		private var _snapInterval:int = 30;
		
		protected static const DAY_MINUTES:int = 1440;
		/**
		 * 
		 * @inheritDoc
		 * 
		 */		
		override public function get requireSelection() : Boolean
		{
			return this._requireSelection;
		}
		
		/**
		 * 
		 * @private
		 * 
		 */
		override public function set requireSelection(value:Boolean) : void
		{
			if(this._requireSelection == value)
			{
				return;
			}
			this._requireSelection = value;
			this.selectedMinutesDirty = true;
			invalidateProperties();
		}
		
		
		/**
		 * <p>
		 * The default time item (in minutes) to center in the drop down that is hinted, but
		 * not be the selected item.
		 * </p>
		 * @default <code>8 am</code>
		 */
		public function get defaultDropDownTime() : Number
		{
			return this._defaultDropDownTime;
		}
		
		public function set defaultDropDownTime(value:Number) : void
		{
			this._defaultDropDownTime = value;
		}
		
		[Bindable(event="valueCommit")]
		/**
		 * <p>
		 * The user selected value in minutes. If there's no item selected, this value is -1.
		 * </p>
		 * @default -1
		 */
		public function get selectedMinutes() : int
		{
			return this._selectedMinutes;
		}
		
		/**
		 * 
		 * @private
		 * 
		 */
		public function set selectedMinutes(value:int) : void
		{
			if(value == this._selectedMinutes || isNaN(value))
			{
				return;
			}
			this._selectedMinutes = value;
			this.selectedMinutesDirty = true;
			invalidateProperties();
			this._selectedMinutes = Math.min(1439,Math.max(-1,this._selectedMinutes));
			dispatchEvent(new FlexEvent(FlexEvent.VALUE_COMMIT));
		}
		
		/**
		 * <p>The intervals in minutes displayed in the drop down.
		 * For example, a value of 30 indicates that the drop down will display times
		 * each 30 minutes: 7:00am, 7:30am, 8:00am, 8:30am., etc.</p>
		 * @default 30
		 */
		public function get snapInterval() : int
		{
			return this._snapInterval;
		}
		
		public function set snapInterval(value:int) : void
		{
			if(value == this._snapInterval)
			{
				return;
			}
			this._snapInterval = value;
			this.snapIntervalDirty = true;
			invalidateProperties();
		}
		
		/**
		 * @inheritDoc 
		 * 
		 */
		override protected function commitProperties() : void
		{
			super.commitProperties();
			if(this.selectedMinutesDirty)
			{
				this.selectedMinutesDirty = false;
				if(isDropDownOpen)
				{
					closeDropDown(false);
				}
				this.setCustomSelectedItem(this._selectedMinutes, false);
			}
			if(this.snapIntervalDirty)
			{
				this.snapIntervalDirty = false;
				this.buildCollection();
				if(!this._requireSelection)
				{
					this.setText("");
					this.setSelectedMinutes(-1, false);
					setSelectedIndex(NO_SELECTION,true);
				}
				else
				{
					this.setSelectedMinutes(0, false);
					setSelectedIndex(0,true);
				}
			}
		}
		
		private var oldSelectedIndex:int;
		
		/**
		 * @inheritDoc 
		 * 
		 */
		override protected function commitSelection(value:Boolean = true) : Boolean
		{
			oldSelectedIndex = _selectedIndex;
			
			var s:String = textInput.text;
			if(selectedIndex == ComboBox.CUSTOM_SELECTED_ITEM)
			{
				this.setCustomSelectedItem(selectedItem.minutes);
				errorString = null;
				validateProperties();
				return false;
			}
			if(this._requireSelection && this._selectedMinutes == NO_SELECTION)
			{
				_selectedIndex = 0;
				this._selectedMinutes = 0;
			}
			var b:Boolean = super.commitSelection(false);
			if(selectedItem && selectedItem is Time)
			{
				this.setSelectedMinutes(selectedItem.minutes, false);
			}
			this.validate();
			if(selectedIndex == NO_SELECTION)
			{
				callLater(this.setText,[s]);
			}
			callLater(textInput.selectRange,[textInput.text.length,textInput.text.length]);
			if(this._selectedMinutes > NO_SELECTION)
			{
				this.invalid = false;
				errorString = null;
				validateProperties();
			}
			
			callLater(dispatchChangeEvent);
			
			return b;
		}
		
		private function dispatchChangeEvent():void
		{
			// Dispatch the change event
			if (dispatchChangeAfterSelection)
			{
				var e:IndexChangeEvent = new IndexChangeEvent(IndexChangeEvent.CHANGE);
				e.oldIndex = oldSelectedIndex;
				e.newIndex = _selectedIndex;
				dispatchEvent(e);
				dispatchChangeAfterSelection = false;
			}
		}
		
		/**
		 *  @private
		 */ 
		override protected function dataProvider_collectionChangeHandler(event:Event):void
		{      
			//Override this function to prevent unwanted behavior in the textInput control
		}
		
		/**
		 * @inheritDoc 
		 * 
		 */
		override protected function createChildren() : void
		{
			super.createChildren();
			maxChars = 11;
			restrict = "0-9.aApPmM:";
			labelFunction = this.dateFieldLabelFunction;
			itemMatchingFunction = this.timeMatchingFunction;
			labelToItemFunction = this.inputTextToItemFunction;
			openOnInput = true;
			this.collection = new AdvancedArrayCollection();
			this.collection.itemEqualFunction = function(a:Time, b:Time):Boolean{ return a.equals(b); };
			var sort:ISort = new Sort();
			var sortField:ISortField = new SortField("minutes",false,true);
			sort.fields = [sortField];
			this.collection.sort = sort;
			this.buildCollection();
			super.dataProvider = this.collection;
			addEventListener(DropDownEvent.OPEN,this.dropDownEventHandler);
			addEventListener(DropDownEvent.CLOSE,this.dropDownEventHandler);
		}
		
		/**
		 * @inheritDoc 
		 * 
		 */
		override protected function partAdded(partName:String, instance:Object) : void
		{
			super.partAdded(partName,instance);
			if(instance == dataGroup)
			{
				this.dataGroupDirty = true;
				invalidateProperties();
			}
			if(instance == textInput)
			{
				textInput.addEventListener(FocusEvent.FOCUS_IN,this.textInputHandler,true);
				textInput.addEventListener(FocusEvent.FOCUS_OUT,this.textInputHandler,true);
				this.textInputDirty = true;
				invalidateProperties();
			}
		}
		
		override public function set dataProvider(value:IList):void
		{
			//Do nothing. Dont let anyone change the dataProvider.
		}
		
		/**
		 * @inheritDoc 
		 * 
		 */
		override protected function partRemoved(partName:String, instance:Object) : void
		{
			super.partRemoved(partName,instance);
			if(instance == textInput)
			{
				textInput.removeEventListener(FocusEvent.FOCUS_IN,this.textInputHandler,true);
				textInput.removeEventListener(FocusEvent.FOCUS_OUT,this.textInputHandler,true);
			}
		}
		
		/**
		 * <p>You should call this method when you no longer want to simply hide the
		 * component and want it removed and eligible for garbage collection.
		 * </p>
		 */
		public function dispose() : void
		{
			if(parent)
			{
				if(parent is IVisualElementContainer)
				{
					IVisualElementContainer(parent).removeElement(this);
				}
				else if(parent is DisplayObjectContainer)
				{
					DisplayObjectContainer(parent).removeChild(this);
				}
			}
			textInput = null;
			dataGroup = null;
			removeEventListener(DropDownEvent.OPEN,this.dropDownEventHandler);
		}
		
		/**
		 * <p>
		 * Update the text input.
		 * </p>
		 */
		public function setText(value:String) : void
		{
			if(textInput)
			{
				textInput.text = value;
			}
		}
		
		/**
		 * <p>
		 * Determines if the selectedItem can be converted to a
		 * valid minutes quantity, and clears the error string if the selectedItem is valid.
		 * </p>
		 */
		public function validate() : Boolean
		{
			if(!this._requireSelection && textInput && textInput.text == null || textInput.text == "")
			{
				this.setSelectedMinutes(-1);
				errorString = null;
				validateProperties();
				return false;
			}
			if(this._requireSelection || !this.invalid)
			{
				errorString = null;
				validateProperties();
				return true;
			}
			return false;
		}
		
		protected function setHintedIndex(index:int) : void
		{
			var item:Time = index > -1 && collection != null ? collection[index] : null;
			if(itemEnabledFunction != null && !itemEnabledFunction(item))
				return;
			var oldItem:Time = hintedIndex > -1 && collection != null ? collection[hintedIndex] : null;
			if(oldItem != null)
				oldItem.isHinted = false;
			if(item != null)
				item.isHinted = true;
			this.hintedIndex = index;
		}
		
		protected function setDefaultDropDownIndex() : void
		{
			var i:int = this.getClosestMinutesIndex(this._defaultDropDownTime);
			this.setCenteredVerticalScrollPosition(i);
			this.setHintedIndex(i);
		}
		
		protected function setSelectedValueIndex(index:int) : void
		{
			this.hintedIndex = selectedIndex = index;
		}
		
		protected function setCustomSelectedItem(minutes:int, fireIndexChange:Boolean=true) : void
		{
			if(minutes == -1)
			{
				if(!this._requireSelection)
				{
					this.setSelectedMinutes(-1, fireIndexChange);
				}
				if(this._requireSelection)
				{
					callLater(this.setSelectedValueIndex,[0]);
					callLater(this.setSelectedMinutes,[0, fireIndexChange]);
					errorString = null;
					validateProperties();
				}
				return;
			}
			var idx:int = this.getMinutesIndex(minutes);
			if(idx > -1)
			{
				callLater(this.setSelectedValueIndex,[idx]);
				return;
			}
			var time:Time = new Time(minutes,this.minutesToTimeString(minutes));
			if(this.userSelectedMinutes > 0)
			{
				idx = this.getMinutesIndex(this.userSelectedMinutes);
				if(idx > -1)
				{
					this.collection.removeItemAt(idx);
				}
			}
			this.userSelectedMinutes = minutes;
			this.collection.addItem(time);
			callLater(this.setSelectedValueIndex,[this.getMinutesIndex(this.userSelectedMinutes)]);
		}
		
		protected function handleKeyboardNavigation(event:KeyboardEvent) : void
		{
			var unit:int = -1;
			switch(event.keyCode)
			{
				case Keyboard.UP:
					unit = NavigationUnit.UP;
					break;
				case Keyboard.DOWN:
					unit = NavigationUnit.DOWN;
					break;
				case Keyboard.PAGE_UP:
					unit = NavigationUnit.PAGE_UP;
					break;
				case Keyboard.PAGE_DOWN:
					unit = NavigationUnit.PAGE_DOWN;
					break;
			}
			if(unit != -1)
			{
				var curIdx:int = this.hintedIndex < NO_SELECTION?NO_SELECTION:this.hintedIndex;
				var destIndex:int = layout.getNavigationDestinationIndex(curIdx,unit,arrowKeysWrapFocus);
				if(destIndex != NO_SELECTION)
				{
					changeHighlightedSelection(destIndex);
					this.setHintedIndex(destIndex);
					event.preventDefault();
				}
			}
		}
		
		protected function setCenteredVerticalScrollPosition(pos:int) : void
		{
			var r:Rectangle = null;
			if(pos > -1 && dataGroup && dataGroup.layout is VerticalLayout)
			{
				this.setHintedIndex(pos);
				r = (dataGroup.layout as VerticalLayout).getElementBounds(pos);
				dataGroup.verticalScrollPosition = r.y - dataGroup.getLayoutBoundsHeight() / 2 + r.height / 2;
			}
		}
		
		/**
		 * <p>
		 * Returns the index of the element in the collection with the closest minutes
		 * value relative to the passed value.
		 * </p>
		 */
		public function getClosestMinutesIndex(minutes:Number) : int
		{
			if(minutes == DAY_MINUTES)
				return this.collection.length - 1;
			for (var i:int=0; i<this.collection.length; i++)
			{
				var time:Time = this.collection[i] as Time;
				
				if(time.minutes == minutes)
				{
					return i;
				}
				if(time.minutes > minutes)
				{
					return i - 1;
				}
			}
			
			return -1;
		}
		
		/**
		 * <p>
		 * Set value for the selectedIndex field by the index of the element in the collection with the closest minutes
		 * value relative to the passed value.
		 * </p>
		 */
		public function selectClosestMinutes(minutes:Number) : void
		{
			this.selectedIndex = getClosestMinutesIndex(minutes);
		}
		
		/**
		 * <p>
		 * Returns the index of the element in the collection with a "minutes"
		 * property that is equal to the passed value. Returns -1 if not found.
		 * </p>
		 */
		public function getMinutesIndex(minutes:Number) : int
		{
			for (var i:int=0; i<this.collection.length; i++)
			{
				var time:Time = this.collection[i] as Time;
				if(time.minutes == minutes)
				{
					return i;
				}
			}
			
			return -1;
		}
		
		/**
		 * <p>Update enabled status of item renderers using itemEnabledFunction function</p>
		 */
		public function updateEnabledItems():void
		{
			if(itemEnabledFunction != null)
			{
				for each(var t:Time in this.collection)
				{
					t.enabled = itemEnabledFunction(t);
				}
			}
		}
		
		override public function get selectedIndex():int
		{
			if(_requireSelection && super.selectedIndex == NO_SELECTION)
			{
				for(var i:int = 0; i < collection.length; i++)
				{
					var t:Time = collection[i];
					if(t.enabled)
					{
						_selectedIndex = i;
						_proposedSelectedIndex = i;
						break;
					}
				}
			}
			return super.selectedIndex;
		}
		
		/**
		 * <p>
		 * Set value for the selectedIndex field by the index of the element in the collection.
		 * </p>
		 */
		public function selectMinutes(minutes:Number) : void
		{
			this.selectedIndex = getMinutesIndex(minutes);
		}
		
		protected function setSelectedMinutes(value:Number, fireIndexChange:Boolean=true) : void
		{
			if(this._selectedMinutes != value)
			{
				this._selectedMinutes = value;
				var oldIdx:int = _selectedIndex;
				this.selectedIndex = getClosestMinutesIndex(value);
				if(fireIndexChange)
					dispatchEvent(new IndexChangeEvent(IndexChangeEvent.CHANGE, false, false, oldIdx, _selectedIndex));
			}
			dispatchEvent(new FlexEvent(FlexEvent.VALUE_COMMIT));
		}
		
		protected function dateFieldLabelFunction(data:Object) : String
		{
			if(data && data.hasOwnProperty("label"))
			{
				return data.label;
			}
			return null;
		}
		
		protected function inputTextToItemFunction(s:String) : Object
		{
			var timeString:String = null;
			var time:Time = null;
			var minutes:Number = this.timeStringToMinutes(s);
			if(!isNaN(minutes))
			{
				this.invalid = false;
				errorString = null;
				validateProperties();
				timeString = this.minutesToTimeString(minutes);
				time = new Time(minutes, timeString);
				return time;
			}
			if(this._requireSelection)
			{
				time = new Time(0,this.minutesToTimeString(0));
				return time;
			}
			this.invalid = true;
			this.setSelectedMinutes(-1);
			errorString = this.validationErrorMessage;
			validateProperties();
			callLater(this.setText,[s]);
			callLater(textInput.selectRange,[s.length,s.length]);
			return null;
		}
		
		protected function timeMatchingFunction(combo:ComboBox, input:String) : Vector.<int>
		{
			var l:int = 0;
			var i:int = 0;
			var time:Time;
			var matchedItems:Vector.<int> = new Vector.<int>();
			var index:int = -1;
			var m:Number = this.timeStringToMinutes(input);
			if(!isNaN(m))
			{
				l = this.collection.length;
				i = 0;
				while(i < l)
				{
					time = this.collection[i];
					if(time.minutes == m)
					{
						index = i;
						break;
					}
					if(time.minutes > m)
					{
						index = i - 1;
						break;
					}
					i++;
				}
				if(index > -1)
				{
					this.setCenteredVerticalScrollPosition(index);
				}
			}
			this.setHintedIndex(index);
			return matchedItems;
		}
		
		protected function buildCollection() : void
		{
			this.collection.removeAll();
			var i:int = 0;
			while(i < DAY_MINUTES)
			{
				var s:String = this.minutesToTimeString(i);
				this.collection.addItem(new Time(i,s));
				i = i + this._snapInterval;
			}
		}
		
		/**
		 * <p>
		 * Converts minutes value into a time string.
		 * </p>
		 */
		protected function minutesToTimeString(minutes:Number) : String
		{
			var h:Number = Math.floor(minutes / 60);
			var m:String = String(minutes % 60);
			if(h > 11)
			{
				h = h - 12;
				var ampm:String = "pm";
			}
			else
				ampm = "am";
			if(h == 0)
			{
				h = 12;
			}
			if(m.length < 2)
			{
				m = "0" + m;
			}
			return String(h) + ":" + String(m) + ampm;
		}
		
		/**
		 * <p>Converts a user entered string to numerical value of minutes.</p>
		 */
		protected function timeStringToMinutes(s:String) : Number
		{
			var ss:String = "";
			for(var i:int=0; i<s.length; i++)
			{
				if(s.charAt(i) != " ")
				{
					ss = ss + s.charAt(i);
				}
			}
			ss = ss.toLowerCase();
			var regex:RegExp = new RegExp("^\\D*(\\d*)[:.]?([0-5]*\\d)?([ap]?).*$");
			var matches:Array = regex.exec(ss);
			s = matches[1];
			var h:Number = s != null && s.length > 0 ? Number(s) : NaN;
			s = matches[2] ? matches[2] :null;
			if(s != null && s.length == 1)
				s = s + "0";
			var n:Number = s != null && s.length > 0? Number(s) : NaN;
			if(h > 24)
			{
				s = String(h);
				if(s.length > 3)
				{
					h = Number(s.charAt(0) + s.charAt(1));
					n = Number(s.charAt(2) + s.charAt(3));
				}
				else if(s.length == 3)
				{
					h = Number(s.charAt(0));
					n = Number(s.charAt(1) + s.charAt(2));
				}
				else if(s.length == 2)
				{
					h = Number(s.charAt(0));
					n = Number(s.charAt(1));
				}
			}
			else
			{
				i = getMinutesIndex(h * 60);
				if(i > -1 && collection && !Time(collection[i]).enabled)
				{
					h = h < 12 ? h + 12 : h - 12;
				}
			}
			
			if(matches[3])
				var ampm:String = String(matches[3]).charAt(0);
			else if(h < 12)
				ampm = "a";
			else
				ampm = "p";
			
			if(h < 12 && ampm == "p")
				h = h + 12;
			else if(h == 12 && ampm == "a")
				h = 0;
			
			var minutes:Number = h * 60;
			
			if(!isNaN(n))
				minutes += n;
			
			if(isNaN(minutes) || minutes < 0 || minutes > DAY_MINUTES)
			{
				return NaN;
			}
			else
			{
				i = getClosestMinutesIndex(minutes);
				if(i > -1 && collection && !Time(collection[i]).enabled)
					return NaN;
			}
			
			return minutes;
		}
		
		/**
		 * 
		 * @inheritDoc
		 * 
		 */
		override protected function focusInHandler(e:FocusEvent) : void
		{
			super.focusInHandler(e);
			if(this.openOnFocus)
			{
				callLater(openDropDown);
			}
		}
		
		/**
		 * 
		 * @inheritDoc
		 * 
		 */
		override protected function focusOutHandler(e:FocusEvent) : void
		{
			super.focusOutHandler(e);
			this.validate();
		}
		
		/**
		 * 
		 * @inheritDoc
		 * 
		 */
		override protected function keyDownHandler(e:KeyboardEvent) : void
		{
			if(e.keyCode == Keyboard.ENTER)
			{
				if(selectedIndex == ComboBox.CUSTOM_SELECTED_ITEM)
				{
					this._selectedMinutes = selectedItem.minutes;
				}
			}
			if(!this.textInputHasFocus && isDropDownOpen)
			{
				this.handleKeyboardNavigation(e);
			}
			super.keyDownHandler(e);
		}
		
		/**
		 * 
		 * @inheritDoc
		 * 
		 */
		override protected function capture_keyDownHandler(e:KeyboardEvent) : void
		{
			if(this.textInputHasFocus && isDropDownOpen)
			{
				this.handleKeyboardNavigation(e);
			}
			super.capture_keyDownHandler(e);
		}
		
		/**
		 * 
		 * @inheritDoc
		 * 
		 */
		override protected function textInput_changeHandler(e:TextOperationEvent) : void
		{
			super.textInput_changeHandler(e);
			if(textInput.text == null || textInput.text == "")
				this.setDefaultDropDownIndex();
		}
		
		/**
		 * <p>
		 * Handles changes to the textInput text property.
		 * </p>
		 */
		protected function textInputHandler(e:Event) : void
		{
			if(e.type == FocusEvent.FOCUS_IN)
				this.textInputHasFocus = true;
			else if(e.type == FocusEvent.FOCUS_OUT)
				this.textInputHasFocus = false;
		}
		
		/**
		 * <p>
		 * Handles events on the TimeField. When the opening the drop down, center
		 * and hint the selectedIndex or the defaultDropDown index.
		 * </p>
		 */
		protected function dropDownEventHandler(e:Event) : void
		{
			switch(e.type)
			{
				case DropDownEvent.CLOSE:
					if(this.collection)
					{
						for each(var time:Time in this.collection)
						{
							time.isHinted = false;
						}
					}
					break;
				case DropDownEvent.OPEN:
					if(selectedIndex == NO_SELECTION)
						this.setDefaultDropDownIndex();
					else
						this.setCenteredVerticalScrollPosition(selectedIndex);
					break;
			}
		}
	}
}
