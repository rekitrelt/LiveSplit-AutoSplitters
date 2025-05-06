state("Apotheon") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Apotheon";

    vars.Helper.Settings.CreateFromXml("Components/Apotheon.Settings.xml");
    vars.Helper.AlertLoadless();

    vars.CompletedSplits = new HashSet<string>();
    vars.oldmap = "";
    vars.symbolcount = 0;
    vars.SymbolsScanned = new HashSet<string>();
    vars.newSymbols = new HashSet<string>();
}

onStart
{
    vars.CompletedSplits.Clear();
    vars.oldmap = "";
}

init
{
    vars.GameInstance = IntPtr.Zero;
}

update
{
    if (vars.GameInstance == IntPtr.Zero)
    {
        var gameInstance = vars.Helper.ScanPagesRel(false, 10, "8B CE FF 15 ???????? 8D 15");
        if (gameInstance == IntPtr.Zero)
        {
            return false;
        }

        // "Player" = gameInstance, 0x2f4
        var pPlayer = 0x2f4;
        vars.Helper["AllowPickup"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0xc);
        vars.Helper["PosX"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0xf0);
        vars.Helper["PosY"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0xf4);
        vars.Helper["StartPosX"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0xf8);
        vars.Helper["StartPosY"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0xfc);
        //vars.Helper["OrigPos"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x13c);
        vars.Helper["NextShieldCharge"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0x214);
        vars.Helper["NextStaminaCharge"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0x224);
        vars.Helper["ItemAnimation"] = vars.Helper.MakeString(128, ReadStringType.UTF16, gameInstance, pPlayer, 0x5a8, 0x8);
        vars.Helper["Classname"] = vars.Helper.MakeString(128, ReadStringType.UTF16, gameInstance, pPlayer, 0x53c, 0x8);

        // "DialogChar" = gameInstance, pPlayer, 0x5ac
        vars.Helper["DialogCharClassname"] = vars.Helper.MakeString(128, ReadStringType.UTF16, gameInstance, pPlayer, 0x5ac, 0x53c, 0x8);

        vars.Helper["PotionSoundName"] = vars.Helper.MakeString(128, ReadStringType.UTF16, gameInstance, pPlayer, 0x5bc, 0x4, 0x8); // is the 0x4 needed?
        
        // "Class" = gameInstance, pPlayer, 0x664
        var pClass = 0x664;
        vars.Helper["BaseHands"] = vars.Helper.MakeString(128, ReadStringType.UTF16, gameInstance, pPlayer, pClass, 0x54, 0x8);
        vars.Helper["HP"] = vars.Helper.Make<float>(gameInstance, pPlayer, pClass, 0x170);
        vars.Helper["StaminaRecharge"] = vars.Helper.Make<float>(gameInstance, pPlayer, pClass, 0x174);
        vars.Helper["StaminaRechargeTimeAfterAttack"] = vars.Helper.Make<bool>(gameInstance, pPlayer, pClass, 0x178);
        vars.Helper["StaminaAttackUse"] = vars.Helper.Make<float>(gameInstance, pPlayer, pClass, 0x17c);
        // vars.Helper["MoveMult"] = vars.Helper.Make<bool>(gameInstance, pPlayer, pClass, 0x1ac); was 0 even after drinking a potion
        // vars.Helper["BaseMoveForce"] = vars.Helper.Make<bool>(gameInstance, pPlayer, pClass, 0x1b0); didnt change even with potion
        vars.Helper["ArmourUpgradeBuy"] = vars.Helper.Make<bool>(gameInstance, pPlayer, pClass, 0x286);
        vars.Helper["WeaponUpgradeBuy"] = vars.Helper.Make<bool>(gameInstance, pPlayer, pClass, 0x287);
        vars.Helper["NoWallCollide"] = vars.Helper.Make<bool>(gameInstance, pPlayer, pClass, 0x291);
        vars.Helper["NoJumping"] = vars.Helper.Make<bool>(gameInstance, pPlayer, pClass, 0x296);
        vars.Helper["GodDeath"] = vars.Helper.Make<bool>(gameInstance, pPlayer, pClass, 0x2a0);
        vars.Helper["NoDamage"] = vars.Helper.Make<bool>(gameInstance, pPlayer, pClass, 0x2a3);
        vars.Helper["IgnoreAllCollisions"] = vars.Helper.Make<bool>(gameInstance, pPlayer, pClass, 0x2a4);


        // "MainInventory" = gameInstance, pPlayer, 0x6d0 
        vars.Helper["ItemClassname"] = vars.Helper.MakeString(128, ReadStringType.UTF16, gameInstance, pPlayer, 0x6d0, 0x24, 0x234, 0x8); // gameInstance -> gameInstance, pPlayer -> MainInventory -> CurrentItem -> Classname
        // "OffhandInventory" = gameInstance, pPlayer, 0x6d4
        // "ArmourInventory" = gameInstance, pPlayer, 0x6d8
        // "SymbolInventory" = gameInstance, pPlayer, 0x6dc
        vars.Helper["SymbolAmount"] = vars.Helper.Make<int>(gameInstance, pPlayer, 0x6dc, 0x14, 0xc); // gameInstance -> gameInstance, pPlayer -> SymbolInventory -> InventorySlots -> Size/Count

        vars.Helper["Coins"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0x6f0);
        vars.Helper["Health"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0x6f4);
        vars.Helper["MaxHealth"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0x724);
        vars.Helper["Armour"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0x6f8);
        vars.Helper["MaxArmour"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0x728);
        vars.Helper["Stamina"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0x714);
        vars.Helper["LookRotation"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0x73c);
        vars.Helper["CurrentMainStrength"] = vars.Helper.Make<float>(gameInstance, pPlayer, 0x748);

        vars.Helper["ArtemisBow"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7e5);
        vars.Helper["ApolloLyre"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7e6);
        vars.Helper["DionysusCup"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7e7);
        vars.Helper["AthenaSymbol"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7e8);
        vars.Helper["PosiedonSymbol"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7e9);
        vars.Helper["AresHelmet"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7ea);
        vars.Helper["HeraPlume"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7eb);

        vars.Helper["InDialog"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7f3);
        vars.Helper["HasShield"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7fc);
        vars.Helper["AllowShielding"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7fd);
        vars.Helper["FindCharacterEnemy"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x7fe);
        vars.Helper["Rolling"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x828);
        vars.Helper["LastOnground"] = vars.Helper.Make<bool>(gameInstance, pPlayer, 0x82b); // yes its a bool

        // "Body" = gameInstance, 0x48
        vars.Helper["TotalForce"] = vars.Helper.Make<float>(gameInstance, 0x48, 0x24);
       // vars.Helper["Force"] = vars.Helper.Make<Vector2>(gameInstance, 0x48, 0x60);

        vars.Helper["OtherScreenHasFocus"] = vars.Helper.Make<bool>(gameInstance, 0x30);
        vars.Helper["IsIngamePause"] = vars.Helper.Make<bool>(gameInstance, 0x3A);
        vars.Helper["GameTime"] = vars.Helper.Make<double>(gameInstance, 0x80);
        vars.Helper["LevelName"] = vars.Helper.MakeString(128, ReadStringType.UTF16, gameInstance, 0x218, 0x8);
        vars.Helper["FadeTransition"] = vars.Helper.Make<float>(gameInstance, 0x3C4);
        vars.Helper["IsLoading"] = vars.Helper.Make<bool>(gameInstance, 0x415);
        vars.Helper["ConsoleVisible"] = vars.Helper.Make<bool>(gameInstance, 0x20, 0x134, 0xa2);

        vars.GameInstance = gameInstance;

        print(vars.Helper.Read<IntPtr>(gameInstance).ToString("X"));
    }
    int count = vars.Helper.Read<int>(vars.GameInstance, 0x1BC, 0x0C);
    current.CompletedObjectives = vars.Helper.ReadSpan<int>(count, vars.GameInstance, 0x1BC, 0x04, 0x08);

    vars.Helper.Update();
    vars.Helper.MapPointers();

    if (vars.Helper.Read<IntPtr>(vars.GameInstance) == IntPtr.Zero)
    {
        vars.GameInstance = IntPtr.Zero;
        return false;
    }
    if (old.LevelName != current.LevelName) {
        vars.oldmap = old.LevelName;
    }
//======================================================================================================================//
    if (vars.SymbolsScanned == null)
        vars.SymbolsScanned = new HashSet<string>();

    var newSymbols = new List<string>();

    var symbolInvPtr = vars.Helper.Read<IntPtr>(vars.GameInstance, 0x2f4, 0x6dc); // SymbolInventory
    if (symbolInvPtr != IntPtr.Zero)
    {
        for (int i = 0; i < 3; i++)
        {
            int groupCount = vars.Helper.Read<int>(vars.GameInstance, 0x2f4, 0x6dc, 0x1c, 0x8, 0x8 + i * 0x10, 0x4, 0x4);
            //print("Entries[{"+i+"}] groupCount = {"+groupCount+"}");
            if (groupCount > 0) {
                for (int j = 0; j < groupCount; j++)
                {
                    var groupPtr = vars.Helper.Read<IntPtr>(vars.GameInstance, 0x2f4, 0x6dc, 0x1c, 0x8, 0x8 + i * 0x10, 0x4, 0x8 + j * 4, 0x14, 0x4); // ItemGroup*
                    if (groupPtr == IntPtr.Zero) continue;

                    int itemCount = vars.Helper.Read<int>(groupPtr, 0x4);
                    //print("  Group " + j +" has " + itemCount + " items");

                    for (int k = 0; k < itemCount; k++)
                    {
                        string classfile = vars.Helper.ReadString(128, ReadStringType.UTF16, vars.GameInstance, 0x2f4, 0x6dc, 0x1c, 0x8, 0x8 + i * 0x10, 0x4, 0x8 + j * 4, 0x14, 0x4, 0x8 + k * 4, 0x10, 0xA4, 0x08); // ItemGroup*
                        if (classfile != "" && classfile != null && classfile.StartsWith("Symbols\\") && !vars.SymbolsScanned.Contains(classfile)) {
                            //print("classfilePtr: " + groupPtr.ToString("X"));
                            //print("classfile: " + classfile);
                            newSymbols.Add(classfile.Substring(8));
                        }
                    }
                }
            }
        }
        vars.NewSymbolFinds = newSymbols;
        foreach (string s in newSymbols) {
            vars.SymbolsScanned.Add(s);
        }
    }
}

