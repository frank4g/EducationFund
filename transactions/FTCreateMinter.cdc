import FungibleToken from 0x1
import FlowToken from 0x02

// Transation that creates a newminter of FlowToken
// Here, the minted amount is set as 
transaction {
    prepare (flowAdmin: AuthAccount){
        // mint amount
        var issueAmount: UFix64 = 100000000.0
        //
        if flowAdmin.address != Address(0x02) {
            panic("You should choose FlowToken Admin(here,0x02) as AuthAccount for this transaction.")
        }
        // fetch admin reference
        let adminRef = flowAdmin.borrow<&FlowToken.Administrator>(from: /storage/flowTokenAdmin)
                        ?? panic("Could not borrow owner's admin reference")
        // initialze minter with issue amount
        if flowAdmin.borrow<&FlowToken.Minter>(from: /storage/flowTokenTestMinter)== nil {
            flowAdmin.save<@FlowToken.Minter>(<-adminRef.createNewMinter(allowedAmount:issueAmount),to:/storage/flowTokenTestMinter)
        }
        log("flowtoken minter successfully created.")
    }
}
