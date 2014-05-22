

groups = DAME.GetGroups()
groupCount = as3.tolua(groups.length) -1

DAME.SetFloatPrecision(3)

tab1 = "\t"
tab2 = "\t\t"
tab3 = "\t\t\t"
tab4 = "\t\t\t\t"
tab5 = "\t\t\t\t\t"

-- slow to call as3.tolua many times so do as much as can in one go and store to a lua variable instead.
exportOnlyCSV = as3.tolua(VALUE_ExportOnlyCSV)
flixelPackage = as3.tolua(VALUE_FlixelPackage)
baseClassName = as3.tolua(VALUE_BaseClass)
baseExtends = as3.tolua(VALUE_BaseClassExtends)
IntermediateClass = as3.tolua(VALUE_IntermediateClass)
hxDir = as3.tolua(VALUE_HxDir)
tileMapClass = as3.tolua(VALUE_TileMapClass)
GamePackage = as3.tolua(VALUE_GamePackage)
csvDir = as3.tolua(VALUE_CSVDir)
importsText = as3.tolua(VALUE_Imports)

compiledir = as3.tolua(VALUE_CompileFolder)

-- This is the file for the map base class
baseFileText = "";
fileText = "";

pathLayers = {}

containsBoxData = false
containsCircleData = false
containsTextData = false
containsPaths = false

------------------------
-- TILEMAP GENERATION
------------------------
function exportMapCSV( mapLayer, layerFileName )
	-- get the raw mapdata. To change format, modify the strings passed in (rowPrefix,rowSuffix,columnPrefix,columnSeparator,columnSuffix)
	mapText = as3.tolua(DAME.ConvertMapToText(mapLayer,"","\n","",",",""))
	DAME.WriteFile(csvDir.."/"..layerFileName, mapText );
end

function exportMapHX( mapLayer, layerFileName )
	-- get the raw mapdata. To change format, modify the strings passed in (rowPrefix,rowSuffix,columnPrefix,columnSeparator,columnSuffix)
	mapText = "package "..GamePackage..".maps;\n\n"
	mapText = mapText.."class CSV_"..layerName.."\n"
	mapText = mapText.."{\n"
	mapText = mapText..tab1..'public static var mapString:String = "'..as3.tolua(DAME.ConvertMapToText(mapLayer,"","\\n","",",",""))..'";\n'
	mapText = mapText.."}\n"

	DAME.WriteFile(haxedir.."/maps/CSV_"..layerName..".hx", mapText );
end

------------------------
-- PATH GENERATION
------------------------

-- This will store the path along with a name so when we call a get it will output the value between the first : and the last %
-- Here it will be paths[i]. When we later call %getparent% on any attached avatar it will output paths[i].
pathText = "%store:paths[%counter:paths%]%"
pathText = pathText.."%counter++:paths%" -- This line will actually incremement the counter.

lineNodeText = "new FlxPoint(%nodex%, %nodey%)"
splineNodeText = "{ pos:new FlxPoint(%nodex%, %nodey%), tan1:new FlxPoint(%tan1x%, %tan1y%), tan2:new FlxPoint(-(%tan2x%), -(%tan2y%)) }"

propertiesString = "generateProperties( [%%proploop%%"
	propertiesString = propertiesString.."{ name:\"%propname%\", value:%propvaluestring% }, "
propertiesString = propertiesString.."%%proploopend%%null] )"

tilePropertiesString = "%%ifproplength%%"..tab3.."tileProperties[%tileid%]="..propertiesString..";\n%%endifproplength%%"

local groupPropTypes = as3.toobject({ String="String", Int="int", Float="Number", Bool="Bool" })

DAME.SetCurrentPropTypes( groupPropTypes )

linkAssignText = "%%if link%%"
	linkAssignText = linkAssignText.."linkedObjectDictionary[%linkid%] = "
linkAssignText = linkAssignText.."%%endiflink%%"
needCallbackText = "%%if link%%, true %%endiflink%%"


function generatePaths( )
	for i,v in ipairs(pathLayers) do	
		containsPaths = true
		fileText = fileText..tab2.."public function addPathsForLayer"..pathLayers[i][3].."(onAddCallback:Dynamic = null):Void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."var pathobj:PathData;\n\n"

		linesText = pathText..tab3.."pathobj = new PathData( [ %nodelist% \n"..tab3.."], %isclosed%, false, "..pathLayers[i][3].."Group );\n"
		linesText = linesText..tab3.."paths.push(pathobj);\n"

		layer = pathLayers[i][2]
		
			linesText = linesText..tab3..linkAssignText.."callbackNewData( pathobj, onAddCallback, "..pathLayers[i][3].."Group, "..propertiesString..", "..as3.tolua(layer.xScroll)..", "..as3.tolua(layer.xScroll)..needCallbackText.." );\n\n"
		
		
		-- An example of how to parse path events. Add eventsText as an extra param to the end of CreateTextForPaths.
		--linesText = linesText.."%%if pathevents%%"..tab3.."events = new Array(%eventcount%)[%eventlist%]\n%%endifpathevents%%"
		--eventsText = "new PathEvent(x=%xpos%, y=%ypos%, percent=%percent%, seg=%segment%, "..propertiesString..")%separator:\n"..tab5.."%"
		
		fileText = fileText..as3.tolua(DAME.CreateTextForPaths(layer, linesText, lineNodeText, linesText, splineNodeText, ",\n"..tab4))
		fileText = fileText..tab2.."}\n\n"
	end
end

-------------------------------------
-- SHAPE and TEXTBOX GENERATION
-------------------------------------

