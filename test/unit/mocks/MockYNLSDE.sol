// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.24;

import {ERC20} from "src/Common.sol";

contract MockYNLSDE is ERC20 {
    constructor() ERC20("Mock ynLSDE", "ynLSDE") {
        _mint(msg.sender, 1000000 * (10 ** uint256(decimals())));
    }

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}
