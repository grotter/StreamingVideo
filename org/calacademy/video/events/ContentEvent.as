package org.calacademy.video.events {
	import flash.events.Event;

	public class ContentEvent extends Event {
        public static const PANO:String = "onPano";
		public static const FULLSCREEN:String = "onFullscreen";
		public static const PROGRESS:String = "onProgress";
		public static const BUFFERING:String = "onBuffer";
		public static const STREAM_PLAYING:String = "onStreamPlay";
		public static const STREAM_ERROR:String = "onStreamError";
		public static const CONNECTION_ERROR:String = "onConnectionError";
		public static const SELECT:String = "onSelect";
		public static const COLLAPSED:String = "onCollapsed";
		public static const STOP:String = "onStop";
		public static const REQUEST_CONTROL:String = "onRequestControl";
		public static const CAMERA_API_RESPONSE:String = "onCameraApiResponse";
		public static const PTZ_ERROR:String = "onPtzError";
		public static const KILL_MESSAGE:String = "onKillMessage";
		public var data:Object;

		public function ContentEvent (type:String, data:Object = null, bubbles:Boolean = false, cancelable:Boolean = false) {
			super(type, bubbles, cancelable);
			this.data = data;
		}
		
		override public function toString ():String {
			return this.formatToString("ContentEvent", "type", "bubbles", "cancelable");
		}
		
		override public function clone ():Event {
			var e:ContentEvent = new ContentEvent(this.type, this.bubbles, this.cancelable);
			return e;
		}
	}
}
