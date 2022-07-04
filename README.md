LeafToken deployed on Ethereum mainnet: 0x80601E902d186FF01DE5FBcF3B8692038245b1ba
      Token without admin controls or anything weird going on, just meant as
      a token compatible with standard DeFi dapps.
      Name: LeafCoin
      Tracker: LEAF
      Max supply: 420 billion
      Decimals: 18
      ERC20, ERC165, IERC1363

LeafLongTermVesting holds LEAF for vestors and allows vestors to
      withdraw their tokens according to the vesting schedule.
      To add new vesting entries, call on the LEAF token's transferAndCall
      function with parameters accepted by this contracts's _transferReceived.
      For each added entry, their vesting schedule starts at the time of their
      addition. Any receiving wallet address can have multiple entries, each
      recording their start time and following their own path along the 315 day
      vesting schedule. The schedule is at follows:
      Initially zero tokens can be withdrawn,
      then 10% unlocks after the cliff period of 45 days,
      and then linearly 90% unlocks over following 270 days.
      When vestor withdraws their unlocked tokens, they withdraw any available
      from all of their entries.
      Only the intended recipients can withdraw their shares of the tokens
      from the contract. The contract always holds enough tokens to return
      every entry's amounts in full.

LeafPresale facilitates LEAF token sales by receiving Ether from users and
      then adding proportionally sized entries to the LEAF vesting contract.
      Amount of tokens from a sale is given by received ETH in wei divided by leafValueInWei.
      The minimum limit of ETH received is defined by minAcceptAmount.
      The upper limit is defined by the amount of tokens the contract holds.
      Owner can set leafValueInWei & minAcceptAmount.
      The received ETH is forwarded to owner.
      Owner can withdraw unsold tokens.
