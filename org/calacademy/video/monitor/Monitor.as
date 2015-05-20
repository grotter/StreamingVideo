package org.calacademy.video.monitor {
  	import flash.desktop.NativeApplication;
  	import adobe.utils.ProductManager;

	import flash.events.Event;
	import org.casalib.time.Interval;
	import org.casalib.util.LocationUtil;

	import org.calacademy.video.monitor.data.SendPulse;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.view.VideoPlayback;
	import org.calacademy.video.monitor.view.VideoPlaybackLiveMonitor;
	import org.calacademy.video.StreamingVideoController;
	import org.calacademy.video.Config;

	public class Monitor extends StreamingVideoController {
		private var _streamIndex:int = 0;
		private var _sendPulse:SendPulse;
		private var _cycleComplete:Boolean = false;

		public function Monitor () {
			super();
			_sendPulse = SendPulse.getInstance();
		}

		public function reboot ():void {
			var app = NativeApplication.nativeApplication;
			var mgr:ProductManager = new ProductManager("airappinstaller");
			mgr.launch("-launch " + app.applicationID + " " + app.publisherID);
			app.exit();
		}

		// don't kill app on deactivation
		override protected function _initAppEvents ():void {}

		override protected function _setIsMobileDevice ():void {
			_isMobileDevice = false;
		}

		override protected function _initConfig ():void {
			/*
			if (LocationUtil.isIde()) {
				Config.xml_path = "http://staging.calacademy.org/webcams/monitor/streams.php";
			} else {
				Config.xml_path = "http://www.calacademy.org/webcams/monitor/streams.php";
			}
			*/

			Config.xml_path = "http://internal-prod.calacademy.org/webcams/monitor/streams.php";
			Config.ga_account = null;
		}

		override protected function _getVideoPlayerInstance (config:Object = null):VideoPlayback {
			return new VideoPlaybackLiveMonitor(_data.getXml(), _alt, config);
		}

		override protected function _initConfigAfterDataLoad ():void {
			Config.idleTimeoutMinutes = 0;
		}

		override protected function _onDataError (e:* = null):void {
			_destroyDatabase();

			// try reloading data
			_loadData();
		}

		override protected function _onVideoError (e:ContentEvent = null, timeout:Boolean = false):void {
			trace("Monitor._onVideoError");
			trace(e);

			var errorType:String = (timeout) ? "Timeout Error" : "Error";
			_tracker.track("Video", errorType, _selectedStream);

			_resetTrackingInterval();
			_buffer(false, false);

			var stream:Object = _video.streams[_streamIndex];
			trace("Buffering failed! " + stream.uri + stream.name + stream.level);

			// try buffering the next stream
			_incrementStreams();
			_playLastStream();
		}

		override protected function _onVideoPlaying (e:ContentEvent):void {
			super._onVideoPlaying(e);
			trace("Monitor._onVideoPlaying");

			var stream:Object = _video.streams[_streamIndex];
			_sendPulse.pulse(stream.uri, stream.name, stream.level);

			// try buffering the next stream after a short delay
			_incrementStreams();

			var foo:Interval = Interval.setTimeout(_playLastStream, Config.monitorDelay * 1000);
			foo.start();
		}

		protected function _incrementStreams ():void {
			_streamIndex++;

			if (_streamIndex >= _video.streams.length) {
				_streamIndex = 0;
				_cycleComplete = true;
			}
		}

		protected function _playNext ():void {
			trace("Monitor._playNext: " + _streamIndex);

			this.addEventListener(Event.ENTER_FRAME, _pollBuffering);

			if (_buffering.onStage) _buffering.reset();
			_buffer(true);

			try {
				_selectedStream = _video.streams[_streamIndex].name;
				_tracker.track("Video", "Select", _selectedStream);
				_resetTrackingInterval();
				_video.play(_selectedStream, _streamIndex);
			} catch (e:*) {
				_onVideoError();
			}
		}

		override protected function _playLastStream (restart:Boolean = false):void {
			// do a maintenance restart
			if (_cycleComplete && Config.reboot) {
				_video.destroy();
				this.reboot();
				return;
			}

			// do nothing if video hasn't been initialized
			if (!_isDataLoaded || _video == null) return;

			// destroy and reinit video
			_initVideo(_video.streams[_streamIndex]);

			// start playing
			_playNext();
		}
	}
}
