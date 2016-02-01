package com.roguelike.editor;

import haxe.ds.ObjectMap;
import haxe.Json;
import openfl.utils.Object;

/**
 * MapData.hx.
 * - Data for Map.hx.
 */
class MapData {
	
	public var name:String;
	public var fileName:String;
	public var width:Int;
	public var height:Int;
	public var tileMap:Object;
	public var tileArray:Array<Int>;
			
	/**
	 * Constructor.
	 * @param {String} jsonString
	 */
	public function new(jsonString:String) {
		deserialize(jsonString);
	}
	
	/**
	 * Returns map data as a json string for saving.
	 * @return {String}
	 */
	public function serialize():String {
		return " ";
	}
	
	/**
	 * Deserializes json string into mapData.
	 * @param {String} jsonString
	 */
	private function deserialize(jsonString:String):Void {
		
		var jsonData:Object = Json.parse(jsonString);
		
		name = jsonData.name;
		fileName = jsonData.fileName;
		width = jsonData.width;
		height = jsonData.height;
		tileMap = jsonData.tileMap;
		tileArray = jsonData.tileArray;
	}
}
