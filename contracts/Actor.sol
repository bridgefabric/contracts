// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// This is the main building block for smart contracts.
contract BridgeActor {
    MapActor private actors;

     function addActor(string memory actorCid, string memory descCid) public  {
        set(actors, actorCid, descCid);
    }
    function getActor(string memory actor) public view returns (Actor memory) {
        return get(actors, actor);
    }
    function getActorIds() public view returns (string[] memory) {
        return getKeys(actors);
    }

    struct Actor {
        address owner;// only owner can change
        string desCid;// description content cid
    }
    // add price + buy count
    // todo change keys to amount, for page
    struct MapActor
    {
        mapping(string=>Actor)  actorMaps;
        string[] keys;
    }

    function get(MapActor storage self, string memory cid) internal view returns(Actor memory)
	{
		return self.actorMaps[cid];
	}
    function getKeys(MapActor storage self) internal view returns(string[] memory)
	{
		return self.keys;
	}
    function set(MapActor storage self, string memory cid, string memory desCid) internal returns(bool) {
        Actor memory a = Actor(msg.sender, desCid);
        Actor memory oldv = self.actorMaps[cid];
        if (oldv.owner == msg.sender || oldv.owner == address(0x0))
        {
            self.keys.push(cid);
            self.actorMaps[cid] = a;
            return true;
	    }
        return false;
    }

}