function generateShapes( )
	for i,v in ipairs(shapeLayers) do	
		groupname = shapeLayers[i][3].."Group"

		
			scrollText = ", "..as3.tolua(layer.xScroll)..", "..as3.tolua(layer.yScroll)
	
		
		textboxText = tab3..linkAssignText.."callbackNewData(new TextData(%xpos%, %ypos%, %width%, %height%, %degrees%, \"%text%\",\"%font%\", %size%, 0x%color%, \"%align%\"), onAddCallback, "..groupname..", "..propertiesString..scrollText..needCallbackText.." ) ;\n"
		
		fileText = fileText..tab2.."public function addShapesForLayer"..shapeLayers[i][3].."(onAddCallback:Dynamic = null):Void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."var obj:Dynamic;\n\n"
		
		boxText = tab3.."obj = new BoxData(%xpos%, %ypos%, %degrees%, %width%, %height%, "..groupname.." );\n"
		boxText = boxText..tab3.."shapes.push(obj);\n"
		boxText = boxText..tab3..linkAssignText.."callbackNewData( obj, onAddCallback, "..groupname..", "..propertiesString..scrollText..needCallbackText.." );\n"

		circleText = tab3.."obj = new CircleData(%xpos%, %ypos%, %radius%, "..groupname.." );\n"
		circleText = circleText..tab3.."shapes.push(obj);\n"
		circleText = circleText..tab3..linkAssignText.."callbackNewData( obj, onAddCallback, "..groupname..", "..propertiesString..scrollText..needCallbackText..");\n"

		shapeText = as3.tolua(DAME.CreateTextForShapes(shapeLayers[i][2], circleText, boxText, textboxText ))
		fileText = fileText..shapeText
		fileText = fileText..tab2.."}\n\n"
		
		if string.find(shapeText, "BoxData") ~= nil then
			containsBoxData = true
		end
		if string.find(shapeText, "CircleData") ~= nil then
			containsCircleData = true
		end
		if containsTextData == false and string.find(shapeText, "TextData") ~= nil then
			containsTextData = true
		end
	end
end

