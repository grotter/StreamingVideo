package org.calacademy.video.generic {
	import flash.events.MouseEvent;
	import flash.display.StageDisplayState;
	import org.casalib.util.FlashVarUtil;
	import org.casalib.util.LocationUtil;
	import org.calacademy.video.Config;	
	import org.calacademy.video.StreamingVideoController;
	import org.calacademy.video.view.Logo;
	import org.calacademy.video.events.ContentEvent;
	
	public class Generic extends StreamingVideoController {
		public function Generic () {
			super();
		}
		
		private function _onClick (e:MouseEvent):void {
			_stage.displayState = StageDisplayState.FULL_SCREEN;
		}
		
		override protected function _initExtraGraphics ():void {
			if (FlashVarUtil.hasKey("logo")) {
				if (FlashVarUtil.getValue("logo") != "1") {
					return;
				}
			}
			
			_logo = (_resolution == 2) ? new LogoMedium() : new Logo();
			_logo.removeMouseListener();
			_logo.addEventListener(MouseEvent.MOUSE_UP, _onClick);
			
			_size(_logo);
			this.addChild(_logo);
		}
		
		override protected function _setIsMobileDevice ():void {
			_isMobileDevice = false;
		}
		
		override protected function _initConfig ():void {
			if (LocationUtil.isIde()) {
				Config.xml_path = "http://www-local.calacademy.org/webcams/generic/akamai.xml";
			} else {
				if (FlashVarUtil.hasKey("xml")) {
					Config.xml_path = FlashVarUtil.getValue("xml");
				} else {
					Config.xml_path = "http://www.calacademy.org/webcams/generic/generic.xml";
				}
			}
			
			Config.ga_account = FlashVarUtil.hasKey("GA_ACCOUNT") ? FlashVarUtil.getValue("GA_ACCOUNT") : null;
		}
		
		override protected function _initConfigAfterDataLoad ():void {
			Config.idleTimeoutMinutes = 0;
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
	}
}
