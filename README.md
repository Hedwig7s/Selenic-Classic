# Selenic Classic
A Classic server written in Lua because I hate myself  
Name comes from Selene (greek personification of the moon and a pun on the fact that Lua is Moon in Portuguese) + -ic (pertaining to) and Classic (Minecraft Classic)

## Setup
Install [Luvit](https://luvit.io/install.html)  
Install [LuaRocks](https://github.com/luarocks/luarocks/wiki/Download)   
Clone the repository or download a release source zip  
Run `./install-dependencies.sh` (Linux)
Run `./run.sh`  

## Features

- [x] Basic TCP server
- [x] Add framework to handle incoming packets based on ID
- [x] Parse login packet
- [x] Send server identification

World:
- [x] World module
- [x] World creation
- [x] World modification
- [ ] Broadcast world modifications
- [x] World saving
- [x] World loading
- [ ] World autosaving
- [ ] Terrain generation
- [ ] Pack world into protocol-compliant gzipped byte-array
- [ ] Level initialize, level data chunk and level finalize packets
- [ ] Split world data into 1024 byte chunks and send to client
- [ ] Per-world configuration
- [ ] Block data
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
- [x] Config creation
- [x] Config loading
- [ ] Full config usage
- [x] Logging system

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