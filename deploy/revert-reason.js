const getRevertReason = require('eth-revert-reason')
const ethers = require("ethers")

// Failed with revert reason "Failed test"
console.log(await getRevertReason('0xf212cc42d0eded75041225d71da6c3a8348bdb9102f2b73434b480419d31d69a')) // 'Failed test'
console.log(await getRevertReason('0x640d2e0d1f4cff9b6e273458216451efb0dc08ebc13c30f6c88d48be7b35872a', 'goerli')) // 'Failed test'

// Failed with no revert reason
console.log(await getRevertReason('0x95ac5a6a1752ccac9647eb21ef8614ca2d3e40a5dbb99914adf87690fb1e6ccf')) // ''

// Successful transaction
console.log(await getRevertReason('0x02b8f8a00a0c0e9dcf60ddebd37ea305483fb30fd61233a505b73036408cae75')) // ''

// Call from the context of a previous block with a custom provider
let txHash = '0xb4c0c05e220dbf16017667a60e4ab9f26655afb2c419a1cf5efb15c575d72b42'
let network = 'mainnet'
network = 'rinkeby'
let blockNumber = 10574191
let provider = new ethers.providers.Web3Provider(network)

console.log(await getRevertReason(txHash, network, blockNumber, provider)) // 'BA: Insufficient gas (ETH) for refund'