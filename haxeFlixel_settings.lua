-- Display the settings for the exporter.

DAME.AddHtmlTextLabel("Ensure you use the <b>DeVZoO</b> PlayState.hx file in the samples as the template for any code.")
DAME.AddBrowsePath("Hx dir:","HxDir",false, "Where you place the HaXe files.")
DAME.AddBrowsePath("CSV dir:","CSVDir",false)
DAME.AddBrowsePath("Compile Folder:","CompileFolder",false, "The folder where your project file is ( For flashdevelop this is the folder where the .hxproj is. Used to get right paths for the embedded files")

DAME.AddTextInput("Base Class", "BaseLevel", "BaseClass", true, "What to call the base class that all levels will extend." )
DAME.AddTextInput("Base Class Extends", "", "BaseClassExtends", true, "If you put something here the base class will extend from it." )
DAME.AddTextInput("Intermediate Class", "", "IntermediateClass", true, "This is an optional class which levels will extend from and must extend from the base class." )
DAME.AddTextInput("Game package", "com", "GamePackage", true, "package for your game's .as files." )
DAME.AddTextInput("Flixel package", "flixel", "FlixelPackage", true, "package use for flixel .as files." )
DAME.AddTextInput("TileMap class", "FlxTilemap", "TileMapClass", true, "Base class used for tilemaps." )
DAME.AddMultiLineTextInput("Imports", "", "Imports", 50, true, "Imports for each level class file go here" )
DAME.AddCheckbox("Export only CSV","ExportOnlyCSV",false,"If ticked then the script will only export the map CSV files and nothing else.")

return 1
