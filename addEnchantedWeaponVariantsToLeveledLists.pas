unit addEnchantedWeaponVariantsToLeveledLists;

interface
implementation
uses xEditAPI, Classes, SysUtils, StrUtils, Windows;

// Global variable declarations
var
  pluginsToCheck: TStringList;
  leveledListsToCheck: TList;
  leveledListEditorID, outputFileName, outputPluginFilePath, outputPluginFileName, pluginFileName, pluginFilePath, currentPluginFileName: string;
  outputFile, outputPluginFile, leveledListGroup, pluginFile: IInterface;
  added_masters, debug_mode, pluginLoaded: boolean;
  i, k, n, j: integer;

  
// Called in logic when debug_mode is enabled
procedure LogDebug(msg: string);
begin
  if debug_mode then
    AddMessage(msg);
end;


// xEdit Base Script function. Called when the script starts.
function Initialize: integer;

var
  leveledListRecord: IInterface;

begin
  // Initialize the pluginsToCheck list and add default plugins
  // Add a new `pluginsToCheck.Add` statement to add new plugins
  // to search for leveled lists in. If a plugin is not found, it
  // will simply be skipped.
  pluginsToCheck := TStringList.Create;
  pluginsToCheck.Add('Skyrim.esm');
  pluginsToCheck.Add('Dawnguard.esm');
  pluginsToCheck.Add('Hearthfires.esm');
  pluginsToCheck.Add('Dragonborn.esm');
  pluginsToCheck.Add('Thaumaturgy.esp');
  pluginsToCheck.Add('Serenity.esp');

  // Enables extra logging during process. You have to change this to true here
  debug_mode := false;

  // Prompt for the Leveled List EditorID fuzzy search parameter
  leveledListEditorID := InputBox('Enter Leveled List EditorID Search Parameter', 'Specify the fuzzy EditorID search parameter. Prefixes such as "SublistEnch", etc apply here:', '');
  if leveledListEditorID = '' then
    Exit;

  // Prompt for the output plugin filename
  outputFileName := InputBox('Output Plugin', 'Specify the output plugin, including the file extension. This ccn exist already. If it does, you will see a message popup.:', '');
  if outputFileName = '' then
    Exit;

  //// Create the output plugin if possible. If not, we assume it already exists
  //// and will attempt to find the plugin by name and assign as output plugin.

  // Create the output plugin and ensure it was created
  try
    outputFile := AddNewFileName(outputFileName);
  except
    AddMessage('Output plugin appears to exist already, using existing plugin');
  end;

  // If the file exists, find the existing output plugin
  if not Assigned(outputFile) then begin

      // Iterate current plugins
      for i := 0 to FileCount - 1 do begin
        outputPluginFile := FileByIndex(i);
        outputPluginFilePath := GetFileName(outputPluginFile);
        outputPluginFileName := ExtractFileName(outputPluginFilePath);

        // Find a match for the input filename
        if SameText(outputFileName, outputPluginFileName) then begin
          outputFile := outputPluginFile;
          outputFileName := outputPluginFileName;
          Break;
        end;

      end;
  end;

  // We should never reach this point
  if not Assigned(outputFile) then begin
    AddMessage('Unable to find or create output plugin, something has gone very wrong');
    Exit;
  end;

  // Add the LVLI GRUP to the newly created output plugin
  Add(outputFile, 'LVLI', True);

  //// Index all LVLIs in checking plugins, and add all with fuzzy search parameter
  //// to a list for iteration in the Process function.
  leveledListsToCheck := TList.Create;

  // Iterate through all specified plugins in pluginsToCheck
  for k := 0 to pluginsToCheck.Count - 1 do begin
    pluginFileName := pluginsToCheck[k];
    pluginLoaded := False;

    // Find the plugin by name
    for n := 0 to FileCount - 1 do begin
      pluginFile := FileByIndex(n);
      pluginFilePath := GetFileName(pluginFile);
      currentPluginFileName := ExtractFileName(pluginFilePath);

      if SameText(currentPluginFileName, pluginFileName) then begin
        pluginLoaded := True;
        Break;
      end;
    end;

    if not pluginLoaded then begin
      AddMessage('Plugin ' + pluginFileName + ' not found or not loaded.');
      Continue;
    end;

    // Find the Leveled List group in the current plugin
    leveledListGroup := GroupBySignature(pluginFile, 'LVLI');
    if not Assigned(leveledListGroup) then begin
      AddMessage('No LVLI GRUP found in plugin: ' + pluginFileName);
      Continue;
    end;

    // Iterate through all leveled lists to find lists containing the input EditorID fuzzy search parameter
    for j := 0 to ElementCount(leveledListGroup) - 1 do begin
      leveledListRecord := ElementByIndex(leveledListGroup, j);

      // Check if the leveled list's EditorID contains the input EditorID
      if Pos(UpperCase(leveledListEditorID), UpperCase(EditorID(leveledListRecord))) > 0 then begin
        leveledListsToCheck.Add(leveledListRecord);
      end;
    end
  end;

  // Initialize variable for determining if masters added
  added_masters := false;

