class XReference
  attr_accessor :source
  attr_accessor :location
  attr_accessor :page
  attr_accessor :line
  attr_accessor :reference
  
  def initialize(source, location, page, line, reference)
    @source = source
    @location = location
    @page = page
    @line = line
    @reference = reference
  end
end

module SHAZ
  module XRef
    #========================================================================
    # DO NOT MODIFY BELOW THIS LINE
    #========================================================================
    VAREXP = /\\v\[(\d+)\]/i
    
    FEATURE_STATE_RATE      = 13
    FEATURE_STATE_RESIST    = 14
    FEATURE_ATK_STATE       = 32
    FEATURE_SKILL_ADD       = 43
    FEATURE_SKILL_SEAL      = 44
    FEATURE_LIST = [FEATURE_STATE_RATE, FEATURE_STATE_RESIST, FEATURE_ATK_STATE,
                    FEATURE_SKILL_ADD, FEATURE_SKILL_SEAL]
    
    EFFECT_ADD_STATE        = 21
    EFFECT_REMOVE_STATE     = 22
    EFFECT_LEARN_SKILL      = 43
    EFFECT_COMMON_EVENT     = 44
    EFFECT_LIST = [EFFECT_ADD_STATE, EFFECT_REMOVE_STATE, 
                   EFFECT_LEARN_SKILL, EFFECT_COMMON_EVENT]
    
    def self.data_sources(sym)
      src =  {:switches       =>      $data_system.switches,
              :variables      =>      $data_system.variables,
              :common_events  =>      $data_common_events,
              :actors         =>      $data_actors,
              :classes        =>      $data_classes,
              :skills         =>      $data_skills,
              :items          =>      $data_items,
              :weapons        =>      $data_weapons,
              :armors         =>      $data_armors,
              :enemies        =>      $data_enemies,
              :troops         =>      $data_troops,
              :states         =>      $data_states,
              :animations     =>      $data_animations}
      return src[sym]
    end
    
    def self.data_title(sym)
      title = {:switches       =>      'Switch',
               :variables      =>      'Variable',
               :common_events  =>      'Common Event',
               :actors         =>      'Actor',
               :classes        =>      'Class',
               :skills         =>      'Skill',
               :items          =>      'Item',
               :weapons        =>      'Weapon',
               :armors         =>      'Armor',
               :enemies        =>      'Enemy',
               :troops         =>      'Troop',
               :states         =>      'State',
               :animations     =>      'Animation'}
      return title[sym]
    end
  
    def self.command(code)
      codes =  {101 => 'Show Text',
                401 => 'Show Text', # continuation
                103 => 'Input Number',
                104 => 'Select Key Item',
                105 => 'Show Scrolling Text',
                405 => 'Show Scrolling Text', # continuation
                111 => 'Conditional Branch',
                117 => 'Call Common Event',
                121 => 'Control Switches',
                122 => 'Control Variables',
                125 => 'Change Gold',
                126 => 'Change Items',
                127 => 'Change Weapons',
                128 => 'Change Armor',
                129 => 'Change Party Member',
                201 => 'Transfer Player',
                202 => 'Set Vehicle Location',
                203 => 'Set Event Location',
                505 => 'Set Move Route', # continuation
                212 => 'Show Animation',
                231 => 'Show Picture',
                232 => 'Move Picture',
                285 => 'Get Location Info',
                301 => 'Battle Processing',
                302 => 'Shop Processing',
                605 => 'Shop Processing', # continuation
                303 => 'Name Input Processing',
                311 => 'Change HP',
                312 => 'Change MP',
                313 => 'Change State',
                314 => 'Recover All',
                315 => 'Change EXP',
                316 => 'Change Level',
                317 => 'Change Parameters',
                318 => 'Change Skills',
                319 => 'Change Equipment',
                320 => 'Change Name',
                321 => 'Change Class',
                324 => 'Change Nickname',
                322 => 'Change Actor Graphic',
                331 => 'Change Enemy HP',
                332 => 'Change Enemy MP',
                333 => 'Change Enemy State',
                334 => 'Enemy Recover All',
                335 => 'Enemy Appear',
                336 => 'Enemy Transform',
                337 => 'Show Battle Animation',
                339 => 'Force Action',
               }
      return codes[code]
    end

    def self.load_xrefs
      $data_xrefs = {}
      
      $data_actors.compact.each         {|actor|  build_actor_xrefs(actor)}
      $data_classes.compact.each        {|cls|    build_class_xrefs(cls)}
      $data_skills.compact.each         {|skill|  build_skill_xrefs(skill)}
      $data_items.compact.each          {|item|   build_item_xrefs(item)}
      $data_weapons.compact.each        {|weapon| build_weapon_xrefs(weapon)}
      $data_armors.compact.each         {|armor|  build_armor_xrefs(armor)}
      $data_enemies.compact.each        {|enemy|  build_enemy_xrefs(enemy)}
      $data_troops.compact.each         {|troop|  build_troop_xrefs(troop)}
      $data_states.compact.each         {|state|  build_state_xrefs(state)}
      $data_common_events.compact.each  {|evt|    build_common_event_xrefs(evt)}
      
      Dir.glob('Data/Map???.rvdata2').each {|filename| build_map_xrefs(filename)}
    end
    
    def self.save_xref(type, id, reference = command(@cmd))
      $data_xrefs[type] = [] if $data_xrefs[type].nil?
      $data_xrefs[type][id] = [] if $data_xrefs[type][id].nil?
      $data_xrefs[type][id].push(XReference.new(@source, sprintf('%d: %s', @refid, @ref), @page, @line, reference))
    end
    
    def self.scan_db_text(text, reference)
      text.scan(SHAZ::XRef::VAREXP).flatten.map {|val| val.to_i}.each { |var|
        save_xref(:variables, var, reference)
      }
    end
    
    def self.scan_features(features)
      features.select{ |ft| FEATURE_LIST.include?(ft.code) }.each { |feature|
        case feature.code
        when FEATURE_STATE_RATE, FEATURE_STATE_RESIST, FEATURE_ATK_STATE
          save_xref(:states, feature.data_id, 'Features')
        when FEATURE_SKILL_ADD, FEATURE_SKILL_SEAL
          save_xref(:skills, feature.data_id, 'Features')
        end
      }
    end
    
    def self.scan_effects(effects)
      effects.select{ |eft| EFFECT_LIST.include?(eft.code) }.each { |effect|
        case effect.code
        when EFFECT_ADD_STATE, EFFECT_REMOVE_STATE
          save_xref(:states, effect.data_id, 'Effects')
        when EFFECT_LEARN_SKILL
          save_xref(:skills, effect.data_id, 'Effects')
        when EFFECT_COMMON_EVENT
          save_xref(:common_events, effect.value1, 'Effects')
        end
      }
    end
    
    def self.build_actor_xrefs(a)
      @source = 'Actor'
      @refid = a.id
      @ref = a.name
      
      # Text Fields
      scan_db_text(a.name, 'Name')
      scan_db_text(a.nickname, 'Nickname')
      scan_db_text(a.description, 'Description')
      
      # Class
      save_xref(:classes, a.class_id, 'Class')
      
      # Starting Equipment
      5.times { |i|
        e = a.equips[i]
        next if e.nil? || e == 0
        if i == 0 || (i == 1 && 
          (a.features + $data_classes[a.class_id].features).select{|ft| ft.code == 55}.size > 0)
          save_xref(:weapons, e, sprintf('Equip Slot %d', i))
        else
          save_xref(:armors, e, sprintf('Equip Slot %d', i))
        end
      }
      
      # features
      scan_features(a.features)
    end
    
    def self.build_class_xrefs(cls)
      @source = 'Class'
      @refid = cls.id
      @ref = cls.name
      
      # Text Fields
      scan_db_text(cls.name, 'Name')
      
      # Learnings
      cls.learnings.compact.each {|skill|
        save_xref(:skills, skill.skill_id, sprintf('Learnings (Level %d)', skill.level))
      }
      
      # features
      scan_features(cls.features)
    end
    
    def self.build_skill_xrefs(skill)
      @source = 'Skill'
      @refid = skill.id
      @ref = skill.name
      
      # Text Fields
      scan_db_text(skill.name, 'Name')
      scan_db_text(skill.description, 'Description')
      scan_db_text(skill.message1, 'Message 1')
      scan_db_text(skill.message2, 'Message 2')
      
      # Animation
      save_xref(:animations, [skill.animation_id, 1].max, 'Animation') if skill.animation_id != 0
      
      # effects
      scan_effects(skill.effects)
    end
    
    def self.build_item_xrefs(item)
      @source = 'Item'
      @refid = item.id
      @ref = item.name
      
      # Text Fields
      scan_db_text(item.name, 'Name')
      scan_db_text(item.description, 'Description')
      
      # Animation
      save_xref(:animations, [item.animation_id, 1].max, 'Animation') if item.animation_id != 0
      
      # effects
      scan_effects(item.effects)
    end
    
    def self.build_weapon_xrefs(weapon)
      @source = 'Weapon'
      @refid = weapon.id
      @ref = weapon.name
      
      # Text Fields
      scan_db_text(weapon.name, 'Name')
      scan_db_text(weapon.description, 'Description')
      
      # Animation
      save_xref(:animations, [weapon.animation_id, 1].max, 'Animation') if weapon.animation_id != 0
      
      # features
      scan_features(weapon.features)
    end
    
    def self.build_armor_xrefs(armor)
      @source = 'Armor'
      @refid = armor.id
      @ref = armor.name
      
      # Text Fields
      scan_db_text(armor.name, 'Name')
      scan_db_text(armor.description, 'Description')
      
      # features
      scan_features(armor.features)
    end
    
    def self.build_enemy_xrefs(enemy)
      @source = 'Enemy'
      @refid = enemy.id
      @ref = enemy.name
      
      # Text Fields
      scan_db_text(enemy.name, 'Name')
      
      # Drop Items
      enemy.drop_items.each { |dropitem|
        case dropitem.kind
        when 1
          save_xref(:items, dropitem.data_id, 'Drop Items')
        when 2
          save_xref(:weapons, dropitem.data_id, 'Drop Items')
        when 3
          save_xref(:armors, dropitem.data_id, 'Drop Items')
        end
      }
      
      # Action Patterns
      enemy.actions.each { |action|
        save_xref(:skills, action.skill_id, 'Action Patterns')
        case action.condition_type
        when 4
          save_xref(:states, action.condition_param1, sprintf('Action Pattern %s',
            $data_skills[action.skill_id].name))
        when 6
          save_xref(:switches, action.condition_param1, sprintf('Action Pattern %s',
            $data_skills[action.skill_id].name))
        end
      }
      
      # features
      scan_features(enemy.features)
    end
    
    def self.build_troop_xrefs(troop)
      @source = 'Troop'
      @refid = troop.id
      @ref = troop.name
      
      # Text Fields
      scan_db_text(troop.name, 'Name')
      
      # Members
      troop.members.collect{|member| member.enemy_id}.uniq.each { |enemy|
        save_xref(:enemies, enemy, 'Members')
      }
      
      # Pages
      troop.pages.size.times { |page|
        @page = page + 1
        @line = nil
        cond = troop.pages[page].condition
        
        # Conditions
        save_xref(:actors, cond.actor_index, 'Page Conditions') if cond.actor_valid
        save_xref(:switches, cond.switch_id, 'Page Conditions') if cond.switch_valid
        
        # Event Commands
        @list = troop.pages[page].list
        build_event_xrefs
      }
      
      @page = nil
      @line = nil
    end
    
    def self.build_state_xrefs(state)
      @source = 'State'
      @refid = state.id
      @ref = state.name
      
      # Text Fields
      scan_db_text(state.name, 'Name')
      scan_db_text(state.message1, 'Message 1')
      scan_db_text(state.message2, 'Message 2')
      scan_db_text(state.message3, 'Message 3')
      scan_db_text(state.message4, 'Message 4')

      # features
      scan_features(state.features)
    end
    
    def self.build_common_event_xrefs(evt)
      @source = 'Common Event'
      @refid = evt.id
      @ref = evt.name
      
      # Conditions
      save_xref(:switches, evt.switch_id, 'Event Conditions') if evt.trigger != 0
      
      # Events
      @list = evt.list
      build_event_xrefs
      
      @line = nil
    end
    
    def self.build_map_xrefs(filename)
      map_id = /Data\/Map(\d+)\.rvdata2/.match(filename)[1].to_i
      map_name = $data_mapinfos[map_id].name
      @source = sprintf('Map %d (%s)', map_id, map_name)
      map = load_data(filename)
      
      # Encounters
      @refid = nil
      @ref = nil
      map.encounter_list.each { |encounter|
        save_xref(:troops, encounter.troop_id, 'Encounter List')
      }
      
      # Events (pages of conditions/event commands)
      map.events.each { |evt_id, evt|
        next if evt.nil? || evt.pages.nil?
        @refid = evt_id
        @ref = evt.name
        
        evt.pages.size.times { |page|
          @page = page + 1
          @line = nil 
          
          # Conditions
          cond = evt.pages[page].condition
          save_xref(:switches, cond.switch1_id, 'Page Conditions') if cond.switch1_valid
          save_xref(:switches, cond.switch2_id, 'Page Conditions') if cond.switch2_valid
          save_xref(:variables, cond.variable_id, 'Page Conditions') if cond.variable_valid
          save_xref(:items, cond.item_id, 'Page Conditions') if cond.item_valid
          save_xref(:actors, cond.actor_id, 'Page Conditions') if cond.actor_valid
          
          # Event Commands
          @list = evt.pages[page].list
          build_event_xrefs
        }
      }
      
      @page = nil
      @line = nil
    end
    
    def self.build_event_xrefs
      return if @list.nil?
      
      @list.size.times { |line|
        @line = line + 1
        @cmd = @list[line].code
        @params = @list[line].parameters.clone
        method_name = "build_xrefs_command_#{@cmd}"
        send(method_name) if respond_to?(method_name)
      }
    end
    
    #--------------------------------------------------------------------------
    # * Show Text
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_101
      # no actual text in the 101 line - it's just setup stuff
    end
    def self.build_xrefs_command_401
      scan_db_text(@params[0], 'Show Text')
    end
    #--------------------------------------------------------------------------
    # * Show Choices
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_102
      @params[0].each {|choice| scan_db_text(choice, 'Show Choices')}
    end
    #--------------------------------------------------------------------------
    # * Input Number
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_103
      save_xref(:variables, @params[0])
    end
    #--------------------------------------------------------------------------
    # * Select Item
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_104
      save_xref(:variables, @params[0])
    end
    #--------------------------------------------------------------------------
    # * Show Scrolling Text
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_105
      # no actual text in the 105 line - it's just setup stuff
    end
    def self.build_xrefs_command_405
      scan_db_text(@params[0], 'Show Scrolling Text')
    end
    #--------------------------------------------------------------------------
    # * Conditional Branch
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_111
      result = false
      case @params[0]
      when 0  # Switch
        save_xref(:switches, @params[1])
      when 1  # Variable
        save_xref(:variables, @params[1])
        save_xref(:variables, @params[3]) if @params[2] != 0
      when 4  # Actor
        save_xref(:actors, @params[1])
        save_xref([:classes, :skills, :weapons, :armors, :states][@params[2] - 2], 
          @params[3]) if @params[2].between?(2, 6)
      when 5  # Enemy
        save_xref(:states, @params[3]) if @params[2] == 1
      when 8  # Item
        save_xref(:items, @params[1])
      when 9  # Weapon
        save_xref(:weapons, @params[1])
      when 10  # Armor
        save_xref(:armors, @params[1])
      end
    end
    #--------------------------------------------------------------------------
    # * Common Event
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_117
      save_xref(:common_events, @params[0])
    end
    #--------------------------------------------------------------------------
    # * Control Switches
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_121
      (@params[0]..@params[1]).each do |i|
        save_xref(:switches, i)
      end
    end
    #--------------------------------------------------------------------------
    # * Control Variables
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_122
      value = 0
      case @params[3]  # Operand
      when 1  # Variable
        save_xref(:variables, @params[4])
      when 3  # Game Data
        save_xref([:items, :weapons, :armors, :actors][@params[4]], @params[5]) if @params[4] <= 3
      end
      (@params[0]..@params[1]).each do |i|
        save_xref(:variables, i)
      end
    end
    #--------------------------------------------------------------------------
    # * Change Gold
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_125
      save_xref(:variables, @params[2]) if @params[1] != 0
    end
    #--------------------------------------------------------------------------
    # * Change Items
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_126
      save_xref(:items, @params[0])
      save_xref(:variables, @params[3]) if @params[2] != 0
    end
    #--------------------------------------------------------------------------
    # * Change Weapons
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_127
      save_xref(:weapons, @params[0])
      save_xref(:variables, @params[3]) if @params[2] != 0
    end
    #--------------------------------------------------------------------------
    # * Change Armor
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_128
      save_xref(:armors, @params[0])
      save_xref(:variables, @params[3]) if @params[2] != 0
    end
    #--------------------------------------------------------------------------
    # * Change Party Member
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_129
      save_xref(:actors, @params[0])
    end
    #--------------------------------------------------------------------------
    # * Transfer Player
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_201
      if @params[0] != 0
        save_xref(:variables, @params[1])
        save_xref(:variables, @params[2])
        save_xref(:variables, @params[3])
      end
    end
    #--------------------------------------------------------------------------
    # * Set Vehicle Location
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_202
      if @params[1] != 0
        save_xref(:variables, @params[2])
        save_xref(:variables, @params[3])
        save_xref(:variables, @params[4])
      end
    end
    #--------------------------------------------------------------------------
    # * Set Event Location
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_203
      if @params[1] != 0
        save_xref(:variables, @params[2])
        save_xref(:variables, @params[3])
      end
    end
    #--------------------------------------------------------------------------
    # * Set Move Route
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_205
      # nothing in the first line of the command - just setup stuff
    end
    def self.build_xrefs_command_505
      save_xref(:switches, @params[0].parameters[0]) if [27, 28].include?(@params[0].code)
    end
    #--------------------------------------------------------------------------
    # * Show Animation
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_212
      save_xref(:animations, @params[1])
    end
    #--------------------------------------------------------------------------
    # * Show Picture
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_231
      if @params[3] != 0
        save_xref(:variables, @params[4])
        save_xref(:variables, @params[5])
      end
    end
    #--------------------------------------------------------------------------
    # * Move Picture
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_232
      if @params[3] != 0
        save_xref(:variables, @params[4])
        save_xref(:variables, @params[5])
      end
    end
    #--------------------------------------------------------------------------
    # * Get Location Info
    #--------------------------------------------------------------------------
    def command_285
      save_xref(:variables, @params[0])
      if @params[2] != 0
        save_xref(:variables, @params[3])
        save_xref(:variables, @params[4])
      end
    end
    #--------------------------------------------------------------------------
    # * Battle Processing
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_301
      save_xref([:troops, :variables][@params[0]], @params[1]) if @params[0] <= 1
    end
    #--------------------------------------------------------------------------
    # * Shop Processing
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_302
      save_xref([:items, :weapons, :armors][@params[0]], @params[1])
    end
    def self.build_xrefs_command_605
      save_xref([:items, :weapons, :armors][@params[0]], @params[1])
    end
    #--------------------------------------------------------------------------
    # * Name Input Processing
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_303
      save_xref(:actors, @params[0])
    end
    #--------------------------------------------------------------------------
    # * Change HP
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_311
      save_xref(:variables, @params[4]) if @params[3] != 0
      save_xref([:actors, :variables][@params[0]], @params[1])
    end
    #--------------------------------------------------------------------------
    # * Change MP
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_312
      save_xref(:variables, @params[4]) if @params[3] != 0
      save_xref([:actors, :variables][@params[0]], @params[1])
    end
    #--------------------------------------------------------------------------
    # * Change State
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_313
      save_xref([:actors, :variables][@params[0]], @params[1])
      save_xref(:states, @params[3])
    end
    #--------------------------------------------------------------------------
    # * Recover All
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_314
      save_xref([:actors, :variables][@params[0]], @params[1])
    end
    #--------------------------------------------------------------------------
    # * Change EXP
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_315
      save_xref(:variables, @params[4]) if @params[3] != 0
      save_xref([:actors, :variables][@params[0]], @params[1])
    end
    #--------------------------------------------------------------------------
    # * Change Level
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_316
      save_xref(:variables, @params[4]) if @params[3] != 0
      save_xref([:actors, :variables][@params[0]], @params[1])
    end
    #--------------------------------------------------------------------------
    # * Change Parameters
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_317
      save_xref(:variables, @params[5]) if @params[4] != 0
      save_xref([:actors, :variables][@params[0]], @params[1])
    end
    #--------------------------------------------------------------------------
    # * Change Skills
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_318
      save_xref(:skills, @params[3])
      save_xref([:actors, :variables][@params[0]], @params[1])
    end
    #--------------------------------------------------------------------------
    # * Change Equipment
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_319
      save_xref(:actors, @params[0])
      return if @params[2] == 0
      case @params[1]
      when 0 # Weapon
        save_xref(:weapons, @params[2])
      when 1 # Weapon or Armor
        if $data_weapons[@params[2]] && $data_armors[@params[2]]
          save_xref(:weapons, @params[2], 'Change Equipment (*)')
          save_xref(:armors, @params[2], 'Change Equipment (*)')
        elsif $data_weapons[@params[2]]
          save_xref(:weapons, @params[2])
        else
          save_xref(:armors, @params[2])
        end
      else
        save_xref(:armors, @params[2])
      end
    end
    #--------------------------------------------------------------------------
    # * Change Name
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_320
      save_xref(:actors, @params[0])
    end
    #--------------------------------------------------------------------------
    # * Change Class
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_321
      save_xref(:actors, @params[0])
      save_xref(:classes, @params[1])
    end
    #--------------------------------------------------------------------------
    # * Change Actor Graphic
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_322
      save_xref(:actors, @params[0])
    end
    #--------------------------------------------------------------------------
    # * Change Nickname
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_324
      save_xref(:actors, @params[0])
    end
    #--------------------------------------------------------------------------
    # * Change Enemy HP
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_331
      save_xref(:variables, @params[3]) if @params[2] != 0
    end
    #--------------------------------------------------------------------------
    # * Change Enemy MP
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_332
      save_xref(:variables, @params[3]) if @params[2] != 0
    end
    #--------------------------------------------------------------------------
    # * Change Enemy State
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_333
      save_xref(:states, @params[2])
    end
    #--------------------------------------------------------------------------
    # * Enemy Transform
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_336
      save_xref(:enemies, @params[1])
    end
    #--------------------------------------------------------------------------
    # * Show Battle Animation
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_337
      save_xref(:animations, @params[1])
    end
    #--------------------------------------------------------------------------
    # * Force Action
    #--------------------------------------------------------------------------
    def self.build_xrefs_command_339
      save_xref(:actors, @params[1]) if @params[0] != 0
      save_xref(:skills, @params[2])
    end
  end
