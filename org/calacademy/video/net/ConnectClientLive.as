package org.calacademy.video.net {
	use namespace flvplayback_internal;
	
	import fl.video.*;
	import flash.net.NetConnection;

	public class ConnectClientLive extends ConnectClientDynamicStream {
		public function ConnectClientLive (owner:NCManager, nc:NetConnection, connIndex:uint = 0) {
			super(owner, nc);
	  	}

		public function onFCUnsubscribe (info:Object):void {}
	}
}  