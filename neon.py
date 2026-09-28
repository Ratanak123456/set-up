#!/usr/bin/env python3
"""NEON v6: keyboard-only Textual Arch post-install workstation configurator."""
import asyncio
import os
import shlex
import shutil
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from textual import work
from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical, VerticalScroll, Container
from textual.screen import ModalScreen
from textual.widgets import Header, Footer, Static, Label, Button, RichLog, ProgressBar, SelectionList, RadioSet, RadioButton, Input

PACKAGES = {
 "BUILD / Git & GitHub CLI": "git github-cli base-devel gcc gdb cmake ninja clang",
 "LANGUAGES / Java, Rust, Python, Node": "python python-pip nodejs npm corepack maven gradle jdk21-openjdk rust",
 "DATABASES / PostgreSQL, Redis, SQLite": "postgresql redis sqlite",
 "TERMINAL / Editors & CLI tools": "kitty neovim tmux btop fastfetch ripgrep fzf fd bat zoxide eza jq tree curl wget unzip 7zip",
 "APPS / Firefox, Telegram & Media": "firefox telegram-desktop discord vlc mpv obs-studio gwenview okular libreoffice-fresh",
 "NETWORK / SSH & Diagnostics": "nmap wireshark-qt openssh android-tools ntfs-3g exfatprogs usbutils",
 "FILES / Dolphin, Thunar, Ark": "dolphin thunar ark",
 "FONTS / Noto, JetBrains Mono": "noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-dejavu ttf-liberation fontconfig ttf-jetbrains-mono ttf-fira-code ttf-nerd-fonts-symbols",
 "VM / QEMU & Virt Manager": "qemu-full virt-manager dnsmasq edk2-ovmf",
 "FLATPAK / Runtime": "flatpak",
}
AUR = ["jetbrains-toolbox", "visual-studio-code-bin", "brave-bin", "google-chrome", "postman-bin", "burpsuite"]

# Never let root own the installer log. This fixes the v3 exit-126 failure.
state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "neon-workstation-v6"
try:
    state.mkdir(parents=True, exist_ok=True)
    path = state / (datetime.now().strftime("%Y%m%d-%H%M%S") + ".log")
    log = path.open("w", encoding="utf8", buffering=1)
except OSError:
    state = Path(tempfile.mkdtemp(prefix="neon-workstation-"))
    path = state / "install.log"
    log = path.open("w", encoding="utf8", buffering=1)

class Prompt(ModalScreen):
    """Keyboard-operable confirmation or file-path dialog."""
    BINDINGS = [("escape", "cancel", "Cancel")]
    CSS = """
    Prompt { align: center middle; background: #010814cc; }
    #box { width: 76; max-width: 95%; height: auto; min-height: 13; border: heavy #27d8d2; padding: 1 2; background: #142238; }
    #question { height: auto; min-height: 3; color: #e0edff; margin-top: 1; }
    #value { margin: 1 0; }
    #modal-buttons { height: 3; align: center middle; }
    #modal-hint { color: #8facbe; text-align: center; height: 1; }
    """
    def __init__(self, title, message, input_mode=False):
        super().__init__(); self.title_text=title; self.msg=message; self.input_mode=input_mode
    def compose(self):
        with Vertical(id="box"):
            yield Label("◈  " + self.title_text)
            yield Static(self.msg, id="question")
            if self.input_mode: yield Input(placeholder="~/Downloads/docker-desktop-x86_64.pkg.tar.zst", id="value")
            with Horizontal(id="modal-buttons"):
                yield Button("[Y] CONFIRM", id="yes", variant="success")
                yield Button("[N] CANCEL", id="no")
            yield Static("Tab switch   •   Enter select   •   Esc cancel", id="modal-hint")
    def on_mount(self):
        if self.input_mode: self.query_one("#value", Input).focus()
        else: self.query_one("#no", Button).focus()  # safe default for destructive changes
    def on_key(self, event):
        # Modal keys work even if the keyboard focus is on either button.
        # Never treat letters typed inside the Docker package path as commands.
        if not self.input_mode and event.key == "y":
            event.stop(); self.dismiss(True)
        elif not self.input_mode and event.key == "n":
            event.stop(); self.action_cancel()
    def on_input_submitted(self, event: Input.Submitted):
        # Enter submits the path. No Tab-to-a-mouse-button required.
        if self.input_mode:
            event.stop()
            self.dismiss(event.value.strip())
    def action_cancel(self): self.dismiss("" if self.input_mode else False)
    def on_button_pressed(self, event):
        if event.button.id == "no": self.action_cancel()
        elif self.input_mode: self.dismiss(self.query_one("#value", Input).value.strip())
        else: self.dismiss(True)

