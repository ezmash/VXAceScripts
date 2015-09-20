=begin

Lazy Tilesets - Exporter
Version 1.0
by Shaz, for RPG Maker Web

Use this script to export your tileset data (tile slots, passage, ladder, 
counter, bush, damage, terrain tags) to an external file that can be shipped 
with the resource pack.

Buyers can then use the companion script to load the tileset data into their
game, and avoid having to set everything up themselves.

On the tabs for tilesets you want to export, add the following in the note box:
  <export tilesetname>

This will create a tilesetname.VXATileset file in your Graphics/Tilesets folder
for each tileset with the note.
  
tilesetname can be any combination of letters and numbers - any other characters
will be stripped out.  Take care not to use the same name in multiple slots -
there will be one .VXATileset created per tileset slot, and there is no check
to see if that file name has already been used - if it has, the existing one
will be overwritten.

If you have multiple tilesets in a pack, give each one individual names.  
Eg:
  <export WildWestInside>
  <export WildWestOutside>
  <export WildWestDungeon>

=end


module RMWeb
  module LazyTilesets
    def self.export_tileset_data
      tilesets = load_data("Data/Tilesets.rvdata2")
      tilesets.compact.each { |tileset|
        if tileset.note =~ /<export (.*)>/i
          filename = $1.gsub(/[^a-zA-Z0-9]/){''} + '.VXATileset'
          File.open("Graphics/Tilesets/#{filename}", "wb") { |file|
            Marshal.dump(tileset, file)
          }
        end
      }
    end
  end
end

RMWeb::LazyTilesets.export_tileset_data