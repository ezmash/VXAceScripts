=begin

Lazy Tilesets - Importer
Version 1.0
by Shaz, for RPG Maker Web

-------------------------------- IMPORTANT ------------------------------------
The names you use must EXACTLY match the files provided with your tileset.
This relies on you NOT renaming any of the tileset resources or the settings file.
-------------------------------------------------------------------------------


This script allows you to create a new blank tileset, add some commands to 
the note box, run your game, and the tileset slots will be populated for you, 
with all the correct settings.  Close your project without saving, then reopen, 
to see the updated tilesets.  No more spending hours wading through, guessing 
what the settings should be!  

When you're all done, you can remove the script and all of the .VXATileset 
files, as well as the tileset notes you added for this purpose.

For the examples below, we'll assume the files RTPExterior.VXATileset, 
RTPInterior.VXATileset and RTPDungeon.VXATileset contain the data for
the RTP tilesets.


BEGINNER MODE:
Put the following into the note of a new tileset, to have the full details
populated:
  <import RTPExterior>
  
INTERMEDIATE MODE:
Put the following into the note of a new tileset, to have only the specified
slots in a new tileset populated:
  <import RTPExterior A1 A2 A3 A4 A5>
  
Put the following into the note of a new tileset, to have a combination of
slots from multiple tilesets:
  <import RTPExterior A1 A2 A3 A4 A5>
  <import RTPInterior B C D E>
  
  (the following would also achive the same thing):
  <import RTPExterior>
  <import RTPInterior B C D E>
  
ADVANCED MODE:
Put the following into the note of a new tileset, to have a combination of
slots from multiple tilesets and move them around as specified:
  <import RTPInterior B C>
  <import RTPDungeon B:D C:E>
  
  - the above copies slots B and C from the RTPInterior file, then copies
    slots B and C from the RTPDungeon file, but puts them into slots D and E
  - this can only be done with the B-E tiles, as they share the same format
    and functionality

=end


module RMWeb
  module LazyTilesets
    def self.import_tileset_data
      backed_up = false
      source_tilesets = {}
      slots = {"A1" => [0, 2048, 2815],
               "A2" => [1, 2816, 4351],
               "A3" => [2, 4352, 5887],
               "A4" => [3, 5888, 8191],
               "A5" => [4, 1536, 1663],
               "B"  => [5, 0, 255],
               "C"  => [6, 256, 511],
               "D"  => [7, 512, 767],
               "E"  => [8, 768, 1023] }
                
      target_tilesets = load_data("Data/Tilesets.rvdata2")
      
      target_tilesets.each { |target|
        next if !target || target.note !~ /<import (.*)>/i
        
        msgprfx = "Tileset #{target.id} - #{target.name}:"
        
        # Backup the original before making any changes
        if !backed_up
          timestamp = Time.now.strftime('%Y%m%d%H%M%S')
          File.open("Data/Tilesets#{timestamp}.rvdata2", "wb") { |file|
            Marshal.dump(target_tilesets, file)
            backed_up = true
          }
        end
        
        # process each import statement
        target.note.split(/[\r\n]+/).each { |line|
          next if !line || line !~ /<import (.*)>/i
          res = /<import (.*)>/i.match(line)[1].scan(/[^ ]+/).collect { |det| det }
          tileset_name = res.shift

          # grab the tileset we're copying from
          if !source_tilesets.has_key?(tileset_name)
            begin
              source_tilesets[tileset_name] = load_data(
                "Graphics/Tilesets/#{tileset_name}.VXATileset")
            rescue
              raise("#{msgprfx} Unable to find Graphics/Tilesets/#{tileset_name}.VXATileset")
            end
          end
          source = source_tilesets[tileset_name]
          
          # copy the whole lot if individual slots haven't been specified
          res = slots.keys if res.size == 0 
          
          res.each { |copy_group|
            from_slot, to_slot = copy_group.split(/:/)
            to_slot = from_slot if !to_slot || to_slot == ''
            
            # ensure slots are valid, and cross-copying is only done between B-E slots
            raise("#{msgprfx} Invalid slot #{from_slot}") if !slots.has_key?(from_slot)
            raise("#{msgprfx} Invalid slot #{to_slot}") if !slots.has_key?(to_slot)
            raise("#{msgprfx} A1-A5 slots cannot be moved") if from_slot != to_slot && 
              (!'BCDE'.include?(from_slot) || !'BCDE'.include?(to_slot))
            
            from_slot_id, from_slot_start, from_slot_end = slots[from_slot]
            to_slot_id, to_slot_counter, tmp = slots[to_slot]
            
            # and copy the slot
            target.tileset_names[to_slot_id] = source.tileset_names[from_slot_id]
            (from_slot_start .. from_slot_end).each { |tile|
              target.flags[to_slot_counter] = source.flags[tile]
              to_slot_counter += 1
            }
            
            # A2 tile determines the tileset mode
            target.mode = source.mode if from_slot == "A2"
          }
        }
      }
      
      # If any changes were made, save the new tileset
      if backed_up
        File.open("Data/Tilesets.rvdata2", "wb") { |file|
          Marshal.dump(target_tilesets, file)
        }
      end
    end
  end
end

RMWeb::LazyTilesets.import_tileset_data