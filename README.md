# MutantBitBirds
Solidity Contract: mintable NFTs having on-chain 'mutable' DNA traits

Experiment based on excellent Daibiri work!
https://github.com/nft-fun

Evolving to a free contract template with tokenomics and on-chain traits with svg dynamic nfts (no need to external storage)

Interfaces.sol - common interfaces defines
MainContract.sol - main contract logic
YieldTokenContract.sol - yield token rewards tokenomics (optional allowed withdrawal)
TokenUriLogicContract.sol - dna-traits and dynamic character logics

Copy, past and compile on Remix
https://remix.ethereum.org/ (enable optimization 200)

Deploy MainContract
Deploy YieldTokenContract (pass MainContract address as constructor param)
Deploy TokenUriLogicContract (pass MainContract address as constructor param)
Set YieldTokenContract address on the deployed MainContract (setYieldToken)
Set TokenUriLogicContract address on the deployed MainContract (setTokenUriLogic)

This is a first draft of a mintable NFT with on-chain traits.

First dynamic svg MutantBitBird is actually flying on testnet !

Opensea:  https://testnets.opensea.io/collection/mutantbitbirds-1

---------------------------------------------------------------------------------------------
Tokenomics 

No need to stake, earn MCS on first mint and much more simply owning one or more MBBs as holder.
The more you own, the more you earn.
Spend earned MCS tokens to 'evolve' yours MBB NFTs (change the on-chain traits, add a nickname and more to come)

Already eployed on groeli testnet at:

0xEC0F6e17668dA43BCF6A620BAe5B853874baaD67 (MutantBitBirds MBB)
https://goerli.etherscan.io/address/0xEC0F6e17668dA43BCF6A620BAe5B853874baaD67#readContract

0xD8BefC4Da6fc79CF9D3e67E7b6F17B8851255E15 (MutantCawSeed MCS)

-----------------------------------------------------------------------------

Test page here (wip):
https://rubykitties.tk/bitBirds.html

