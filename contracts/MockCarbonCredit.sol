// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

import "./ERC3643/IERC3643.sol";

contract MockCarbonCredit is IERC3643 {
    function totalSupply() external view override returns (uint256) {}

    function balanceOf(
        address account
    ) external view override returns (uint256) {}

    function transfer(
        address to,
        uint256 value
    ) external override returns (bool) {}

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {}

    function approve(
        address spender,
        uint256 value
    ) external override returns (bool) {}

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {}

    function decimals() external view override returns (uint8) {}

    function name() external view override returns (string memory) {}

    function onchainID() external view override returns (address) {}

    function symbol() external view override returns (string memory) {}

    function version() external view override returns (string memory) {}

    function identityRegistry()
        external
        view
        override
        returns (IIdentityRegistry)
    {}

    function compliance() external view override returns (ICompliance) {}

    function paused() external view override returns (bool) {}

    function isFrozen(
        address _userAddress
    ) external view override returns (bool) {}

    function getFrozenTokens(
        address _userAddress
    ) external view override returns (uint256) {}

    function setName(string calldata _name) external override {}

    function setSymbol(string calldata _symbol) external override {}

    function setOnchainID(address _onchainID) external override {}

    function pause() external override {}

    function unpause() external override {}

    function setAddressFrozen(
        address _userAddress,
        bool _freeze
    ) external override {}

    function freezePartialTokens(
        address _userAddress,
        uint256 _amount
    ) external override {}

    function unfreezePartialTokens(
        address _userAddress,
        uint256 _amount
    ) external override {}

    function setIdentityRegistry(address _identityRegistry) external override {}

    function setCompliance(address _compliance) external override {}

    function forcedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external override returns (bool) {}

    function mint(address _to, uint256 _amount) external override {}

    function burn(address _userAddress, uint256 _amount) external override {}

    function recoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _investorOnchainID
    ) external override returns (bool) {}

    function batchTransfer(
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external override {}

    function batchForcedTransfer(
        address[] calldata _fromList,
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external override {}

    function batchMint(
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external override {}

    function batchBurn(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts
    ) external override {}

    function batchSetAddressFrozen(
        address[] calldata _userAddresses,
        bool[] calldata _freeze
    ) external override {}

    function batchFreezePartialTokens(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts
    ) external override {}

    function batchUnfreezePartialTokens(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts
    ) external override {}

    function transferOwnershipOnTokenContract(
        address _newOwner
    ) external override {}

    function addAgentOnTokenContract(address _agent) external override {}

    function removeAgentOnTokenContract(address _agent) external override {}
}