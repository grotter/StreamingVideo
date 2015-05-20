package org.calacademy.video.net {
	use namespace flvplayback_internal;

	import fl.video.*;
	import flash.net.NetConnection;
    
	/**
	 * Handle some weird CDN requirements
	 * @see http://www.seanhsmith.com/2009/10/05/live-flash-with-flvplayback-2-5-limelight-akamai/
	 *
	 * @author Greg Rotter
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
	 */
	public class NCManagerFCSubscribe extends NCManagerSingleConnection {
        
		public function NCManagerFCSubscribe () {}

		override flvplayback_internal function onConnected (p_nc:NetConnection, p_bw:Number):void {
			super.onConnected(p_nc, p_bw);
			
			for (var i in this.streams) {
				var stream:Object = this.streams[i];
				// trace("NCManagerFCSubscribe.onConnected / FCSubscribe: " + stream.src);
				
				this.netConnection.call("FCSubscribe", null, stream.src);
			}
		}
	} 
}
