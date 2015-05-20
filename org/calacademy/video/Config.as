package org.calacademy.video {
    
	/**
	 * Some configuration settings
	 * 
	 * @langversion ActionScript 3
	 * @playerversion Flash 9.0.0
	 * 
	 * @author Rotter, Greg
	 * @since  18.08.2010
	 */
	public class Config {
		public static const DEBUG:Boolean = false;
		
		// public static var xml_path:String = "xml/cam/";
		public static var xml_path:String = "xml/generic.xml";
		
		public static var grab_path:String = "../xml/grab/";
		public static var screenGrabConfigKey:String = "";
		// public static var grab_path:String = "http://www-local.calacademy.org/webcams/xml/grab/";
		
		public static var flat_video_path:String = "pocketpenguins.flv";
		public static var shared_object_name:String = "farallonesUserData";
		public static var ga_account:String = "UA-6206955-8";
		
		public static var loadingMessage:String = "Connecting...";
		public static var staticLoadingMessage:String = "Positioning camera...";
		public static var stageWidth:Number = 480;
		public static var stageHeight:Number = 320;
		
		public static var msgScreenGrab:Object = {
			title: "Upload a Snapshot",
			body: "Sign and post this snapshot to our Flickr group, then share it with your friends!"
		};
		
		public static var msgScreenGrabComplete:Object = {
			title: "Upload Complete!",
			body: "Would you like to view your snapshot on Flickr?"
		};
		
		public static var msgScreenGrabError:Object = {
			title: "Oops.",
			body: "The server encountered a problem uploading your snapshot. Would you like to try again?"
		};
		
		public static var msgKillControlling:Object = {
			title: "Pardon the interruption.",
			body: "The biologists need to use the camera. Your time will continue when the camera becomes available at approximately %%time_reactivation%% PST. Thank you."
		};
		
		public static var msgKillInQueue:Object = {
			title: "Pardon the interruption.",
			body: "The biologists need to use the camera until approximately %%time_reactivation%% PST. Your order in the queue will remain while you stay on this page. Thank you."
		};
		
		public static var msgKillNotInQueue:Object = {
			title: "Pardon the interruption.",
			body: "The biologists need to use the camera until approximately %%time_reactivation%% PST. The queue will open when their work is completed. Thank you."
		};
		
		public static var msgInactiveEncoder:Object = {
			title: "Currently Offline",
			body: "Please check back soon. Would you like to view an interactive panorama of the island?"
		};
		
		public static var msgInactiveEncoderEmbed:Object = {
			title: "Currently Offline",
			body: "Please check back soon."
		};
		
		public static var msgFlatVideoComplete:Object = {
			body: "Would you like to replay the presentation?"
		};

		public static var msgPtzError:Object = {
			title: "Oops.",
			body: "The camera control request failed. Please try again."
		};
		
		public static var msgDataError:Object = {
			title: "Oops.",
			body: "A network connection could not be found. Please try again."
		};
		
		public static var msgVideoError:Object = {
			title: "Oops.",
			body: "Your network connection appears to have been lost. Please try again."
		};
		
		public static var msgIdle:Object = {
			title: "Idle Timeout",
			body: "Would you like to continue streaming?"
		};
		
		// the following values should be considered defaults.
		// they will be reset with values loaded off the server when available.
		
		public static var trackingPulse:int = 10000;
		public static var camControlPulse:int = 3000;
		public static var timeoutDuration:int = 10000;
		public static var reconnectInterval:int = 3000;
		public static var connectAttempts:int = 3;
		public static var idleTimeoutMinutes:int = 0;
		public static var bufferTime:int = 10;
		public static var idleThreshold:int = 5000;
		
		public static var server:String = "";
		public static var ptzDataUrl:String = "/webcams/farallones/xml/ptz/";
		public static var miscDataUrl:String = "/webcams/farallones/xml/";
		
		public static var logoUrl:String = "http://www.calacademy.org/";
		public static var smsUrl:String;
		public static var isSmsCapable:Boolean = false;
		public static var reboot:Boolean = false;
		
		public static var msgLogoClick:Object = {
			title: "Visit us Online",
			body: "For general Academy information, purchasing tickets, feedback on this app, terms of service and more!"
		};
		
		public static var msgSms:Object = {
			title: "Help Advance our Mission",
			body: "Text PENGUINS to 20222<br>to donate $5. A charge will appear on your phone bill."
		};
		
		public static var moneyAltFrameLabel:String = "buy-tickets";
		public static var moneyAltUrl:String = "http://www.calacademy.org/tickets/";
		
		public static var msgAltMoney:Object = {
			title: "Purchase Tickets",
			body: "Would you like to visit our<br>website to purchase museum tickets?"
		};
	}
}