------------------------
-- BASE CLASS
------------------------
if exportOnlyCSV == false then	
	baseFileText = "//Code generated with DAME and DeVZoO. http://www.dambots.com http://www.dev-zoo.net\n\n"
	baseFileText = baseFileText.."package"..GamePackage..";\n"
	
	baseFileText = baseFileText..tab1.."import "..flixelPackage..".group.FlxGroup;\n"
	baseFileText = baseFileText..tab1.."import "..flixelPackage..".FlxSprite;\n"
	baseFileText = baseFileText..tab1.."import "..flixelPackage..".FlxObject;\n"
	baseFileText = baseFileText..tab1.."import "..flixelPackage..".text.FlxText;\n"
    baseFileText = baseFileText..tab1.."import "..flixelPackage..".util.FlxPoint;\n"
    baseFileText = baseFileText..tab1.."import "..flixelPackage..".tile.FlxTilemap;\n"
	baseFileText = baseFileText..tab1.."import flash.utils.Dictionary;\n"
	if # importsText > 0 then
		baseFileText = baseFileText..tab1.."// Custom imports:\n"..importsText.."\n"
	end
	
	baseFileText = baseFileText..tab1.." class "..baseClassName
	if # baseExtends > 0 then
		baseFileText = baseFileText.." extends "..baseExtends
	end
	baseFileText = baseFileText.."\n"
	
	baseFileText = baseFileText..tab1.."{\n"
	baseFileText = baseFileText..tab2.."// The masterLayer contains every single object in this group making it easy to empty the level.\n"
	baseFileText = baseFileText..tab2.."public var masterLayer:FlxGroup;\n\n"
	baseFileText = baseFileText..tab2.."// This group contains all the tilemaps specified to use collisions.\n"
	baseFileText = baseFileText..tab2.."public var hitTilemaps:FlxGroup;\n"
	baseFileText = baseFileText..tab2.."// This group contains all the tilemaps.\n"
	baseFileText = baseFileText..tab2.."public var tilemaps:FlxGroup;\n\n"
	baseFileText = baseFileText..tab2.."public var boundsMinX:Int;\n"
	baseFileText = baseFileText..tab2.."public var boundsMinY:Int;\n"
	baseFileText = baseFileText..tab2.."public var boundsMaxX:Int;\n"
	baseFileText = baseFileText..tab2.."public var boundsMaxY:Int;\n\n"
	baseFileText = baseFileText..tab2.."public var boundsMin:FlxPoint;\n"
	baseFileText = baseFileText..tab2.."public var boundsMax:FlxPoint;\n"
	baseFileText = baseFileText..tab2.."public var bgColor:Int;\n"
	baseFileText = baseFileText..tab2.."public var paths:Array<Dynamic>;\t// Array of PathData\n"
	baseFileText = baseFileText..tab2.."public var shapes:Array<Dynamic>;\t//Array of ShapeData.\n"
	
	
	baseFileText = baseFileText..tab2.."public static var linkedObjectDictionary:Array<Dynamic>;\t// Array <Dynamic> instead of Dictionary\n\n"
	
	baseFileText = baseFileText..tab1.."public function new()\n"
	baseFileText = baseFileText..tab1.."{\n"
	baseFileText = baseFileText..tab2.."masterLayer = new FlxGroup();\n"
	baseFileText = baseFileText..tab2.."hitTilemaps = new FlxGroup();\n"
	baseFileText = baseFileText..tab2.."tilemaps = new FlxGroup();\n"
	baseFileText = baseFileText..tab2.."paths = new Array<Dynamic>();\n"
	baseFileText = baseFileText..tab2.."shapes = new Array<Dynamic>();\n"
	baseFileText = baseFileText..tab2.."linkedObjectDictionary = new Array<Dynamic>();\n"
	baseFileText = baseFileText..tab1.."}\n"
	baseFileText = baseFileText..tab1.."\n"
	
	baseFileText = baseFileText..tab2.."// Expects callback function to be callback(newobj:Dynamic,layer:FlxGroup,level:BaseLevel,properties:Array)\n"
	baseFileText = baseFileText..tab2.."public function createObjects(onAddCallback:Dynamic = null, parentObject:Dynamic = null):Void { }\n\n"
	
	baseFileText = baseFileText..tab2.."public function addTilemap( mapClass:Dynamic, imageClass:Class<Dynamic>, xpos:Float, ypos:Float, tileWidth:UInt, tileHeight:UInt, scrollX:Float, scrollY:Float, hits:Bool, collideIdx:UInt, drawIdx:UInt, properties:Array<Dynamic>, onAddCallback:Dynamic = null ):"..tileMapClass.."\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var map:"..tileMapClass.." = new "..tileMapClass.."();\n"
	baseFileText = baseFileText..tab3.."map.loadMap( mapClass, imageClass, tileWidth, tileHeight, FlxTilemap.OFF, 0, drawIdx, collideIdx);\n"
	
	baseFileText = baseFileText..tab3.."map.x = xpos;\n"
	baseFileText = baseFileText..tab3.."map.y = ypos;\n"
	baseFileText = baseFileText..tab3.."map.scrollFactor.x = scrollX;\n"
	baseFileText = baseFileText..tab3.."map.scrollFactor.y = scrollY;\n"
	baseFileText = baseFileText..tab3.."if ( hits )\n"
	baseFileText = baseFileText..tab4.."hitTilemaps.add(map);\n"
	baseFileText = baseFileText..tab3.."tilemaps.add(map);\n"
	baseFileText = baseFileText..tab3.."//if(onAddCallback != null)\n"
	baseFileText = baseFileText..tab4.."//onAddCallback(map, null, properties);\n"
	
	baseFileText = baseFileText..tab3.."return map;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	baseFileText = baseFileText..tab2.."public function addSpriteToLayer(obj:FlxSprite, type:Dynamic, layer:FlxGroup, xpos:Float, ypos:Float, angle:Float, scrollX:Float, scrollY:Float, flipped:Bool = false, scaleX:Float = 1, scaleY:Float = 1, properties:Array<Dynamic> = null, onAddCallback:Dynamic = null):FlxSprite\n"
	
	baseFileText = baseFileText..tab1.."{\n"
	baseFileText = baseFileText..tab2.."if( obj == null ) {\n"
	baseFileText = baseFileText..tab3.."obj = Type.createInstance(type, [xpos,ypos]);\n"
	baseFileText = baseFileText..tab2.."}\n"
	baseFileText = baseFileText..tab3.."obj.x += obj.offset.x;\n"
	baseFileText = baseFileText..tab3.."obj.y += obj.offset.y;\n"
	baseFileText = baseFileText..tab3.."obj.angle = angle;\n"
	baseFileText = baseFileText..tab3.."if ( scaleX != 1 || scaleY != 1 )\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."obj.scale.x = scaleX;\n"
	baseFileText = baseFileText..tab4.."obj.scale.y = scaleY;\n"
	baseFileText = baseFileText..tab4.."obj.width *= scaleX;\n"
	baseFileText = baseFileText..tab4.."obj.height *= scaleY;\n"
	baseFileText = baseFileText..tab4.."// Adjust the offset, in case it was already set.\n"
	baseFileText = baseFileText..tab4.."var newFrameWidth:Float = obj.frameWidth * scaleX;\n"
	baseFileText = baseFileText..tab4.."var newFrameHeight:Float = obj.frameHeight * scaleY;\n"
	baseFileText = baseFileText..tab4.."var hullOffsetX:Float = obj.offset.x * scaleX;\n"
	baseFileText = baseFileText..tab4.."var hullOffsetY:Float = obj.offset.y * scaleY;\n"
	baseFileText = baseFileText..tab4.."obj.offset.x -= (newFrameWidth- obj.frameWidth) / 2;\n"
	baseFileText = baseFileText..tab4.."obj.offset.y -= (newFrameHeight - obj.frameHeight) / 2;\n"
	
	baseFileText = baseFileText..tab3.."}\n"
	
		baseFileText = baseFileText..tab3.."if( obj.facing == FlxObject.RIGHT )\n"
		baseFileText = baseFileText..tab4.."obj.facing = flipped ? FlxObject.LEFT : FlxObject.RIGHT;\n"
		baseFileText = baseFileText..tab3.."obj.scrollFactor.x = scrollX;\n"
		baseFileText = baseFileText..tab3.."obj.scrollFactor.y = scrollY;\n"
		baseFileText = baseFileText..tab3.."layer.add(obj);\n"
		baseFileText = baseFileText..tab3.."callbackNewData(obj, onAddCallback, layer, properties, scrollX, scrollY, false);\n"
	
	baseFileText = baseFileText..tab3.."return obj;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	baseFileText = baseFileText..tab2.."public function addTextToLayer(textdata:TextData, layer:FlxGroup, scrollX:Float, scrollY:Float, embed:Bool, properties:Array<Dynamic>, onAddCallback:Dynamic ):FlxText\n"
	
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var textobj:FlxText = new FlxText(textdata.x, textdata.y, textdata.width, textdata.text, embed);\n"
	baseFileText = baseFileText..tab3.."textobj.setFormat(textdata.fontName, textdata.size, textdata.color, textdata.alignment);\n"
	
		baseFileText = baseFileText..tab3.."addSpriteToLayer(textobj, FlxText, layer , 0, 0, textdata.angle, scrollX, scrollY, false, 1, 1, properties, onAddCallback );\n"
	
	baseFileText = baseFileText..tab3.."textobj.height = textdata.height;\n"
	baseFileText = baseFileText..tab3.."textobj.origin.x = textobj.width * 0.5;\n"
	baseFileText = baseFileText..tab3.."textobj.origin.y = textobj.height * 0.5;\n"
	baseFileText = baseFileText..tab3.."return textobj;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	
		baseFileText = baseFileText..tab2.."private function callbackNewData(data:Dynamic, onAddCallback:Dynamic, layer:FlxGroup, properties:Array<Dynamic>, scrollX:Float, scrollY:Float, needsReturnData:Bool = false):Dynamic\n"
	
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."if(onAddCallback != null)\n"
	baseFileText = baseFileText..tab3.."{\n"
	
		baseFileText = baseFileText..tab4.."var newData:Dynamic = onAddCallback(data, layer, this, properties);\n"
	
	baseFileText = baseFileText..tab4.."if( newData != null )\n"
	baseFileText = baseFileText..tab5.."data = newData;\n"
	baseFileText = baseFileText..tab4.."else if ( needsReturnData )\n"
	baseFileText = baseFileText..tab5.."trace(\"Error: callback needs to return either the object passed in or a new object to set up links correctly.\");\n"
	baseFileText = baseFileText..tab3.."}\n"
	baseFileText = baseFileText..tab3.."return data;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
		baseFileText = baseFileText..tab1.."/**\n"
	baseFileText = baseFileText..tab1.." * Removes the null value that is at the end of the argument array\n"
	baseFileText = baseFileText..tab1.." * @param	args An array of properties	fromatted like { name:'foo', value:'foo'}\n"
	baseFileText = baseFileText..tab1.."*/\n"
	baseFileText = baseFileText..tab1.."private function generateProperties( args:Array<Dynamic> ):Array<Dynamic>\n"
	baseFileText = baseFileText..tab1.."{\n"
	baseFileText = baseFileText..tab2.."var properties = new Array<Dynamic>();\n"
	baseFileText = baseFileText..tab2.."if (args != null && args.length != 0)\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var i:Int = args.length - 1;\n"
	baseFileText = baseFileText..tab3.."while(i-- != 0)\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."properties.push( args[i] );\n"
	baseFileText = baseFileText..tab3.."}\n"
	baseFileText = baseFileText..tab2.."}\n"
	baseFileText = baseFileText..tab2.."return properties;\n"
	baseFileText = baseFileText..tab1.."}\n\n"

	
	baseFileText = baseFileText..tab2.."public function createLink( objectFrom:Dynamic, target:Dynamic, onAddCallback:Dynamic, properties:Array<Dynamic> ):Void\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var link:ObjectLink = new ObjectLink( objectFrom, target );\n"
	
		baseFileText = baseFileText..tab3.."callbackNewData(link, onAddCallback, null, properties, objectFrom.scrollFactor.x, objectFrom.scrollFactor.y);\n"
	
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab2
	if baseExtends == "FlxGroup" then
		baseFileText = baseFileText.."override "
	end
	baseFileText = baseFileText.."public function destroy():Void\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."masterLayer.destroy();\n"
	baseFileText = baseFileText..tab3.."masterLayer = null;\n"
	baseFileText = baseFileText..tab3.."tilemaps = null;\n"
	baseFileText = baseFileText..tab3.."hitTilemaps = null;\n\n"
			
	baseFileText = baseFileText..tab3.."var i:UInt;\n"
	baseFileText = baseFileText..tab3.."for ( i in paths)\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."var pathobj:Dynamic = paths[i];\n"
	baseFileText = baseFileText..tab4.."if ( pathobj )\n"
	baseFileText = baseFileText..tab4.."{\n"
	baseFileText = baseFileText..tab5.."pathobj.destroy();\n"
	baseFileText = baseFileText..tab4.."}\n"
	baseFileText = baseFileText..tab3.."}\n"
	baseFileText = baseFileText..tab3.."paths = null;\n\n"
			
	baseFileText = baseFileText..tab3.."for ( i in shapes)\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."var shape:Dynamic = shapes[i];\n"
	baseFileText = baseFileText..tab4.."if ( shape )\n"
	baseFileText = baseFileText..tab4.."{\n"
	baseFileText = baseFileText..tab5.."shape.destroy();\n"
	baseFileText = baseFileText..tab4.."}\n"
	baseFileText = baseFileText..tab3.."}\n"
	baseFileText = baseFileText..tab3.."shapes = null;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab2.."// List of null classes allows you to spawn levels dynamically from code using ClassReference.\n"
