# Selenic Classic
A Classic server written in Lua because I hate myself
Name comes from Selene (greek personification of the moon and a pun on the fact that Lua is Moon in Portuguese) + -ic (pertaining to) and Classic (Minecraft Classic)

## SETUP
Install [Luvit](https://luvit.io/install.html)
Install [LuaRocks](https://github.com/luarocks/luarocks/wiki/Download) 
Clone the repository or download a release source zip
Run `./install-dependencies.sh` (Linux) or `./install-dependencies.bat` (Windows) (expects LuaRocks to be in PATH)
Run `luvit main.lua`

## TODO
- [x] Basic TCP server
- [x] Add framework to handle incoming packages based on ID
- [x] Parse login packet
- [x] Send server identification
- [x] World module
- [x] World creation
- [x] World modification
- [x] World saving
- [x] World loading
- [x] World autosaving
- [ ] Terrain generation
- [x] Pack world into protocol-complient gzipped byte-array
- [x] Level initialize, level data chunk and level finalize packets
- [x] Split world data into 1024 byte chunks and send to client
- [x] Player module
- [x] Player block modification
- [ ] Block placement rules
- [x] Basic player spawning
- [x] Player movement
- [x] Relative player movement
- [x] Player cleanup
- [x] Cooldowns
- [x] Duplicate name blocking
- [ ] Enforce max players
- [x] Chat
- [ ] Join/Leave messages
- [ ] Commands
- [ ] Physics
- [ ] Permissions/Ranks
- [x] Config creation
- [x] Config loading
- [ ] Full config usage
- [ ] CPE
- [ ] Web client
- [x] Heartbeat
- [ ] Name verification
- [ ] Block history
