import FungibleToken from 0x01
import FlowToken from 0x02

// This script reads the Vault balances of two accounts.
pub fun main() {
    // Get the accounts' public account objects
    let fund = getAccount(0x03)
    let parent = getAccount(0x04)
    let child = getAccount(0x05)

    // Get references to the account's balances
    // by getting their public capability
    // and borrowing a reference from the capability
    for acct in [fund,parent,child] {
        let acctRef = acct.getCapability(/public/flowTokenBalance)
                      .borrow<&FlowToken.Vault{FungibleToken.Balance}>()
                      ?? panic("Could not borrow a reference to the fund receiver")
        log("FlowToken Balance")
        log(acctRef.balance)
    }
    let acctRef = fund.getCapability(/public/flowTokenBalanceXYZ)
                      .borrow<&FlowToken.Vault{FungibleToken.Balance}>()
                      ?? panic("Could not borrow a reference to the fund receiver")
    log("SafeFund Balance")
    log(acctRef.balance)
}
