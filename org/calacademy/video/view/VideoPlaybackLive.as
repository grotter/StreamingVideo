package org.calacademy.video.view {
	import fl.video.*;
	import flash.net.NetStream;
	import flash.net.NetConnection;
	import flash.events.NetStatusEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.casalib.util.ArrayUtil;
	import org.casalib.util.FlashVarUtil;
	import org.casalib.time.Interval;
	
	import org.calacademy.video.view.VideoPlayback;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.Config;
	
	import org.calacademy.video.net.NCListener;
	import org.calacademy.video.net.NCManagerSingleConnection;
	import org.calacademy.video.net.NCManagerFCSubscribe;
	
	public class VideoPlaybackLive extends VideoPlayback {
		protected var _data:XML;
		protected var _streams:Array;
		protected var _selectedStream:Object;
		protected var _listener:NCListener;
		protected var _connectAttempts:int;
		protected var _reconnectInterval:Interval;
		protected var _fcsubscribe:Boolean = false;
		
		public function VideoPlaybackLive (data:Object = null, alt:Boolean = false, config:Object = null) {
			super(data, alt, config);
		}

		public function get streams ():Array {
			return _streams;
		}

		override protected function init (data:Object = null, config:Object = null):void {
			if (data == null) {
				trace("Invalid stream data!");
				return;
			}
			
			_data = data;
			_setVideoConfig(config);
			_resetReconnectInterval();

			// listening to NetConnection status events with FLVPlayback and
			// NCManager requires some customization
			_listener = NCListener.getInstance();
            _listener.removeEventListeners();
			_listener.addEventListener(NetStatusEvent.NET_STATUS, _onConnectionStatus);
			
			_initStream();
			_initVideo();
		}
		
		protected function _setVideoConfig (config:Object = null):void {
			if (_alt) {
				_fcsubscribe = (_data.@altfcsubscribe == "1");
			} else {
				_fcsubscribe = (_data.@fcsubscribe == "1");
			}
			
			// setting video encoding dimensions from...
			if (FlashVarUtil.hasKey("w") && FlashVarUtil.hasKey("h")) {
				// flashvars
				_dimensions = {
					w: int(FlashVarUtil.getValue("w")),
					h: int(FlashVarUtil.getValue("h"))
				};
			} else {
				// xml config
				_dimensions = {
					w: _data.@width,
					h: _data.@height
				};
			}
		}

		override public function play (streamName:String, streamIndex:* = null):void {
			_closing = false;
			
			var stream:Object;
			
			if (streamIndex == null) {
				stream = ArrayUtil.getItemByKey(_streams, "name", streamName)
			} else {
				stream = _streams[streamIndex];
			}
			
			if (stream == null) {
				_onVideoError({
					info: {
						level: "error",
						code: "NetStream.Play.StreamNotFound"
					}
				});
				return;
			} else {
				if (_selectedStream != null) {
					if (streamName != _selectedStream.name) {
						// selecting a different stream
						_resetReconnectInterval();
					}
				}
				
				_selectedStream = stream;
			}
			
			_connectAttempts++;
			this.removeEventListener(Event.ENTER_FRAME, _pollFPS);
			this.addEventListener(Event.ENTER_FRAME, _pollConnection);
			
			trace("VideoPlaybackLive.play: " + _selectedStream.name);
			trace("Connection attempt #" + _connectAttempts);
			
			try {
				_flvPlayback.play2(_selectedStream.ds);
				this.source = _selectedStream.name;
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
		
		protected function _initStream ():void {
			_streams = new Array();
			 
			if (FlashVarUtil.hasKey("stream") && FlashVarUtil.hasKey("kbps")) {
				// setting stream names & kbps from flashvars
				
				var dsFlashVar:DynamicStreamItem = new DynamicStreamItem();
				var streamNameFlashVar:String = FlashVarUtil.getValue("stream");
				
				dsFlashVar.uri = _data.@rtmphost;
				dsFlashVar.addStream(streamNameFlashVar + "1", int(FlashVarUtil.getValue("kbps")));
				
				_streams.push({
					name: streamNameFlashVar,
					ds: dsFlashVar
				});
			} else {
				// setting stream names and bitrates from xml config
				var streamData = _alt ? _data.altcam : _data.cam;
				var rtmphost:String = _alt ? _data.@altrtmphost : _data.@rtmphost;

				for each (var node:XML in streamData) {
					var ds:DynamicStreamItem = new DynamicStreamItem();
					var streamName:String = node.prefix.toString();

					ds.uri = rtmphost;

					for each (var stream:XML in node.streams.stream) {
						var bitrate:Number = Number(stream.@bitrate);
						
						if (stream.@level == undefined) {
							ds.addStream(streamName, bitrate);
						} else {
							ds.addStream(streamName + stream.@level, bitrate);
						}
					}

					_streams.push({
						name: streamName,
						ds: ds
					});
				}
			}
		} 

		override protected function _initVideo ():void {
			// setup video display
			if (_fcsubscribe) {
				VideoPlayer.iNCManagerClass = NCManagerFCSubscribe;
			} else {
				VideoPlayer.iNCManagerClass = NCManagerSingleConnection;
			}
			
			_flvPlayback = new FLVPlayback();
			_initVideoProperties(true);
			_setVideoSize();
			
			this.addChild(_flvPlayback);
		}
        
		override protected function _onVideoStop ():void {}

		override protected function _onStreamFailure (e:*):void {
			// trigger NetConnection.Connect.Closed
			_resetReconnectInterval();
			super._onStreamFailure(e);
		}
		
		override protected function _onConnectionFailure (e:ContentEvent):void {
			if (_closing) return;
			_resetReconnectInterval(false);
			_reconnectInterval.start();
		}
		
		override protected function _onStreamProgress (e:ContentEvent):void {
			_resetReconnectInterval();
			super._onStreamProgress(e);
		}
		
		override protected function _onBuffer (e:ContentEvent):void {
			super._onBuffer(e);
			
			// reconnect in case connection was lost during playback of last buffer
			var nc = this.getNetConnection();
			
			if (nc != false) {
				if (nc.connected) {
					return;
				}
			} 
			
			// already trying
			if (_reconnectInterval.running) return;
			
			_reconnect();
		}
		
		protected function _reconnect ():void {
			trace("VideoPlaybackLive._reconnect");
			
			this.dispatchEvent(new ContentEvent(ContentEvent.PROGRESS));
			
			if (_connectAttempts == Config.connectAttempts) {
				// maximum number of connection attempts reached, dispatch an error
				trace("Maximum number of connection attempts reached!");
				
				_onVideoError({
					info: {
						level: "error",
						code: "NetConnection.Connect.Failed"
					}
				});
				return;
			}
			
			if (_selectedStream != null) {
				this.dispatchEvent(new ContentEvent(ContentEvent.BUFFERING)); 
				this.play(_selectedStream.name);
			}
		}
		
		protected function _resetReconnectInterval (resetAttempts:Boolean = true):void {
			if (_reconnectInterval != null) _reconnectInterval.destroy();
			_reconnectInterval = Interval.setTimeout(this._reconnect, Config.reconnectInterval);
			if (resetAttempts) _connectAttempts = 0;
		}
		
		override protected function _onPlay ():void {
			super._onPlay();
			_resetReconnectInterval(); 
		}
        
		override protected function _stopPolling ():void {
			_resetReconnectInterval();
			super._stopPolling();
		}
	}
}