end

------------------------
-- GROUP CLASSES
------------------------
for groupIndex = 0,groupCount do

	maps = {}
	spriteLayers = {}
	shapeLayers = {}
	pathLayers = {}
	masterLayerAddText = ""
	stageAddText = ""
	
	group = groups[groupIndex]
	groupName = as3.tolua(group.name)
	groupName = string.gsub(groupName, " ", "_")
	
	DAME.ResetCounters()
	
	baseFileText = baseFileText..tab2.."private static var level_"..groupName..":Level_"..groupName..";\n"
	
	
	layerCount = as3.tolua(group.children.length) - 1
	
	-- This is the file for the map group class.
	fileText = "//Code generated with DAME and DeVZoO. http://www.dambots.com http://www.dev-zoo.net\n\n"
	fileText = fileText.."package; "..GamePackage.."\n"
	
	fileText = fileText..tab1.."import "..flixelPackage..".FlxG;\n"
	
	fileText = fileText..tab1.."import "..flixelPackage..".group.FlxGroup;\n"
	fileText = fileText..tab1.."import "..flixelPackage..".FlxSprite;\n"
	fileText = fileText..tab1.."import "..flixelPackage..".FlxObject;\n"
	fileText = fileText..tab1.."import "..flixelPackage..".text.FlxText;\n"
    fileText = fileText..tab1.."import "..flixelPackage..".util.FlxPoint;\n"
    fileText = fileText..tab1.."import "..flixelPackage..".tile.FlxTilemap;\n"
	fileText = fileText..tab1.."import openfl.Assets;\n"
	fileText = fileText..tab1.."import flash.utils.Dictionary;\n"
	
	if # importsText > 0 then
		fileText = fileText..tab1.."// Custom imports:\n"..importsText.."\n"
	end
	fileText = fileText..tab1.."class Level_"..groupName.." extends "
	if # IntermediateClass > 0 then
		fileText = fileText..IntermediateClass.."\n"
	else
		fileText = fileText..baseClassName.."\n"
	end
	
	fileText = fileText..tab1.."{\n"
	fileText = fileText..tab2.."//Embedded media...\n"
	
	-- Go through each layer and store some tables for the different layer types.
	for layerIndex = 0,layerCount do
		layer = group.children[layerIndex]
		isMap = as3.tolua(layer.map)~=nil
		layerName = as3.tolua(layer.name)
		layerName = string.gsub(layerName, " ", "_")
		if isMap == true then
			mapFileName = "mapCSV_"..groupName.."_"..layerName..".csv"
			-- Generate the map file.
			exportMapCSV( layer, mapFileName )
			
			-- This needs to be done here so it maintains the layer visibility ordering.
			if exportOnlyCSV == false then
				table.insert(maps,{layer,layerName})
				-- For maps just generate the Embeds needed at the top of the class.
				--fileText = fileText..tab2.."[Embed(source=\""..as3.tolua(DAME.GetRelativePath(hxDir, csvDir.."/"..mapFileName)).."\", mimeType=\"application/octet-stream\")] public var CSV_"..layerName..":Class;\n"
				--fileText = fileText..tab2.."[Embed(source=\""..as3.tolua(DAME.GetRelativePath(compiledir, layer.imageFile)).."\")] public var Img_"..layerName..":Class;\n"
				masterLayerAddText = masterLayerAddText..tab3.."masterLayer.add(layer"..layerName..");\n"
			end

		elseif exportOnlyCSV == false then
			addGroup = false;
			if as3.tolua(layer.IsSpriteLayer()) == true then
				table.insert( spriteLayers,{groupName,layer,layerName})
				addGroup = true;
				stageAddText = stageAddText..tab3.."addSpritesForLayer"..layerName.."(onAddCallback);\n"
			elseif as3.tolua(layer.IsShapeLayer()) == true then
				table.insert(shapeLayers,{groupName,layer,layerName})
				addGroup = true
			elseif as3.tolua(layer.IsPathLayer()) == true then
				table.insert(pathLayers,{groupName,layer,layerName})
				addGroup = true
			end
			
			if addGroup == true then
				masterLayerAddText = masterLayerAddText..tab3.."masterLayer.add("..layerName.."Group);\n"
				
					--masterLayerAddText = masterLayerAddText..tab3..layerName.."Group.scrollFactor.x = "..string.format("%.4f",as3.tolua(layer.xScroll))..";\n"
					--masterLayerAddText = masterLayerAddText..tab3..layerName.."Group.scrollFactor.y = "..string.format("%.4f",as3.tolua(layer.yScroll))..";\n"
				
			end
		end
	end

	-- Generate the actual text for the derived class file.
	
	if exportOnlyCSV == false then

		------------------------------------
		-- VARIABLE DECLARATIONS
		-------------------------------------
		fileText = fileText.."\n"
		
		if # maps > 0 then
			fileText = fileText..tab2.."//Tilemaps\n"
			for i,v in ipairs(maps) do
				fileText = fileText..tab2.."public var layer"..maps[i][2]..":"..tileMapClass..";\n"
			end
			fileText = fileText.."\n"
		end
		
		if # spriteLayers > 0 then
			fileText = fileText..tab2.."//Sprites\n"
			for i,v in ipairs(spriteLayers) do
				fileText = fileText..tab2.."public var "..spriteLayers[i][3].."Group:FlxGroup;\n"
			end
			fileText = fileText.."\n"
		end
		
		if # shapeLayers > 0 then
			fileText = fileText..tab2.."//Shapes\n"
			for i,v in ipairs(shapeLayers) do
				fileText = fileText..tab2.."public var "..shapeLayers[i][3].."Group:FlxGroup;\n"
			end
			fileText = fileText.."\n"
		end
		
		if # pathLayers > 0 then
			fileText = fileText..tab2.."//Paths\n"
			for i,v in ipairs(pathLayers) do
				fileText = fileText..tab2.."public var "..pathLayers[i][3].."Group:FlxGroup;\n"
			end
			fileText = fileText.."\n"
		end
		
		groupPropertiesString = "%%proploop%%"..tab2.."public var %propnamefriendly%:%proptype% = %propvaluestring%;\n%%proploopend%%"
		
		fileText = fileText..tab2.."//Properties\n"
		fileText = fileText..as3.tolua(DAME.GetTextForProperties( groupPropertiesString, group.properties, groupPropTypes )).."\n"
		
		fileText = fileText.."\n"
		fileText = fileText..tab2.."public function new(addToStage:Bool = true, onAddCallback:Dynamic = null, parentObject:Dynamic = null)\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab2.."super();\n"
		fileText = fileText..tab2.."var mapString:String;\n"
		fileText = fileText..tab2.."var image:Dynamic;\n"

		if # spriteLayers > 0 then
			fileText = fileText..tab2.."//Sprites\n"
			for i,v in ipairs(spriteLayers) do
				fileText = fileText..tab2..spriteLayers[i][3].."Group = new FlxGroup();\n"
			end
			fileText = fileText.."\n"
		end

		if # shapeLayers > 0 then
			fileText = fileText..tab1.."//Shapes\n"
			for i,v in ipairs(shapeLayers) do
				fileText = fileText..tab2..shapeLayers[i][3].."Group= new FlxGroup();\n"
			end
			fileText = fileText.."\n"
		end

		if # pathLayers > 0 then
			fileText = fileText..tab2.."//Paths\n"
			for i,v in ipairs(pathLayers) do
				fileText = fileText..tab2..pathLayers[i][3].."Group = new FlxGroup();\n"
			end
			fileText = fileText.."\n"
		end

		
		fileText = fileText..tab3.."// Generate maps.\n"
		
		fileText = fileText..tab2.."var properties:Array<Dynamic> = new Array<Dynamic>();\n\n"
		--fileText = fileText..tab3.."var tileProperties:Dictionary = new Dictionary;\n\n"
		
		minx = 9999999
		miny = 9999999
		maxx = -9999999
		maxy = -9999999
		-- Create the tilemaps.
		for i,v in ipairs(maps) do
			layerName = maps[i][2]
			layer = maps[i][1]
			
			x = as3.tolua(layer.map.x)
			y = as3.tolua(layer.map.y)
			width = as3.tolua(layer.map.width)
			height = as3.tolua(layer.map.height)
			xscroll = as3.tolua(layer.xScroll)
			yscroll = as3.tolua(layer.yScroll)
			hasHitsString = ""
			if as3.tolua(layer.HasHits) == true then
				hasHitsString = "true"
			else
				hasHitsString = "false"
			end
			
			mapPath = "'"..as3.tolua(DAME.GetRelativePath(compiledir, csvDir.."/mapCSV_"..groupName.."_"..layerName..".csv")).."'"	--Get the name to the csv
			imagePath = "'"..as3.tolua(DAME.GetRelativePath(compiledir, layer.imageFile))								--Get the image for the layer
			fileText = fileText..tab2.."mapString = ("..mapPath..").toString();\n"
			fileText = fileText..tab2.."image = ("..imagePath.."');\n"
			fileText = fileText..tab2.."properties = "..as3.tolua(DAME.GetTextForProperties( propertiesString, layer.properties ))..";\n"
			fileText = fileText..tab2.."layer"..layerName.." = addTilemap(Assets.getText(mapString) ,image, "..string.format("%.3f",x)..", "..string.format("%.3f",y)..", "..as3.tolua(layer.map.tileWidth)..", "..as3.tolua(layer.map.tileHeight)..", "..string.format("%.3f",xscroll)..", "..string.format("%.3f",yscroll)..", "..hasHitsString..", "..as3.tolua(layer.map.collideIndex)..", "..as3.tolua(layer.map.drawIndex)..", properties, onAddCallback );\n\n"

			--fileText = fileText..tab3.."properties = "..as3.tolua(DAME.GetTextForProperties( propertiesString, layer.properties ))..";\n"
			--tileData = as3.tolua(DAME.CreateTileDataText( layer, tilePropertiesString, "", ""))
			--if # tileData > 0 then
				--fileText = fileText..tileData
				--fileText = fileText..tab3.."properties.push( { name:\"%DAME_tiledata%\", value:tileProperties } );\n"
			--end
			--fileText = fileText..tab3.."layer"..layerName.." = addTilemap( CSV_"..layerName..", Img_"..layerName..", "..string.format("%.3f",x)..", "..string.format("%.3f",y)..", "..as3.tolua(layer.map.tileWidth)..", "..as3.tolua(layer.map.tileHeight)..", "..string.format("%.3f",xscroll)..", "..string.format("%.3f",yscroll)..", "..hasHitsString..", "..as3.tolua(layer.map.collideIndex)..", "..as3.tolua(layer.map.drawIndex)..", properties, onAddCallback );\n"

			-- Only set the bounds based on maps whose scroll factor is the same as the player's.
			if xscroll == 1 and yscroll == 1 then
				if x < minx then minx = x end
				if y < miny then miny = y end
				if x + width > maxx then maxx = x + width end
				if y + height > maxy then maxy = y + height end
			end
			
		end
		
		------------------
		-- MASTER GROUP.
		------------------
		
		fileText = fileText.."\n"..tab3.."//Add layers to the master group in correct order.\n"
		fileText = fileText..masterLayerAddText.."\n";
		
		fileText = fileText..tab3.."if ( addToStage )\n"
		fileText = fileText..tab4.."createObjects(onAddCallback, parentObject);\n\n"
		
		fileText = fileText..tab3.."boundsMinX = "..minx..";\n"
		fileText = fileText..tab3.."boundsMinY = "..miny..";\n"
		fileText = fileText..tab3.."boundsMaxX = "..maxx..";\n"
		fileText = fileText..tab3.."boundsMaxY = "..maxy..";\n"
		
		fileText = fileText..tab3.."boundsMin = new FlxPoint("..minx..", "..miny..");\n"
		fileText = fileText..tab3.."boundsMax = new FlxPoint("..maxx..", "..maxy..");\n"
		
		fileText = fileText..tab3.."bgColor = "..as3.tolua(DAME.GetBackgroundColor())..";\n"
		
		fileText = fileText..tab2.."}\n\n"	-- end constructor
		
		---------------
		-- OBJECTS
		---------------
		-- One function for each layer.
		
		fileText = fileText..tab2.."override public function createObjects(onAddCallback:Dynamic = null, parentObject:Dynamic = null):Void\n"
		fileText = fileText..tab2.."{\n"
		-- Must add the paths before the sprites as the sprites index into the paths array.
		for i,v in ipairs(pathLayers) do
			fileText = fileText..tab3.."addPathsForLayer"..pathLayers[i][3].."(onAddCallback);\n"
		end
		for i,v in ipairs(shapeLayers) do
			fileText = fileText..tab3.."addShapesForLayer"..shapeLayers[i][3].."(onAddCallback);\n"
		end
		fileText = fileText..stageAddText
		fileText = fileText..tab3.."generateObjectLinks(onAddCallback);\n"
		fileText = fileText..tab3.."if ( parentObject != null )\n"
		fileText = fileText..tab4.."parentObject.add(masterLayer);\n"
		fileText = fileText..tab3.."else\n"
		fileText = fileText..tab4.."FlxG.state.add(masterLayer);\n"
		fileText = fileText..tab2.."}\n\n"
		
		-- Create the paths first so that sprites can reference them if any are attached.
		
		generatePaths()
		generateShapes()
		
		-- create the sprites.
		
		for i,v in ipairs(spriteLayers) do
			layer = spriteLayers[i][2]
			creationText = tab3..linkAssignText
			creationText = creationText.."%%if parent%%"
				creationText = creationText.."%getparent%.childSprite = "
			creationText = creationText.."%%endifparent%%"
			
				creationText = creationText.."addSpriteToLayer(%constructor:null%, %class%, "..spriteLayers[i][3].."Group , %xpos%, %ypos%, %degrees%, "..as3.tolua(layer.xScroll)..", "..as3.tolua(layer.xScroll)..", %flipped%, %scalex%, %scaley%, "..propertiesString..", onAddCallback );//%name%\n" 
			
			creationText = creationText.."%%if parent%%"
				creationText = creationText..tab3.."%getparent%.childAttachNode = %attachedsegment%;\n"
				creationText = creationText..tab3.."%getparent%.childAttachT = %attachedsegment_t%;\n"
			creationText = creationText.."%%endifparent%%"
			
			fileText = fileText..tab2.."public function addSpritesForLayer"..spriteLayers[i][3].."(onAddCallback:Dynamic = null):Void\n"
			fileText = fileText..tab2.."{\n"
		
			fileText = fileText..as3.tolua(DAME.CreateTextForSprites(layer,creationText,"Avatar"))
			fileText = fileText..tab2.."}\n\n"
		end
		
		-- Create the links between objects.
		
		fileText = fileText..tab2.."public function generateObjectLinks(onAddCallback:Dynamic = null):Void\n"
		fileText = fileText..tab2.."{\n"
		linkText = tab3.."createLink(linkedObjectDictionary[%linkfromid%], linkedObjectDictionary[%linktoid%], onAddCallback, "..propertiesString.." );\n"
		fileText = fileText..as3.tolua(DAME.GetTextForLinks(linkText,group))
		fileText = fileText..tab2.."}\n"
		
		fileText = fileText.."\n"
		fileText = fileText..tab1.."}\n"	-- end class
		--end package Base
		
		
			
		-- Save the file!
		
		DAME.WriteFile(hxDir.."/Level_"..groupName..".hx", fileText )
		
	end
