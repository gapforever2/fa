"""Run a private two-process FA match and capture its real JsonStats packet.

No lobby account, live service or installed game source is modified. A temporary
SIM overlay creates predictable income and ends the match after 125 game seconds.
Only child game processes started by this script are terminated on completion.
"""
import argparse
import ctypes
import json
import socket
import struct
import subprocess
import threading
import time
from pathlib import Path


def read_exact(connection, size):
    value = b""
    while len(value) < size:
        chunk = connection.recv(size - len(value))
        if not chunk:
            raise EOFError()
        value += chunk
    return value


def read_int(connection):
    return struct.unpack("<i", read_exact(connection, 4))[0]


def read_string(connection):
    size = read_int(connection)
    if not 0 <= size <= 4 * 1024 * 1024:
        raise ValueError("Invalid GPGNet string size")
    return read_exact(connection, size).decode("utf-8")


class Peer:
    def __init__(self, player_id, name):
        self.player_id, self.name = player_id, name
        self.listener = socket.socket()
        self.listener.bind(("127.0.0.1", 0))
        self.listener.listen(1)
        self.listener.settimeout(45)
        self.port = self.listener.getsockname()[1]
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as udp:
            udp.bind(("127.0.0.1", 0))
            self.udp_port = udp.getsockname()[1]
        self.messages = []
        self.error = None
        self.connection = None
        self.lock = threading.Lock()

    def send(self, command, *arguments):
        def string(value):
            encoded = value.encode("utf-8")
            return struct.pack("<i", len(encoded)) + encoded
        payload = string(command) + struct.pack("<i", len(arguments))
        for value in arguments:
            payload += b"\x00" + struct.pack("<i", value) if isinstance(value, int) else b"\x01" + string(value)
        with self.lock:
            self.connection.sendall(payload)

    def receive(self):
        try:
            self.connection, _ = self.listener.accept()
            self.connection.settimeout(300)
            while True:
                command = read_string(self.connection)
                count = read_int(self.connection)
                arguments = []
                for _ in range(count):
                    kind = read_exact(self.connection, 1)
                    arguments.append(read_int(self.connection) if kind == b"\x00" else read_string(self.connection))
                self.messages.append((command, arguments))
                if command == "GameState" and arguments == ["Idle"]:
                    self.send("CreateLobby", 1, self.udp_port, self.name, self.player_id, 1)
        except Exception as error:
            self.error = repr(error)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-bin", type=Path, default=Path("C:/ProgramData/GapForever/bin"))
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--run-root", type=Path, required=True)
    args = parser.parse_args()
    run = args.run_root.resolve()
    run.mkdir(parents=True, exist_ok=False)
    overlay = run / "overlay/lua/sim"
    overlay.mkdir(parents=True)
    score = (args.source / "lua/sim/score.lua").read_text(encoding="utf-8")
    # This instrumentation belongs exclusively to the isolated test mount.
    score += """
local PerformanceTestInit = init
function init()
    PerformanceTestInit()
    ForkThread(function()
        WaitSeconds(5)
        for index, brain in ArmyBrains do
            if brain.BrainType == 'Human' then
                local x, z = brain:GetArmyStartPos()
                local unit = CreateUnitHPR('ueb1101', index, x + 8,
                    GetTerrainHeight(x + 8, z + 8), z + 8, 0, 0, 0)
                unit:SetProductionPerSecondMass(index * 5)
                LOG('[EXP-TEST] economy fixture for army ', index)
            end
        end
        WaitSeconds(120)
        LOG('[EXP-TEST] deterministic defeat at ', GetGameTimeSeconds())
        ArmyBrains[2]:OnDefeat()
    end)
end
"""
    (overlay / "score.lua").write_text(score, encoding="utf-8")
    init = run / "init.lua"
    init.write_text(
        "InitFileDir = '" + args.game_bin.as_posix() + "'\n"
        "dofile(InitFileDir .. '/init.lua')\n"
        "table.insert(path, 1, {dir = '" + args.source.as_posix() + "', mountpoint = '/'})\n"
        "table.insert(path, 1, {dir = '" + (run / "overlay").as_posix() + "', mountpoint = '/'})\n",
        encoding="utf-8")
    peers = [Peer(920001, "ExpTest_A"), Peer(920002, "ExpTest_B")]
    children = []
    rendering = set()
    started = time.monotonic()

    def wait_until(predicate, timeout, reason):
        limit = time.monotonic() + timeout
        while time.monotonic() < limit:
            # FA suspends its simulation while the render window is hidden.
            # Enable only our child windows, offscreen and without taking focus.
            pending = {child.pid for child in children} - rendering
            if pending:
                user32 = ctypes.windll.user32
                callback_type = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)
                def enable_render(hwnd, _):
                    pid = ctypes.c_ulong()
                    user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
                    if pid.value in pending:
                        title = ctypes.create_unicode_buffer(128)
                        user32.GetWindowTextW(hwnd, title, 128)
                        if title.value == "Forged Alliance":
                            user32.SetWindowPos(hwnd, 0, -3000, -3000, 1024, 768, 0x10 | 0x40)
                            user32.ShowWindow(hwnd, 4)
                            rendering.add(pid.value)
                    return True
                user32.EnumWindows(callback_type(enable_render), 0)
            if predicate():
                return
            for child in children:
                if child.poll() is not None:
                    raise RuntimeError("Test game exited early: " + reason)
            time.sleep(.2)
        raise TimeoutError(reason)

    try:
        for index, peer in enumerate(peers):
            threading.Thread(target=peer.receive, daemon=True).start()
            command = [str(args.game_bin / "ForgedAlliance.exe"), "/init", str(init),
                       "/nobugreport", "/nosound", "/nomovie", "/windowed", "1024", "768",
                       "/log", str(run / (peer.name + ".log")),
                       "/pref", str(run / (peer.name + ".prefs")),
                       "/gpgnet", "127.0.0.1:" + str(peer.port), "/players", "2",
                       "/uef", "/team", str(index + 2), "/startspot", str(index + 1),
                       "/color", str(index + 1), "/mean", "1500", "/deviation", "100",
                       "/numgames", "50", "/performance", str(index - .5), "/performancegames", "4",
                       "/gameoptions", "TeamSpawn:fixed", "AutoTeams:none", "CheatsEnabled:false",
                       "Share:ShareUntilDeath", "GameSpeed:normal", "GAFExpectedPlayer1:ExpTest_A",
                       "GAFExpectedPlayer2:ExpTest_B", "GAFExpectedTeam1:2", "GAFExpectedTeam2:3"]
            startup = subprocess.STARTUPINFO()
            startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startup.wShowWindow = 0
            children.append(subprocess.Popen(command, cwd=args.game_bin, startupinfo=startup,
                                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
        wait_until(lambda: all(("GameState", ["Lobby"]) in p.messages for p in peers),
                   50, "FA did not create both isolated lobbies")
        print("Both test lobbies ready", flush=True)
        peers[0].send("HostGame", "SCMP_001")
        peers[1].send("JoinGame", "127.0.0.1:" + str(peers[0].udp_port), peers[0].name, peers[0].player_id)
        peers[0].send("ConnectToPeer", "127.0.0.1:" + str(peers[1].udp_port), peers[1].name, peers[1].player_id)
        wait_until(lambda: all(("GameState", ["Launching"]) in p.messages for p in peers),
                   65, "FA peers did not launch the private match")
        print("Private match launched; waiting for 125 simulation seconds", flush=True)
        wait_until(lambda: any(any(m[0] == "JsonStats" for m in p.messages) for p in peers),
                   240, "No JsonStats after deterministic game end")
        report = next(json.loads(m[1][0]) for p in peers for m in p.messages if m[0] == "JsonStats")
        humans = [a for a in report["stats"] if a["type"] == "Human"]
        assert len(humans) == 2, humans
        for army in humans:
            performance = army["performance"]
            assert performance["version"] == 1
            assert performance["duration"] >= 120
            assert len(performance["mass_income"]) == performance["duration"] // 60
            assert sum(performance["mass_income"]) > 0, performance
        (run / "game-stats.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
        receipt = {"elapsed_seconds": round(time.monotonic() - started, 1),
                   "players": {a["name"]: a["performance"] for a in humans},
                   "test_pids": [child.pid for child in children]}
        (run / "receipt.json").write_text(json.dumps(receipt, indent=2), encoding="utf-8")
        print(json.dumps(receipt), flush=True)
    finally:
        for peer in peers:
            (run / (peer.name + "-gpgnet.json")).write_text(
                json.dumps({"messages": peer.messages, "error": peer.error}, indent=2), encoding="utf-8")
        for child in children:
            if child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    child.kill()
        for peer in peers:
            if peer.connection:
                peer.connection.close()
            peer.listener.close()


if __name__ == "__main__":
    main()
