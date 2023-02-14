# MutantBitBirds
Solidity Contract: mintable NFTs having on-chain 'mutable' DNA traits

Experiment based on excellent Daibiri work!
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

First dynamic svg MutantBitBird is actually flying on testnet !

Opensea:  https://testnets.opensea.io/collection/mutantbitbirds-1

---------------------------------------------------------------------------------------------
Tokenomics 

No need to stake, earn MCS on first mint and much more simply owning one or more MBBs as holder.
The more you own, the more you earn.
Spend earned MCS tokens to 'evolve' yours MBB NFTs (change the on-chain traits, add a nickname and more to come)

Already eployed on groeli testnet at:

0x016fDf76a0180Fa438c286A9de7aC5aB8DD9746f (MutantBitBirds MBB)<br />
https://goerli.etherscan.io/address/0x016fDf76a0180Fa438c286A9de7aC5aB8DD9746f#readContract<br />
<br />
0xC961e7e4D5a7451817111BE3087ee69fa1603054 (MutantCawSeed MCS)<br />

-----------------------------------------------------------------------------

Test page here (wip):
https://rubykitties.tk/bitBirds.html

Previous build:
0xEC0F6e17668dA43BCF6A620BAe5B853874baaD67
