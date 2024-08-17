---@meta

---@alias ServerPackets.DisconnectPlayer fun(connection: Connection, reason: string): boolean?, string? @Disconnects a player with a reason
---@alias ServerPackets.ServerIdentification fun(connection: Connection): boolean?, string? @Identifies server to client
---@alias ServerPackets.Ping fun(connection: Connection): boolean?, string? @Pings the client
---@alias ServerPackets.LevelInitialize fun(connection: Connection): boolean?, string? @Indicates to client that level data is about to be sent
---@alias ServerPackets.LevelDataChunk fun(connection: Connection, length: number, data: string, percent: number): boolean?, string? @Sends a chunk of level data to the client
---@alias ServerPackets.LevelFinalize fun(connection: Connection, size: Vector3): boolean?, string? @Indicates to client that level has been fully sent, also sends size
---@alias ServerPackets.SetBlock fun(connection: Connection, _: any, x: number, y: number, z: number, block: BlockIDs): boolean?, string? @Updates client(s) of a block update
---@alias ServerPackets.SpawnPlayer fun(connection: Connection, id: number, name: string, x: number, y: number, z: number, yaw: number, pitch: number): boolean?, string? @Tells clients to spawn player with specified positional information
---@alias ServerPackets.SetPositionAndOrientation fun(connection: Connection, id: number, x: number, y: number, z: number, yaw: number, pitch: number, skipSelf: boolean?): boolean?, string? @Tells clients to move player to specified location
---@alias ServerPackets.PositionAndOrientationUpdate fun(id: number, x: number, y: number, z: number, yaw: number, pitch: number, connection: Connection): boolean?, string? @Tells clients to move player relative to current (client-side) location and orientation
---@alias ServerPackets.PositionUpdate fun(id: number, x: number, y: number, z: number, criteria?: fun(connection: Connection):boolean): boolean?, string? @Tells clients to move player relative to current (client-side) location
---@alias ServerPackets.OrientationUpdate fun(connection: Connection, id: number, yaw: number, pitch: number, criteria?: fun(connection: Connection):boolean): boolean?, string? @Tells client to rotate player relative to current (client-side) orientation
---@alias ServerPackets.DespawnPlayer fun(connection: Connection, id: number): boolean?, string? @Despawns a player from the world
---@alias ServerPackets.Message fun(connection: Connection, message: string, id?: number): boolean?, string? @Sends a message to client(s)
---@alias ServerPackets.UpdateUserType fun(connection: Connection, id: number, type: number): boolean?, string? @Changes the user type of a player

---@class ServerPackets
---@field public ServerIdentification ServerPackets.ServerIdentification
---@field public Ping ServerPackets.Ping
---@field public LevelInitialize ServerPackets.LevelInitialize
---@field public LevelDataChunk ServerPackets.LevelDataChunk
---@field public LevelFinalize ServerPackets.LevelFinalize
---@field public SetBlock ServerPackets.SetBlock
---@field public SpawnPlayer ServerPackets.SpawnPlayer
---@field public SetPositionAndOrientation ServerPackets.SetPositionAndOrientation
---@field public PositionAndOrientationUpdate ServerPackets.PositionAndOrientationUpdate
---@field public PositionUpdate ServerPackets.PositionUpdate
---@field public OrientationUpdate ServerPackets.OrientationUpdate
---@field public DespawnPlayer ServerPackets.DespawnPlayer
---@field public Message ServerPackets.Message
---@field public DisconnectPlayer ServerPackets.DisconnectPlayer
---@field public UpdateUserType ServerPackets.UpdateUserType

---@alias ClientPacket fun(data:string, connection:Connection)

---@alias ClientPackets.PlayerIdentification fun(data:string, connection:Connection, protocol:Protocol) @Handles player identification
---@alias ClientPackets.SetBlock ClientPacket @Handles client trying to set block
---@alias ClientPackets.PositionAndOrientation ClientPacket @Handles client trying to move
---@alias ClientPackets.Message ClientPacket @Handles chat messages from client
 
---@class ClientPackets 
---@field public [0] ClientPackets.PlayerIdentification
---@field public [5] ClientPackets.SetBlock
---@field public [8] ClientPackets.PositionAndOrientation
---@field public [13] ClientPackets.Message

---@class Protocol
---@field public ServerPackets ServerPackets
---@field public ClientPackets ClientPackets
---@field public Version number
---@field public PacketSizes table<number,number> @Size of each packet type
---@field public ClientVersions string