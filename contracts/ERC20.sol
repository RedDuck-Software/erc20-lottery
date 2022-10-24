// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract XENToken is ERC20Permit {
    constructor() ERC20Permit("Xen") ERC20("XEN", "XEN") {
        _mint(msg.sender, 2000000000 * 10**18);
    }
}
