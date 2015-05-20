package org.calacademy.video.data {
	import com.adobe.images.PNGEncoder;
	import flash.display.Bitmap;
	import flash.display.BitmapData; 
	import flash.utils.ByteArray;
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.URLRequestHeader;
	import flash.system.Capabilities;
	import org.casalib.util.StageReference;
	import org.casalib.load.DataLoad;
	import org.casalib.events.LoadEvent;
	import org.casalib.events.RemovableEventDispatcher;
	import org.casalib.util.NumberUtil;
	import org.casalib.util.LocationUtil;
	import org.calacademy.video.Config;
	
	public class ScreenGrab extends RemovableEventDispatcher {
		protected static var _instance:ScreenGrab;
		protected var _data:DataLoad;
		protected var _xml:XML;
		
		public function ScreenGrab (singletonEnforcer:*) {
			super();
		}
		
		public function getXml ():XML {
			return _xml;
		}
		
		public function getFlickrUrl ():* {
			try {
				var flickrId:String = _xml.data;
				return "http://www.flickr.com/photos/calacademy/" + flickrId;
			} catch (e:Error) {
				trace(e);
			}
			
			return false;
		}
		
		public function send (grab:Bitmap, name:String = "", location:String = "", configkey:String = ""):void {
			// only let calacademy send
			if (!Config.DEBUG && !LocationUtil.isDomain(StageReference.getStage(), "calacademy.org")) {
				_onError();
				return;
			}
			
			// add a random white pixel to the top row
			var myBitmapData:BitmapData = grab.bitmapData;
			var x:int = NumberUtil.randomIntegerWithinRange(0, myBitmapData.width - 1);
			myBitmapData.setPixel(x, 0, 0xffffff);
			
			var variables:URLVariables = new URLVariables();
			variables.x = x;
			variables.name = name;
			variables.location = location;
			variables.configkey = configkey;
						
            var header:URLRequestHeader = new URLRequestHeader("Content-type", "application/octet-stream");
			var request:URLRequest = new URLRequest(Config.grab_path + "?" + variables.toString());
			trace(Config.grab_path + "?" + variables.toString());
			
			request.requestHeaders.push(header);
			request.method = URLRequestMethod.POST;
			request.data = PNGEncoder.encode(myBitmapData);
            
			this.destroy();
			_data = new DataLoad(request);
			_data.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this._onError);
			_data.addEventListener(IOErrorEvent.IO_ERROR, this._onError);
			_data.addEventListener(LoadEvent.COMPLETE, this._onDataLoad);

			try {
				_data.start();
			} catch (e:*) {
				_onError(e);
			}
		}
		
		private function _onDataLoad (e:LoadEvent):void {
			try {
				_xml = _data.dataAsXml;
			} catch (e:Error) {
				trace(e);
				this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
				return;
			}
			
			this.destroy();
			trace(_xml);
			
			if (_xml.success == "1") {
				this.dispatchEvent(new LoadEvent(LoadEvent.COMPLETE)); 
			} else {
				this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
			}
		}
		
		private function _onError (e:* = null):void {
			trace(e);
			this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
		}
		
		override public function destroy ():void {
			// super.destroy();
			try {
				if (_data) {
					_data.destroy();
					_data = null;
				}
			} catch (e:Error) {
				// trace(e);
			}
		}
		
		public static function getInstance ():ScreenGrab {
			if (ScreenGrab._instance == null) {
				ScreenGrab._instance = new ScreenGrab(new SingletonEnforcer());
			}
			
			return ScreenGrab._instance;
		}
	}
}

class SingletonEnforcer {}