end;


// xEdit Base Script function. Called on every selected record
function Process(e: IInterface): integer;
var
  weaponRecord, enchantment, newLeveledListRecord, entry, weapon_keywords, iteratingLeveledList: IInterface;
  y, i, z, o, level, currentFlags: integer;
  enchantmentEditorID, tier, weapon_type, CurrentKeyword, enchantment_string, iteratingLeveledListEI: string;
  found: boolean;
  masterList: TStringList;

begin
  found := False;

  // Ensure the record being processed is a weapon
  if Signature(e) = 'WEAP' then begin
    weaponRecord := e;

    AddMessage('-------------------------------------------------------------');
    AddMessage('Processing weapon record: ' + EditorID(weaponRecord));

    // Derive the enchantment attached to the currently iterated weapon
    enchantment := LinksTo(ElementByPath(weaponRecord, 'EITM'));
    // Craft a string of the Enchantment's display name with whitespace stripped
    enchantment_string := StringReplace(DisplayName(enchantment), ' ', '',[rfReplaceAll]);

    // If the magic is effect is FireDamange, FrostDamage, ShockDamage,
    // or PoisonDamage, remove the "Damage" from string
    if SameText(enchantment_string, 'FireDamage') then begin
      enchantment_string := 'Fire';
    end else if SameText(enchantment_string, 'FrostDamage') then begin
      enchantment_string := 'Frost';
    end else if SameText(enchantment_string, 'ShockDamage') then begin
      enchantment_string := 'Shock';
    end else if SameText(enchantment_string, 'PoisonDamage') then begin
      enchantment_string := 'Poison';
    end;

    // If the magic effect is DamageStamina or DamageMagicka,
    // remove the "Damage" from string.
    if SameText(enchantment_string, 'DamageStamina') then begin
      enchantment_string := 'Stamina';
    end;
    if SameText(enchantment_string, 'DamageMagicka') then begin
      enchantment_string := 'Magicka';
    end;

    // If the magict effect is TurnUndead, remove the "Undead"
    // from the string.
    if SameText(enchantment_string, 'TurnUndead') then
      enchantment_string := 'Turn';

    // If the magict effect is SunDamage, remove the "Damage"
    // from the string.
    if SameText(enchantment_string, 'SunDamage') then
      enchantment_string := 'Sun';

    // If the magict effect is SilentMoonsEnchant, change
    // it to LunarDamage
    if SameText(enchantment_string, 'SilentMoonsEnchant') then
      enchantment_string := 'LunarDamage';

    // Derive weapon type and tier from weapon keywords
    weapon_keywords := ElementByPath(weaponRecord, 'KWDA');
    tier := '';
    weapon_type := '';
    for o := ElementCount(weapon_keywords) - 1 downTo 0 do
    begin
        CurrentKeyword := EditorId(WinningOverride(LinksTo(ElementByIndex(weapon_keywords, o))));
        // Replace DLC2WeaponMaterial prefix with WeapMaterial in the keyword if it exists
        if pos('DLC2WeaponMaterial', CurrentKeyword) > 0 then
          CurrentKeyword := StringReplace(CurrentKeyword, 'DLC2Weapon', 'Weap', [rfReplaceAll]);

        // Remove DLC1 prefix in the keyword if it exists
        if pos('DLC1Weap', CurrentKeyword) > 0 then
          CurrentKeyword := StringReplace(CurrentKeyword, 'DLC1', '', [rfReplaceAll]);

        // Strip WeapType to only leave weapon type (i.e Greatsword) and assign to weapon_type
        if pos('WeapType', CurrentKeyword) > 0 then
        begin
          weapon_type := StringReplace(CurrentKeyword, 'WeapType', '', [rfReplaceAll]);
        end;

        // Strip WeapMaterial to only leave weapon material (i.e Orcish) and assign to tier
        if pos('WeapMaterial', CurrentKeyword) > 0 then
        begin
          tier := StringReplace(CurrentKeyword, 'WeapMaterial', '', [rfReplaceAll]);
        end;
    end;

    // Convert Wood tier weapons to Hunting or Iron, depending on whether
    // the weapon type is a bow or not.
    if SameText('Bow', weapon_type) then begin
      if SameText('Wood', tier) then
        tier := 'Hunting'
    end;

    if not SameText('Bow', weapon_type) then begin
      if SameText('Wood', tier) then
        tier := 'Iron'
    end;

    // Convert Steel tier weapons to Imperial, if the weapon type
    // is a Bow
    if SameText('Bow', weapon_type) then begin
      if SameText('Steel', tier) then
        tier := 'Imperial'
    end;

    // Convert new weapon types to the list they would be placed in
    if SameText('Pike', weapon_type) then
      weapon_type := 'Battleaxe';
    if SameText('Halberd', weapon_type) then
      weapon_type := 'Battleaxe';
    if SameText('Scythe', weapon_type) then
      weapon_type := 'Battleaxe';
    if SameText('QtrStaff', weapon_type) then
      weapon_type := 'Battleaxe';
    if SameText('Quarterstaff', weapon_type) then
      weapon_type := 'Battleaxe';
    if SameText('Rapier', weapon_type) then
      weapon_type := 'Sword';
    if SameText('Katana', weapon_type) then
      weapon_type := 'Sword';
    if SameText('CurvedSword', weapon_type) then
      weapon_type := 'Sword';
    if SameText('Claw', weapon_type) then
      weapon_type := 'Dagger';

    LogDebug(enchantment_string);
    LogDebug(tier);
    LogDebug(weapon_type);

    // Iterate over all leveled lists verified to contain the EditorID
    // fuzzy search parameter
    for y := 0 to leveledListsToCheck.Count -1 do begin

      // Get current iterating leveled list
      iteratingLeveledList := ObjectToElement(leveledListsToCheck[y]);
      iteratingLeveledListEI := EditorID(iteratingLeveledList);

      // If the effect is a XDamage, and the current leveled list
      // is a "WeaknessToX" leveled list, go to the next list
      if SameText(enchantment_string, 'Fire') then begin
        if Pos('Weakness', iteratingLeveledListEI) > 0 then
          Continue;
      end else if SameText(enchantment_string, 'Frost') then begin
        if Pos('Weakness', iteratingLeveledListEI) > 0 then
          Continue;
      end else if SameText(enchantment_string, 'Shock') then begin
        if Pos('Weakness', iteratingLeveledListEI) > 0 then
          Continue;
      end else if SameText(enchantment_string, 'Poison') then begin
        if Pos('Weakness', iteratingLeveledListEI) > 0 then
          Continue;
      end;

      // If the current leveled list is an "Absorb" list, and the current weapon
      // has a "Damage" enchantment, go to the next list.
      if SameText(enchantment_string, 'Stamina') then begin
        if Pos('Absorb', iteratingLeveledListEI) > 0 then
          Continue;
      end;
      if SameText(enchantment_string, 'Magicka') then begin
        if Pos('Absorb', iteratingLeveledListEI) > 0 then
          Continue;
      end;

      // Check that found LVLI EditorID contains enchantment effect name with whitespace stripped
      if Pos(UpperCase(enchantment_string), UpperCase(iteratingLeveledListEI)) > 0 then begin
        LogDebug('LVLI EditorID contains enchantment_string');

        // Check that found LVLI EditorID contains the derived tier
        if Pos(UpperCase(tier), UpperCase(iteratingLeveledListEI)) > 0 then begin
          LogDebug('LVLI EditorID contains tier');

          // If the current leveled list is a "Greatsword" list, and the current
          // weapon type is a "Sword", go to the next list.
          if SameText(weapon_type, 'Sword') then begin
            if Pos('Greatsword', iteratingLeveledListEI) > 0 then
              Continue;
          end;

          // Check that found LVLI EditorID contains the derived weapon type
          if Pos(UpperCase(weapon_type), UpperCase(iteratingLeveledListEI)) > 0 then begin
            LogDebug('LVLI EditorID contains weapon type');

            // A full match has been found
            AddMessage('Found a matching leveled list: ' + iteratingLeveledListEI);
            found := True;

            // Adding necessary masters to the output plugin
            masterList := TStringList.Create;
            try
              if not added_masters then begin
                // Get master files for the plugin the weapon is from.
                // This only needs to be done on the first iteration as
                // this script generally only iterates over weapons from
                // one plugin, with the enchanted variants.
                AddMessage('Adding required masters to the output plugin. ' +
                'This may take some time and freeze up xEdit, it only occurs ' +
                'on the first weapon record iteration.');

                ReportRequiredMasters(GetFile(e), masterList, true, True);
                added_masters := true
              end;

              // Get master files for the winning override of the leveled list.
              // This must be done on each iteration to ensure the latest LVLI
              // override can be used.
              ReportRequiredMasters(
                GetFile(
                  WinningOverride(iteratingLeveledList)
                ),
                 masterList, true, True);

              // Add all masters to the output plugin from masterList
              for z := 0 to masterList.Count - 1 do begin
                AddMasterIfMissing(outputFile, masterList[z]);
              end;

            finally
              masterList.Free;
            end;

            // Create an override for the LVLI entry in the output file
            newLeveledListRecord := wbCopyElementToFile(WinningOverride(iteratingLeveledList), outputFile, False, True);
            if not Assigned(newLeveledListRecord) then begin
              AddMessage('Failed to create override for leveled list: ' + iteratingLeveledListEI)
            end;

            // Determine the LVLO level to assign based on the weapon's tier
            // and enchantment effect. If you want to change the levels
            // equipment goes to, change the values in the relevant block
            // below. The first three values are what that tier generally
            // uses. We are still checking for the three MGEF levels that
            // are not normally used in each tier.
            if Assigned(enchantment) then begin

              // IRON
              if SameText(tier, 'Iron') then begin
                if Pos('01', EditorID(enchantment)) > 0 then
                  level := 1
                else if Pos('02', EditorID(enchantment)) > 0 then
                  level := 4
                else if Pos('03', EditorID(enchantment)) > 0 then
                  level := 6
                else if Pos('04', EditorID(enchantment)) > 0 then
                  level := 11
                else if Pos('05', EditorID(enchantment)) > 0 then
                  level := 25
                else if Pos('06', EditorID(enchantment)) > 0 then
                  level := 43
                else
                  level := 1;

              // STEEL
              end else if SameText(tier, 'Steel') then begin
                if Pos('01', EditorID(enchantment)) > 0 then
                  level := 4
                else if Pos('02', EditorID(enchantment)) > 0 then
                  level := 6
                else if Pos('03', EditorID(enchantment)) > 0 then
                  level := 8
                else if Pos('04', EditorID(enchantment)) > 0 then
                  level := 11
                else if Pos('05', EditorID(enchantment)) > 0 then
                  level := 25
                else if Pos('06', EditorID(enchantment)) > 0 then
                  level := 43
                else
                  level := 4;

              // DWARVEN
              end else if SameText(tier, 'Dwarven') then begin
                if Pos('02', EditorID(enchantment)) > 0 then
                  level := 7
                else if Pos('03', EditorID(enchantment)) > 0 then
                  level := 9
                else if Pos('04', EditorID(enchantment)) > 0 then
                  level := 11
                else if Pos('01', EditorID(enchantment)) > 0 then
                  level := 7
                else if Pos('05', EditorID(enchantment)) > 0 then
                  level := 25
                else if Pos('06', EditorID(enchantment)) > 0 then
                  level := 43
                else
                  level := 7;

              // ELVEN
              end else if SameText(tier, 'Elven') then begin
                if Pos('02', EditorID(enchantment)) > 0 then
                  level := 13
                else if Pos('03', EditorID(enchantment)) > 0 then
                  level := 15
                else if Pos('04', EditorID(enchantment)) > 0 then
                  level := 17
                else if Pos('01', EditorID(enchantment)) > 0 then
                  level := 13
                else if Pos('05', EditorID(enchantment)) > 0 then
                  level := 25
                else if Pos('06', EditorID(enchantment)) > 0 then
                  level := 43
                else
                  level := 13;

              // ORCISH AND NORDIC
              end else if SameText(tier, 'Orcish') or SameText(tier, 'Nordic') then begin
                if Pos('03', EditorID(enchantment)) > 0 then
                  level := 20
                else if Pos('04', EditorID(enchantment)) > 0 then
                  level := 22
                else if Pos('05', EditorID(enchantment)) > 0 then
                  level := 25
                else if Pos('01', EditorID(enchantment)) > 0 then
                  level := 20
                else if Pos('02', EditorID(enchantment)) > 0 then
                  level := 20
                else if Pos('06', EditorID(enchantment)) > 0 then
                  level := 43
                else
                  level := 20

              // GLASS
              end else if SameText(tier, 'Glass') then begin
                if Pos('03', EditorID(enchantment)) > 0 then
                  level := 28
                else if Pos('04', EditorID(enchantment)) > 0 then
                  level := 31
                else if Pos('05', EditorID(enchantment)) > 0 then
                  level := 34
                else if Pos('01', EditorID(enchantment)) > 0 then
                  level := 28
                else if Pos('02', EditorID(enchantment)) > 0 then
                  level := 28
                else if Pos('06', EditorID(enchantment)) > 0 then
                  level := 43
                else
                  level := 28

              // EBONY AND STALHRIM
              end else if SameText(tier, 'Ebony') or SameText(tier, 'Stalhrim') then begin
                if Pos('04', EditorID(enchantment)) > 0 then
                  level := 37
                else if Pos('05', EditorID(enchantment)) > 0 then
                  level := 40
                else if Pos('06', EditorID(enchantment)) > 0 then
                  level := 43
                else if Pos('01', EditorID(enchantment)) > 0 then
                  level := 37
                else if Pos('02', EditorID(enchantment)) > 0 then
                  level := 37
                else if Pos('03', EditorID(enchantment)) > 0 then
                  level := 37
                else
                  level := 37

              // DAEDRIC
              end else if SameText(tier, 'Daedric') then begin
                if Pos('04', EditorID(enchantment)) > 0 then
                  level := 47
                else if Pos('05', EditorID(enchantment)) > 0 then
                  level := 50
                else if Pos('06', EditorID(enchantment)) > 0 then
                  level := 53
                else if Pos('01', EditorID(enchantment)) > 0 then
                  level := 47
                else if Pos('02', EditorID(enchantment)) > 0 then
                  level := 47
                else if Pos('03', EditorID(enchantment)) > 0 then
                  level := 47
                else
                  level := 47;

              // EXTRA TIERS
              // These are less encompassing but there are still lists
              // here that we use

              // HUNTING
              end else if SameText(tier, 'Hunting') then begin
                if Pos('01', EditorID(enchantment)) > 0 then
                  level := 3
                else if Pos('02', EditorID(enchantment)) > 0 then
                  level := 5
                else if Pos('03', EditorID(enchantment)) > 0 then
                  level := 7
                else if Pos('04', EditorID(enchantment)) > 0 then
                  level := 11
                else if Pos('05', EditorID(enchantment)) > 0 then
                  level := 25
                else if Pos('06', EditorID(enchantment)) > 0 then
                  level := 43
                else
                  level := 3;

              // IMPERIAL
              end else if SameText(tier, 'Imperial') then begin
                if Pos('01', EditorID(enchantment)) > 0 then
                  level := 3
                else if Pos('02', EditorID(enchantment)) > 0 then
                  level := 4
                else if Pos('03', EditorID(enchantment)) > 0 then
                  level := 5
                else if Pos('04', EditorID(enchantment)) > 0 then
                  level := 11
                else if Pos('05', EditorID(enchantment)) > 0 then
                  level := 25
                else if Pos('06', EditorID(enchantment)) > 0 then
                  level := 43
                else
                  level := 3;
              end;

            end;

            // Adding proper flags to the LVLI
            // Without doing this. if you are level 43, you will get the highest tier enchantments for Ebony
            // in your roll, but if all the variants only applied to the lower two tiers, you would only get
            // the vanilla variant. Setting these flags ensures that you can still roll for the lower level
            // enchantment. The lower tier enchantment lists already have these flags set in vanilla.

            // Get the flags from the LVLI
            currentFlags := GetElementNativeValues(newLeveledListRecord, 'LVLF');

            // Set "Calculate from all levels <= player's level" AND
            // "Calculate for each item in count" on the LVLI flags.
            currentFlags := currentFlags or 1 or 2;

            // Apply the changed flags to the LVLI
            SetElementNativeValues(newLeveledListRecord, 'LVLF', currentFlags);

            // Create the new leveled list entry/LVLO and add it to the LVLI
            entry := ElementAssign(ElementByPath(newLeveledListRecord, 'Leveled List Entries'), HighInteger, nil, False);

            // Assign the weapon, set the count to 1, and apply the derived level to the created LVLO
            SetElementEditValues(entry, 'LVLO\Level', IntToStr(level));
            SetElementEditValues(entry, 'LVLO\Reference', Name(weaponRecord));
            SetElementEditValues(entry, 'LVLO\Count', '1');

            AddMessage('Added weapon ' + EditorID(weaponRecord) + ' to leveled list ' + EditorID(newLeveledListRecord) + ' at level ' + IntToStr(level));
          end;
        end;
      end;
    end;
  end;

  if not found then
    AddMessage('No matching leveled list found for:' + EditorID(weaponRecord));

  Result := 0;
end;

end.

