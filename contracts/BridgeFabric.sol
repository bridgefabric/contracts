// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import "./erc20fevm.sol";

// This is the main building block for smart contracts.
contract Bridge is ERC20 {
    constructor() ERC20("Bridge Fabric Token", "BFT") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    uint private nodeCount;
    mapping(uint => string) nodes; 
    mapping(string => string[])  private actors; // byte59
    // mapping(string => mapping (string => uint)) private hostActorAvalibleCount; // host => actor => buied count

    function addActorHost(string memory actor, string memory host) public  {
        actors[actor].push(host);
    }
    function getActorHost(string memory actor) public view returns (string[] memory) {
        return actors[actor];
    }
    
    //Deposit amount
    uint256 public nodeDepositAmount = 500 * 10 ** decimals();
    // // A mapping is a key/value map. Here we store each staked user.
    mapping(string => uint256) nodeDeposits;
    mapping(string => address) nodeOwner;
    // /**
    //  *
    //  */
    function isDeposit(string memory host) external view returns (bool) {
        return nodeDeposits[host] != 0;
    }

    // /**
    //  *
    //  */
    function stake(string memory host) external {
        require(nodeDeposits[host] == 0, "Already staked");
        require(balanceOf(msg.sender) >= nodeDepositAmount, "Not enough BFT");
        _transfer(msg.sender, address(this), nodeDepositAmount);
        nodeDeposits[host] += nodeDepositAmount;
        nodeOwner[host] = msg.sender;
    }
    // /**
    //  *
    //  */
    function withdraw(string memory host) external {
        require(nodeDeposits[host] > 0);
        require(msg.sender == nodeOwner[host]);
        _transfer(address(this), msg.sender, nodeDeposits[host]);
        delete nodeDeposits[host];
        delete nodeOwner[host];
    }

    MapUint private nodePrices;
    function addPrice(string memory host, uint price) external {
        require(nodeOwner[host] == msg.sender, "Not owner");
        require(price > 0, "Invalid price");
        set(nodePrices, host, price);
    }

    function getNodes() public view returns(string[] memory) {
        return getKeys(nodePrices);
    }

    function getNodePrice(string memory node) public view returns(uint) {
        return get(nodePrices, node);
    }

    // function getNodesWithPrice() public view returns(MapUint[] memory) {
    //     return getKeys(nodePrices);
    // }


    // add price + buy count
    // todo change keys to amount, for page
    struct MapUint
    {
        mapping(string=>uint256)  uintMaps;
        string[] keys;
    }

    function get(MapUint storage self, string memory itemId) internal view returns(uint256)
	{
		return self.uintMaps[itemId];
	}
    function getKeys(MapUint storage self) internal view returns(string[] memory)
	{
		return self.keys;
	} 
    function set(MapUint storage self, string memory itemId, uint256 amount) internal returns(bool) {
        uint256 oldv = self.uintMaps[itemId];
        self.uintMaps[itemId] = amount;	
        if (oldv == 0 && amount > 0)       
            {
		self.keys.push(itemId);
	    }
        return true;
    }

    struct buyer {
        uint count;
        uint price;
        address owner;
        uint used;
    }

    // ==== buy 
    // todo change unit to buyer
    // todo stack to this contract and then withdraw.
    mapping (string=> mapping (string=> uint)) wasmAvaCount;// node->wasm->count
    function countBuy(string memory host,string memory actor, uint amount) public {
        // add to actor discovery
        uint price = getNodePrice(host);
        require(price > 0, "Invalid Node");
        require(amount > 0, "Invalid amount");
        uint paid = price * amount;
        require(paid > 0, "Invalid amount");
        require(balanceOf(msg.sender) >= paid, "Not enough BFT");
        _transfer(msg.sender, nodeOwner[host], paid);
        addActorHost(actor, host);
        wasmAvaCount[host][actor] += amount;
    }
    function countReduce(string memory host,string memory actor, uint amount) public {
        // require node owner
        require(msg.sender == nodeOwner[host]);
        require(amount > 0, "Invalid amount");
        uint left = wasmAvaCount[host][actor] - amount;
        if (left < 0) {
            left = 0;
        }
        wasmAvaCount[host][actor] = left;
    }
    function countCurrent(string memory host,string memory actor) public view returns(uint){
        return wasmAvaCount[host][actor];
    }
}
