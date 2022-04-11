
// Transaction that mint and send flowtokens to an account through minting from tokenOwner
// use 0x03 for fund
// use 0x04 for parent
transaction {
    // for minter
    let minterRef: &FlowToken.Minter
    // for receivers
    //let recipientReceiverRef: &FlowToken.Vault{FungibleToken.Receiver}

    prepare (flowAdmin: AuthAccount){
        if flowAdmin.address != Address(0x02) {
            panic("You should choose FlowToken Admin(here,0x02) as AuthAccount for this transaction.")
        }
        // fetch minter reference 
        self.minterRef = flowAdmin.borrow<&FlowToken.Minter>(from: /storage/flowTokenTestMinter)
                        ?? panic("Could not borrow owner's vault minter reference")

    }
    execute {
        // choose recipent address
        for addr in [0x03,0x04] { 
            log(addr)
            let recipient = getAccount(Address(addr))
            // load receiver of recipient
            let recipientReceiverRef = recipient.getCapability(/public/flowTokenReceiver)
                            .borrow<&FlowToken.Vault{FungibleToken.Receiver}>()
                            ?? panic("Could not borrow a reference to the receiver")
            // Mint tokens for parent and fund
            recipientReceiverRef.deposit(from: <-self.minterRef.mintTokens(amount:1000.0))
            log("successfully minted")  
        }
    }
}
