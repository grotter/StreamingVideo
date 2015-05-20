package org.calacademy.video.pocketpenguins {
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import org.casalib.events.InactivityEvent;
	
	import org.calacademy.video.StreamingVideoController;
	import org.calacademy.video.events.XmlEvent;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.Config;
	import org.calacademy.video.pocketpenguins.view.Dock;
	import org.calacademy.video.pocketpenguins.view.DockMedium;
	import org.calacademy.video.pocketpenguins.view.CamIcon;
	import org.calacademy.video.pocketpenguins.view.Logo;
	import org.calacademy.video.pocketpenguins.view.MoneyButton;
	
	public class PocketPenguins extends StreamingVideoController {
		protected var _logo:Logo;
		private var _moneyButton:MoneyButton;
		private var _dock:Dock;
		private var _camIcon:CamIcon;
		
		public function PocketPenguins () {
			super(); 
		}
		
		override protected function _initConfig ():void {
			Config.xml_path = "http://www.calacademy.org/module/penguincams/xml/";
			Config.flat_video_path = "pocketpenguins.flv";
			Config.shared_object_name = "pocketPenguinsUserData";
			Config.ga_account = "UA-6206955-5";
			
			Config.msgDataError = {
				title: "Oops.",
				body: "A network connection could not be found. Would you like to watch a short, prerecorded presentation?"
			};

			Config.msgVideoError = {
				title: "Oops.",
				body: "Your network connection appears to have been lost. Would you like to watch a short, prerecorded presentation?"
			};
		}
		
		protected function _initLogo ():void {
			_logo = (_resolution == 2) ? new LogoMedium() : new Logo();
		}
		
		override protected function _initExtraGraphics ():void {
			_initLogo();
			_size(_logo);
			_logo.addEventListener(MouseEvent.MOUSE_UP, _onLogoClick);
			this.addChild(_logo);
		}
		
		override protected function _onVisible ():void {
			// wiggle
			if (_moneyButton != null) {
				_moneyButton.play();
			}
			
			super._onVisible();
		}
		
		override protected function _pollBuffering (e:Event):void {
			if (_video.getPercentBuffered() > 0) {
				this.removeEventListener(Event.ENTER_FRAME, _pollBuffering);
				if (_dock != null) _dock.enabled = true;
			}
		}
		
		private function _initMoneyButton ():void {
			_moneyButton = (_resolution == 2) ? new MoneyButtonMedium() : new MoneyButton();
			
			if (_isSms()) {
				_moneyButton.setGraphic("sms");
			} else {
				// if device isn't SMS capable, set the proper alternate graphic
				_moneyButton.setGraphic(Config.moneyAltFrameLabel);
			}
			
			_size(_moneyButton);
			_moneyButton.addEventListener(MouseEvent.MOUSE_UP, _onMoneyButtonClick);
			this.addChild(_moneyButton);
		}

		private function _onLogoClick (e:*):void {
			if (!_isDataLoaded) return;
			_tracker.track("Interaction", "Logo Click");
			
			_displayAlert(Config.msgLogoClick, {
				title: "Cancel",
				callback: function () {
					_tracker.track("Alert", "Logo Cancel");
					_removeAlert();
					
					if (_isBuffering) {
						_buffer(true);
					} else if (_video != null) {
						if (_video.isPlaying()) {
							// restart idle timeout
							_initInactivityTimeout();
						}
					}
				}
			}, {
				title: "OK",
				callback: function () {
					_tracker.track("Alert", "Logo Confirm");
					var request:URLRequest = new URLRequest(Config.logoUrl);

					try {
						navigateToURL(request, "_blank");
					} catch (e:Error) {
						trace(e);
					}
				}
			});
		}
		
		private function _onMoneyButtonClick (e:*):void {
			_tracker.track("Interaction", "Money Button Click", _moneyButton.label);
			
			var msg:Object = _isSms() ? Config.msgSms : Config.msgAltMoney;
			var targetUrl:String = _isSms() ? Config.smsUrl : Config.moneyAltUrl;
			var btnText:String = _isSms() ? "Send SMS" : "OK";
			
			_displayAlert(msg, {
				title: "Cancel",
				callback: function () {
					_tracker.track("Alert", "Money Button Cancel", _moneyButton.label);
					_removeAlert();
					
					if (_isBuffering) {
						_buffer(true);
					} else if (_video != null) {
						if (_video.isPlaying()) {
							// restart idle timeout
							_initInactivityTimeout();
						}
					} 
				}
			}, {
				title: btnText,
				callback: function () {
					_tracker.track("Alert", "Money Button Confirm", _moneyButton.label);
					var request:URLRequest = new URLRequest(targetUrl);

					try {
						navigateToURL(request, "_blank");
					} catch (e:Error) {
						trace(e);
					}
				}
			});
		}
		
		override protected function _onActivate (e:Event):void {
			if (!_isAppFocused) { 
				// wiggle
				if (_moneyButton != null) {
					_moneyButton.play();
				}
			}
			
			super._onActivate(e);
		}

		override protected function _onUserIdle (e:*):void {
			_collapseDock();
		}
		
		override protected function _onData (e:XmlEvent):void {
			_tracker.track("Network", "Data Loaded");
			_timeout.stop();
			
			// reset timeout per loaded config
			_timeout.delay = Config.timeoutDuration;
			
			// setup video if not already initialized
			// by flat video
			_initVideo();
			
			// donate
			_initMoneyButton();
			
			// cam icon
			_camIcon = (_resolution == 2) ? new CamIconMedium() : new CamIcon();
			_size(_camIcon);
			this.addChild(_camIcon);
			
			try {
				// dock
				var myXml:XML = this._data.getXml();
				_dock = (_resolution == 2) ? new DockMedium(myXml) : new Dock(myXml);
				_size(_dock);
				
				// listen for when dock is done collapsing
				_dock.addEventListener(ContentEvent.COLLAPSED, _onDockCollapsed);
			} catch (e:Error) {
				// invalid xml
				trace(e);
				_onDataError(null);
				return;
			}
			
			// listen to dock button
			_camIcon.addEventListener(ContentEvent.SELECT, _onCamIconActivate);
			
			// listen to each stream button
			for each (var node:XML in myXml.cam) {
				var prefix:String = node.prefix.toString();
				_dock.addEventListener(prefix, _onStreamSelect);
			}
			
			// display the dock
			this.addChild(_dock);
			
			// start listening for idle events
			_initIdleEvents();
			
			// we now have data
			_isDataLoaded = true;

			// if app has focus and not playing flat video,
			// start loading initial stream
			if (_isAppFocused) _playLastStream();
		}
		
		private function _onCamIconActivate (e:*):void {
			if (_camIcon == null || _dock == null) return;
			
			_camIcon.enable(false);
			_dock.show();
			_isDockOpen = true;
		}
		
		private function _collapseDock (tween:Boolean = true):void {
			if (!_isDockOpen) return;
			if (_dock != null) _dock.hide(tween);
		}
		
		private function _onDockCollapsed (e:ContentEvent):void {
			_isDockOpen = false;
			_camIcon.enable(true);
		}
        
		override protected function _onAlertCancel (str:String):void {
			super._onAlertCancel(str);
			if (_isDataLoaded) _onCamIconActivate(null);
		}

		override protected function _onStreamSelect (e:*, isFlat:Boolean = false):void {
			_collapseDock();
			if (_dock != null) _dock.enabled = false;
			super._onStreamSelect(e, isFlat);
		}

		override protected function _onVideoError (e:ContentEvent = null, timeout:Boolean = false):void {
			super._onVideoError(e, timeout);
			if (_dock != null) _dock.reenableAll();
		}

		override protected function _onIdleTimeout (e:InactivityEvent):void {
			super._onIdleTimeout(e);
			
			if (_video == null) return;
			if (!_video.isPlaying()) return; 
			
			// reenable buttons
			if (_dock != null) _dock.reenableAll();
		}

		override protected function _playLastStream (restart:Boolean = false):void {
			// do nothing if video hasn't been initialized
			if (!_isDataLoaded || _video == null) return;
			
			// use previously accessed stream if available
			var lastStream = SharedObject.getLocal(Config.shared_object_name).data.lastStream;
			
			if (typeof(lastStream) == "string"
				&& _data.numStreams > 1
				&& _data.isValidStream(lastStream)) {
					
				_dock.select(lastStream, restart);
				
			} else {
				_dock.select(0, restart);
			}
		}

		override protected function _playFlatVideo ():void {
			super._playFlatVideo();
			
			// deselect all live icons
			if (_dock != null) _dock.reenableAll();
		}
        
		override protected function _displayAlert (msg:Object, btn1:Object, btn2:Object = null, isError:Boolean = false, secondsAutoRemoval:int = 0):void {
			super._displayAlert(msg, btn1, btn2, isError, secondsAutoRemoval);
			
			// do nothing
			if (_alert.onStage || !_isAppFocused) return;
			
			// suppress keyboard
			if (_camIcon != null) _camIcon.keyEnabled = false;
			
			// collapse the dock
			_collapseDock();
		}

		override protected function _removeAlert (e:* = null):void {
			super._removeAlert(e);
			
			// reenable keyboard
			if (_camIcon != null) _camIcon.keyEnabled = true;
			
			// for mysterious reasons, key listeners don't fire
			// unless this is set after alert removal
			_stage.focus = null;
		}

		override protected function _setStageDimensions ():void {
			Config.stageWidth = Math.max(_stage.fullScreenWidth, _stage.fullScreenHeight);
    		Config.stageHeight = Math.min(_stage.fullScreenWidth, _stage.fullScreenHeight);
		}
	}
}
