// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MercurySBT is ERC721, AccessControl {
    uint256 public tokenCount;

    uint256[] public tokenIds;
    mapping(uint256 => uint256) tokenIdIdxs;

    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory admins
    ) ERC721(name_, symbol_) {
        for (uint8 i = 0; i < admins.length; ) {
            _setupRole(DEFAULT_ADMIN_ROLE, admins[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _transfer(
        address /* from */,
        address /* to */,
        uint256 /* tokenId */
    ) internal virtual override {
        revert();
    }

    function mint(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(balanceOf(to) == 0, "Address is already a member");
        tokenCount++;
        _mint(to, tokenCount);
        tokenIdIdxs[tokenCount] = tokenIds.length;
        tokenIds.push(tokenCount);
    }

    function revoke(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_exists(tokenId), "Token with id does not exist");
        tokenCount--;
        _burn(tokenId);

        uint256 idx = tokenIdIdxs[tokenId];
        uint256 last = tokenIds[tokenIds.length - 1];
        tokenIds[idx] = last;
        tokenIdIdxs[last] = idx;
        tokenIds.pop();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
