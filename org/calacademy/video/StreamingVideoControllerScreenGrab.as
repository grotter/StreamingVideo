package org.calacademy.video {
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.events.ErrorEvent;
	import org.casalib.events.LoadEvent;
	import org.calacademy.video.view.SnapShot;
	import org.calacademy.video.Config;	
	import org.calacademy.video.StreamingVideoController;
	import org.calacademy.video.data.ScreenGrab;
	import org.calacademy.video.view.ScreenGrabForm;
	
	public class StreamingVideoControllerScreenGrab extends StreamingVideoController {
		protected var _screenGrab:ScreenGrab = ScreenGrab.getInstance();
		
		public function StreamingVideoControllerScreenGrab () {
			super();
			Config.staticLoadingMessage = "Uploading snapshot...";
			_screenGrab.addEventListener(LoadEvent.COMPLETE, _onGrabComplete);
			_screenGrab.addEventListener(ErrorEvent.ERROR, _onGrabError); 
		}

		protected function _sendGrab (still:*):void {
			if (still == false) return;
			
			var fields:* = _alert.getFields();
			if (fields == false) return;
			
			// validate form
			if (fields.name.value == "") {
				fields.name.displayError();
				return;
			}
			
			_removeAlert();
			this.buffer(true, true);
			_screenGrab.send(still, fields.name.value, fields.location.value, Config.screenGrabConfigKey);
		}
		
		protected function _grab (e:* = null):void {
			if (_isBuffering || !_isAppFocused || _alert.onStage || !_video.isPlaying()) return;
			
			// get the still
			var still = _video.getStill();
			
			if (still == false) {
				return;
			} else {
				// show the flash
				this.addChild(new SnapShot());
			}
			
			// init form
			var form:ScreenGrabForm = new ScreenGrabForm(_resolution == 2);
			form.still = still;
			_initAlert(form);
			
			// display form
			_displayAlert(Config.msgScreenGrab, {
				title: "Cancel",
				callback: function () {
					_onAlertCancel("Screen Grab Cancel");
				}
			}, {
				title: "OK",
				callback: function () {
					_tracker.track("Alert", "Screen Grab Confirm");
					_sendGrab(still);
				}
			});
		}
		
		protected function _onGrabComplete (e:LoadEvent):void {
			_tracker.track("Screen Grab", "Complete");
			this.buffer(false);
			
			_displayAlert(Config.msgScreenGrabComplete, {
				title: "Cancel",
				callback: function () {
					_onAlertCancel("Screen Grab Complete Cancel");
				}
			}, {
				title: "OK",
				callback: function () {
					_tracker.track("Alert", "Screen Grab Complete Confirm");
					_removeAlert();
					
					// go to the capture Flickr page
					var flickrUrl = _screenGrab.getFlickrUrl();
					
					if (flickrUrl != false) {
						var link:URLRequest = new URLRequest(flickrUrl);
						navigateToURL(link, "_top");
					}
				}
			});
		}
		
		protected function _onGrabError (e:ErrorEvent):void {
			_tracker.track("Screen Grab", "Error");
			this.buffer(false);
			
			_displayAlert(Config.msgScreenGrabError, {
				title: "Cancel",
				callback: function () {
					_onAlertCancel("Screen Grab Error Cancel");
				}
			}, {
				title: "OK",
				callback: function () {
					_tracker.track("Alert", "Screen Grab Error Confirm");
					_removeAlert();
					_grab();
				}
			});
		}
	}
}
