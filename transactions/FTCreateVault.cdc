import FungibleToken from 0x1
import FlowToken from 0x02

// Transation that creates empty flowToken Vault for accounts,
// and make public links for them
//
// use 0x03 for fund
// use 0x04 for parent
// use 0x05 for child
transaction {

    prepare (fund: AuthAccount,parent:AuthAccount,child:AuthAccount){
        for acct in [fund,parent,child] {
            if acct.borrow<&FungibleToken.Vault>(from: /storage/flowTokenVault)== nil {
                acct.save<@FungibleToken.Vault>(<- FlowToken.createEmptyVault(), to: /storage/flowTokenVault)
                //acct.save<@FungibleToken.Vault>(<- create FungibleToken.Vault(balance: 0.0), to: /storage/flowTokenVault)
                acct.link<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver, target: /storage/flowTokenVault)
                acct.link<&FlowToken.Vault{FungibleToken.Balance}>(/public/flowTokenBalance, target: /storage/flowTokenVault)
                log(acct.address)
                log("successfully created")
            }
        }

    }
}
