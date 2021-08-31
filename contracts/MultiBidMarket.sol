// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import 'OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/utils/cryptography/MerkleProof.sol';

struct Bid {
  uint128 amount;
  uint128 price;
}

abstract contract MultiBidMarket {
  bytes32 public immutable root;
  address public immutable nft;

  mapping(uint => uint) public traits;
  mapping(address => uint) public balanceOf;
  mapping(address => mapping(uint => Bid)) public bids;

  constructor(bytes32 _root, address _nft) {
    root = _root;
    nft = _nft;
  }

  function addBid(
    uint mask,
    uint128 amount,
    uint128 price
  ) external payable {
    _deposit();
    bids[msg.sender][mask].amount += amount;
    bids[msg.sender][mask].price = price;
  }

  function removeBid(
    uint mask,
    uint128 amount,
    uint128 price
  ) external {
    bids[msg.sender][mask].amount -= amount;
    bids[msg.sender][mask].price = price;
  }

  function sell(
    uint nftid,
    address buyer,
    uint mask,
    uint trait,
    bytes32[] memory proof
  ) external {
    if (proof.length > 0) {
      relayTraitInfo(nftid, trait, proof);
    }
    require(traits[nftid] == trait, '!trait');
    require((trait & mask) != 0, '!mask');
    Bid storage bid = bids[msg.sender][trait];
    balanceOf[buyer] -= bid.price;
    balanceOf[msg.sender] += bid.price;
    bid.amount -= 1;
    _sendNFT(nftid, msg.sender, buyer);
  }

  function relayTraitInfo(
    uint nftid,
    uint trait,
    bytes32[] memory proof
  ) public {
    bytes32 leaf = keccak256(abi.encodePacked(nftid, trait));
    require(MerkleProof.verify(proof, root, leaf), '!verify');
    traits[nftid] = trait;
  }

  function withdraw(uint wad) external {
    balanceOf[msg.sender] -= wad;
    payable(msg.sender).transfer(wad);
  }

  function deposit() external payable {
    _deposit();
  }

  function _deposit() internal {
    if (msg.value > 0) {
      balanceOf[msg.sender] += msg.value;
    }
  }

  function _sendNFT(
    uint nftid,
    address from,
    address to
  ) internal virtual;
}
