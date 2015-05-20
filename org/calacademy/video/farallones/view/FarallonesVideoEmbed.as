package org.calacademy.video.farallones.view {	
	import org.casalib.util.LocationUtil;
	import org.calacademy.video.Config;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.farallones.view.FarallonesVideo;
    
	public class FarallonesVideoEmbed extends FarallonesVideo {
		public function FarallonesVideoEmbed () {
			super();
		}
		
		override protected function _playLastStream (restart:Boolean = false):void {
			// check if is FMLE is active per the current schedule
			if (_isDataLoaded) {
				if (!isActive) {
					_displayAlert(Config.msgInactiveEncoderEmbed, {
						title: "OK",
						callback: function () {
							_onAlertCancel("Inactive FMLE");
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
				title: "OK",
				callback: function () {
					_onAlertCancel("Data Error Cancel");
					
					// try reloading data
					_buffer(true);
					_loadData();
				}
			}, null, true);
		}
		
		override protected function _onVideoError (e:ContentEvent = null, timeout:Boolean = false):void {
			var errorType:String = (timeout) ? "Timeout Error" : "Error";
			_tracker.track("Video", errorType, _selectedStream);
			
			_resetTrackingInterval();
			_buffer(false, false);
			
			// alert
			_displayAlert(Config.msgVideoError, {
				title: "OK",
				callback: function () {
					_onAlertCancel("Video Error Cancel");
					_playLastStream();
				}
			}, null, true); 
		}
		
		override protected function _initConfig ():void {
			// override pano messaging
			if (LocationUtil.isIde()) {
				Config.server = "http://staging.calacademy.org";
			} else {
				Config.server = "http://www.calacademy.org";
			}
			
			Config.xml_path = Config.server + "/webcams/farallones/xml/cam/";
		}
	}
}
