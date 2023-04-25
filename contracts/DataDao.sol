// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IDataDao.sol";
import "./interfaces/IDataManager.sol";
import "./interfaces/IMarketplace.sol";
import "./interfaces/IStorage.sol";
import "./interfaces/IDealClient.sol";
import "./MercurySBT.sol";

contract DataDao is Initializable, AccessControl {
    using SafeMath for uint256;

    MercurySBT public sbt;
    IERC20 public MCY;

    IStorage s;

    IDataManager dataManager;
    IMarketplace marketplace;
    IDealClient client;

    function initialize(
        string memory name,
        string memory symbol,
        address[] memory admins,
        IERC20 _MCY,
        IDataManager _dataManager,
        IMarketplace _marketplace,
        IStorage _s,
        IDealClient _dealClient
    ) external initializer {
        for (uint8 i = 0; i < admins.length; ) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);

            unchecked {
                ++i;
            }
        }

        sbt = new MercurySBT(name, symbol, admins);
        MCY = _MCY;
        dataManager = _dataManager;
        marketplace = _marketplace;
        s = _s;
        client = _dealClient;
    }

    modifier onlyMember() {
        if (sbt.balanceOf(msg.sender) != 1) {
            revert();
        }
        _;
    }

    function grantMembership(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sbt.mint(to);
    }

    function revokeMembership(
        uint256 tokenId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sbt.revoke(tokenId);
    }

    function activePieceCids() external view returns (bytes[] memory) {
        return s.activePieceCids();
    }

    function isMember(address user) external view returns (bool) {
        return sbt.balanceOf(user) == 1;
    }

    function membersCount() external view returns (uint256) {
        return sbt.tokenCount();
    }

    function distributeEarnings() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 daoBalance = MCY.balanceOf(address(this));
        uint256 memberCount = sbt.tokenCount();
        uint256 payoutPerMember = daoBalance.div(memberCount);

        for (uint256 i = 0; i < memberCount; i++) {
            uint256 tokenId = sbt.tokenIds(i);
            address owner = sbt.ownerOf(tokenId);
            MCY.transfer(owner, payoutPerMember);
        }
    }

    function depositFil() external payable {
        uint256 deposits = s.filDeposits(msg.sender);
        s.setFilDeposit(msg.sender, deposits + msg.value);
    }

    function withdrawFil(uint256 amount) external {
        if (s.filDeposits(msg.sender) < amount) {
            revert();
        }
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            revert();
        }
    }

    function makeDealProposal(Structs.DealRequest calldata deal) external {
        client.makeDealProposal(deal);
    }

    function createOrder(
        uint256 _price,
        uint256 _dataUnits,
        Structs.DataType memory _dataType,
        bytes32 _dataHash
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dataManager.createOrder(
            _price,
            _dataUnits,
            _dataType,
            false,
            _dataHash
        );
    }

    function updateOrder(
        bytes32 _id,
        uint256 _price,
        uint256 _dataUnits,
        Structs.DataType memory _dataType
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dataManager.updateOrder(_id, _price, _dataUnits, _dataType);
    }

    function cancelOrder(bytes32 _id) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dataManager.cancelOrder(_id);
    }

    function setOrderActive(
        bytes32 _id,
        bool _isActive
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dataManager.setOrderActive(_id, _isActive);
    }

    function acceptBuyOrder(
        bytes32 _id,
        uint256 _units,
        bytes32 _dataHash
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketplace.acceptBuyOrder(_id, _units, _dataHash);
    }
}
