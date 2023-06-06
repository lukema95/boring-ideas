// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Ghost
 * @author lukema95
 * @notice The Ghost contract is a ghost, don't try to understand it
 */
contract Ghost {

  // Mapping sender address to backup address list
  mapping(address => address[]) public registry;

  // Mapping sender address to route address
  mapping(address => address) public router;

  /**
   * @dev Emitted when sender to register  
   */
  event Register(address, address[]);

  /**
   * @dev Emitted when sender to route
   */
  event Route(address, address);

  constructor() {
  }

  /**
   * @dev External function to register user's backup address
   * 
   * @param _registry Address list 
   */
  function register(address[] memory _registry) external {
    address[] memory registed = registry[msg.sender];
    require(registed.length == 0, "user already registed");
    for (uint i = 0; i < _registry.length; i++) {
      registry[msg.sender].push(_registry[i]);
    }

    emit Register(msg.sender, _registry);
    
  }

  /**
   * @dev Public view function to query account registry
   * 
   * @param _account Address of the account to be queried
   * 
   * @return _registry The registry of the account to be queried
   */
  function queryRegistry(address _account) public view returns(address[] memory _registry){
    _registry = registry[_account];
  }

  /**
   * @dev Public view function to query account registry by index
   * 
   * @param _account Address of the account to be queried
   * @param _index The index of the registry to be queried
   * 
   * @return The address of the index in the registry
   */
  function queryRegistryIndex(address _account, uint256 _index) public view returns(address) {
    address[] memory _registry = registry[_account];
    require(_registry.length > _index, "index larger than user's registry length");
    return _registry[_index];
  }
  
  /**
   * @dev External function to route 
   * 
   * @param to The address to be routed
   */
  function route(address to) external {
    address[] memory _registry = registry[msg.sender];
    require(_registry.length > 0, "user has not registered yet");
    require(router[msg.sender] == address(0), "user already routed");

    for (uint i = 0; i < _registry.length; i++) {
      if (to == _registry[i]) {
        router[msg.sender] = to;
        emit Route(msg.sender, to);
      }
    }

    require(router[msg.sender] != address(0), "address is not in the registery");
  }

  /**
   * @dev External view fucntion to query account router
   * 
   * @param _account Address of the account to be queried
   * 
   * @return Indicates the address of the rerouted account
   */
  function queryRoute(address _account) external view returns (address) {
    address redirection = router[_account];
    if(redirection == address(0)) {
      return msg.sender;
    }

    return redirection;
  }

}
