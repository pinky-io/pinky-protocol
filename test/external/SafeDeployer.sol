// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@safe-contracts/contracts/Safe.sol";
import "@safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import "@safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface ISafe {
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);
}

contract SafeDeployer {
    using Counters for Counters.Counter;

    address public safe;
    SafeProxyFactory private factory = new SafeProxyFactory();
    Counters.Counter private saltNonce;

    function deploySafe(address[] memory _owners, uint256 _threshold) public returns (address) {
        require(_owners.length > 0, "SafeDeployer: owners must not be empty");
        require(_threshold > 0 && _threshold <= _owners.length, "SafeDeployer: invalid threshold");

        address masterCopy = address(new Safe());
        bytes memory data = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            _owners,
            _threshold,
            address(0),
            "",
            address(0),
            address(0),
            0,
            address(0)
        );

        saltNonce.increment();
        safe = address(factory.createProxyWithNonce(masterCopy, data, saltNonce.current()));
        return safe;
    }
}
