package org.calacademy.video.data {
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.Capabilities;
	import org.casalib.load.DataLoad;
	import org.casalib.events.LoadEvent;
	import org.casalib.events.RemovableEventDispatcher;
	import org.casalib.util.FlashVarUtil;
	import org.calacademy.video.events.XmlEvent;
	import org.calacademy.video.Config;
	
	public class Database extends RemovableEventDispatcher {
		public var numStreams:int = 0;
		protected var _xmlPath:String = Config.xml_path;
		protected var _data:DataLoad;
		protected static var _instance:Database;
		protected var _xml:XML;
		
		public function Database (singletonEnforcer:*) {
			super();
		}
		
		public function init ():void {
			var variables:URLVariables = new URLVariables();
            variables.capabilities = Capabilities.serverString;
			
			var request:URLRequest = new URLRequest(this._xmlPath);
            request.data = variables;
            request.method = URLRequestMethod.POST;

			_data = new DataLoad(request);
			_data.retries = Config.connectAttempts - 1;
			
			_data.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this._onError);
			_data.addEventListener(IOErrorEvent.IO_ERROR, this._onError);
			_data.addEventListener(LoadEvent.COMPLETE, this._onDataLoad);

			try {
				trace("Database.init: loading cam data from " + this._xmlPath);
				_data.start();
			} catch (e:*) {
				_onError(e);
			}
		} 
		
		public function hasAlt ():Boolean {
			if (_xml == null) return false;
			if (_xml.@altrtmphost == undefined) return false;
			if (_xml.altcam.streams == undefined) return false;

			return true;
		}

		public function isValidStream (stream:String):Boolean {
			if (_xml == null) return false;
			if (FlashVarUtil.hasKey("stream")) return true;
			
			for each (var cam:XML in _xml.cam) {
				if (stream == cam.prefix) {
					return true;
				}
			}
			
			return false;
		}
		
		public function getStreamNameFromIndex (num:int):* {			
			if (_xml == null) return false;
			if (FlashVarUtil.hasKey("stream")) return FlashVarUtil.getValue("stream");
			return _xml.cam[num].prefix;
		}
		
		public function getXml ():XML {
			return _xml;
		}
		
		protected function _onDataLoad (e:LoadEvent):void {
			try {
				_xml = _data.dataAsXml;
			} catch (e:Error) {
				trace(e);
				this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
				return;
			}
			
			_data.destroy();
			_data = null;
			
			_setConfig();
			this.numStreams = FlashVarUtil.hasKey("stream") ? 1 : _xml.cam.length();
			this.dispatchEvent(new XmlEvent(XmlEvent.LOADED));
		}
		
		protected function _isConstantSpecified (name:String):Boolean {
			try {
				var len:Number = _xml.constants[name].children().length();
				return (len > 0);
			} catch (e:Error) {
				trace(e);
			}
			
			return false;
		}
		
		protected function _setMsg (id:String, target:String):void {
			var node = _xml.messages.message.(@id == id);
			if (node.children().length() == 0) return;

			Config[target] = {
				title: node.title,
				body: node.body
			};
		}
		
		protected function _setConfig ():void {
			if (_isConstantSpecified("buffertime")) {
				Config.bufferTime = int(_xml.constants.buffertime);
			}
			
			if (_isConstantSpecified("idlethreshold")) {
				Config.idleThreshold = int(_xml.constants.idlethreshold);
			}
			
			if (_isConstantSpecified("trackingpulse")) {
				Config.trackingPulse = int(_xml.constants.trackingpulse);
			}
			
			if (_isConstantSpecified("timeoutduration")) {
				Config.timeoutDuration = int(_xml.constants.timeoutduration);
			}
			
			if (_isConstantSpecified("connectattempts")) {
				Config.connectAttempts = int(_xml.constants.connectattempts);
			}
			
			if (_isConstantSpecified("reconnectinterval")) {
				Config.reconnectInterval = int(_xml.constants.reconnectinterval);
			}
			
			if (_isConstantSpecified("smsurl")) {
				Config.smsUrl = _xml.constants.smsurl;
			}
			
			if (_isConstantSpecified("logourl")) {
				Config.logoUrl = _xml.constants.logourl;
			}
			
			// override default and xml config logo url with
			// flashvar if present
			if (FlashVarUtil.hasKey("logourl")) {
				Config.logoUrl = FlashVarUtil.getValue("logourl");	
			}

			if (_isConstantSpecified("idletimeoutminutes")) {
				Config.idleTimeoutMinutes = int(_xml.constants.idletimeoutminutes);
			}
			
			if (_isConstantSpecified("issmscapable")) {
				Config.isSmsCapable = (_xml.constants.issmscapable == "1");
			}
			
			if (_isConstantSpecified("moneyalturl")) {
				Config.moneyAltUrl = _xml.constants.moneyalturl;
			}
			
			if (_isConstantSpecified("moneyaltframelabel")) {
				Config.moneyAltFrameLabel = _xml.constants.moneyaltframelabel;
			}

			if (_isConstantSpecified("monitordelay")) {
				Config.monitorDelay = int(_xml.constants.monitordelay);
			}

			if (_isConstantSpecified("reboot")) {
				Config.reboot = (_xml.constants.reboot == "1");
			}
			
			_setMsg("alt-money", "msgAltMoney");
			_setMsg("sms", "msgSms");
			_setMsg("logo-click", "msgLogoClick");
		}
		
		protected function _onError (e:*):void {
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
		
		public static function getInstance ():Database {
			if (Database._instance == null) {
				Database._instance = new Database(new SingletonEnforcer());
			}
			
			return Database._instance;
		}
	}
}

class SingletonEnforcer {}
