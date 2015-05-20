package org.calacademy.video.coralreef {
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.events.FullScreenEvent;
	import flash.display.StageDisplayState;
	import org.casalib.util.LocationUtil;
	import org.casalib.util.FlashVarUtil;
	import org.casalib.util.StageReference;
	import org.calacademy.video.Config;	
	import org.calacademy.video.StreamingVideoControllerScreenGrab;
	import org.calacademy.video.view.Logo;
	import org.calacademy.video.view.FullScreenButton;
	import org.calacademy.video.events.ContentEvent;
	
	public class CoralReef extends StreamingVideoControllerScreenGrab {
		private var _fullScreenButton:FullScreenButton;
		private var _logo:Logo;
		
		public function CoralReef () {
			super();
			
			if (LocationUtil.isPlugin()) {
				// get snapshot requests from ExternalInterface / JS
				try {
					if (ExternalInterface.available) {
						ExternalInterface.addCallback("grab", _grab);
					}
				} catch (e:*) {
					trace(e);
				}
			} else {
				// add an artificial mechanism for testing in the IDE
				if (LocationUtil.isIde()) {
					this.addEventListener(MouseEvent.MOUSE_UP, _grab);
				}
			}
			
			_logo = new Logo();
			this.addChild(_logo);

			_logo.visible = (FlashVarUtil.getValue("logo") == 1); 
			
			_stage = StageReference.getStage();
			_stage.addEventListener(FullScreenEvent.FULL_SCREEN, _onFullScreenToggle);
		}
		
		override protected function _initExtraGraphics ():void {
			if (FlashVarUtil.getValue("context") != "social") {
				_fullScreenButton = new FullScreenButton();
				_fullScreenButton.addEventListener(ContentEvent.FULLSCREEN, _onFullscreenSelect);
				_fullScreenButton.x = Config.stageWidth - _fullScreenButton.width - 10;
				_fullScreenButton.y = Config.stageHeight - _fullScreenButton.height - 10;

				this.addChild(_fullScreenButton);
			}
		}
		
		override protected function _setIsMobileDevice ():void {
			_isMobileDevice = false;
		}
		
		override protected function _initConfig ():void {
			Config.screenGrabConfigKey = "coral-reef";
			Config.xml_path = "http://www.calacademy.org/webcams/coral-reef/xml/";
			Config.shared_object_name = "coralReefUserData";
			Config.ga_account = "UA-6206955-10";
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
		
		private function _onFullscreenSelect (e:ContentEvent):void {
			if (LocationUtil.isIde()) {
				// for dev only
				_onFullScreenToggle(null);
			} else {
				_stage.displayState = StageDisplayState.FULL_SCREEN;
			}
		}
		
		override protected function _onFullScreenToggle (event:FullScreenEvent):void {
			super._onFullScreenToggle(event);
			
			_fullScreenButton.visible = !this.fullscreen;
			_logo.visible = this.fullscreen;
			
			if (this.fullscreen) {
				_logo.removeMouseListener();
			}
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
