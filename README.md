# Selenic Classic
A Classic server written in Lua because I hate myself  
Name comes from Selene (greek personification of the moon and a pun on the fact that Lua is Moon in Portuguese) + -ic (pertaining to) and Classic (Minecraft Classic)

## Setup
Note: This is only intended for linux or other unix-like environments
Install [Luvit](https://luvit.io/install.html)  
Install [LuaRocks](https://github.com/luarocks/luarocks/wiki/Download)   
Clone the repository or download a release source zip  
Source set-path.sh
Run install-dependencies.sh
Run run.sh (server files will be under ./build)

## Features


World:
- [x] World module
- [x] World creation
- [x] World modification
- [x] Broadcast world modifications
- [x] World saving
- [x] World loading
- [x] World autosaving
- [ ] Terrain generation
- [x] Pack world into protocol-compliant gzipped byte-array
- [ ] Multithreaded major world operations + general optimizations
- [x] Use buffers in place of tables for worlds
- [x] Level initialize, level data chunk and level finalize packets
- [x] Split world data into 1024 byte chunks and send to client
- [ ] Per-world configuration
- [ ] Block data
- [ ] Block history

Player:
- [x] Player module
- [x] Player block modification
- [ ] Block placement rules
- [x] Basic player spawning
- [x] Player movement
- [ ] Relative player movement
- [x] Player cleanup
- [ ] Console player
- [ ] Console input
- [x] Duplicate name blocking
- [x] Enforce max players
- [x] Name verification
- [ ] Persistent player information (including bans)
- [ ] Fancy names & Nicknames

Messages:
- [x] Color code module
- [x] Chat
- [ ] Join/Leave messages
- [ ] Global Chat/Join/Leave messages
- [ ] Translation file

Server Management:
- [ ] Action cooldowns
- [ ] Permissions/Ranks
- [x] Config creation
- [x] Config loading
- [x] Full config usage
- [x] Logging system

Plugins:
- [ ] Basic system
- [ ] Full API
- [ ] Events
- [ ] Commands

Networking:
- [x] Basic TCP server
- [x] Add framework to handle incoming packets based on ID
- [x] Parse login packet
- [x] Send server identification
- [ ] Support all protocols (with toggles)
- [x] Heartbeat
- [ ] Salt caching
- [ ] Full CPE
- [ ] Web client

Advanced Features:
- [ ] Physics

Safety:
- [ ] Function assertions
- [ ] Unit tests

Misc:
- [x] Refactor to remove global types -- NOTE: Only removed where possible, may refactor codebase so all files use type files
- [ ] GUI