package bubblebobble;

import com.tyrannotorus.utils.Colors;
import com.tyrannotorus.utils.Constants;
import com.tyrannotorus.utils.Utils;
import com.tyrannotorus.utils.KeyCodes;
import com.tyrannotorus.utils.ActorUtils;
import com.tyrannotorus.assetloader.AssetEvent;
import com.tyrannotorus.assetloader.AssetLoader;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import haxe.ds.ArraySort;

class Game extends Sprite {
		
	private var screen:Sprite;
	private var player:Actor;
	private var opponent:Actor;
	private var healthBars:HealthBars;
	private var menu:Menu;
	private var tilesDialog:TilesDialog;
	
	// Keyboard Controls
	private var zKey:Bool = false;
	private var xKey:Bool = false;
	private var cKey:Bool = false;
	private var upKey:Bool = false;
	private var downKey:Bool = false;
	private var leftKey:Bool = false;
	private var rightKey:Bool = false;
		
	// Music and sfx
	private var music:Sound;
	private var musicChannel:SoundChannel;
	private var musicTransform:SoundTransform;
	
	public function new() {
		super();
		scaleX = scaleY = 3;
	}
	
	public function loadGame():Void {
		
		screen = new Sprite();
		
		tilesDialog = new TilesDialog();
		tilesDialog.loadTiles();
		addChild(tilesDialog);
		
		
				
		// Create Bub.
		var bubSpritesheet:BitmapData = Assets.getBitmapData("actors/bub_spritesheet.png");
		var bubLogic:String = Assets.getText("actors/bub_logic.txt");
		var bubData:Dynamic = ActorUtils.parseActorData(bubSpritesheet, bubLogic);
		player = new Actor(bubData);
		
		Utils.position(player, 8, 8);
		addChild(player);
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onGameKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onGameKeyUp);
		
		healthBars = new HealthBars();
		menu = new Menu();
		addChild(menu);
		
		//var testText:Dynamic = { };
		//testText.text = "Mike Tysons\nPunch\nout!!";
		//testText.fontColor1 = Colors.WHITE;
		//testText.fontSet = 4;
		//addChild(textManager.typeText(testText));
		
		
				
		musicTransform = new SoundTransform(0.1);
		music = Assets.getSound("audio/title_music.mp3", true);
		musicChannel = music.play();
		musicChannel.soundTransform = musicTransform;
	}
	
	
	
	/**
	 * External Asset has been loaded and extracted from the zip. Parse it.
	 * @param {AssetEvent.LOAD_COMPLETE}	e
	 */
	private function parseExternalAsset(e:AssetEvent):Void {
		trace("parseExternalAsset");
		var assetLoader:AssetLoader = cast(e.target, AssetLoader);
		assetLoader.removeEventListener(AssetEvent.LOAD_COMPLETE, parseExternalAsset);
		
		if (e.assetData == null) {
			return;
		}
		
		var spritesheet:Bitmap = e.getData("spritesheet.png");
		var logic:String = e.getData("logic.txt");
		var characterData:Dynamic = ActorUtils.parseActorData(spritesheet.bitmapData, logic);
		opponent = new Actor(characterData);
		Utils.position(opponent, Constants.CENTER, 73);
		addChild(opponent);
		
		Utils.position(player, 96, 132);
		addChild(player);
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onGameKeyDown);
		stage.addEventListener(KeyboardEvent.KEY_UP, onGameKeyUp);
	}
	
	private function onEnterFrame(e:Event):Void {
				
		player.animate();
	//	opponent.animate();
	}
	
	private function onGameKeyDown(e:KeyboardEvent):Void {
		
		switch(e.keyCode) {
			
			// Left key
			case KeyCodes.LEFT:
				//if (leftKey == false) {
					leftKey = true;
					player.xMove(-1, -1, player.WALK);
				//}
			
			// Up key
			case KeyCodes.UP:
				if (upKey == false) {
					upKey = true;
				}
			
			// Right Key	
			case KeyCodes.RIGHT:
				//if (rightKey == false) {
					rightKey = true;
					player.xMove(1, 1, player.WALK);
				//}
			
			// Down Key
			case KeyCodes.DOWN:
				if (downKey == false) {
					downKey = true;
					//player.duck(true);
				}
			
			// X Key
			case KeyCodes.X:
				if (xKey == false && zKey == false) {
					xKey = true;
					if (upKey == true) {
						//player.highPunchA();
					} else {
						//player.lowPunchA();
					}
				}
			
			// Z Key
			case KeyCodes.Z:
				if (zKey == false && xKey == false) {
					zKey = true;
					if (upKey == true) {
						//player.highPunchB();
					} else {
						//player.lowPunchB();
					}
				}
		}
			
	}
	
	private function onGameKeyUp(e:KeyboardEvent):Void {
				
		switch(e.keyCode) {
			case KeyCodes.LEFT:
				leftKey = false;
				player.xMove(0, 0, player.IDLE);
			case KeyCodes.UP:
				upKey = false;
			case KeyCodes.RIGHT:
				rightKey = false;
				player.xMove(0, 0, player.IDLE);
			case KeyCodes.DOWN:
				downKey = false;
				player.duck(false);
			case KeyCodes.X:
				xKey = false;
			case KeyCodes.Z:
				zKey = false;
		}
		
	}
	
	
	
}
