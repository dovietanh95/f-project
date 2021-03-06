package testdata.di
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;
	
	import spark.components.SkinnableContainer;
	import spark.components.TextInput;
	
	import testdata.TestUser;

	[EventHandling(event="initialize",handler="view_initialize")]
	public class Injector_bindProperties_028 extends SkinnableContainer
	{
		[Bindable]
		public var employee:TestUser;
		
		[Bindable]
		public var employee2:TestUser;
		
		[SkinPart(required="true")]
		[PropertyBinding(text="net.fproject.utils.DateTimeUtil.formatIsoDate(employee.birthDay@)")]
		public var bodTextInput:TextInput;
		
		[SkinPart(required="true")]
		[PropertyBinding(text="net.fproject.utils.DateTimeUtil.formatIsoDate(employee2.birthDay)")]
		public var bodTextInput2:TextInput;
		
		public function Injector_bindProperties_028()
		{
			employee2 = new TestUser({birthDay:new Date(1999,0,1)});
			this.setStyle("skinClass", Injector_bindProperties_028Skin);
		}
		
		public function view_initialize(e:Event):void
		{
			employee = new TestUser({birthDay:new Date(2000,0,1)});
		}
		
		public function show():void
		{
			PopUpManager.addPopUp(this, FlexGlobals.topLevelApplication as DisplayObject);
		}
	}
}