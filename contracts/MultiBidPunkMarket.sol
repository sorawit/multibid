// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import './MultiBidMarket.sol';

interface PunkToken {
  function punkIndexToAddress(uint punkIndex) external view returns (address);

  function buyPunk(uint punkIndex) external payable;

  function transferPunk(address to, uint punkIndex) external;
}

contract MultiBidPunkMarket is MultiBidMarket {
  constructor(bytes32 _root, address _nft) MultiBidMarket(_root, _nft) {}

  function _sendNFT(
    uint nftid,
    address from,
    address to
  ) internal override {
    require(PunkToken(nft).punkIndexToAddress(nftid) == from, '!from');
    PunkToken(nft).buyPunk(nftid);
    PunkToken(nft).transferPunk(to, nftid);
  }
}
