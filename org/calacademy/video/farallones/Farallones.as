package org.calacademy.video.farallones {
	import flash.display.StageDisplayState;
	import flash.display.Stage;
	import flash.events.FullScreenEvent;
	
	import org.casalib.display.CasaSprite;
	import org.casalib.display.CasaMovieClip;
	import org.casalib.util.StageReference;
	import org.casalib.time.Interval;
	import org.casalib.events.LoadEvent;
	import org.casalib.util.LocationUtil;
	import org.casalib.util.FlashVarUtil;
	
	import org.calacademy.video.Config;
	import org.calacademy.video.view.Logo;
	import org.calacademy.video.farallones.view.LiveStreamDataDisplay;
	import org.calacademy.video.farallones.view.Map;
	import org.calacademy.video.farallones.view.CamControl;
	import org.calacademy.video.farallones.view.FarallonesVideo;
	import org.calacademy.video.farallones.view.FarallonesVideoEmbed;
	import org.calacademy.video.farallones.view.PanoramaButton;
	import org.calacademy.video.farallones.view.FullScreenButton;
	import org.calacademy.video.farallones.data.LiveStreamData;
	import org.calacademy.video.events.ContentEvent;
	import org.calacademy.video.events.XmlEvent;
	
	public class Farallones extends CasaMovieClip {
		private var _video:FarallonesVideo;
		private var _map:Map;
		private var _info:LiveStreamDataDisplay;
		private var _padding:Number = 10;
		private var _database:LiveStreamData;
		private var _dataInterval:Interval;
		private var _camControl:CamControl;
		private var _panoramaButton:PanoramaButton;
		private var _fullScreenButton:FullScreenButton;
		private var _stage:Stage;
		private var _mask:CasaSprite;
		private var _bg:CasaSprite;
		private var _origBgPosition:Object;
		private var _isEmbed:Boolean = false;
		
		public function Farallones () {
			super();
			StageReference.setStage(this.stage);
			
			_isEmbed = (FlashVarUtil.getValue("embed") == 1);
			_stage = StageReference.getStage();
			_initStream();
			_initInfoViews();
			_stage.addEventListener(FullScreenEvent.FULL_SCREEN, _onFullScreenToggle);
			
			if (_isEmbed) _initEmbedView();
		}
		
		private function _initEmbedView ():void {						
			_video.fullscreen = true;
			_onFullScreenToggle(null);
			
			var logo:Logo = new Logo();
			logo.x = Config.stageWidth;
			logo.y = Config.stageHeight;
			_video.addChild(logo);
			
			_camControl.x = _padding * 2;
			
			// remove extra stuff
			_info.destroy();
			_map.destroy();
			_bg.destroy();
		}
		
		private function _drawVideoMask (w:Number, h:Number) {
			if (_mask) _mask.destroy();
			
			_mask = new CasaSprite();
			_mask.graphics.beginFill(0xFF0000);
			_mask.graphics.drawRect(0, 0, w, h);
			_video.mask = _mask;
		}
		
		private function _initStream ():void {
			_video = _isEmbed ? new FarallonesVideoEmbed() : new FarallonesVideo();
			_video.addEventListener(ContentEvent.PANO, _onPano);
			_video.addEventListener(XmlEvent.PARSED, _onStreamDataParsed);			
			_drawVideoMask(_video.width, _video.height);
			this.addChild(_video); 
		}
		
		private function _onStreamDataParsed (e:XmlEvent):void {
			trace("Farallones._onStreamDataParsed: setting cam control pulse interval to " + Config.camControlPulse + "ms");
			_dataInterval = Interval.setInterval(_loadData, Config.camControlPulse);
			_dataInterval.start();
		}
		
		private function _onPano (e:ContentEvent):void {
			if (_panoramaButton) _panoramaButton.showPano();
		}
		
		private function _drawBg (w:Number = 251, h:Number = 253, col:Number = 0xffffff, alpha:Number = .05):void {
			_bg.alpha = alpha;
			_bg.graphics.clear();
			_bg.graphics.beginFill(col);
			_bg.graphics.drawRoundRect(0, 0, w, h, 10, 10);
		}
		
		private function _initInfoViews ():void {
			// set up views
			_info = new LiveStreamDataDisplay();
			_info.x = _video.x + _padding;
			_info.y = _video.y + _padding;
            
			_camControl = new CamControl(_video);
			_camControl.addEventListener(ContentEvent.PTZ_ERROR, _video.onPtzError);
			_camControl.addEventListener(ContentEvent.KILL_MESSAGE, _video.onKillMessage);
			_camControl.x = _video.x + _video.width + _padding;
			_camControl.y = _padding * 2; 
			
			_origBgPosition = {
				x: _video.x + _video.width + _padding,
				y: _camControl.y + _camControl.height + _padding - 15
			};
			
			_bg = new CasaSprite();
			_map = new Map();
            _toggleMapFullscreen(false);

			_panoramaButton = new PanoramaButton();
			_fullScreenButton = new FullScreenButton();
			_fullScreenButton.addEventListener(ContentEvent.FULLSCREEN, _onFullscreenSelect);
			
			_panoramaButton.y = _fullScreenButton.y = _bg.y + _bg.height - _panoramaButton.height - _padding;
			_panoramaButton.x = _bg.x + _padding; 
			_fullScreenButton.x = _bg.x + _bg.width - _fullScreenButton.width - _padding;
			
			this.addChild(_bg);
			this.addChild(_panoramaButton);
			this.addChild(_fullScreenButton);
			this.addChild(_info);
			this.addChild(_map);
			this.addChild(_camControl);

			// start polling the database
			_database = LiveStreamData.getInstance();
			_database.addEventListener(LoadEvent.COMPLETE, _onDataLoaded);
			
			// init views
			_onDataLoaded(null);
			
			// do an immediate load call
			_loadData();
		}
		
		private function _onFullscreenSelect (e:ContentEvent):void {
			if (LocationUtil.isIde()) {
				// for dev only
				_onFullScreenToggle(null);
			} else {
				_stage.displayState = StageDisplayState.FULL_SCREEN;
			}
		}
		
		private function _onFullScreenToggle (event:FullScreenEvent):void {
		    _panoramaButton.visible = !_panoramaButton.visible;
			_fullScreenButton.visible = !_fullScreenButton.visible;
			_camControl.fullscreen = !_camControl.fullscreen;
		    _drawVideoMask(_video.width, _video.height);
			_toggleMapFullscreen(_video.fullscreen);
			
			if (_video.fullscreen) {
				_camControl.x = _stage.stageWidth - _camControl.width;
			} else {
				_camControl.x = _video.x + _video.width + _padding;
			}
		}
		
		private function _toggleMapFullscreen (fullscreen:Boolean):void {
			if (fullscreen) {
				_drawBg(251, 220, 0x000000, .5);
				_bg.x = _padding;
				_bg.y = _stage.stageHeight - _bg.height - _padding - 2;
			} else {
				_drawBg();
				_bg.x = _origBgPosition.x;
				_bg.y = _origBgPosition.y;
			}

			_map.x = _bg.x + _padding;
			_map.y = _bg.y + _padding;
		}
		
		private function _loadData ():void {
			_database.load();
		}
		
		private function _onRequestControl (e:ContentEvent):void {
			_loadData();
		}

		private function _onDataLoaded (e:LoadEvent):void {
			if (_info) _info.update(_database.data);
			if (_map) _map.update(_database.data);
						
			// don't bother activating cam control if not streaming
			if (_video.isActive) {
				if (_camControl) {
					_camControl.update(_database.data);
				}
			}
		}
		
		override public function destroy ():void {
			_database.destroy();
			_dataInterval.destroy();
			super.destroy();
		} 
	}
}
