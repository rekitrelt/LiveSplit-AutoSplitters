state("Apotheon") { }

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
    vars.Helper.GameName = "Apotheon";

    vars.Helper.Settings.CreateFromXml("Components/Apotheon.Settings.xml");
    vars.Helper.AlertLoadless();

    vars.CompletedSplits = new HashSet<string>();
}

onStart
{
    vars.CompletedSplits.Clear();
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
}

split
{
    if (current.CompletedObjectives == null || old.CompletedObjectives == null)
        return false;

    int[] oldObjectives = (int[])old.CompletedObjectives;
    int[] CompletedObjectives = (int[])current.CompletedObjectives;

    foreach (var obj in CompletedObjectives)
    {
        if (!Array.Exists(oldObjectives, o => o == obj))
        {
            string splitKey = obj.ToString();

            if (settings[splitKey])
            {
                return vars.CompletedSplits.Add(splitKey);
            }
        }
    }

    return false;
}

isLoading
{
    return current.IsLoading
        || current.ConsoleVisible
        || current.IsIngamePause
        || current.OtherScreenHasFocus
        || current.FadeTransition < 1.0025f;
}

start
{
    return (current.LevelName == "village-act1" && current.GameTime > 1 && current.GameTime < 4);
}