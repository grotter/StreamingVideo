package org.calacademy.video.farallones.view {
	import flash.display.Stage;
	
	import org.casalib.util.StageReference;
	import org.casalib.util.LocationUtil;
	
	import org.calacademy.video.StreamingVideoController;
	import org.calacademy.video.Config;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.events.XmlEvent;
	import org.calacademy.video.farallones.data.DatabaseFarallones;

	public class FarallonesVideo extends StreamingVideoController {
		public var isActive:Boolean = false;
		
		public function FarallonesVideo () {
			super();
		}
		
		public function onKillMessage (e:ContentEvent):void {
			_displayAlert(e.data, {
				title: "OK",
				callback: function () {
					_onAlertCancel("Control Message Cancel");
				}
			}, null, true, 10);
		}
		
		public function onPtzError (e:ContentEvent):void {
			_tracker.track("Network", "PTZ Error");
			
			_displayAlert(Config.msgPtzError, {
				title: "OK",
				callback: function () {
					_onAlertCancel("PTZ Error Cancel");
				}
			}, null, true);
		}
		
		private function _showPano ():void {
			this.dispatchEvent(new ContentEvent(ContentEvent.PANO));
		}
		
		override protected function _initData ():void {
			_data = DatabaseFarallones.getInstance();
		}
		
		override protected function _onData (e:XmlEvent):void {
			isActive = _data.isActive();
			super._onData(e);
		}
		
		override protected function _playLastStream (restart:Boolean = false):void {
			// check if is FMLE is active per the current schedule
			if (_isDataLoaded) {
				if (!isActive) {
					_displayAlert(Config.msgInactiveEncoder, {
						title: "OK",
						callback: function () {
							_tracker.track("Alert", "Inactive FMLE Pano");
							_showPano();
						}
					}, null, true); 

					return;
				}
			}
			
			super._playLastStream(restart);
		}
		
		override protected function _onDataError (e:* = null):void {
			_tracker.track("Network", "Data Error");
			_destroyDatabase();
			_buffer(false, false);
			
			_displayAlert(Config.msgDataError, {
				title: "Try Again",
				callback: function () {
					_onAlertCancel("Data Error Cancel");
					
					// try reloading data
					_buffer(true);
					_loadData();
				}
			}, {
				title: "View Panorama",
				callback: function () {
					_tracker.track("Alert", "Data Error Pano");
					_showPano();
				}
			}, true); 
		}
		
		override protected function _onVideoError (e:ContentEvent = null, timeout:Boolean = false):void {
			var errorType:String = (timeout) ? "Timeout Error" : "Error";
			_tracker.track("Video", errorType, _selectedStream);
			
			_resetTrackingInterval();
			_buffer(false, false);
			
			// alert
			_displayAlert(Config.msgVideoError, {
				title: "Try Again",
				callback: function () {
					_onAlertCancel("Video Error Cancel");
					_playLastStream();
				}
			}, {
				title: "View Panorama",
				callback: function () {
					_tracker.track("Alert", "Video Error Pano");
					_showPano();
				}
			}, true); 
		}
		
		override protected function _initConfig ():void {
			if (LocationUtil.isIde()) {
				Config.server = "http://staging.calacademy.org";
			} else {
				Config.server = "http://www.calacademy.org";
			}
			
			Config.xml_path = Config.server + "/webcams/farallones/xml/cam/";
			
			Config.msgDataError = {
				title: "Oops.",
				body: "A network connection could not be found. Would you like to view an interactive panorama of the island?"
			};
			
			Config.msgVideoError = {
				title: "Oops.",
				body: "Your network connection appears to have been lost. Would you like to view an interactive panorama of the island?"
			};
		}
		
		override public function get width ():Number {
			return Config.stageWidth;
		}
		
		override public function get height ():Number {
			return Config.stageHeight;
		}
		
		override protected function _setIsMobileDevice ():void {
			_isMobileDevice = false;
		}
		
		override protected function _setStageDimensions ():void {
			Config.stageWidth =  563;
			Config.stageHeight =  341;
		}
	}
}
