package org.calacademy.video.farallones.data {
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import org.casalib.util.LocationUtil;
	import org.casalib.load.DataLoad;
	import org.casalib.events.LoadEvent;
	import org.casalib.util.StringUtil;
	import org.casalib.events.RemovableEventDispatcher;
	import org.calacademy.video.Config;
	import org.calacademy.video.events.ContentEvent;
	
	public class LiveStreamData extends RemovableEventDispatcher {
		private var _data:Object;
		private var _dataLoad:DataLoad;
		private var _ptz:DataLoad;
		private var _inQueue:Boolean = false;
		private var _postData:URLVariables = new URLVariables();
		private var _uid_cam:int = 1;
		private var _code:String = StringUtil.createRandomIdentifier(30);
		
		public function LiveStreamData (singletonEnforcer:SingletonEnforcer) {
			super();
			_postData.uid_cam = _uid_cam;
			if (!LocationUtil.isPlugin()) _postData.code = _code;
			 
			_data = {
				timestamp: null,
				camcontrol: null,
				hotspots: null,
				ticker: null,
				position: null,
				temperature: {
					fahrenheit: null,
					celsius: null
				},
				wind: {
					speed: null,
					direction: null
				}
			};
		}
        
		public function get inQueue ():Boolean {
			return _inQueue;
		}
        
		public function getQueuePosition ():int {
			if (_data.camcontrol != null) {
				if (_data.camcontrol.queue_position == undefined) {
					// invalid
					return 0;
				}
				
				return int(_data.camcontrol.queue_position);
			}

			return 0;
		}

		public function joinQueue (boo:Boolean = true):void {
			_postData.join_queue = boo ? 1 : 0;
			_inQueue = boo;
		}
		
		public function isAdminDisabled ():Boolean {
			if (_data.camcontrol != null) {
				if (_data.camcontrol.admin_disabled == undefined) {
					// invalid
					return false;
				}
				
				if (int(_data.camcontrol.admin_disabled) == 1) {
					return true;
				}
			}

			return false;
		}
		
		public function isControlling ():Boolean {
			if (_data.camcontrol != null) {
				if (_data.camcontrol.uid_control_queue == undefined) {
					// invalid
					return false;
				}
				
				if (int(_data.camcontrol.in_queue) == 1) {
					if (int(_data.camcontrol.queue_position) == 1) {
						return true;
					}
				}
			}

			return false;
		}
		
		public function load ():void {
			var request:URLRequest = new URLRequest(Config.server + Config.miscDataUrl);
            request.data = _postData;
            request.method = URLRequestMethod.POST;
			
			// @todo
			// migrate to production server and schedule update cron
			if (this._dataLoad) this._dataLoad.destroy();
            this._dataLoad = new DataLoad(request);
			this._dataLoad.addEventListener(IOErrorEvent.IO_ERROR, this._onError);
            this._dataLoad.addEventListener(LoadEvent.COMPLETE, this._onComplete);  

			try {
				this._dataLoad.start();
			} catch (e:*) {
				_onError(e);
			}
		}
		
		public function get data ():Object {
			return _data;
		}
		
		public function gotoHotspot (code:String):void {
			// @todo
			// * migrate to production server
			// * add error handling
			// * dispatch response(?)
			
			var variables:URLVariables = new URLVariables();
            variables.action = "gotoserverpresetno";
			variables.hotspot_code = code;
			variables.arguments = code.substring(11);
			
			// append standard post data
			for (var i:Object in _postData) {
				variables[i] = _postData[i];
			}
			
			var request:URLRequest = new URLRequest(Config.server + Config.ptzDataUrl);
            request.data = variables;
            request.method = URLRequestMethod.POST;
            
			if (_ptz != null) _ptz.destroy();
			_ptz = new DataLoad(request);
			_ptz.addEventListener(IOErrorEvent.IO_ERROR, this._onPtzError);
            _ptz.addEventListener(LoadEvent.COMPLETE, this._onPtzComplete);
			_ptz.start();
		}
		
		private function _onPtzError (e:*):void {
			// camera api request failed
			this.dispatchEvent(new ContentEvent(ContentEvent.CAMERA_API_RESPONSE, false));
		}
		
		private function _onPtzComplete (e:LoadEvent):void {
			// got a response from the camera api, check result
			var success:Boolean = (int(_ptz.dataAsXml.success) == 1);
			this.dispatchEvent(new ContentEvent(ContentEvent.CAMERA_API_RESPONSE, success));
		}
		
		private function _onComplete (e:LoadEvent):void {
			if (_dataLoad.dataAsXml == null) return;
			
			var xml:XML = _dataLoad.dataAsXml;
			
			// timestamp
			data.timestamp = xml.timestamp;
			
			// queue
			data.camcontrol = xml.camcontrol.client_info;
			
			// hotspots
			// create an array of hotspot objects
			var hotspots:XMLList = xml.hotspots.children();
			var arr:Array = new Array();
			
			for (var i in hotspots) {
				arr.push({
					code: hotspots[i].code,
					title: hotspots[i].title,
					rotation: Number(hotspots[i].rotation)
				});
			}
			
			data.hotspots = (arr.length > 0) ? arr : null;
			
			// position
			if (xml.position) {
				data.position = Number(xml.position);
			}
			
			// temperature
			if (xml.temperature) {
				data.temperature = {
					fahrenheit: Number(xml.temperature.fahrenheit),
					celsius: Number(xml.temperature.celsius)
				};
			}
			
			// wind
			if (xml.wind) {
				data.wind = {
		        	speed: Number(xml.wind.speed),
					direction: StringUtil.trim(xml.wind.direction)
				};
			}
			
			this.dispatchEvent(new LoadEvent(LoadEvent.COMPLETE));
        }

		private function _onError (e:* = null):void {
			trace("LiveStreamData._onError: " + e);
			this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR));
		}
		
		public static function getInstance ():LiveStreamData {
			if (LiveStreamData._instance == null) {
				LiveStreamData._instance = new LiveStreamData(new SingletonEnforcer());
			}
			
			return LiveStreamData._instance;
		}
		
		override public function destroy ():void {
			this._destroyGroupLoad();
			// super.destroy();
		}  
	}
}

class SingletonEnforcer {}
