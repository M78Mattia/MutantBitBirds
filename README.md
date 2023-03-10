# MutantBitBirds
Solidity Contract: mintable NFTs having on-chain 'mutable' DNA traits and a yield token for tokenomics.

Experiment based on excellent Dabiri work!
https://github.com/nft-fun

Evolving to a free contract template with tokenomics and on-chain traits with svg dynamic nfts (no need to external storage)

Interfaces.sol - common interfaces defines<br />
MainContract.sol - main contract logic<br />
YieldTokenContract.sol - yield token rewards tokenomics (optional allowed withdrawal)<br />
TokenUriLogicContract.sol - dna-traits and dynamic character logics<br />

Copy, past and compile on Remix<br />
https://remix.ethereum.org/ (enable optimization 200)<br />

Deploy MainContract<br />
Deploy YieldTokenContract (pass MainContract address as constructor param)<br />
Deploy TokenUriLogicContract (pass MainContract address as constructor param)<br />
Set YieldTokenContract address on the deployed MainContract (setYieldToken)<br />
Set TokenUriLogicContract address on the deployed MainContract (setTokenUriLogic)<br />

This is a first draft of a mintable NFT with on-chain traits.

The first dynamic MutantBitBird's svg is actually flying on goerli testnet !

Opensea:  https://testnets.opensea.io/collection/mutantbitbirds-3

---------------------------------------------------------------------------------------------
Tokenomics 

No need to stake, earn MCS on first mint and much more simply owning one or more MBBs as holder.
The more you own, the more you earn.
Spend earned MCS tokens to 'evolve' yours MBB NFTs (change the on-chain traits, add a nickname and more to come)

Already deployed on groeli testnet at:

0xb5adA6C70a1f497Fee69Fa5906BCAAe4DAe0Af28 (MutantBitBirds MBB)<br />
https://goerli.etherscan.io/address/0xb5adA6C70a1f497Fee69Fa5906BCAAe4DAe0Af28#readContract<br />
<br />
0xBA2b0daED2dfaC14489524ac771C5F43F04F8d95 (MutantCawSeed MCS)<br />
https://goerli.etherscan.io/address/0xBA2b0daED2dfaC14489524ac771C5F43F04F8d95#readContract
<br />
0x948e431375f76c33de8cBbf0649adA3605851FE9 (TokeUri Logic)<br />
https://goerli.etherscan.io/address/0x948e431375f76c33de8cBbf0649adA3605851FE9#readContract

-----------------------------------------------------------------------------

Test page here (wip):
https://rubykitties.tk/bitBirds.html

Previous build:
0x7Cc5b6d10071cc2E13e74955786b038A0D64d075
