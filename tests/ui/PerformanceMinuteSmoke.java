import java.nio.file.Files;
import java.nio.file.Path;
import org.luaj.vm2.lib.jse.JsePlatform;

/** Runs the actual sampling helper with simulation time and brains stubbed. */
public class PerformanceMinuteSmoke {
    public static void main(String[] args) throws Exception {
        var source = Files.readString(Path.of(args[0], "lua/sim/score.lua"));
        var capture = source.substring(source.indexOf("local performanceMinute = 0"),
                source.indexOf("local function PerformanceHistoryThread"));
        capture = capture.replace("in ArmyBrains do", "in pairs(ArmyBrains) do");
        var setup = "local t=0; function GetGameTimeSeconds() return t end\n"
                + "local dead=false; local ArmyBrains={{IsDefeated=function() return dead end}}\n"
                + "local ArmyScore={{performance={mass_income={}},resources={massin={rate=2}}}}\n";
        var assertions = "\nt=59; CapturePerformanceMinute(); assert(#ArmyScore[1].performance.mass_income==0)\n"
                + "t=60; CapturePerformanceMinute(); assert(ArmyScore[1].performance.mass_income[1]==20)\n"
                + "CapturePerformanceMinute(); assert(#ArmyScore[1].performance.mass_income==1)\n"
                + "dead=true; t=120; CapturePerformanceMinute(); assert(ArmyScore[1].performance.mass_income[2]==0)\n"
                + "assert(ArmyScore[1].performance.mass_income[1]==20)\n";
        JsePlatform.standardGlobals().load(setup + capture + assertions).call();
        System.out.println("Minute boundaries, units, duplicate capture and defeat: passed");
    }
}
