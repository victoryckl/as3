package org.zengrong.media
{
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import mx.core.UIComponent;
	
	[Event(name='close', type='flash.events.Event')]
	[Event(name='complete', type='flash.events.Event')]
	
	//
	[Bindable]
	public class VideoDisplay extends UIComponent
	{
		private var _video:Video;
		private var _type:String;
		private var _playing:Boolean = false;
		private var _streamName:String;
		private var _serverURI:String;
		private var _nc:NetConnection;
		private var _ns:NetStream;
		
		public static const URISTREAM:String = 'uristream'
		public static const NETSTREAM:String = 'netstream';
		public static const CAMERA:String = 'camera';
		
		public function VideoDisplay($width:int=320, $height:int=240)
		{
			this.width = $width;
			this.height = $height;
		}
		
		public function get type():String
		{
			return _type;
		}
		
		public function get playing():Boolean
		{
			return _playing;
		}
		
		protected override function createChildren(): void 
		{
			super.createChildren();
			if(_video)
			{
				_video.width = this.width;
				_video.height = this.height;
			}
			else
			{
				_video = new Video(this.width, this.height);
			}
			this.addChild(_video);
			_video.visible = false;
//			trace('VideoDisplay.createChildren,width:',this.width,',height:', height);
		}
		
		public function attachNetStream($ns:NetStream):void
		{
			if(type != null) throw new Error('VideoDisplay已經被用於NetStream視訊！');
			_type = NETSTREAM;
			_playing = true;
			_video.clear();
			_video.attachNetStream($ns);
			_video.visible = true;
//			trace('VideoDisplay.attachNetStream,ns:', $ns);
		}
		
		public function attachCamera($cam:Camera):void
		{
			if(type != null) throw new Error('VideoDisplay已經被用於Camera視訊！');
			_type = CAMERA;
			_playing = true;
			_video.clear();
			_video.attachCamera($cam);
			_video.visible = true;
//			trace('VideoDisplay.attachCamera:_video.width:',_video.width,'$cam.width:',$cam.width);
		}
		
		public function attachURIStream($serverURI:String, $streamName:String, $param:*=null):void
		{
			var __streamNameArr:Array = $streamName.split('.');
			//如果当前类型为空，就初始化
			if(type == null || type == URISTREAM) 
			{
				_serverURI = $serverURI;
				//将streamName变成需要的形式
				_streamName = __streamNameArr[1] + ':' + __streamNameArr[0];
				initnc();
				_nc.connect(_serverURI, $param);
				_video.visible = true;
				_type = URISTREAM;	
			}	
			else
			{
				throw new Error('VideoDisplay已經被用於其它視訊！');		
			}
		}
		
		private function initnc():void
		{
			if(_nc == null)
			{
				_nc = new NetConnection();
				_nc.addEventListener(NetStatusEvent.NET_STATUS, ncStatus_Handler);
			}
			else
			{
				if(_nc.connected)
				{
					close();
				}
			}
		}
		
		private function ncStatus_Handler(evt:NetStatusEvent):void
		{
			trace('VideoDisplay,nc statue:', evt.info.code);
			switch(evt.info.code)
			{
				case NCType.SUCCESS:
					if(_ns == null)
					{
						_ns = new NetStream(_nc);
						_ns.addEventListener(NetStatusEvent.NET_STATUS, nsStatus_Handler);
						_ns.client = new StreamClient(this);
					}
					_ns.play(_streamName);
					_video.attachNetStream(_ns);
					trace('nc success， uri:', _nc.uri, ' streamName:', _streamName);
					break;
				case NCType.CLOSED:
					if(_ns != null)
					{
						_ns.close();
						_ns.removeEventListener(NetStatusEvent.NET_STATUS, nsStatus_Handler);
						_ns = null;
					}
					dispatchEvent(new Event(Event.CLOSE));
					break;
			}
		}
		
		private function nsStatus_Handler(evt:NetStatusEvent):void
		{
			trace('VideoDisplay,ns statue:', evt.info.code);
		}
		
		public function clear():void
		{
//			trace(Util.getTime(), "//**** VideoDisplay.clear 执行****//");
			if((type==NETSTREAM) || (type==URISTREAM))
			{
				_video.attachNetStream(null);
//				trace(Util.getTime(), "停止显示NetStream");
			}
			else if(type == CAMERA)
			{				
				_video.attachCamera(null);
//				trace(Util.getTime(), "停止显示Camera");
			}
			_playing = false;
			_video.clear();
			_video.visible = false;
//			trace(Util.getTime(), "清除显示内容");
			
		}
		
		public function close():void
		{
			clear();
			if(_type == URISTREAM)
			{
				if(_nc.connected) _nc.close();
			}
			_type = null;
		}
		
		protected override function updateDisplayList(unscaledWidth: Number, unscaledHeight:Number):void 
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
//			trace(Util.getTime(), "VideoDisaplay中的updateDisplayList运行,type:", type, ",unscaledWidth:",unscaledWidth,",unscaledHeight:",unscaledHeight);
			_video.width = unscaledWidth;
			_video.height = unscaledHeight;
//			_video.clear();
//			trace(Util.getTime(), "_video.width,height:",_video.width,_video.height);
//			trace(Util.getTime(), "this.width,height:",this.width,this.height);
		}
	}
}

import org.zengrong.media.VideoDisplay;
import flash.events.Event;
class StreamClient
{
	private var _videoDisplay:VideoDisplay;
	
	public function StreamClient($video:VideoDisplay)
	{
		_videoDisplay = $video;
	} 

	public function onPlayStatus($obj:Object):void
	{
		trace('NetStream.onPlayStatus:', $obj.code);
		if($obj.code == 'NetStream.Play.Complete')
		{
			_videoDisplay.dispatchEvent(new Event(Event.COMPLETE));
		}
	}
	
	public function onMetaData($obj:Object):void
	{
		trace($obj);
	}
}