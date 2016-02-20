/**
Title:      Perlin noise
Version:    1.3
Author:      Ron Valstar
Author URI:    http://www.sjeiti.com/
Original code port from http://mrl.nyu.edu/~perlin/noise/
and some help from http://freespace.virgin.net/hugo.elias/models/m_perlin.htm
AS3 optimizations by Mario Klingemann http://www.quasimondo.com
Haxe port and optimization by Nicolas Cannasse http://haxe.org
*/

package com.tyrannotorus.utils;

import com.roguelike.editor.MapData;
import flash.display.BitmapData;
import openfl.utils.Object;
import openfl.Vector;
import openfl.display.BitmapData;

class OptimizedPerlin {

  private static var P = [
    151,160,137,91,90,15,131,13,201,95,
    96,53,194,233,7,225,140,36,103,30,69,
    142,8,99,37,240,21,10,23,190,6,148,
    247,120,234,75,0,26,197,62,94,252,
    219,203,117,35,11,32,57,177,33,88,
    237,149,56,87,174,20,125,136,171,
    168,68,175,74,165,71,134,139,48,27,
    166,77,146,158,231,83,111,229,122,
    60,211,133,230,220,105,92,41,55,46,
    245,40,244,102,143,54,65,25,63,161,
    1,216,80,73,209,76,132,187,208,89,
    18,169,200,196,135,130,116,188,159,
    86,164,100,109,198,173,186,3,64,52,
    217,226,250,124,123,5,202,38,147,118,
    126,255,82,85,212,207,206,59,227,47,
    16,58,17,182,189,28,42,223,183,170,
    213,119,248,152,2,44,154,163,70,221,
    153,101,155,167,43,172,9,129,22,39,
    253,19,98,108,110,79,113,224,232,
    178,185,112,104,218,246,97,228,251,
    34,242,193,238,210,144,12,191,179,
    162,241,81,51,145,235,249,14,239,
    107,49,192,214,31,181,199,106,157,
    184,84,204,176,115,121,50,45,127,4,
    150,254,138,236,205,93,222,114,67,29,
    24,72,243,141,128,195,78,66,215,61,
    156,180,151,160,137,91,90,15,131,13,
    201,95,96,53,194,233,7,225,140,36,
    103,30,69,142,8,99,37,240,21,10,23,
    190,6,148,247,120,234,75,0,26,197,
    62,94,252,219,203,117,35,11,32,57,
    177,33,88,237,149,56,87,174,20,125,
    136,171,168,68,175,74,165,71,134,139,
    48,27,166,77,146,158,231,83,111,229,
    122,60,211,133,230,220,105,92,41,55,
    46,245,40,244,102,143,54,65,25,63,
    161,1,216,80,73,209,76,132,187,208,
    89,18,169,200,196,135,130,116,188,
    159,86,164,100,109,198,173,186,3,64,
    52,217,226,250,124,123,5,202,38,147,
    118,126,255,82,85,212,207,206,59,
    227,47,16,58,17,182,189,28,42,223,
    183,170,213,119,248,152,2,44,154,
    163,70,221,153,101,155,167,43,172,9,
    129,22,39,253,19,98,108,110,79,113,
    224,232,178,185,112,104,218,246,97,
    228,251,34,242,193,238,210,144,12,
    191,179,162,241,81,51,145,235,249,
    14,239,107,49,192,214,31,181,199,
    106,157,184,84,204,176,115,121,50,
    45,127,4,150,254,138,236,205,93,
    222,114,67,29,24,72,243,141,128,
    195,78,66,215,61,156,180
  ];

  var octaves : Int;

  var aOctFreq:Array<Float>; // frequency per octave
  var aOctPers:Array<Float>; // persistence per octave
  var fPersMax:Float;// 1 / max persistence

  var iXoffset:Float;
  var iYoffset:Float;
  var iZoffset:Float;

  var baseFactor:Float;

  public function new( ?seed, ?octaves, ?falloff ) {
    if( seed == null ) seed = 123;
    if( falloff == null ) falloff = .5;
    this.octaves = if( octaves == null ) 4 else octaves;
    baseFactor = 1 / 64;
    seedOffset(seed);
    octFreqPers(falloff);
  }
  