class Neon(App):
    TITLE="N E O N   //   W O R K S T A T I O N"
    SUB_TITLE="POST-INSTALL DEVELOPER TOOLS"
    CSS="""
    Screen { background: #080e1a; color: #e1edff; }
    Header, Footer { background: #14263c; color: #53e9d6; }
    #welcome { width: 100%; height: 1fr; align: center middle; background: #080e1a; }
    #landing { width: 78; max-width: 95%; height: auto; border: heavy #33e6d1; padding: 2 4; background: #102136; }
    #landing-eyebrow { color: #6ae5e0; text-align: center; text-style: bold; margin-bottom: 1; }
    #landing-title { color: #f1f7ff; text-align: center; text-style: bold; height: 5; }
    #landing-subtitle { color: #a9bdd5; text-align: center; margin: 1 0 2 0; }
    #landing-status { color: #4ce6c2; text-align: center; height: 2; margin: 1 0; }
    #landing-guide { border-top: solid #274760; padding: 1 0; color: #b4cae1; height: auto; }
    #landing-buttons { height: 4; align: center middle; margin-top: 1; }
    #landing-keyboard { color: #7eabc0; text-align: center; height: 3; }
    #dashboard { width: 100%; height: 1fr; display: none; }
    #hero { margin: 1 2 0 2; height: 4; text-align: center; content-align: center middle; background: #102238; border: heavy #30cfc7; color: #d6fbfa; text-style: bold; }
    #description { text-align: center; height: 2; color: #98aec5; }
    #workspace { margin: 0 2; height: 1fr; }
    #choices { width: 45%; min-width: 37; border: round #2b5772; padding: 1; background: #111d30; }
    #monitor { width: 1fr; margin-left: 1; border: round #2b5772; padding: 1; background: #111d30; }
    .label { color: #64dfd9; text-style: bold; margin-bottom: 1; }
    SelectionList { height: 13; background: #111d30; border: none; }
    #container-choice { height: 9; border: solid #263e60; margin: 1 0; }
    #aur-list { height: 10; min-height: 8; border: solid #263e60; }
    RichLog { height: 1fr; color: #c3dcf2; background: #091522; scrollbar-color: #3badbd; }
    #status { margin-top: 1; height: 3; color: #b6c6db; }
    #progress { height: 2; margin-top: 1; }
    #buttons { height: 4; align: center middle; }
    #keyboard-hint { height: 2; color: #83aec2; text-align: center; } 
    #nav-strip { color: #80e8e2; height: 3; text-align: center; border-bottom: solid #31516a; margin: 0 2; }
    #choices:focus-within, #monitor:focus-within { border: heavy #31e7d3; }
    SelectionList:focus, RadioSet:focus, Button:focus, Input:focus { border: heavy #ffe08b; }
    Button:focus { text-style: bold reverse; }
    Button { margin: 0 1; min-width: 15; }
    #start, #enter { background: #22b9ab; color: #06172b; text-style: bold; }
    #preview, #welcome-demo { background: #385b8e; color: white; }
    #exit, #home { background: #314258; color: white; }
    """
    BINDINGS=[
        ("f1", "home", "Welcome"),
        ("f2", "focus_modules", "Packages"),
        ("f3", "focus_docker", "Docker"),
        ("f4", "focus_aur", "AUR"),
        ("f5", "focus_logs", "Logs"),
        ("f6", "install_selected", "Install"),
        ("f7", "preview_selected", "Preview"),
        # Laptop keyboards sometimes require Fn for F-keys.
        Binding("ctrl+1", "focus_modules", show=False),
        Binding("ctrl+2", "focus_docker", show=False),
        Binding("ctrl+3", "focus_aur", show=False),
        Binding("ctrl+4", "focus_logs", show=False),
        Binding("ctrl+s", "install_selected", show=False),
        Binding("ctrl+p", "preview_selected", show=False),
        Binding("ctrl+h", "home", show=False),
        ("ctrl+q", "quit", "Quit"),
    ]
    def __init__(self):
        super().__init__(); self.running=False; self.demo="--demo" in sys.argv; self.failed=[]; self.done=0; self.total=1
    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Container(id="welcome"):
            with Vertical(id="landing"):
                yield Static("◆   SYSTEM / WORKSTATION   ◆",id="landing-eyebrow")
                yield Static("N  E  O  N\nWORKSTATION  /  06",id="landing-title")
                yield Static("YOUR TERMINAL. YOUR DEVELOPMENT ENVIRONMENT.\nOnly application setup — your OS, compositor and dotfiles stay yours.",id="landing-subtitle")
                yield Static("◈   READY TO CONFIGURE",id="landing-status")
                yield Static("01   SELECT  /  tools, runtimes, IDEs, applications\n02   REVIEW  /  Docker and optional community packages\n03   DEPLOY  /  monitor installation with live logs",id="landing-guide")
                with Horizontal(id="landing-buttons"):
                    yield Button("[ENTER] CONTINUE",id="enter")
                    yield Button("[D] DEMO",id="welcome-demo")
                    yield Button("[Q] EXIT",id="exit")
                yield Static("NO MOUSE NEEDED  •  ENTER: continue  •  D: demo  •  Q: quit\nTAB / SHIFT+TAB: move focus  •  ENTER: activate focused button",id="landing-keyboard")
        with Container(id="dashboard"):
            yield Static("◆    N E O N    /    WORKSTATION    ◆\nBUILD  •  CREATE  •  SHIP", id="hero")
            yield Static("POST-INSTALL SOFTWARE ONLY  ◇  Arch, Hyprland and dotfiles remain untouched",id="description")
            yield Static("F2 PACKAGES    F3 DOCKER    F4 AUR    F5 LOGS    F6 INSTALL    F7 PREVIEW    F1 HOME", id="nav-strip")
            with Horizontal(id="workspace"):
                with VerticalScroll(id="choices"):
                    yield Label("◈  CHOOSE YOUR MODULES",classes="label")
                    yield SelectionList(*[(k,k,k.startswith(("BUILD", "LANGUAGES", "TERMINAL", "APPS"))) for k in PACKAGES], id="modules")
                    yield Label("◈  CONTAINER STACK",classes="label")
                    with RadioSet(id="container-choice"):
                        yield RadioButton("No Docker", value=True, id="docker-none")
                        yield RadioButton("Engine + Compose + Buildx", id="docker-engine")
                        yield RadioButton("Docker Desktop / local .pkg",id="docker-desktop")
                    yield Label("◈  OPTIONAL AUR APPS",classes="label")
                    yield SelectionList(*[(p,p,False) for p in AUR],id="aur-list")
                with Vertical(id="monitor"):
                    yield Label("◈  LIVE OPERATIONS / INSTALL LOG",classes="label")
                    yield RichLog(id="log",markup=False,highlight=False,wrap=True,auto_scroll=True)
                    yield Static("READY  /  Choose packages, then start.\nLog: " + str(path), id="status")
                    yield ProgressBar(total=100,show_eta=False,id="progress")
            with Horizontal(id="buttons"):
                yield Button("[F6] INSTALL",id="start")
                yield Button("[F7] PREVIEW",id="preview")
                yield Button("[F1] WELCOME",id="home")
            yield Static("↑↓ move  •  SPACE select  •  F2-F5 jump panels (or CTRL+1..4)  •  TAB switch controls\nENTER activate  •  F6 / CTRL+S install  •  F7 / CTRL+P preview  •  CTRL+Q exit",id="keyboard-hint")
        yield Footer()
    def on_mount(self):
        self.welcome_visible = True
        self.anim_frames = ("◈   READY TO CONFIGURE", "◇   READY TO CONFIGURE", "◆   READY TO CONFIGURE")
        self.anim_pos=0
        self.set_interval(.55,self.animate_landing)
        self.query_one("#enter",Button).focus()
    def animate_landing(self):
        if not self.welcome_visible: return
        self.anim_pos=(self.anim_pos+1)%len(self.anim_frames)
        self.query_one("#landing-status",Static).update(self.anim_frames[self.anim_pos])
    def on_key(self,event):
        if not self.welcome_visible: return
        if event.key == "d":
            event.stop(); self.action_open_dashboard(); self.action_preview_selected()
        elif event.key == "q":
            event.stop(); self.exit()
    def action_open_dashboard(self):
        self.welcome_visible=False
        self.query_one("#welcome").display=False
        self.query_one("#dashboard").display=True
        self.query_one("#modules",SelectionList).focus()
        if not getattr(self,"dashboard_initialized",False):
            self.dashboard_initialized=True
            self.line("NEON initialized. Installation progress appears here in real time.")
            self.line("F2 Packages • F3 Docker • F4 AUR • F5 Logs • F6 Install • F7 Preview.")
            self.line("Arrows + Space change options; all dialogs use Enter / Y / N / Esc.")
    def _focus_panel(self, widget_id, widget_type):
        if not self.welcome_visible and not self.running:
            widget = self.query_one(widget_id, widget_type)
            widget.focus()
            widget.scroll_visible()
    def action_focus_modules(self): self._focus_panel("#modules", SelectionList)
    def action_focus_docker(self): self._focus_panel("#container-choice", RadioSet)
    def action_focus_aur(self): self._focus_panel("#aur-list", SelectionList)
    def action_focus_logs(self):
        if not self.welcome_visible:
            widget = self.query_one("#log", RichLog)
            widget.focus()
            widget.scroll_visible()
    def action_home(self):
        if self.running or self.screen.is_modal: return
        self.welcome_visible=True
        self.query_one("#dashboard").display=False
        self.query_one("#welcome").display=True
        self.query_one("#enter",Button).focus()
    def line(self,message):
        self.query_one("#log",RichLog).write(message)
        log.write(str(message)+"\n")
    def action_clear_logs(self): self.query_one("#log",RichLog).clear()
    def action_install_selected(self):
        if not self.running and not self.welcome_visible and not self.screen.is_modal:
            if "--demo" in sys.argv:
                self.line("DEMO SESSION: installation disabled. Restart without --demo to install.")
                return
            self.demo=False
            self.install()
    def action_preview_selected(self):
        if not self.running and not self.welcome_visible and not self.screen.is_modal:
            self.demo=True
            self.install()
    def on_button_pressed(self,event):
        button=event.button.id
        if button=="exit": self.exit()
        elif button=="enter": self.action_open_dashboard()
        elif button=="welcome-demo": self.action_open_dashboard(); self.action_preview_selected()
        elif button=="home": self.action_home()
        elif button=="start": self.action_install_selected()
        elif button=="preview": self.action_preview_selected()
    def progress(self):
        self.done+=1; self.query_one("#progress",ProgressBar).update(progress=int(100*self.done/self.total))
    async def approval(self,title,message): return await self.push_screen_wait(Prompt(title,message))
    async def ask_path(self): return await self.push_screen_wait(Prompt("DOCKER DESKTOP", "Provide the local Docker Desktop package downloaded from official Docker docs. Leave empty to skip.",True))
    async def packages_in_repo(self, packages):
        found=[]
        for pkg in packages.split():
            p=await asyncio.create_subprocess_exec("pacman","-Si",pkg,stdout=asyncio.subprocess.DEVNULL,stderr=asyncio.subprocess.DEVNULL)
            await p.wait()
            if p.returncode==0: found.append(pkg)
            else: self.line(f"SKIPPED: {pkg} not found in configured repositories")
        return found
    async def execute(self, name, args, cwd=None):
        self.query_one("#status",Static).update("⟳  " + name)
        self.line("\n▶ " + name)
        log.write("\n"+datetime.now().isoformat()+" $ "+shlex.join(args)+"\n")
        try:
            p=await asyncio.create_subprocess_exec(*args,cwd=cwd,stdin=asyncio.subprocess.DEVNULL,stdout=asyncio.subprocess.PIPE,stderr=asyncio.subprocess.STDOUT)
            while True:
                raw=await p.stdout.readline()
                if not raw: break
                message=raw.decode("utf8",errors="replace").rstrip()
                if message: self.line(message)
            rc=await p.wait()
        except OSError as exc:
            rc=127; self.line(f"STARTUP ERROR: {exc}")
        if rc:
            self.failed.append(f"{name} (exit {rc})"); self.line(f"✕ FAILED: {name}; exit={rc}; inspect log")
            return False
        self.line("✓ COMPLETE: " + name)
        return True
    async def install_repo(self,name,pkgs):
        available=await self.packages_in_repo(pkgs)
        if available: return await self.execute(name,["sudo","-n","pacman","-S","--needed","--noconfirm",*available])
        self.failed.append("No available packages: "+name); return False
    def install(self):
        # Reserve the run before the worker is scheduled; repeated keys must not
        # cancel a worker that may already be changing the system.
        if self.running:
            return
        self.running = True
        return self._install()

    @work
    async def _install(self):
        self.failed=[]; self.done=0
        self.query_one("#progress",ProgressBar).update(progress=0)
        self.query_one("#start",Button).disabled=True
        selected=list(self.query_one("#modules",SelectionList).selected)
        aur=list(self.query_one("#aur-list",SelectionList).selected)
        choice=self.query_one("#container-choice",RadioSet).pressed_button
        docker=choice.id if choice else "docker-none"
        self.total=max(1,1+len(selected)+len(aur)+(docker!="docker-none"))
        heartbeat=None
        try:
            if self.demo:
                self.line("\n◈  PREVIEW / NO SYSTEM CHANGES")
                preview_items = ["System upgrade"] + selected + (["Docker: " + docker] if docker != "docker-none" else []) + aur
                self.total = max(1, len(preview_items))
                for title in preview_items:
                    self.line("◌  "+title); self.query_one("#status",Static).update("PREVIEW / "+title)
                    await asyncio.sleep(.32); self.progress()
                self.line("✓ Preview complete: no commands executed.")
                return
            approved=await self.approval("CONFIRM SYSTEM UPDATE", "First run sudo pacman -Syu? This can upgrade your existing kernel and desktop packages. Cancel makes no changes.")
            if not approved: self.line("Cancelled before installation."); return
            # Installer starts from install.sh, which authenticates sudo BEFORE opening the TUI.
            async def sudo_heartbeat():
                while True:
                    await asyncio.sleep(45)
                    proc=await asyncio.create_subprocess_exec("sudo","-n","-v",stdout=asyncio.subprocess.DEVNULL,stderr=asyncio.subprocess.DEVNULL)
                    await proc.wait()
            heartbeat=asyncio.create_task(sudo_heartbeat())
            if not await self.execute("Full system upgrade",["sudo","-n","pacman","-Syu","--noconfirm"]):
                self.line("Stopped: do not continue after a failed Arch upgrade."); return
            self.progress()
            for name in selected:
                await self.install_repo(name,PACKAGES[name]); self.progress()
            if docker=="docker-engine":
                await self.install_repo("Docker Engine + Compose + Buildx","docker docker-compose docker-buildx")
                self.line("Docker service is NOT started automatically; optional command: sudo systemctl enable --now docker")
                self.line("Do not grant docker-group access unless you accept its root-equivalent privileges.")
                self.progress()
            elif docker=="docker-desktop":
                filepath=await self.ask_path()
                if filepath:
                    pkg=Path(filepath).expanduser()
                    if pkg.is_file() and pkg.name.endswith(".pkg.tar.zst"):
                        if not Path("/dev/kvm").exists(): self.line("WARNING: /dev/kvm missing; Docker Desktop requires virtualization.")
                        await self.execute("Docker Desktop local Arch package",["sudo","-n","pacman","-U","--noconfirm","--",str(pkg.resolve())])
                    else: self.failed.append("Invalid Docker Desktop package path"); self.line("Invalid local Docker Desktop package; skipped.")
                self.progress()
            if aur:
                if not shutil.which("yay"):
                    self.line("yay missing. Git and base-devel are required to build this AUR helper.")
                    if await self.approval("BOOTSTRAP YAY", "Clone yay from the official AUR git repository and build as your normal user? Review community PKGBUILDs before trusting them."):
                        if await self.install_repo("AUR build dependencies","git base-devel"):
                            temp=Path(tempfile.mkdtemp(prefix="neon-yay-"))
                            if await self.execute("Clone yay",["git","clone","https://aur.archlinux.org/yay.git",str(temp/"yay")]):
                                await self.execute("Build yay",["makepkg","-si","--noconfirm"],cwd=str(temp/"yay"))
                if shutil.which("yay") and await self.approval("INSTALL AUR PACKAGES", "Install selected third-party AUR packages? Only proceed if you trust the PKGBUILDs. Use yay manually for interactive review if unsure."):
                    for pkg in aur:
                        await self.execute("AUR: "+pkg,["yay","-S","--needed","--noconfirm",pkg]); self.progress()
                elif not shutil.which("yay"):
                    self.failed.append("AUR packages skipped: yay missing")
            self.line("\n━━  MISSION REPORT  ━━")
            if self.failed:
                self.line("FINISHED WITH ERRORS:\n"+"\n".join(self.failed))
            else: self.line("ALL SELECTED TASKS COMPLETED")
            self.line("Log: "+str(path)); self.line("Next: gh auth login; docker compose version; jetbrains-toolbox")
        except Exception as exc:
            self.line("INSTALLER ERROR: "+repr(exc)); self.failed.append(repr(exc))
        finally:
            if heartbeat: heartbeat.cancel()
            self.running=False
            self.query_one("#start",Button).disabled=False
            self.query_one("#status",Static).update("PREVIEW COMPLETE" if self.demo else "FINISHED: check report and saved log")

if __name__=="__main__": Neon().run()
