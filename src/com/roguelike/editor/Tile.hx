package com.roguelike.editor;

import com.tyrannotorus.utils.KeyCodes;
import motion.Actuate;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.utils.Object;
import com.tyrannotorus.utils.Colors;

/**
 * Tile.hx.
 * - A game tile.
 */
class Tile extends Sprite {
	
	public var tileData:TileData;
	public var neighbourTiles:Object;
	public var tileStackArray:Array<Bitmap>;
	public var tilesContainer:Sprite;
	public var tileBitmap:Bitmap;
	public var highlightBitmap:Bitmap;
	public var hitSprite:Sprite;
	public var occupant:Dynamic;
	public var elevation:Int;
	public var tinted:Bool;
	public var tileHeight:Int;
	public var centerX:Int = 0;
	public var centerY:Int = 0;
	public var neEdge:Bitmap;
	public var nwEdge:Bitmap;
		
	/**
	 * Constructor.
	 */
	public function new(tileData:TileData) {
		
		super();
		
		this.tileData = tileData;
		
		neighbourTiles = { };
		
		tilesContainer = new Sprite();
		tilesContainer.mouseChildren = false;
		tilesContainer.mouseEnabled = false;
		
		tileBitmap = new Bitmap(tileData.tileBmd);
		tilesContainer.addChild(tileBitmap);
		
		tileStackArray = new Array<Bitmap>();
		tileStackArray.push(tileBitmap);
		
		highlightBitmap = new Bitmap(tileData.highlightBmd);
		highlightBitmap.visible = false;
		tilesContainer.addChild(highlightBitmap);
		
		tilesContainer.x = -tileBitmap.width / 2;
		tilesContainer.y = -tileBitmap.height / 2;
		
		nwEdge = new Bitmap(tileData.nwEdge);
		nwEdge.visible = false;
		addChild(nwEdge);
		
		neEdge = new Bitmap(tileData.neEdge);
		neEdge.visible = false;
		addChild(neEdge);
			
		addChild(tilesContainer);
		
		// HitAreas only work in flash apparently.
		#if flash
			hitSprite = new Sprite();
			hitSprite.graphics.copyFrom(tileData.hitSprite.graphics);
			hitSprite.mouseEnabled = false;
			hitSprite.visible = false;
			hitSprite.x = tilesContainer.x;
			hitSprite.y = tilesContainer.y;
			addChild(hitSprite);
			this.hitArea = hitSprite;
		#end
		
		this.mouseChildren = false;
		this.cacheAsBitmap = true;
		
		if (tileData.fileName == "empty.png") {
			tileBitmap.bitmapData = null;
		}
		
		elevation = tileData.elevation;
	}
	
	/**
	 * Add an occupant to this tile (Actor, Treasure, etc);
	 * @param {Dynamic} occupant
	 */
	public function addOccupant(occupant:Dynamic, xOffset:Float = 0, yOffset:Float = 0):Void {
		
		// Occupant already occupies tile.
		if (this.occupant == occupant) {
			return;
		}
		
		// Remove occupant from previous tile.
		if (occupant.currentTile != null) {
			occupant.currentTile.removeOccupant();
		}
		
		// Add occupant to this tile.
		this.occupant = occupant;
		occupant.x = xOffset + centerX;
		occupant.y = yOffset + centerY;
		occupant.currentTile = this;
		occupant.mouseEnabled = false;
		highlight(true);
		addChild(occupant);
		setChildIndex(occupant, numChildren -1);
	}
	
	/**
	 * Remove an occupant from this tile (Actor, Treasure, etc);
	 */
	public function removeOccupant():Void {
		if(occupant != null) {
			removeChild(occupant);
			highlight(false);
			occupant = null;
		}
	}
		
	/**
	 * Add or subtract elevation from tile by modifier value.
	 * @param {Int} modifier
	 */
	public function addElevation(value:Int):Void {
		
		var newElevation:Int = elevation + value;
		
		if (value == 0 || newElevation < 1) {
			return;
		}
		
		var elevationIncrement:Int = cast(value / Math.abs(value));
		var topTile:Bitmap;
		var newTile:Bitmap;
		
		while(elevation != newElevation) {
		
			elevation += elevationIncrement;
			centerX = 0;
			centerY = (elevation - 1) * -tileData.centerY;
			
			// Adding elevation to tile.
			if (elevationIncrement > 0) {
				topTile = tileStackArray[tileStackArray.length - 1];
				newTile = new Bitmap(topTile.bitmapData);
				newTile.y = centerY;
				tileStackArray.push(newTile);
				tilesContainer.addChild(newTile);
				
			// Subtracting elevation from tile.	
			} else if(tileStackArray.length > 1) {
				topTile = tileStackArray.pop();
				tilesContainer.removeChild(topTile);
			}
		}
			
		tilesContainer.setChildIndex(highlightBitmap, tileStackArray.length);
		highlightBitmap.x = centerX;
		highlightBitmap.y = centerY;
		
		if (occupant != null) {
			occupant.y = centerY;
		}
		
		update();
	}
	
