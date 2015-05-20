package org.calacademy.video.events {
	import flash.events.Event;

	public class XmlEvent extends Event {
		public static const PARSED:String = "onParsed";
		public static const LOADED:String = "onLoaded";

		public function XmlEvent (type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
		}
		
		override public function toString ():String {
			return this.formatToString("XmlEvent", "type", "bubbles", "cancelable");
		}
		
		override public function clone ():Event {
			var e:XmlEvent = new XmlEvent(this.type, this.bubbles, this.cancelable);
			
			return e;
		}
	}
}
