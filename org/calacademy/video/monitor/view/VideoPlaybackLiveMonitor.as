package org.calacademy.video.monitor.view {	
	import fl.video.*;
	import org.calacademy.video.view.VideoPlaybackLive;

	public class VideoPlaybackLiveMonitor extends VideoPlaybackLive {
		public function VideoPlaybackLiveMonitor (data:Object = null, alt:Boolean = false, config:Object = null) {
			super(data, alt, config);
		}

		override protected function _setVideoConfig (config:Object = null):void {
			if (config == null) {
				// this is only needed for the first unused init invocation
				super._setVideoConfig();
				return;
			}

			_fcsubscribe = (config.fcsubscribe == "1");

			_dimensions = {
				w: config.width,
				h: config.height
			};
		}

		// XML structure for monitoring is slightly different
		override protected function _initStream ():void {
			_streams = new Array();
			 
			// setting stream names and bitrates from xml config
			for each (var node:XML in _data.cam) {
				var ds:DynamicStreamItem = new DynamicStreamItem();
				var streamName:String = node.prefix.toString();

				var stream:Object = node.stream;

				ds.uri = node.rtmphost.toString();
				ds.addStream(streamName + stream.@level, stream.@bitrate);

				_streams.push({
					uri: ds.uri,
					name: streamName,
					level: stream.@level,
					ds: ds,
					width: stream.@width,
					height: stream.@height,
					fcsubscribe: node.rtmphost.@fcsubscribe
				});
			}
		} 
	}
}