end

-- Create any extra required classes.
-- must be done last after the parser has gone through.

if exportOnlyCSV == false then
	


	baseFileText = baseFileText..tab1.."}\n"	-- end class
	--end package
	DAME.WriteFile(hxDir.."/"..baseClassName..".hx", baseFileText )

	spriteAnimString = "%%spriteanimloop%%"..tab3.."spriteData.animData.push( new AnimData( \"%animname%\",[%%animframeloop%%%tileid%%separator:,%%%animframeloopend%%], %fps%, %looped% ) );\n%%spriteanimloopend%%"
	spriteShapeString = "%%spriteframeloop%%"..tab3.."spriteData.shapeList[%frame%] = ( [%%shapeloop%%new AnimFrameShapeData(\"%shapename%\", AnimFrameShapeData.SHAPE_%TYPE%, %xpos%, %ypos%, %radius%, %wid%, %ht%)%separator:,\n"..tab5..tab5.."%%%shapeloopend%% ]);\n%%spriteframeloopend%%"
	spriteText = "%%if spriteanimsorshapes%%"..tab3.."spriteData = new SpriteData(\"%class%\", \"%name%\");\n"..spriteShapeString..spriteAnimString..tab3.."spriteList.push( spriteData );\n\n%%endif spriteanimsorshapes%%";

	spriteText = as3.tolua( DAME.CreateTextForSpriteClasses( spriteText, "", "", "", "", "" ) )

	if # spriteText > 0 then
		headerText = "//Code generated with DAME and DeV-ZoO. http://www.dambots http://www.dev-zoo.net.com\n\n"
		headerText = headerText.."package "..GamePackage..".DAME_Export\n"
		
		
		fileText = headerText
		fileText = fileText..tab1.."class SpriteInfo\n"
		fileText = fileText..tab1.."{\n"
		fileText = fileText..tab2.."var spriteList:Array = [];\n"
		fileText = fileText..tab2.."public function new():Void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."var spriteData:SpriteData;\n\n"
		fileText = fileText..spriteText
		fileText = fileText..tab2.."}\n"
		fileText = fileText..tab1.."}\n"
		DAME.WriteFile(hxDir.."\\DAME_Export\\SpriteInfo.hx", fileText )
		
		--SpriteData class
		fileText = headerText
		fileText = fileText..tab1.."import flash.utils.Dictionary;\n"
		fileText = fileText..tab1.."class SpriteData\n"
		fileText = fileText..tab1.."{\n"
		fileText = fileText..tab2.."var animData:Array = [];	// AnimData\n"
		fileText = fileText..tab2.."var shapeList:Dictionary = new Dictionary;	// frame index => array of AnimFrameShapeList\n"
		fileText = fileText..tab2.."var className:String;\n"
		fileText = fileText..tab2.."var name:String;\n"
		fileText = fileText..tab2.."public function new( ClassName:String, Name:String ):Void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."className = ClassName;\n"
		fileText = fileText..tab3.."name = Name;\n"
		fileText = fileText..tab2.."}\n"
		fileText = fileText..tab1.."}\n"
		DAME.WriteFile(hxDir.."\\DAME_Export\\SpriteData.hx", fileText )
		
		fileText = headerText
		fileText = fileText..tab1.."class AnimFrameShapeData\n"
		fileText = fileText..tab1.."{\n"
		fileText = fileText..tab2.."public var name:String;\n"
		fileText = fileText..tab2.."public var x:Int;\n"
		fileText = fileText..tab2.."public var y:Int;\n"
		fileText = fileText..tab2.."public var type:Int;\n"
		fileText = fileText..tab2.."public var width:Int = 0;\n"
		fileText = fileText..tab2.."public var height:Int = 0;\n"
		fileText = fileText..tab2.."public var radius:Int = 0;\n"
		fileText = fileText..tab2.."public static const SHAPE_POINT:UInt = 0;\n"
		fileText = fileText..tab2.."public static const SHAPE_BOX:UInt = 1;\n"
		fileText = fileText..tab2.."public static const SHAPE_CIRCLE:UInt = 2;\n"
		fileText = fileText..tab2.."public function new( Name:String, Type:Int, X:Int, Y:Int, Radius:Int, Wid:Int, Ht:Int ):Void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."name = Name;\n"
		fileText = fileText..tab3.."type = Type;\n"
		fileText = fileText..tab3.."x = X;\n"
		fileText = fileText..tab3.."y = Y;\n"
		fileText = fileText..tab3.."radius = Radius;\n"
		fileText = fileText..tab3.."width = Wid;\n"
		fileText = fileText..tab3.."Ht = Ht;\n"
		fileText = fileText..tab2.."}\n"
		fileText = fileText..tab1.."}\n"
		fileText = fileText.."}\n"
		DAME.WriteFile(hxDir.."\\DAME_Export\\AnimFrameShapeData.hx", fileText )
		
		fileText = headerText
		fileText = fileText..tab1.."class AnimData\n"
		fileText = fileText..tab1.."{\n"
		fileText = fileText..tab2.."public var name:String;\n"
		fileText = fileText..tab2.."public var frames:Array;\n"
		fileText = fileText..tab2.."public var fps:Float;\n"
		fileText = fileText..tab2.."public var looped:Bool;\n"
		fileText = fileText..tab2.."public function new( Name:String, Frames:Array, Fps:Float, Looped:Bool):Void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."name = Name;\n"
		fileText = fileText..tab3.."frames = Frames;\n"
		fileText = fileText..tab3.."fps = Fps;\n"
		fileText = fileText..tab3.."looped = Looped;\n"
		fileText = fileText..tab2.."}\n"
		fileText = fileText..tab1.."}\n"
		fileText = fileText.."}\n"
		DAME.WriteFile(hxDir.."\\DAME_Export\\AnimData.hx", fileText )
	end


	--if containsTextData == true then
		textfile = "package "..GamePackage..";\n"
		textfile = textfile..tab1.."class TextData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var x:Float;\n"
		textfile = textfile..tab2.."public var y:Float;\n"
		textfile = textfile..tab2.."public var width:UInt;\n"
		textfile = textfile..tab2.."public var height:UInt;\n"
		textfile = textfile..tab2.."public var angle:Float;\n"
		textfile = textfile..tab2.."public var text:String;\n"
		textfile = textfile..tab2.."public var fontName:String;\n"
		textfile = textfile..tab2.."public var size:UInt;\n"
		textfile = textfile..tab2.."public var color:UInt;\n"
		textfile = textfile..tab2.."public var alignment:String;\n\n"
		textfile = textfile..tab2.."public function new( X:Float, Y:Float, Width:UInt, Height:UInt, Angle:Float, Text:String, FontName:String, Size:UInt, Color:UInt, Alignment:String )\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."x = X;\n"
		textfile = textfile..tab3.."y = Y;\n"
		textfile = textfile..tab3.."width = Width;\n"
		textfile = textfile..tab3.."height = Height;\n"
		textfile = textfile..tab3.."angle = Angle;\n"
		textfile = textfile..tab3.."text = Text;\n"
		textfile = textfile..tab3.."fontName = FontName;\n"
		textfile = textfile..tab3.."size = Size;\n"
		textfile = textfile..tab3.."color = Color;\n"
		textfile = textfile..tab3.."alignment = Alignment;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		
		DAME.WriteFile(hxDir.."/TextData.hx", textfile )
	--end
	
	if containsPaths == true then
		textfile = "package "..GamePackage..";\n"
		textfile = textfile..tab1.."import "..flixelPackage..".group.FlxGroup;\n"
		textfile = textfile..tab1.."import "..flixelPackage..".FlxSprite;\n\n"
		textfile = textfile..tab1.."class PathData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var nodes:Array;\n"
		textfile = textfile..tab2.."public var isClosed:Bool;\n"
		textfile = textfile..tab2.."public var isSpline:Bool;\n"
		textfile = textfile..tab2.."public var layer:FlxGroup;\n\n"
		textfile = textfile..tab2.."// These values are only set if there is an attachment.\n"
		textfile = textfile..tab2.."public var childSprite:FlxSprite = null;\n"
		textfile = textfile..tab2.."public var childAttachNode:Int = 0;\n"
		textfile = textfile..tab2.."public var childAttachT:Float = 0;\t// position of child between attachNode and next node.(0-1)\n\n"
		textfile = textfile..tab2.."public function new( Nodes:Array, Closed:Bool, Spline:Bool, Layer:FlxGroup )\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."nodes = Nodes;\n"
		textfile = textfile..tab3.."isClosed = Closed;\n"
		textfile = textfile..tab3.."isSpline = Spline;\n"
		textfile = textfile..tab3.."layer = Layer;\n"
		textfile = textfile..tab2.."}\n\n"
		textfile = textfile..tab2.."public function destroy():Void\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."layer = null;\n"
		textfile = textfile..tab3.."childSprite = null;\n"
		textfile = textfile..tab3.."nodes = null;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		
		DAME.WriteFile(hxDir.."/PathData.hx", textfile )
		
	end
	
	if containsBoxData == true or containsCircleData == true then
		textfile = "package "..GamePackage..";\n"
		textfile = textfile..tab1.."import "..flixelPackage..".group.FlxGroup;\n\n"
		textfile = textfile..tab1.."class ShapeData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var x:Float;\n"
		textfile = textfile..tab2.."public var y:Float;\n"
		textfile = textfile..tab2.."public var group:FlxGroup;\n\n"
		textfile = textfile..tab2.."public function new(X:Float, Y:Float, Group:FlxGroup )\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."x = X;\n"
		textfile = textfile..tab3.."y = Y;\n"
		textfile = textfile..tab3.."group = Group;\n"
		textfile = textfile..tab2.."}\n\n"
		textfile = textfile..tab2.."public function destroy():Void\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."group = null;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		
		DAME.WriteFile(hxDir.."/ShapeData.hx", textfile )
	end
	
	if containsBoxData == true then
		textfile = "package "..GamePackage..";\n"
		textfile = textfile..tab1.."import "..flixelPackage..".group.FlxGroup;\n\n"
		textfile = textfile..tab1.."class BoxData extends ShapeData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var angle:Float;\n"
		textfile = textfile..tab2.."public var width:UInt;\n"
		textfile = textfile..tab2.."public var height:UInt;\n\n"
		textfile = textfile..tab2.."public function new( X:Float, Y:Float, Angle:Float, Width:Float, Height:Float, Group:FlxGroup ) \n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."super(X, Y, Group);\n"
		textfile = textfile..tab3.."angle = Angle;\n"
		textfile = textfile..tab3.."width = Std.int(Width); //rounding Float to Int\n"
		textfile = textfile..tab3.."height = Std.int(Height); //rounding Float to Int\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		
		DAME.WriteFile(hxDir.."/BoxData.hx", textfile )
	end
	
	if containsCircleData == true then
		textfile = "package "..GamePackage..";\n"
		textfile = textfile..tab1.."import "..flixelPackage..".group.FlxGroup;\n\n"
		textfile = textfile..tab1.."class CircleData extends ShapeData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var radius:Float;\n\n"
		textfile = textfile..tab2.."public function new( X:Float, Y:Float, Radius:Float, Group:FlxGroup )\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."super(X, Y, Group);\n"
		textfile = textfile..tab3.."radius = Radius;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		
		DAME.WriteFile(hxDir.."/CircleData.hx", textfile )
	end
	
	textfile = "package "..GamePackage..";\n"
	textfile = textfile..tab1.."class ObjectLink\n"
	textfile = textfile..tab1.."{\n"
	textfile = textfile..tab2.."public var fromObject:Dynamic;\n"
	textfile = textfile..tab2.."public var toObject:Dynamic;\n"
	textfile = textfile..tab2.."public function new(from:Dynamic, to:Dynamic)\n"
	textfile = textfile..tab2.."{\n"
	textfile = textfile..tab3.."fromObject = from;\n"
	textfile = textfile..tab3.."toObject = to;\n"
	textfile = textfile..tab2.."}\n\n"
	textfile = textfile..tab2.."public function destroy():Void\n"
	textfile = textfile..tab2.."{\n"
	textfile = textfile..tab3.."fromObject = null;\n"
	textfile = textfile..tab3.."toObject = null;\n"
	textfile = textfile..tab2.."}\n"
	textfile = textfile..tab1.."}\n"
	
	DAME.WriteFile(hxDir.."/ObjectLink.hx", textfile )
end


return 1