end

module DataManager
  class << self
    alias shaz_xref_load_normal_database load_normal_database
  end
  
  def self.load_normal_database
    shaz_xref_load_normal_database
    $data_xrefs = {}
    SHAZ::XRef::load_xrefs
  end
end

class Window_MenuCommand < Window_Command
  alias shaz_xref_window_menucommand_add_original_commands add_original_commands
  def add_original_commands
    add_command('XRef Tool', :xref) if $TEST
  end
end

class Scene_Menu < Scene_MenuBase
  alias shaz_xref_scene_menu_create_command_window create_command_window
  def create_command_window
    shaz_xref_scene_menu_create_command_window
    @command_window.set_handler(:xref, method(:command_xref)) if $TEST
  end
  
  def command_xref
    SceneManager.call(Scene_XRef)
  end
end

class Window_XRefCommand < Window_Command
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :selection_window
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0)
    @@last_command_symbol = nil
    select_last
  end
  #--------------------------------------------------------------------------
  # * Get Window Width
  #--------------------------------------------------------------------------
  def window_width
    return 160
  end
  #--------------------------------------------------------------------------
  # * Get Number of Lines to Show
  #--------------------------------------------------------------------------
  def visible_line_number
    item_max
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    @selection_window.mode = current_symbol if @selection_window
  end
  #--------------------------------------------------------------------------
  # * Create Command List
  #--------------------------------------------------------------------------
  def make_command_list
    add_command('Switches',      :switches, $data_xrefs[:switches])
    add_command('Variables',     :variables, $data_xrefs[:variables])
    add_command('Common Events', :common_events, $data_xrefs[:common_events])
    add_command('Actors',        :actors, $data_xrefs[:actors])
    add_command('Classes',       :classes, $data_xrefs[:classes])
    add_command('Skills',        :skills, $data_xrefs[:skills])
    add_command('Items',         :items, $data_xrefs[:items])
    add_command('Weapons',       :weapons, $data_xrefs[:weapons])
    add_command('Armors',        :armors, $data_xrefs[:armors])
    add_command('Enemies',       :enemies, $data_xrefs[:enemies])
    add_command('Troops',        :troops, $data_xrefs[:troops])
    add_command('States',        :states, $data_xrefs[:states])
    add_command('Animations',    :animations, $data_xrefs[:animations])
  end
  #--------------------------------------------------------------------------
  # * Set Item Window
  #--------------------------------------------------------------------------
  def selection_window=(selection_window)
    @selection_window = selection_window
    update
  end
  #--------------------------------------------------------------------------
  # * Processing When OK Button Is Pressed
  #--------------------------------------------------------------------------
  def process_ok
    @@last_command_symbol = current_symbol
    super
  end
  #--------------------------------------------------------------------------
  # * Restore Previous Selection Position
  #--------------------------------------------------------------------------
  def select_last
    select_symbol(@@last_command_symbol)
  end
