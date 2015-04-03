package  {
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.getDefinitionByName;
	import flash.utils.Dictionary;
	import scaleform.clik.events.*;
	import scaleform.clik.data.DataProvider;
	
	import ValveLib.*;
	import flash.text.TextFormat;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class Feedback extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;

		var newSubmitBtn:Object;
		var newScoreSlider:Object;
		//var yesWillPlayAgainBtn:Object;
		//var noWillPlayAgainBtn:Object;


		public function Feedback() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			this.gameAPI = api;
			this.globals = globals;
			
			// Font Labels
			var txFormatBold:TextFormat = new TextFormat;
			txFormatBold.font = "$TextFontBold";
			var txFormatTitle:TextFormat = new TextFormat;
			txFormatTitle.font = "$TitleFontBold";

			this.feedbackTitle.text = Globals.instance.GameInterface.Translate("#FeedbackTitle");
			this.feedbackTitle.setTextFormat(txFormatTitle);

			this.q1Title.text = Globals.instance.GameInterface.Translate("#Q1Title");
			this.q1Title.setTextFormat(txFormatBold);

			this.q2Title.text = Globals.instance.GameInterface.Translate("#Q2Title");
			this.q2Title.setTextFormat(txFormatBold);

			this.q3Title.text = Globals.instance.GameInterface.Translate("#Q3Title");
			this.q3Title.setTextFormat(txFormatBold);

			this.q4Title.text = Globals.instance.GameInterface.Translate("#Q4Title");
			this.q4Title.setTextFormat(txFormatBold);

			this.q5Title.text = Globals.instance.GameInterface.Translate("#Q5Title");
			this.q5Title.setTextFormat(txFormatBold);

			this.scoreSliderLabel.text = Globals.instance.GameInterface.Translate("#FeedbackScoreLabel") + " 5/10";				
			this.scoreSliderLabel.setTextFormat(txFormatBold);

			// scoreSlider
			this.newScoreSlider = replaceWithValveComponent(scoreSlider, "Slider_New", true);
			this.newScoreSlider.minimum = 1;
			this.newScoreSlider.maximum = 10;
			this.newScoreSlider.value = 5;
			this.newScoreSlider.snapInterval = 1;
			this.newScoreSlider.snapping = true;
			this.newScoreSlider.addEventListener( SliderEvent.VALUE_CHANGE, onScoreSliderChanged );
			trace("slider width: " + this.newScoreSlider.width + " height: " + this.newScoreSlider.height)


			/*this.noBtn = replaceWithValveComponent(noBtn, "ButtonThinSecondary", true);
			this.noBtn.addEventListener(ButtonEvent.CLICK, onNoButtonClicked);
			this.noBtn.label = Globals.instance.GameInterface.Translate("#No");
			
			this.yesPlayAgainBtn = replaceWithValveComponent(yesBtn, "ButtonThinPrimary", true);
			this.yesPlayAgainBtn.addEventListener(ButtonEvent.CLICK, onYesButtonClicked);
			this.yesPlayAgainBtn.label = Globals.instance.GameInterface.Translate("#Yes");*/

			newSubmitBtn = replaceWithValveComponent(submitBtn, "ButtonThinPrimary", true);
			newSubmitBtn.addEventListener(ButtonEvent.CLICK, onSubmitClicked);
			newSubmitBtn.label = Globals.instance.GameInterface.Translate("#Submit");

			this.visible = false;
			trace("##Called Feedback Setup!");
		}
		
        public function onSubmitClicked(event:ButtonEvent)
        {
            trace("onSubmitClicked");
            this.visible = false;
			this.gameAPI.SendServerCommand("feedback_submitted");
            return;
        }


		public function onScoreSliderChanged(event:SliderEvent)
        {
			trace("score slider value " + this.newScoreSlider.value);
			this.scoreSliderLabel.text = Globals.instance.GameInterface.Translate("#FeedbackScoreLabel") + " " + this.newScoreSlider.value + "/10";
			
			//font
			var txFormat:TextFormat = new TextFormat;
			txFormat.font = "$TextFontBold";					
			this.scoreSliderLabel.setTextFormat(txFormat);
        }

		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean) {
			trace("Stage Size: ",stageW,stageH);

			this.width = this.width*yScale;
			this.height	 = this.height*yScale;

			// this is always called at the resolution the player is currently at.
			this.x = stageW/2;
			this.y = stageH/2 + 100*yScale;
			
			trace("#Result Resize: ",this.x,this.y,yScale);
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
		}
		//Parameters: 
		//	mc - The movieclip to replace
		//	type - The name of the class you want to replace with
		//	keepDimensions - Resize from default dimensions to the dimensions of mc (optional, false by default)
		public function replaceWithValveComponent(mc:MovieClip, type:String, keepDimensions:Boolean = false) : MovieClip {
			var parent = mc.parent;
			var oldx = mc.x;
			var oldy = mc.y;
			var oldwidth = mc.width;
			var oldheight = mc.height;
			
			var newObjectClass = getDefinitionByName(type);
			var newObject = new newObjectClass();
			newObject.x = oldx;
			newObject.y = oldy;
			if (keepDimensions) {
				newObject.width = oldwidth;
				newObject.height = oldheight;
			}
			
			parent.removeChild(mc);
			parent.addChild(newObject);
			
			return newObject;
		}
	}
}

