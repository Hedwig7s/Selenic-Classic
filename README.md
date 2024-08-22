# Selenic Classic
A Classic server written in Lua because I hate myself  
Name comes from Selene (greek personification of the moon and a pun on the fact that Lua is Moon in Portuguese) + -ic (pertaining to) and Classic (Minecraft Classic)

## Setup
Install [Luvit](https://luvit.io/install.html)  
Install [LuaRocks](https://github.com/luarocks/luarocks/wiki/Download)   
Clone the repository or download a release source zip  
Run `./install-dependencies.sh` (Linux) or `./install-dependencies.bat` (Windows) (expects LuaRocks to be in PATH)  
Run `luvit main.lua`  

## Features

- [x] Basic TCP server
- [ ] Add framework to handle incoming packets based on ID
- [ ] Parse login packet
- [ ] Send server identification

World:
- [ ] World module
- [ ] World creation
- [ ] World modification
- [ ] World saving
- [ ] World loading
- [ ] World autosaving
- [ ] Terrain generation
- [ ] Pack world into protocol-compliant gzipped byte-array
- [ ] Level initialize, level data chunk and level finalize packets
- [ ] Split world data into 1024 byte chunks and send to client
- [ ] Per-world configuration
- [ ] Block history

Player:
- [ ] Player module
- [ ] Player block modification
- [ ] Block placement rules
- [ ] Basic player spawning
- [ ] Player movement
- [ ] Relative player movement
- [ ] Player cleanup
- [ ] Console player
- [ ] Console input
- [ ] Duplicate name blocking
- [ ] Enforce max players
- [ ] Persistent player information (including bans)
- [ ] Fancy names & Nicknames

Messages:
- [ ] Chat
- [ ] Join/Leave messages
- [ ] Global Chat/Join/Leave messages
- [ ] Translation file

Server Management:
- [ ] Commands
- [ ] Cooldowns
- [ ] Permissions/Ranks
- [ ] Config creation
- [ ] Config loading
- [ ] Full config usage
- [ ] Logging system

Networking:
- [ ] Support all protocols (with toggles)
- [ ] Heartbeat
- [ ] Name verification
- [ ] Salt caching
- [ ] Full CPE
- [ ] Better CPE extension mechanism
- [ ] Web client

Advanced Features:
- [ ] Physics

Code Improvement:
- [ ] Code cleanup