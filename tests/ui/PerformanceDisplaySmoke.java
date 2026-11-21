import java.nio.file.Files;
import java.nio.file.Path;
import org.luaj.vm2.lib.jse.JsePlatform;

/** Exercise the real Lua selector with ordinary, M&B, old and zero-score peers. */
public class PerformanceDisplaySmoke {
    public static void main(String[] args) throws Exception {
        var root=Path.of(args[0]);
        var source=Files.readString(root.resolve("lua/ui/lobby/performance.lua"));
        var check="""
            local p={Performance=12.5,PerformanceGames=10,PerformanceMnb=-1.29,PerformanceMnbGames=9}
            local value,games,name=Select(p,{},'mnb-v28,mnb-v29')
            assert(value==12.5 and games==10 and name=='EXP')
            value,games,name=Select(p,{['mnb-v29']=true},'mnb-v28,mnb-v29')
            assert(value==-1.29 and games==9 and name=='M&B EXP')
            value=Select(p,{['looks-like-mnb']=true},'mnb-v28,mnb-v29');assert(value==12.5)
            value=Select(p,{['mnb-v29']=false},'mnb-v28,mnb-v29');assert(value==12.5)
            value=Select({Performance=12.5},{['mnb-v29']=true},'mnb-v29');assert(value==nil)
            value,games=Select({Performance=12.5,PerformanceMnb=0,PerformanceMnbGames=2},{['mnb-v29']=true},'mnb-v29')
            assert(value==0 and games==2)
            value=Select(p,{},'mnb-v29');assert(value==12.5 and p.PerformanceMnb==-1.29)
            """;
        JsePlatform.standardGlobals().load(source+"\n"+check).call();
        System.out.println("Lua EXP selection: standard, M&B, switching back, unknown UID, missing history and zero: passed");
    }
}
