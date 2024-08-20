unit addEnchantedArmorVariantsToLeveledLists;

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
  debug_mode := true;

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
  armorRecord, enchantment, newLeveledListRecord, entry, armor_keywords, iteratingLeveledList: IInterface;
  y, i, z, o, currentFlags: integer;
  tier, armor_type, CurrentKeyword, enchantment_string, iteratingLeveledListEI: string;
  found: boolean;
  masterList: TStringList;

begin
  found := False;

  // Ensure the record being processed is an armor piece
  if Signature(e) = 'ARMO' then begin
    armorRecord := e;

    AddMessage('-------------------------------------------------------------');
    AddMessage('Processing armor record: ' + EditorID(armorRecord));

    // Derive the enchantment attached to the currently iterated armor piece
    enchantment := LinksTo(ElementByPath(armorRecord, 'EITM'));
    // Craft a string of the Enchantment's EditorID with underscores stripped
    enchantment_string := StringReplace(EditorID(enchantment), '_', '',[rfReplaceAll]);

    /// Based on the enchantment effect tier found on the armor piece's EditorID,
    /// change the enchantment_string to match to leveled list tier that the
    /// piece would be placed in.

    LogDebug(enchantment_string);

    // 01
    if (Pos('01A', enchantment_string) > 0) or (Pos('01', enchantment_string) > 0) then
      enchantment_string := '01';

    // 02
    if (Pos('01B', enchantment_string) > 0) or (Pos('02', enchantment_string) > 0) then
      enchantment_string := '02';

    // 03
    if (Pos('02B', enchantment_string) > 0) or (Pos('03', enchantment_string) > 0) then
      enchantment_string := '03';

    // 04
    if (Pos('03B', enchantment_string) > 0) or (Pos('04', enchantment_string) > 0) then
      enchantment_string := '04';

    // 05
    if (Pos('04A', enchantment_string) > 0) or (Pos('05', enchantment_string) > 0) then
      enchantment_string := '05';

    // 06
    if (Pos('04B', enchantment_string) > 0) or (Pos('06', enchantment_string) > 0) then
      enchantment_string := '06';

    // Derive armor type and tier from armor piece keywords
    armor_keywords := ElementByPath(armorRecord, 'KWDA');
    tier := '';
    armor_type := '';
    for o := ElementCount(armor_keywords) - 1 downTo 0 do
    begin
        CurrentKeyword := EditorId(WinningOverride(LinksTo(ElementByIndex(armor_keywords, o))));
        // Skip the keyword if it is ArmorHeavy or ArmorLight
        if (Pos('ArmorHeavy', CurrentKeyword) > 0) or (Pos('ArmorLight', CurrentKeyword) > 0) then
          Continue;

        // Skip the keyword if it contains Vendor
        if (Pos('Vendor', CurrentKeyword) > 0) then
          Continue;

        // Remove  DLC2 prefix in the keyword if it exists
        if pos('DLC2ArmorMaterial', CurrentKeyword) > 0 then
          CurrentKeyword := StringReplace(CurrentKeyword, 'DLC2', '', [rfReplaceAll]);

        // Remove DLC1 prefix in the keyword if it exists
        if pos('DLC1ArmorMaterial', CurrentKeyword) > 0 then
          CurrentKeyword := StringReplace(CurrentKeyword, 'DLC1', '', [rfReplaceAll]);

        // Strip ArmorMaterial to only leave weapon material (i.e Orcish) and assign to tier
        if pos('ArmorMaterial', CurrentKeyword) > 0 then
        begin
          tier := StringReplace(CurrentKeyword, 'ArmorMaterial', '', [rfReplaceAll]);
        end;

        // Strip Armor to only leave armor type (i.e Helmet) and assign to armor_type
        if pos('Armor', CurrentKeyword) > 0 then
        begin
          // Skip if keyword contains ArmorMaterial
          if pos('ArmorMaterial', CurrentKeyword) > 0 then
            Continue;

          armor_type := StringReplace(CurrentKeyword, 'Armor', '', [rfReplaceAll]);
        end;

    end;

    // Convert ImperialLight to Leather, Elven if a Shield
    if pos('ImperialLight', tier) > 0 then begin
      if pos('Shield', armor_type) > 0 then begin
        tier := 'Elven';
      end else
        tier := 'Leather';
    end;

    // Convert ImperialHeavy to Steel
    if pos('ImperialHeavy', tier) > 0 then
      tier := 'Steel';

    // If armor_type is Shield
    if pos('Shield', armor_type) > 0 then begin
      // Convert Scaled to Elven
      if pos('Scaled', tier) > 0 then
        tier := 'Elven';
    end;

    LogDebug(enchantment_string);
    LogDebug(tier);
    LogDebug(armor_type);

    // Iterate over all leveled lists verified to contain the EditorID
    // fuzzy search parameter
    for y := 0 to leveledListsToCheck.Count -1 do begin

      // Get current iterating leveled list
      iteratingLeveledList := ObjectToElement(leveledListsToCheck[y]);
      iteratingLeveledListEI := EditorID(iteratingLeveledList);

      // Check that found LVLI EditorID contains enchantment magnitude
      if Pos(UpperCase(enchantment_string), UpperCase(iteratingLeveledListEI)) > 0 then begin

        // Check that found LVLI EditorID contains the derived tier
        if Pos(UpperCase(tier), UpperCase(iteratingLeveledListEI)) > 0 then begin

          // Check that found LVLI EditorID contains the derived armor type
          if Pos(UpperCase(armor_type), UpperCase(iteratingLeveledListEI)) > 0 then begin

            // A full match has been found
            AddMessage('Found a matching leveled list: ' + iteratingLeveledListEI);
            found := True;

            // Adding necessary masters to the output plugin
            masterList := TStringList.Create;
            try
              if not added_masters then begin
                // Get master files for the plugin the armor is from.
                // This only needs to be done on the first iteration as
                // this script generally only iterates over armors from
                // one plugin, with the enchanted variants.
                AddMessage('Adding required masters to the output plugin. ' +
                'This may take some time and freeze up xEdit, it only occurs ' +
                'on the first armor record iteration.');

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

            // Assign the armor, set the count to 1, and set the level to 1
            // All enchanted armor leveled SublistEnch lists use 1 for the level
            SetElementEditValues(entry, 'LVLO\Level', IntToStr(1));
            SetElementEditValues(entry, 'LVLO\Reference', Name(armorRecord));
            SetElementEditValues(entry, 'LVLO\Count', '1');

            AddMessage('Added armor piece ' + EditorID(armorRecord) + ' to leveled list ' + EditorID(newLeveledListRecord) + ' at level ' + IntToStr(1));

            // We only want to add each piece to one leveled list, and using
            // mods such as Thaumaturgy can cause it's override to register as
            // a separate list.
            Break;
          end;
        end;
      end;
    end;
  end;

  if not found then
    AddMessage('No matching leveled list found for:' + EditorID(armorRecord));

  Result := 0;
end;

end.