	public function highlight(value:Bool):Void {
		highlightBitmap.visible = value;
	}
	
	/**
	 * Update the look of the tile
	 */
	public function update():Void {
		
		var tile:Tile;
		var neighbours:Array<Int> = [KeyCodes.SW, KeyCodes.SE];
			
		// Update edges of this tile if it overshadows northernly neighbours.
		for (idxTile in 0...neighbours.length) {
			tile = getNeighbourTile(neighbours[idxTile]);
			if (tile != null) {
				tile.updateEdges();
			}
		}
		
		// Update the shadows of southernly neighbours.
		neighbours = [KeyCodes.SE, KeyCodes.DOWN, KeyCodes.SW];
		for (idxTile in 0...neighbours.length) {
			tile = getNeighbourTile(neighbours[idxTile]);
			if (tile != null) {
				tile.updateShadow();
			}
		}
			
		// Update this tile's edges/shadow.
		updateEdges();
		updateShadow();
	}
	
	public function updateEdges():Void {
		
		nwEdge.x = tilesContainer.x;
		nwEdge.y = centerY - nwEdge.height - 2;
		nwEdge.visible = false;
		
		neEdge.x = tilesContainer.x + neEdge.width;
		neEdge.y = centerY - neEdge.height - 2;
		neEdge.visible = false;
		
		var tile:Tile;
		var tileId:Int;
		var neighbours:Array<Int> = [KeyCodes.NW, KeyCodes.NE];
			
		// Update edges of this tile if it overshadows northernly neighbours.
		for (idxTile in 0...neighbours.length) {
			
			tileId = neighbours[idxTile];
			tile = getNeighbourTile(tileId);
						
			if (tile != null && elevation > tile.elevation && tileData.fileName == tile.tileData.fileName) {
				if (tileId == KeyCodes.NW) {
					nwEdge.visible = true;
				} else if (tileId == KeyCodes.NE) {
					neEdge.visible = true;
				}
			}
		}
	}
	
	public function updateShadow():Void {
		
		var tile:Tile;
		var neighbours:Array<Int> = [KeyCodes.NE, KeyCodes.UP, KeyCodes.NW];
			
		for (idxTile in 0...neighbours.length) {
			tile = getNeighbourTile(neighbours[idxTile]);
			if (tile != null && elevation < tile.elevation) {
				Actuate.transform(this, 0).color(Colors.BLACK, 0.6);
				return;
			}
		}
		
		Actuate.transform(this, 0).color(Colors.BLACK, 0);
	}
	
	/**
	 * Use the tinted bitmap for the tile.
	 * @param {Bool} value
	 */
	public function tint(value:Bool = true):Void {
		if(tileData.elevation != -1) {
			tinted = value;
			tileBitmap.bitmapData = tileData.tintBmd;
		}
		
		for (i in 0...tileStackArray.length) {
			tileStackArray[i].bitmapData = tileData.tintBmd;
		}
	}
	
	public function setNeighbourTile(tile:Tile, tileKey:Int):Void {
		neighbourTiles[tileKey] = tile;
	}
	
	public function getNeighbourTile(tileKey:Int):Tile {
		return neighbourTiles[tileKey];
	}
	
	/**
	 * Clone a tile, or return a clone of ourself.
	 * @param {Tile} tile
	 * @return {Tile}
	 */
	public function clone(tile:Tile = null):Tile {
		
		// This tile is becoming a clone of the tile parameter.
		if (tile != null) {
			this.tileData = tile.tileData;
			
			if(tinted) {
				tileBitmap.bitmapData = this.tileData.tintBmd;
			} else {
				tileBitmap.bitmapData = this.tileData.tileBmd;
			}
			
			//tintBitmap.bitmapData = this.tileData.tintBmd;
			highlightBitmap.bitmapData = this.tileData.highlightBmd;
			tilesContainer.x = tile.tilesContainer.x;
			tilesContainer.y = tile.tilesContainer.y;
			elevation = tile.elevation;
			
			#if flash
				hitSprite.graphics.copyFrom(this.tileData.hitSprite.graphics);
				hitSprite.x = tile.hitSprite.x;
				hitSprite.y = tile.hitSprite.y;
				this.hitArea = hitSprite;
			#end
			
			return null;
		
		// We're returning a clone of ourself. 
		} else {
			return new Tile(tileData);
		}
	}
}