	/**
	 * Returns an elevation map based on perlin noise for speified parameters.
	 * @param	{Int} mapWidth
	 * @param	{Int} mapHeight
	 * @param	{Array<Int>} mapElevations
	 */
	public function getElevationArray(mapData:MapData, mapElevations:Array<Int>, xFloat:Float, yFloat:Float, zFloat:Float):Array<Array<Int>> {
		
		var bmd:BitmapData = new BitmapData(mapData.width, mapData.height, true, Colors.TRANSPARENT);
		fill(bmd, xFloat, yFloat, zFloat);
		var noiseVector:Vector<UInt> = bmd.getVector(bmd.rect);
		var brightnessArray:Array<Int> = new Array<Int>();
		var minBrightness:Int = 100;
		var maxBrightness:Int = 0;
		
		// Determine the brightness of each pixel in the perlin noise vector.
		for (ii in 0...noiseVector.length) {
			var pixelBrightness:Int = cast(determineBrightness(noiseVector[ii]) * 100);
			minBrightness = (pixelBrightness < minBrightness) ? pixelBrightness : minBrightness;
			maxBrightness = (pixelBrightness > maxBrightness) ? pixelBrightness : maxBrightness;
			brightnessArray[ii] = pixelBrightness;
		}
		
		// Replace map elevations with brightness values for each elevation, and attempt to normalize the distribution.
		var elevationIncrement:Int = cast((maxBrightness - minBrightness) / mapElevations.length);
		var normalizer:Int = 0;
		var remainder:Int = elevationIncrement - 1 - ((maxBrightness - minBrightness) % elevationIncrement);
		for (ii in 0...mapElevations.length) {
			normalizer = (remainder-- > 0) ? normalizer + 1 : normalizer;
			mapElevations[ii] = cast((minBrightness - normalizer + ((ii + 1) * elevationIncrement)));
		}
				
		var elevationMap:Object = {};
		var currentElevation:Int = 0;
		var currentBrightness:Int = minBrightness;
		var numberIndexes:Int = maxBrightness - minBrightness + 1;
		
		for (ii in 0...numberIndexes) {
			
			if (mapElevations.indexOf(currentBrightness) != -1) {
				currentElevation++;
			}
			
			elevationMap[currentBrightness] = currentElevation;
			currentBrightness++;
		}
		
		// Create the actual elevation array.
		var idxPixel:Int = 0;
		var elevationArray:Array<Array<Int>> = new Array<Array<Int>>();
		for (yy in 0...mapData.height) {
			elevationArray[yy] = new Array<Int>();
			for (xx in 0...mapData.width) {
				elevationArray[yy][xx] = cast(elevationMap[brightnessArray[idxPixel++]]);
			}
		}
		
		return elevationArray;
	}
	
	/**
	 * Returns the brightness of a specified color as a float from 0.00 to 1.00
	 * @param {UInt} colour
	 * @return {Float}
	 */
	public function determineBrightness(colour:UInt):Float {
		var rgb:Array<UInt> = HexToRGB(colour);
		return Math.sqrt((rgb[0] * rgb[0] * 0.241) + (rgb[1] * rgb[1] * 0.691) + (rgb[2] * rgb[2] * 0.068) ) / 255;
	}
	