split
{
    if (current.CompletedObjectives == null || old.CompletedObjectives == null)
        return false;

    int[] oldObjectives = (int[])old.CompletedObjectives;
    int[] CompletedObjectives = (int[])current.CompletedObjectives;

    if (vars.NewSymbolFinds != null)
    {
        foreach (string symbol in vars.NewSymbolFinds)
        {
            if (settings[symbol]) {
                if (vars.CompletedSplits.Add(symbol))
                {
                    print("Split for symbol: " + symbol);
                    return true;
                }
            }
        }
    }

    foreach (var obj in CompletedObjectives)
    {
        if (!Array.Exists(oldObjectives, o => o == obj))
        {
            string splitKey = obj.ToString();
            if (splitKey == "8" || settings[splitKey])
            {
                bool IsNewAddition = vars.CompletedSplits.Add(splitKey);
                if (IsNewAddition) {
                    print("objective split " + splitKey);
                    return true;
                }
            }
        }
    }

    /*
    string SymbolSplitKey = "Symbol " + current.SymbolAmount;
    if (current.SymbolAmount != 0 && settings[SymbolSplitKey]) {
        if (vars.CompletedSplits.Add(SymbolSplitKey)) {
            print("objective split " + SymbolSplitKey);
            return true;
        }
    }
    */
    
    if (settings["-8"] && vars.oldmap == "village-act1" && current.LevelName == "Agora-gate") {
        if (vars.CompletedSplits.Add("-8")) {
            print("first burn");
            return true;
        }
    }
    if (settings["-9"] && vars.oldmap == "Agora-market" && current.LevelName == "Agora") {
        if (vars.CompletedSplits.Add("-9")) {
            print("bought all items");
            return true;
        }
    }

    return false;
}

isLoading
{
    return current.IsLoading
        || current.GodDeath
        || current.InDialog
        || current.ConsoleVisible
        || current.IsIngamePause
        || current.OtherScreenHasFocus
        || current.FadeTransition < 1.0025f;
}

start
{
    return (current.GameTime > 1 && current.GameTime < 4);
}
