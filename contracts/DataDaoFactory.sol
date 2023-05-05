// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDataManager.sol";
import "./interfaces/IMarketplace.sol";
import "./interfaces/IStorage.sol";
import "./interfaces/IDealClient.sol";
import "./DataDao.sol";
import "./DealClient.sol";
import "./Storage.sol";

contract DataDaoFactory is Ownable {
    IERC20 MCY;
    IDataManager dataManager;
    IMarketplace marketplace;

    address masterDataDao;
    address masterStorage;
    address masterClient;

    mapping(address => address[]) public deployedDaos;

    uint256 public deployedDaoCount;

    event DataDaoCreated(address indexed dao);

    constructor(
        IERC20 _MCY,
        IDataManager _dataManager,
        IMarketplace _marketplace,
        address _masterDataDao,
        address _masterClient,
        address _masterStorage
    ) {
        MCY =_MCY;
        dataManager = _dataManager;
        marketplace = _marketplace;
        masterDataDao = _masterDataDao;
        masterClient = _masterClient;
        masterStorage = _masterStorage;
    }

    function createDataDao(string memory name, string memory symbol, address[] memory admins) external {
        Storage _s = Storage(Clones.clone(masterStorage));

        DealClient _c = DealClient(Clones.clone(masterClient));
        _c.initialize(_s);

        DataDao _dataDao = DataDao(Clones.clone(masterDataDao));
        _dataDao.initialize(name, symbol, admins, MCY, dataManager, marketplace, IStorage(address(_s)), IDealClient(address(_c)));

        _c.setDao(address(_dataDao));
        _s.setAuth(address(_c), address(_dataDao));

        deployedDaos[msg.sender].push(address(_dataDao));
        deployedDaoCount++;
        
        emit DataDaoCreated(address(_dataDao));
    }

    function setMaster(address _masterDataDao, address _masterStorage, address _masterClient) external onlyOwner {
        masterDataDao = _masterDataDao;
        masterStorage = _masterStorage;
        masterClient = _masterClient;
    }

    function setMercury(IERC20 _MCY, IDataManager _dataManager, IMarketplace _marketplace) external onlyOwner {
        MCY = _MCY;
        dataManager = _dataManager;
        marketplace = _marketplace;
    }

    function deployedDaosCountForUser(address user) public view returns (uint256) {
        return deployedDaos[user].length;
    }

    function deployedDaosForUser(address user) public view returns (address[] memory) {
        return deployedDaos[user];
    }
}