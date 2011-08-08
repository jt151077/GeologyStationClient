﻿package  {		import flash.display.*;	import flash.events.*;	import flash.media.Sound;	import flash.media.SoundChannel;	import flash.utils.Timer;		import gs.TweenLite;
		public class QuizMode_backup extends MovieClip {				private var qTF:TField = new TField(Fonts.qText(), 1200);		private var maskCircle:MovieClip = new MovieClip();		private var bgshape:Sprite;		private var default_bg_color:uint = 0xff4400;		//private var restartTimer:Timer = new Timer(4000, 1);		private var qText:String;				private var image:MovieClip = new MovieClip();		private var channel:SoundChannel;		private var snd:Sound;				public function QuizMode_backup(qImage:Bitmap, qT:String, snd:Sound) {					this.snd = snd;			channel = new SoundChannel();			channel = this.snd.play();									qText = qT;						image.addChild(qImage);			addChild(image);						image.x = 100;			image.y = 200;						maskCircle.graphics.lineStyle(0);			maskCircle.graphics.beginFill(0xffffff)			maskCircle.graphics.drawCircle(2, 2, 10);			maskCircle.x = 1920/2;			maskCircle.y = 1080/2;			maskCircle.graphics.endFill();						addChild(maskCircle);			image.mask = maskCircle;						qTF.content = qT;			qTF.x = 120;			qTF.y = 100;			addChild(qTF);							TweenLite.to(maskCircle, 5, {scaleX: 200, scaleY: 200});			//TweenLite.to(image, 10, {y:200})			//restartTimer.addEventListener(TimerEvent.TIMER_COMPLETE, reset);						initBG();						addChildAt(bgshape, 0);			bgshape.alpha = 0;		}				public function stopSound():void {			if(this.snd != null) {				channel.stop();			}		}						public function reset():void {			qTF.content = "";			TweenLite.to(maskCircle, 0.2, {scaleX: 0.1, scaleY: 0.1, onComplete: poseQ})		}								private function poseQ():void {						qTF.content = qText;			qTF.x = 120;			qTF.y = 100;						maskCircle.graphics.drawCircle(2, 2, 10);			maskCircle.x = stage.stageWidth/2;			maskCircle.y = stage.stageHeight/2;						image.alpha = 1;				bgshape.alpha = 0;			image.mask = maskCircle;					TweenLite.to(maskCircle, 5, {scaleX: 200, scaleY: 200});		}						private function updateText(t:String, c:uint):void {			bgshape.alpha = 1;			changeBGColor(c);			bgshape.mask = maskCircle;			image.alpha = 0;			//qTF.mask = maskCircle;			maskCircle.x = stage.stageWidth/2 - 50;			maskCircle.y = qTF.y = stage.stageHeight/2 - 50;			qTF.x = stage.stageWidth/2 - 225;			TweenLite.to(maskCircle, 0.2, {scaleX: 25, scaleY: 25});						qTF.content = t;						//restartTimer.start();		}				public function correctAnswer():void {			qTF.content = "";			TweenLite.to(maskCircle, 0.2, {scaleX: 0.1, scaleY: 0.1, onComplete:updateText, onCompleteParams:['Det er riktig.\nKjempebra!', 0x00bb44]})														}				public function wrongAnswer():void {			qTF.content = "";			TweenLite.to(maskCircle, 0.2, {scaleX: 0.1, scaleY: 0.1, onComplete:updateText, onCompleteParams:['Det er ikke riktig.\nPrøv igjen!', 0xff4400]})							}		private function initBG()		{			bgshape = new Sprite();			bgshape.graphics.beginFill(default_bg_color);			bgshape.graphics.drawRect(0,0,1920, 1080);			addChildAt(bgshape, 0);			//stage.addEventListener(Event.RESIZE, resizeBGWithStage);		}				private function changeBGColor(color:uint) 		{			bgshape.graphics.beginFill(color);			bgshape.graphics.drawRect(0,0, 1920, 1080);		}						private function resizeBGWithStage(e:Event)		{			try {				bgshape.width = 1920;				bgshape.height = 1080;			} catch(e){}		}			}	}