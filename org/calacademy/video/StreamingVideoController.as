package org.calacademy.video {
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.display.StageDisplayState;
	import flash.display.MovieClip;
	import flash.display.DisplayObject;
	import flash.display.Bitmap;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.FullScreenEvent;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	
	import org.casalib.util.StageReference;
	import org.casalib.display.CasaSprite;
	import org.casalib.events.InactivityEvent;
    import org.casalib.time.Inactivity;
	import org.casalib.time.Interval;
	import org.casalib.util.LocationUtil;
	
	import org.calacademy.time.PauseableInterval;
	import org.calacademy.utils.NumberUtilExtra;
	
	import org.calacademy.video.data.Database;
	import org.calacademy.video.events.XmlEvent;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.Config;
	import org.calacademy.video.Tracker;
	import org.calacademy.video.view.VideoPlayback;
	import org.calacademy.video.view.VideoPlaybackLive;
	import org.calacademy.video.view.Buffering;
	import org.calacademy.video.view.Alert;
	import org.calacademy.video.view.StillMain;
	
	// import flash.system.Security;
	// import flash.system.SecurityPanel;
	
	public class StreamingVideoController extends MovieClip {
		protected var _data:Database;
		protected var _buffering:Buffering;
		protected var _video:VideoPlayback;
		protected var _videoContainer:CasaSprite;
		protected var _still:*;
		protected var _stillMain:StillMain;
		protected var _inactivity:Inactivity;
		protected var _inactivityTimeout:Inactivity;
		protected var _timeout:Interval;
		protected var _alert:Alert;
		protected var _stage:Stage;
		protected var _resolution:int;
		protected var _fullscreen:Boolean;
		protected var _alt:Boolean = false; 
		
		protected var _selectedStream:String = "";
		protected var _tracker:Tracker;
		protected var _trackingInterval:PauseableInterval;
		protected var _autoAlertRemovalInterval:Interval;
		
		protected var _isBuffering:Boolean = false;
		protected var _isFirstRun:Boolean = true;
		protected var _isDockOpen:Boolean = false;
		protected var _isAppFocused:Boolean = true;
		protected var _isDataLoaded:Boolean = false;
		protected var _isFlat:Boolean = false;
		protected var _isMobileDevice:Boolean;
		protected var _isSleepSuppress:Boolean;
		
		public function StreamingVideoController () {
			super();
			if (this.stage) StageReference.setStage(this.stage);
			
			// Security.showSettings(SecurityPanel.LOCAL_STORAGE);
			
			_initConfig();
			_setIsSleepSuppress();
			_setIsMobileDevice();
			
			if (_isMobileDevice) {
				// short pause before making visible to account for
				// screen glitch on mobile devices
				this.visible = false;
				var makeVisible:Interval = Interval.setTimeout(this._onVisible, 500);
				makeVisible.start();
			}
			
			_initStage();
			_initTracker();
			_initAppEvents();
			
			// alert
            _initAlert(new Alert(_resolution == 2));
			
			// init timeout and start
			_timeout = Interval.setTimeout(this._onTimeout, Config.timeoutDuration);
			_timeout.start();
			
			// container with initial still
			_stillMain = new StillMain();
			_videoContainer = new CasaSprite();
			_videoContainer.addChild(_stillMain);
			this.addChild(_videoContainer);
			
			// buffering
			_buffering = new Buffering(_resolution == 2);
			_size(_buffering);
			_buffering.addEventListener(ContentEvent.PROGRESS, _onProgress);
			_buffer(true);
			
			_initExtraGraphics();
			
			this.fullscreen = false;
			_loadData(); 
		}
		
		protected function _initTracker ():void {
			_tracker = Tracker.getInstance();
			_tracker.track("State", "Initial Launch");
			_resetTrackingInterval();
		}
		
		protected function _initAlert (instance:Alert):void {
			if (_alert != null) _alert.destroy();
			_alert = instance;
			_size(_alert);
			_alert.initScreen();
		}
		
		protected function _initConfig ():void {}
		
		protected function _initConfigAfterDataLoad ():void {}
		
		protected function _initExtraGraphics ():void {}
		
		protected function _onVisible ():void {
			this.visible = true;
		}
		
		protected function _setIsMobileDevice ():void {
			_isMobileDevice = true;
		}
		
		protected function _setIsSleepSuppress ():void {				
			// "On Android, the application must specify the Android permissions for DISABLE_KEYGUARD and WAKE_LOCK
			// in the application descriptor or the operating system will not honor this setting."
			// http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/desktop/SystemIdleMode.html#KEEP_AWAKE
		
			// "Kindle Fire does not support apps that contain disable_keyguard permissions or customize the lockscreen."
			// https://developer.amazon.com/help/faq.html#KindleFire 
			_isSleepSuppress = true;
		}
		
		protected function _onFullScreen (e:*):void {
			// needs UI from subclass
			_stage.displayState = StageDisplayState.FULL_SCREEN;
		}
		
		protected function _onFullScreenToggle (event:FullScreenEvent):void {
			this.fullscreen = !this.fullscreen;
		}
		
		public function set fullscreen (boo:Boolean):void {
			if (boo) {
				var myStage:Stage = StageReference.getStage();
				Config.stageWidth = myStage.stageWidth;
				Config.stageHeight = myStage.stageHeight;
			} else {
				// default
				_setStageDimensions();
			}
			
			if (_buffering) {
				if (_buffering.onStage) {
					_buffering.x = Config.stageWidth / 2;
					_buffering.y = Config.stageHeight / 2;
				}
			}
			
			if (_still) {
				_still.width = Config.stageWidth;
				_still.height = Config.stageHeight;
			}
			
			if (_video) _video.resize();
			if (_alert) _alert.resize();
			if (_stillMain) _stillMain.resize();
			
			_fullscreen = boo;
		}
		
		public function get fullscreen ():Boolean {
			return _fullscreen;
		}
		
		private function _onTrackingPulse ():void {
			if (_isFlat) return;
			if (_video == null) return;
			
			// quality of service	
			var qos = _video.getQoS();
			
			if (qos != false) {
				_tracker.track("Network", "kbps", String(Math.round(qos.maxBytesPerSecond / 1024)));
			}
			
			// duration
			var milliseconds = _trackingInterval.currentCount * Config.trackingPulse;
			_tracker.track("Video", _selectedStream, NumberUtilExtra.formatSeconds(milliseconds));
		}
		
		protected function _resetTrackingInterval ():void {
            if (_trackingInterval != null) _trackingInterval.destroy();
			_trackingInterval = PauseableInterval.setInterval(this._onTrackingPulse, Config.trackingPulse);
			_trackingInterval.reset();
		}
		
		protected function _isSms ():Boolean {
			// admin disabled
			if (Config.smsUrl == null) return false;
			if (Config.smsUrl == "") return false;
			
			// device not capable
			if (!Config.isSmsCapable) return false;
			
			return true;
		}
				
		protected function _size (obj:DisplayObject):void {
			if (_resolution == 3) {
				obj.scaleX = obj.scaleY = 2;
			}
		}
		
		protected function _initStage ():void {			
			_stage = StageReference.getStage();
			_stage.quality = "high";
			_stage.scaleMode = StageScaleMode.NO_SCALE;
			_stage.align = StageAlign.TOP_LEFT;
			_stage.addEventListener(FullScreenEvent.FULL_SCREEN, _onFullScreenToggle);
			_setStageDimensions();            
			
			_resolution = 1;
			
			if (Config.stageWidth > 750) {
				_resolution = 2;
				
				if (Config.stageWidth > 860) {
					_resolution = 3;
				}
				
				// ipads
				/*
				if (Config.stageWidth > 1000) {
					_resolution = 2;
				}
				*/
			}
		}
		
		protected function _setStageDimensions ():void {
			Config.stageWidth = _stage.stageWidth;
    		Config.stageHeight = _stage.stageHeight;
		}
		
		protected function _loadData ():void {
			_destroyDatabase();
			
			_initData();
			_data.addEventListener(XmlEvent.LOADED, _onData);
			_data.addEventListener(ErrorEvent.ERROR, _onDataError);
			_data.init();
		}
        
		protected function _initData ():void {
			_data = Database.getInstance();
		}

		protected function _destroyDatabase ():void {
			if (_data == null) return;
			
			_data.destroy();
			_data.removeEventListener(XmlEvent.LOADED, _onData);
			_data.removeEventListener(ErrorEvent.ERROR, _onDataError);
			_data = null;
		}
        
		public function buffer (boo:Boolean = true, isStatic:Boolean = false):void {
			_buffering.isStatic = isStatic;
			
			if (boo) {
				if (!_alert.onStage) {
					if (!_buffering.onStage) {
						// add buffering display object if not already on the stage
						_videoContainer.addChild(_buffering);
					}
				}
			} else {
				// remove buffering display object if it's on the stage
				if (_buffering.onStage) {
					_videoContainer.removeChild(_buffering);
				}
			}
			
			_isBuffering = boo;
		}

		protected function _buffer (boo:Boolean = true, removeStill:Boolean = true):void {
			if (boo) {
				// add still if not first run
				if (!_isFirstRun) _displayStill(true);
				
				// turn down the volume
				// @see _onVideoPlaying turns back up
				if (_video != null) _video.volume = 0;
				
				// start timeout timer
				_timeout.reset();
				_timeout.start();
				
				// pause view length tracking
				if (_trackingInterval != null) {
					if (_trackingInterval.running) {
						_trackingInterval.pause();
					}
				}
			} else {
				if (removeStill) _displayStill(false);
				
				// stop timeout timer since we're now playing video.
				// restart if we need to buffer the current stream or
				// attempt to load a different one.
				_timeout.stop();
			}
			
			buffer(boo);
		}
		
		private function _displayStill (boo:Boolean) {
			if (boo) {
				if (_still == null && _video != null) {
					try {
						var still = _video.getStill();

						if (still != false) {
							_still = still;
							_still.x = _video.x;
							_still.y = _video.y; 
							_videoContainer.addChild(_still);
						}
					} catch (e:Error) {
						trace(e);
					}
				}
			} else {
				try {
					if (_still) {
						_videoContainer.removeChild(_still);
						_still.bitmapData.dispose();
						_still = null;
					}
				} catch (e:Error) {
					trace(e);
				}
			}
		}

		protected function _onActivate (e:Event):void {
			if (_isSleepSuppress) {
				try {
					NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
				} catch (e:*) {}
			}

			// this function only fires in AIR
			// app was previously closed
			if (!_isAppFocused) { 
				_tracker.track("State", "Relaunch");
				
				if (_isDataLoaded) {
                	// reopen stream
					_playLastStream(true);
				} else {
					// load data
					_buffer(true);
					_loadData();
				}
			}
			
			_isAppFocused = true;
			
			// only reactivate dock inactivity,
			// timeout inactivity will reactivate when video is buffered
			if (_isDataLoaded) _initIdleEvents();
		}
		
		protected function _onDeactivate (e:Event):void {
			if (_isSleepSuppress) {
				try {
					NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
				} catch (e:*) {}
			}
			
			_tracker.track("State", "Close");
			_isAppFocused = false;
			
			// if data not yet loaded, destroy Database
			if (!_isDataLoaded) _destroyDatabase();
			
			// stop both inactivity timers
			if (this._inactivity != null) this._inactivity.stop();
			if (this._inactivityTimeout != null) this._inactivityTimeout.stop();

			_removeAlert();
			
			// add still
			_displayStill(true);
			
			if (_video != null) {
				// close stream
				_closeVideo();
				
				// hide
				_video.visible = false;
			}
			
			// remove buffer and stop the timeout
			_buffer(false, false);
			
			// stop polling
			this.removeEventListener(Event.ENTER_FRAME, _pollBuffering);
		}

		protected function _initAppEvents ():void {
			try {
				if (_isSleepSuppress) {
					NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
				}

				// add some basic listeners
				NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, _onActivate);
				NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, _onDeactivate);
			} catch (e:Error) {
				trace(e);
			}
		}
		
		protected function _initIdleEvents ():void {
			if (this._inactivity == null) {
				this._inactivity = new Inactivity(Config.idleThreshold);
	            this._inactivity.addEventListener(InactivityEvent.INACTIVE, _onUserIdle);
			}
			
            this._inactivity.start();
		}
		
		protected function _initInactivityTimeout ():void {
			if (Config.idleTimeoutMinutes == 0 || _isFlat) {
				trace("bypassing idle timeout...");
				return;
			}

			if (this._inactivityTimeout == null) {
				// this._inactivityTimeout = new Inactivity(10000);
				
				this._inactivityTimeout = new Inactivity(Config.idleTimeoutMinutes * 60 * 1000);
				this._inactivityTimeout.addEventListener(InactivityEvent.INACTIVE, _onIdleTimeout);
			}
			
			trace("setting idle timeout to " + Config.idleTimeoutMinutes + " minute(s)...");
            this._inactivityTimeout.start();
		}

		protected function _onUserIdle (e:*):void {}
		
		protected function _initVideo (config:Object = null):void {
			if (_video != null) _video.destroy();
			
			_video = this._getVideoPlayerInstance(config);
			_buffering.setStream(_video);
			
			_video.addEventListener(ContentEvent.PROGRESS, _onProgress);
			_video.addEventListener(ContentEvent.BUFFERING, _onVideoBuffering);
			_video.addEventListener(ContentEvent.STREAM_PLAYING, _onVideoPlaying);
			_video.addEventListener(ContentEvent.STREAM_ERROR, _onStreamError);
			_video.addEventListener(ContentEvent.CONNECTION_ERROR, _onVideoError);
			
			if (_isFlat) {
				_video.addEventListener(ContentEvent.STOP, _onFlatVideoComplete);
			}
			
			_videoContainer.addChild(_video);
		}
		
		protected function _getVideoPlayerInstance (config:Object = null):VideoPlayback {
			if (_isFlat) {
				return new VideoPlayback(null, _alt);
			} else {
				return new VideoPlaybackLive(_data.getXml(), _alt, config);
			}	
		}

		protected function _onVideoBuffering (e:ContentEvent):void {
			_buffer(true);
		}
		
		protected function _onVideoPlaying (e:ContentEvent):void {
			_isFirstRun = false;

			if (_video != null) {
				_video.visible = true;
				_video.volume = 1;
				_tracker.track("Video", "Start", _selectedStream);
			}
			
			_buffer(false);
			_initInactivityTimeout();
			
			// track length viewed
			if (_trackingInterval.paused) {
				// already running
				_trackingInterval.resume();
			} else {
				// start polling
				_resetTrackingInterval();
				_onTrackingPulse(); 
				_trackingInterval.start();
			}
		}
		
		protected function _onData (e:XmlEvent):void {
			_initConfigAfterDataLoad();
			_tracker.track("Network", "Data Loaded");
			_timeout.stop();

			// reset timeout per loaded config
			_timeout.delay = Config.timeoutDuration;
			
			// setup video if not already initialized
			// by flat video
			_initVideo();
			
			// start listening for idle events
			_initIdleEvents();
			
			// we now have data
			_isDataLoaded = true;

			// if app has focus and not playing flat video,
			// start loading initial stream
			if (_isAppFocused) _playLastStream();
			
			this.dispatchEvent(new XmlEvent(XmlEvent.PARSED));
		}
		
		protected function _playLastStream (restart:Boolean = false):void {
			// do nothing if video hasn't been initialized
			if (!_isDataLoaded || _video == null) return;

			// use previously accessed stream if available
			var lastStream = SharedObject.getLocal(Config.shared_object_name).data.lastStream;
			
			if (typeof(lastStream) == "string"
				&& _data.numStreams > 1
				&& _data.isValidStream(lastStream)) {

				_onStreamSelect({
					type: lastStream
				}, restart);
				
			} else {
				_onStreamSelect({
					type: 0
				}, restart);
			}
		}

		protected function _pollBuffering (e:Event):void {
			if (_video.getPercentBuffered() > 0) {
				this.removeEventListener(Event.ENTER_FRAME, _pollBuffering);
			}
		}
		
		protected function _onStreamSelect (e:*, isFlat:Boolean = false):void {
			this.addEventListener(Event.ENTER_FRAME, _pollBuffering);
			
			if (typeof(e.type) != "string") {
				e.type = _data.getStreamNameFromIndex(e.type);
			}

			var so:SharedObject = SharedObject.getLocal(Config.shared_object_name);
			so.data.lastStream = e.type;
			
			try {
				so.flush();
			} catch (e:Error) {
				trace(e);
			}
			
			if (_buffering.onStage) _buffering.reset();
			_buffer(true);
			
			var toggleVideoMode:Boolean = false;
			
			if (isFlat !== _isFlat) {
				// set prop as last request
				_isFlat = isFlat;
				toggleVideoMode = true;
			}			
			
			if (isFlat || toggleVideoMode) {
				// @todo
				// not sure why flat video always requires
				// a re-initialization 
				_initVideo();
			}
			
			_selectedStream = e.type;
			_tracker.track("Video", "Select", _selectedStream);
			_resetTrackingInterval();

			trace('_onStreamSelect');
			trace('_selectedStream: ' + _selectedStream);
			_video.play(_selectedStream);
		}
		
		protected function _onProgress (e:ContentEvent):void {
			_timeout.reset();
			_timeout.start();
		}

		protected function _onStreamError (e:ContentEvent = null):void {
			_tracker.track("Video", "Stream Error", _selectedStream);
			
			// add still
			_displayStill(true);
			
			// trigger NetConnection.Connect.Closed
			_closeVideo(false);
		}
        
		protected function _onDataError (e:* = null):void {
			_tracker.track("Network", "Data Error");
			_destroyDatabase();
			_buffer(false, false);
			
			_displayAlert(Config.msgDataError, {
				title: "Cancel",
				callback: function () {
					_onAlertCancel("Data Error Cancel");
					
					// try reloading data
					_buffer(true);
					_loadData();
				}
			}, {
				title: "OK",
				callback: function () {
					_tracker.track("Alert", "Data Error Confirm");
					_playFlatVideo();
				}
			}, true);
		}
        
		protected function _onTimeout ():void {
			try {
				var doAlt:Boolean = (_data.hasAlt() && !_alt);

				if (!doAlt) _buffer(false, false);
				_closeVideo();
				
				if (_isDataLoaded) {
					if (doAlt) {
						_onAltToggle();
						_initVideo();
						_playLastStream();
					} else {
						// mimic a video error
						_onVideoError(null, true);
					} 				
				} else {
					// timeout fired before we got data, mimic a data load error
					_onDataError();
				}	
			} catch (e) {
				trace(e);
			}
		}

		protected function _onAltToggle ():void {
			trace("Attempting to connect to alt CDN...");
			_alt = true;	
		}

		protected function _onAlertCancel (str:String):void {
			_tracker.track("Alert", str);
			_removeAlert();
		}

		protected function _onVideoError (e:ContentEvent = null, timeout:Boolean = false):void {
			var errorType:String = (timeout) ? "Timeout Error" : "Error";
			_tracker.track("Video", errorType, _selectedStream);
			
			_resetTrackingInterval();
			_buffer(false, false);
			
			// alert
			_displayAlert(Config.msgVideoError, {
				title: "Cancel",
				callback: function () {
					_onAlertCancel("Video Error Cancel");
				}
			}, {
				title: "OK",
				callback: function () {
					_tracker.track("Alert", "Play Flat Video");
					_playFlatVideo();
				}
			}, true);
		}

		protected function _onIdleTimeout (e:InactivityEvent):void {
			// _initInactivityTimeout called @see _onVideoPlaying, so we definitely have data
			if (_video == null) return;
			if (!_video.isPlaying()) return; 
			
			// add still
			_displayStill(true);
			
			// stop video
			_closeVideo();
			
			_tracker.track("Video", "Inactivity Timeout", _selectedStream);
			
			// alert
			_displayAlert(Config.msgIdle, {
				title: "Cancel",
				callback: function () {
					_onAlertCancel("Inactivity Timeout Cancel");
				}
			}, {
				title: "OK",
				callback: function () {
					_tracker.track("Alert", "Inactivity Timeout Restart");
					_removeAlert();
					
					// keep playing
					_buffer(true);
					_playLastStream(true);
				}
			}, true);
		}
        
		protected function _onFlatVideoComplete (e:ContentEvent):void {
			_resetTrackingInterval();
			
			_displayAlert(Config.msgFlatVideoComplete, {
				title: "Cancel",
				callback: function () {
					_onAlertCancel("Flat Video Complete Cancel");
					
					if (!_isDataLoaded) {
                    	// try data load again
						_buffer();
						_loadData();
					}
				}
			}, {
				title: "OK",
				callback: function () {
					_tracker.track("Alert", "Flat Video Replay");
					_playFlatVideo();
				}
			});
		}

		protected function _playFlatVideo ():void {
			_removeAlert();
			
			// play flat video
			_onStreamSelect({
				type: Config.flat_video_path
			}, true);
		}

		protected function _closeVideo (closing:Boolean = true):void {
			_resetTrackingInterval();
			if (_video != null) _video.close(closing);
		}
		
		protected function _displayAlert (msg:Object, btn1:Object, btn2:Object = null, isError:Boolean = false, secondsAutoRemoval:int = 0):void {
			_timeout.stop();
			
			// do nothing
			if (_alert.onStage || !_isAppFocused) return;
			
			// display the alert
			_alert.setButtons(btn1, btn2);
			_alert.setText(msg.title, msg.body);
			this.addChild(_alert);
			
			// stop inactivity timer
			if (this._inactivity != null) this._inactivity.stop();
			
			// if this is a video / data error, stop inactivity timeout
			if (isError) {
				if (this._inactivityTimeout != null) {
					this._inactivityTimeout.stop(); 
				}
			}
			
			// remove the buffering display object
			if (_buffering.onStage) {
				_videoContainer.removeChild(_buffering);
			}
			
			if (secondsAutoRemoval > 0) {
				if (_autoAlertRemovalInterval) _autoAlertRemovalInterval.destroy();
				_autoAlertRemovalInterval = Interval.setTimeout(_removeAlert, secondsAutoRemoval * 1000);
				_autoAlertRemovalInterval.start();
			}
		}

		protected function _removeAlert (e:* = null):void {
			if (_autoAlertRemovalInterval) _autoAlertRemovalInterval.destroy();
			_initIdleEvents();
			if (_alert.onStage) this.removeChild(_alert);
			_initAlert(new Alert(_resolution == 2));
			
			// @todo
			// more testing
			if (_isBuffering) {
				_buffer(true);
			}
		}
	}
}
