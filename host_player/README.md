the plugin keeps track of who the lobby host is. It provides a basic API other plugins can use to make use of this. If a lobby gets reserved, the client who made the reservation request will always override current host. If a host leaves, it will be passed down to whoever was connected the longest. If a host loads late during map transitions, they will still be host.

i made this so that this "host" player can be given special permissions for configuring gameplay of my servers

**WARNING**
Windows isn't tested at all!