end

class Window_XRefSelection < Window_Selectable
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super
    @mode = :none
    @data = []
    self.contents.font.size = 20
  end
  #--------------------------------------------------------------------------
  # * Set Mode
  #--------------------------------------------------------------------------
  def mode=(mode)
    return if @mode == mode
    @mode = mode
  end
  #--------------------------------------------------------------------------
  # * Get Digit Count
  #--------------------------------------------------------------------------
  def col_max
    return 2
  end
  #--------------------------------------------------------------------------
  # * Get Number of Items
  #--------------------------------------------------------------------------
  def item_max
    @data ? @data.size : 0
  end
  #--------------------------------------------------------------------------
  # * Get Item
  #--------------------------------------------------------------------------
  def item
    @data && index >= 0 ? @data[index] : nil
  end
  #--------------------------------------------------------------------------
  # * Create Item List
  #--------------------------------------------------------------------------
  def make_item_list
    @data = Array.new(SHAZ::XRef::data_sources(@mode).size - 1) {|id| id + 1}
  end
  #--------------------------------------------------------------------------
  # * Draw Item
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[index]
    return if item.nil?
    rect = item_rect(index)
    rect.width -= 4
    
    id_text = sprintf('%04d: ', item)
    id_width = text_size(id_text).width
    
    src = SHAZ::XRef::data_sources(@mode)
    case @mode
    when :switches, :variables
      name = src[item]
    else
      name = src[item] ? src[item].name : ''
    end
    
    change_color(normal_color)
    rect.x += 4
    draw_text(rect, id_text)
    rect.x += id_width
    rect.width -= id_width + 20
    draw_text(rect, name)
  end
  #--------------------------------------------------------------------------
  # * Help Text
  #--------------------------------------------------------------------------
  def help_text
    src = SHAZ::XRef::data_sources(@mode)
    case @mode
    when :switches, :variables
      name = src[item]
    else
      name = src[item] ? src[item].name : ''
    end
    
    txt = sprintf('%s %4d: %s', SHAZ::XRef::data_title(@mode), item, name)
    return txt
  end
  #--------------------------------------------------------------------------
  # * Set Command Window
  #--------------------------------------------------------------------------
  def command_window=(command_window)
    @command_window = command_window
    update
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    make_item_list
    create_contents
    self.contents.font.size = 20
    draw_all_items
  end