  public function fill( bitmap:BitmapData, _x:Float, _y:Float, _z:Float, ?_ ):Void {

    var baseX:Float;

    baseX = _x * baseFactor + iXoffset;
    _y = _y * baseFactor + iYoffset;
    _z = _z * baseFactor + iZoffset;

    var width:Int = bitmap.width;
    var height:Int = bitmap.height;

    var p = P;
    var octaves = octaves;
    var aOctFreq = aOctFreq;
    var aOctPers = aOctPers;

    for ( py in 0...height )
    {
      _x = baseX;

      for ( px in 0...width )
      {
        var s = 0.;

        for ( i in 0...octaves )
        {
          var fFreq = aOctFreq[i];
          var fPers = aOctPers[i];

          var x = _x * fFreq;
          var y = _y * fFreq;
          var z = _z * fFreq;

          var xf = x - (x % 1);
          var yf = y - (y % 1);
          var zf = z - (z % 1);

          var X = Std.int(xf) & 255;
          var Y = Std.int(yf) & 255;
          var Z = Std.int(zf) & 255;

          x -= xf;
          y -= yf;
          z -= zf;

          var u = x * x * x * (x * (x*6 - 15) + 10);
          var v = y * y * y * (y * (y*6 - 15) + 10);
          var w = z * z * z * (z * (z*6 - 15) + 10);

          var A  = (p[X]) + Y;
          var AA = (p[A]) + Z;
          var AB = (p[A+1]) + Z;
          var B  = (p[X+1]) + Y;
          var BA = (p[B]) + Z;
          var BB = (p[B+1]) + Z;

          var x1 = x-1;
          var y1 = y-1;
          var z1 = z-1;

          var hash = (p[BB+1]) & 15;
          var g1 = ((hash&1) == 0 ? (hash<8 ? x1 : y1) : (hash<8 ? -x1 : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 : ( hash==12 ? x1 : z1 ) : hash<4 ? -y1 : ( hash==14 ? -x1 : -z1 ));

          hash = (p[AB+1]) & 15;
          var g2 = ((hash&1) == 0 ? (hash<8 ? x  : y1) : (hash<8 ? -x  : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 : ( hash==12 ? x  : z1 ) : hash<4 ? -y1 : ( hash==14 ? -x : -z1 ));

          hash = (p[BA+1]) & 15;
          var g3 = ((hash&1) == 0 ? (hash<8 ? x1 : y ) : (hash<8 ? -x1 : -y )) + ((hash&2) == 0 ? hash<4 ? y  : ( hash==12 ? x1 : z1 ) : hash<4 ? -y  : ( hash==14 ? -x1 : -z1 ));

          hash = (p[AA+1]) & 15;
          var g4 = ((hash&1) == 0 ? (hash<8 ? x  : y ) : (hash<8 ? -x  : -y )) + ((hash&2) == 0 ? hash<4 ? y  : ( hash==12 ? x  : z1 ) : hash<4 ? -y  : ( hash==14 ? -x  : -z1 ));

          hash = (p[BB]) & 15;
          var g5 = ((hash&1) == 0 ? (hash<8 ? x1 : y1) : (hash<8 ? -x1 : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 : ( hash==12 ? x1 : z  ) : hash<4 ? -y1 : ( hash==14 ? -x1 : -z  ));

          hash = (p[AB]) & 15;
          var g6 = ((hash&1) == 0 ? (hash<8 ? x  : y1) : (hash<8 ? -x  : -y1)) + ((hash&2) == 0 ? hash<4 ? y1 : ( hash==12 ? x  : z  ) : hash<4 ? -y1 : ( hash==14 ? -x  : -z  ));

          hash = (p[BA]) & 15;
          var g7 = ((hash&1) == 0 ? (hash<8 ? x1 : y ) : (hash<8 ? -x1 : -y )) + ((hash&2) == 0 ? hash<4 ? y  : ( hash==12 ? x1 : z  ) : hash<4 ? -y  : ( hash==14 ? -x1 : -z  ));

          hash = (p[AA]) & 15;
          var g8 = ((hash&1) == 0 ? (hash<8 ? x  : y ) : (hash<8 ? -x  : -y )) + ((hash&2) == 0 ? hash<4 ? y  : ( hash==12 ? x  : z  ) : hash<4 ? -y  : ( hash==14 ? -x  : -z  ));

          g2 += u * (g1 - g2);
          g4 += u * (g3 - g4);
          g6 += u * (g5 - g6);
          g8 += u * (g7 - g8);

          g4 += v * (g2 - g4);
          g8 += v * (g6 - g8);

          s += ( g8 + w * (g4 - g8)) * fPers;
        }

        var color = Std.int( ( s * fPersMax + 1 ) * 128 );

        bitmap.setPixel32( px, py, 0xff000000 | color << 16 | color << 8 | color );

        _x += baseFactor;
      }

      _y += baseFactor;
    }
  }

  function octFreqPers( fPersistence ) {

    var fFreq:Float, fPers:Float;

    aOctFreq = [];
    aOctPers = [];
    fPersMax = 0;

    for ( i in 0...octaves ) {
      fFreq = Math.pow(2,i);
      fPers = Math.pow(fPersistence,i);
      fPersMax += fPers;
      aOctFreq.push( fFreq );
      aOctPers.push( fPers );
    }

    fPersMax = 1 / fPersMax;
  }

  function seedOffset( iSeed : Int ) {
    iXoffset = iSeed = Std.int((iSeed * 16807.) % 2147483647);
    iYoffset = iSeed = Std.int((iSeed * 16807.) % 2147483647);
    iZoffset = iSeed = Std.int((iSeed * 16807.) % 2147483647);
  }
  
  function HexToRGB(hex:UInt):Array<UInt> {
	
    var rgb:Array<UInt> = new Array<UInt>();
           
	rgb.push(hex >> 16 & 0xFF);
    rgb.push(hex >> 8 & 0xFF);
    rgb.push(hex & 0xFF);
           
   // rgb.push(r, g, b);
    return rgb;
}
}