package org.calacademy.video.net {
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	import org.calacademy.video.Config;
	
	public class NetworkCapabilities extends Object {
		public var isSMSCapable:Boolean = false;
		
		public function NetworkCapabilities () {
			super();
			
			if (NetworkInfo.isSupported) {
				var interfaces:Vector.<NetworkInterface> = NetworkInfo.networkInfo.findInterfaces();

				for each (var obj:NetworkInterface in interfaces) { 
					trace("name: " + obj.name); 
					trace("display name: " + obj.displayName); 
					trace("mtu: " + obj.mtu); 
					trace("active: " + obj.active); 
					trace("parent interface: " + obj.parent); 
					trace("hardware address: " + obj.hardwareAddress);

					if (obj.subInterfaces != null) { 
						trace("# subinterfaces: " + obj.subInterfaces.length); 
					}                 

					trace("---------");
				}
			} else {
				trace("NetworkInfo not supported!");
			}
		}
	}
}