end

class Window_XRefResults < Window_Selectable
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super(x, y, width, height)
    @mode = :none
    @selection = nil
    @data = []
    self.contents.font.size = 20
  end
  #--------------------------------------------------------------------------
  # * Set Mode
  #--------------------------------------------------------------------------
  def mode=(mode)
    @mode = mode
  end
  #--------------------------------------------------------------------------
  # * Set Selection
  #--------------------------------------------------------------------------
  def selection=(selection)
    @selection = selection if !selection.nil?
  end
  #--------------------------------------------------------------------------
  # * Get Number of Items
  #--------------------------------------------------------------------------
  def item_max
    @data ? @data.size : 0
  end
  #--------------------------------------------------------------------------
  # * Create Item List
  #--------------------------------------------------------------------------
  def make_item_list
    if $data_xrefs.nil? || $data_xrefs[@mode].nil? || $data_xrefs[@mode][@selection].nil?
      @data = [nil]
    else
      @data = $data_xrefs[@mode][@selection]
    end
  end
  #--------------------------------------------------------------------------
  # * Draw Item
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[index]
    rect = item_rect_for_text(index)
    if item.nil?
      draw_text(rect, 'No References Found', 1)
    else
      y = rect.y
      draw_text(4, y, 190, line_height, item.source)
      draw_text(198, y, 160, line_height, item.location) if !item.location.nil?
      if item.page && item.line
        draw_text(362, y, 70, line_height, sprintf('%3d:%d', item.page, item.line)) 
      elsif item.page
        draw_text(362, y, 70, line_height, sprintf('%3d:', item.page))
      elsif item.line
        draw_text(362, y, 70, line_height, sprintf('   :%d', item.line))
      end
      draw_text(436, y, 200, line_height, item.reference)
    end
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    make_item_list
    create_contents
    self.contents.font.size = 20
    draw_all_items
  end
