package org.calacademy.video.net {
	use namespace flvplayback_internal;

	import fl.video.*;
	import flash.events.TimerEvent;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	
	import org.calacademy.utils.ObjectUtil;
	import org.calacademy.video.net.ConnectClientLive;
	import org.calacademy.video.net.NCListener;
    
	/**
	 * An extension of NCManager for handling stream switching over a single NetConnection
	 * and routing NetConnection status events. Suppresses NC reconnection attempts for outside handling.
	 *
	 * @author Greg Rotter
     * @langversion 3.0
     * @playerversion Flash 9.0.28.0
	 */
	public class NCManagerSingleConnection extends NCManagerDynamicStream {
        protected var _listener:NCListener = NCListener.getInstance();

		public function NCManagerSingleConnection () {}

		override flvplayback_internal function onConnected (p_nc:NetConnection, p_bw:Number):void {
			super.onConnected(p_nc, p_bw);
			this.netConnection.client = ConnectClientLive;
		}
        
		/*
		override flvplayback_internal function connectOnStatus(e:NetStatusEvent):void {
			super.connectOnStatus(e);
			_listener.dispatchEvent(e);
		}
		
		override flvplayback_internal function disconnectOnStatus(e:NetStatusEvent):void {
			super.disconnectOnStatus(e);
			_listener.dispatchEvent(e);
		}
		
		override flvplayback_internal function reconnectOnStatus(e:NetStatusEvent):void {
			super.reconnectOnStatus(e);
			_listener.dispatchEvent(e);
		}
		*/
        
		override public function connectAgain():Boolean {
			return false;
		}
        
		override flvplayback_internal function tryFallBack():void {}

		override flvplayback_internal function nextConnect(e:TimerEvent=null):void {
			var protocol:String;
			var port:String;
			
			if (_connTypeCounter == 0) {
				protocol = _protocol;
				port = _portNumber;
			} else {
				port = null;
				
				if (_protocol == "rtmp:/") {
					protocol = "rtmpt:/"
				} else if (_protocol == "rtmpe:/") {
					protocol = "rtmpte:/"
				} else {
					_tryNC.pop();
					return;
				}
			}
			
			var xnURL:String = protocol + ((_serverName == null) ? "" : "/" + _serverName + ((port == null) ? "" : (":" + port)) + "/") + ((_wrappedURL == null) ? "" : _wrappedURL + "/") + _appName + ((_queryString == null) ? "" : "?"+_queryString);
            
			// skip connection if we already have one
			if (_nc != null) {
				if (_nc.connected) {
					this.onConnected(_nc, 500);
					return;
				}
			}
			
			_tryNC[_connTypeCounter].client.pending = true;
			
			// add custom listener			
			_tryNC[_connTypeCounter].addEventListener(NetStatusEvent.NET_STATUS, function (e:NetStatusEvent) {				
				_listener.dispatchEvent(e);
			});
			
			_tryNC[_connTypeCounter].connect(xnURL, _autoSenseBW);
			
			if (_connTypeCounter < (_tryNC.length-1)) {
				_connTypeCounter++;
				
				// timer attempts to reconnect
				// _tryNCTimer.reset();
				// _tryNCTimer.start();
				_tryNCTimer.stop();
			}
		}
	} 
}
