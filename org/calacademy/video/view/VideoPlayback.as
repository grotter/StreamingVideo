package org.calacademy.video.view {
	import org.casalib.display.CasaSprite;
	import fl.video.*;
	import flash.net.NetStream;
	import flash.net.NetConnection;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.geom.Rectangle;
	import flash.display.Bitmap; 
	import flash.display.BitmapData;
	import org.casalib.util.StringUtil;
	import org.casalib.util.RatioUtil;
	import com.greensock.TweenLite;
	import com.greensock.easing.*;
	
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.Config;
	
	public class VideoPlayback extends CasaSprite {
		protected var _flvPlayback:FLVPlayback;
		protected var _ns:NetStream;
		protected var _hasPlayed:Boolean = false;
		protected var _closing:Boolean = false;
		protected var _dimensions:Object = {w: 640, h: 480};
		protected var _alt:Boolean = false;
		
		public var source:* = false;
		
		public function VideoPlayback (data:Object = null, alt:Boolean = false, config:Object = null) {
			super();
			_alt = alt;
			init(data, config);
		}
		
		protected function init (data:Object = null, config:Object = null):void {
			_initVideo();
		}
		
		public function set volume (myVolume:Number):void {
			if (_flvPlayback == null) return;
			TweenLite.killTweensOf(_flvPlayback);
			
			TweenLite.to(_flvPlayback, 3.5, {
				volume: myVolume,
				delay: .1,
				ease: Expo.easeOut
			});
		}
		
		public function close (closing:Boolean = true):void {
			this.source = false;
			_stopPolling();
			_closing = closing;			
			if (_flvPlayback != null) _flvPlayback.getVideoPlayer(0).close();
		}
		
		public function getQoS ():* {
			if (_ns == null || !_ns) return false;
			if (_ns.info == null) return false;
			return _ns.info;
		}
		
		public function play (streamName:String, streamIndex:* = null):void {
			_closing = false;
			
			this.removeEventListener(Event.ENTER_FRAME, _pollFPS);
			this.addEventListener(Event.ENTER_FRAME, _pollConnection);
            
			try {
				_flvPlayback.play(streamName);
				this.source = streamName;
			} catch (e:Error) {
				// invalid stream
				_onVideoError({
					info: {
						level: "error",
						code: "NetConnection.Connect.Failed"
					}
				});
			}
		}
		
		public function getStill ():* {
			// nothing to capture
			if (!_hasPlayed) return false;
			
			// rtmp://brightcove.fc.llnwd.net/brightcove/156
			try {
				var myBitmapData:BitmapData = new BitmapData(_flvPlayback.width, _flvPlayback.height);
			    myBitmapData.draw(_flvPlayback);
			} catch (error:*) {
				return false;
			}
		    
			var myBitmap:Bitmap = new Bitmap(myBitmapData);
			myBitmap.smoothing = true;
			
		    return myBitmap;
		}
		
		public function isPlaying ():Boolean {
			return (_getFPS() > 0);
		}
		
		protected function _initVideoProperties (isLive:Boolean):void {
			_flvPlayback.fullScreenTakeOver = false;
			_flvPlayback.getVideoPlayer(0).smoothing = true;
			// _flvPlayback.getVideoPlayer(0).deblocking = 4;
			_flvPlayback.autoPlay = false;
			_flvPlayback.isLive = isLive;
			_flvPlayback.visible = false;
			_flvPlayback.volume = 0;
			_flvPlayback.idleTimeout = 1000 * 60 * 60 * 24; // 1 day   
		}
		
		protected function _initVideo ():void {
			// setup video display
			trace("VideoPlayback._initVideo");
			
			_flvPlayback = new FLVPlayback();
		    _initVideoProperties(false);
			_setVideoSize();
			
			this.addChild(_flvPlayback);
		}
		
		protected function _pollConnection (e:*):void {
			var ns = this.getNetStream();
			if (!ns) return;
			
			this.removeEventListener(Event.ENTER_FRAME, _pollConnection);

			_ns = ns;
			_ns.addEventListener(NetStatusEvent.NET_STATUS, _onConnectionStatus);
			trace("_ns.bufferTime: " + _ns.bufferTime);
		}
		
		public function getPercentBuffered ():Number {
			var ns = this.getNetStream();
			if (!ns) return 0;
			if (isNaN(ns.bufferLength)) return 0;
			
			var per:Number = Math.floor((ns.bufferLength / ns.bufferTime) * 100);
			if (per > 99) per = 99;
			
			return per;
		}
		
		public function getBufferLength ():Number {
			var ns = this.getNetStream();
			
			if (!ns) return 0;
			
			if (isNaN(ns.bufferLength)) {
				return 0;
			} else {
				return ns.bufferLength;
			}
		}
		
		public function getNetStream ():* {
			var ns = _flvPlayback.getVideoPlayer(0).netStream;
			if (ns == null) return false;
			
			return ns;
		}
		
		public function getNetConnection ():* {
			var nc = _flvPlayback.getVideoPlayer(0).netConnection;
			if (nc == null) return false;
			
			return nc;
		}
		
		public function onPlayStatus (info:Object):void {}
		
		public function onMetaData (info:Object):void {}
		
		override public function get x ():Number {
			if (_flvPlayback) {
				return _flvPlayback.x;
			}
			
			return super.x;
		}
		
		override public function get y ():Number {
			if (_flvPlayback) {
				return _flvPlayback.y;
			}
			
			return super.y;
		}
		
		protected function _onConnectionStatus (e:NetStatusEvent):void {
			// handle both NetStream and NetConnection status events
			// @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/events/NetStatusEvent.html#info
			trace("*** " + e.info.code);
			
			/*
			if (e.info.level == "error") {
				_onVideoError(e);
				return;
			}
			*/
			
			switch (e.info.code) {
				case "NetStream.Play.Stop":
					_onVideoStop();
					break;
				case "NetStream.Play.Start":
				case "NetConnection.Connect.Success":
					_onStreamProgress(null);
					break;
				case "NetStream.Buffer.Empty":
					_onBuffer(null);
					break;
				case "NetStream.Buffer.Full":
					_onBufferComplete(null);
					break;
				case "NetConnection.Connect.Closed":
				case "NetConnection.Connect.Failed":
				case "NetConnection.Connect.Rejected":
					_onConnectionFailure(null);
					break;
				case "NetStream.Play.UnpublishNotify":
				case "NetStream.Publish.Idle":
				case "NetStream.Failed":
					_onStreamFailure(e);
					break;
				case "NetStream.Play.Transition":
				case "NetConnection.Connect.IdleTimeout":
				case "NetConnection.Connect.NetworkChange":
					break;
			}
		}
		
		protected function _onVideoStop ():void {
			this.dispatchEvent(new ContentEvent(ContentEvent.STOP));
		}
		
		protected function _onStreamFailure (e:*):void {
			this.dispatchEvent(new ContentEvent(ContentEvent.STREAM_ERROR, e));
		}
		
		protected function _onConnectionFailure (e:ContentEvent):void {}
		
		protected function _onStreamProgress (e:ContentEvent):void {
			this.dispatchEvent(new ContentEvent(ContentEvent.PROGRESS));
		}
		
		protected function _onBufferComplete (e:ContentEvent):void {
			this.addEventListener(Event.ENTER_FRAME, _pollFPS);
		}
		
		protected function _onBuffer (e:ContentEvent):void {
			this.dispatchEvent(new ContentEvent(ContentEvent.BUFFERING));
		}
		
		protected function _onPlay ():void {
			this.dispatchEvent(new ContentEvent(ContentEvent.STREAM_PLAYING));
			_flvPlayback.visible = true;
			_hasPlayed = true; 
		}
		
		protected function _getFPS ():Number {
			if (_ns == null || !_ns) return 0;
			return _ns.currentFPS;
		}
		
		protected function _pollFPS (e:Event):void {
			if (_getFPS() > 0) {
				this.removeEventListener(Event.ENTER_FRAME, _pollFPS);
				_onPlay();
			}
		}
		
		protected function _setVideoSize ():void {
			var videoSize:Rectangle = new Rectangle(0, 0, _dimensions.w, _dimensions.h);
			var bounds:Rectangle = new Rectangle(0, 0, Config.stageWidth, Config.stageHeight);
			var result:Rectangle = RatioUtil.scaleToFill(videoSize, bounds);
			
			_flvPlayback.width = result.width;
			_flvPlayback.height = result.height;
			
			_flvPlayback.x = Math.round((Config.stageWidth - _flvPlayback.width) / 2);
			_flvPlayback.y = Math.round((Config.stageHeight - _flvPlayback.height) / 2);
		}
        
		public function resize ():void {
			_setVideoSize();
		}

		protected function _onVideoError (e:*):void {
			_stopPolling();
			this.dispatchEvent(new ContentEvent(ContentEvent.CONNECTION_ERROR, e));
        }
        
		protected function _stopPolling ():void {
			this.removeEventListener(Event.ENTER_FRAME, _pollFPS);
			this.removeEventListener(Event.ENTER_FRAME, _pollConnection);
		}

		protected function _kill (closing:Boolean = true):void {
			if (_flvPlayback) {
				this.close();
				this.removeChild(_flvPlayback);
				_flvPlayback = null;
			}
			
			_stopPolling();
			super.destroy();
		}
		
		override public function destroy ():void {
			_kill();
		}
	}
}