end

class Scene_XRef < Scene_Base
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  def start
    super
    create_command_window
    create_selection_window
    create_help_window
    create_result_window
  end
  #--------------------------------------------------------------------------
  # * Create Command Window
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_XRefCommand.new
    @command_window.set_handler(:switches,      method(:command_choice))
    @command_window.set_handler(:variables,     method(:command_choice))
    @command_window.set_handler(:common_events, method(:command_choice))
    @command_window.set_handler(:actors,        method(:command_choice))
    @command_window.set_handler(:classes,       method(:command_choice))
    @command_window.set_handler(:skills,        method(:command_choice))
    @command_window.set_handler(:items,         method(:command_choice))
    @command_window.set_handler(:weapons,       method(:command_choice))
    @command_window.set_handler(:armors,        method(:command_choice))
    @command_window.set_handler(:enemies,       method(:command_choice))
    @command_window.set_handler(:troops,        method(:command_choice))
    @command_window.set_handler(:states,        method(:command_choice))
    @command_window.set_handler(:animations,    method(:command_choice))
    @command_window.set_handler(:cancel,        method(:return_scene))
  end
  #--------------------------------------------------------------------------
  # * Create Selection Window
  #--------------------------------------------------------------------------
  def create_selection_window
    wx = @command_window.x + @command_window.width
    ww = Graphics.width - wx
    @selection_window = Window_XRefSelection.new(wx, 0, ww, Graphics.height)
    @selection_window.set_handler(:ok,     method(:on_selection_ok))
    @selection_window.set_handler(:cancel, method(:on_selection_cancel))
    @command_window.selection_window = @selection_window
    @selection_window.command_window = @command_window
  end
  #--------------------------------------------------------------------------
  # * Create Help Window
  #--------------------------------------------------------------------------
  def create_help_window
    @help_window = Window_Help.new(1)
    @help_window.create_contents
    @help_window.visible = false
  end
  #--------------------------------------------------------------------------
  # * Create Result Window
  #--------------------------------------------------------------------------
  def create_result_window
    wy = @help_window.y + @help_window.height
    wh = Graphics.height - wy
    @result_window = Window_XRefResults.new(0, wy, Graphics.width, wh)
    @result_window.viewport = @viewport
    @result_window.set_handler(:cancel, method(:on_result_cancel))
    @result_window.hide
  end
  #--------------------------------------------------------------------------
  # * On Choice
  #--------------------------------------------------------------------------
  def command_choice
    @selection_window.refresh
    @selection_window.activate
    @selection_window.select(0)
  end
  #--------------------------------------------------------------------------
  # * Selection [OK]
  #--------------------------------------------------------------------------
  def on_selection_ok
    @result_window.mode = @command_window.current_symbol
    @last_selection = @selection_window.index
    @result_window.selection = @selection_window.item
    @result_window.refresh
    @help_window.show
    @help_window.set_text(@selection_window.help_text)
    @selection_window.hide.unselect
    @command_window.hide
    @result_window.show.activate
  end
  #--------------------------------------------------------------------------
  # * Selection [Cancel]
  #--------------------------------------------------------------------------
  def on_selection_cancel
    @selection_window.unselect
    @command_window.activate
  end
  #--------------------------------------------------------------------------
  # * Result [Cancel]
  #--------------------------------------------------------------------------
  def on_result_cancel
    @result_window.hide.unselect
    @help_window.hide
    @selection_window.show.activate
    @selection_window.select(@last_selection)
    @command_window.show
  end
end