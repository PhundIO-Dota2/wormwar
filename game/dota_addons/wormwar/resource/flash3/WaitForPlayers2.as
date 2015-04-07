package  {
	import flash.display.MovieClip;
	
	//import some stuff from the valve lib
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	public class WaitForPlayers2 extends MovieClip {
		
		public var gameAPI:Object;
		public var globals:Object;

		public function WaitForPlayers2() {
			// constructor code
		}
		
		//set initialise this instance's gameAPI
		public function setup(api:Object, globals:Object) {
			trace("##WaitForPlayers2 start");
			this.gameAPI = api;
			this.globals = globals;
			
			this.wormWarHelpText.wordWrap = true;
			this.wormWarHelpText.text = Globals.instance.GameInterface.Translate("#WormWarHelpText")
			this.visible = true;
			trace("##Called WaitForPlayers2 Setup!");
		}
		
		//onScreenResize
		public function screenResize(stageW:int, stageH:int, xScale:Number, yScale:Number, wide:Boolean) {
			this.width = this.width*yScale;
			this.height	 = this.height*yScale;

			// this is always called at the resolution the player is currently at.
			this.x = this.width/2;
			this.y = stageH - this.height/2;
			
			//trace("#Result Resize: ",this.x,this.y,yScale);
			
			//Now we just set the scale of this element, because these parameters are already the inverse ratios
			this.scaleX = xScale;
			this.scaleY = yScale;
		}
	}	
}

