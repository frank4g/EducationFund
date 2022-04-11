import FungibleToken from 0x1
import FlowToken from 0x02
import EducationFund from 0x03

// Transaction that deposits to FundVault of SafeFund(EducationFund's)
transaction {
    // Temporary Vault object that holds the balance that is being transferred
    var temporaryVault: @FungibleToken.Vault

    prepare(sender: AuthAccount) {
        // deposit amount
        let amount = 100.0
        //
        // withdraw tokens from your vault by borrowing a reference to it
        // and calling the withdraw function with that reference
        let senderRef = sender.borrow<&FlowToken.Vault{FungibleToken.Provider}>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow a reference to the owner's vault")
        // set amount
        
        self.temporaryVault <- senderRef.withdraw(amount: amount)
    }
    execute{
        let efund = getAccount(0x03)
        let safeFundPath = EducationFund.getSafeFundPublicPath(guardian:Address(0x04),recipient:Address(0x05))
                            ?? panic("safeFund not registered")
        let safefund = efund.getCapability(safeFundPath)
                             .borrow<&EducationFund.SafeFund>()
                             ?? panic("Could not borrow a reference to the fund safeFund")
        log(self.temporaryVault.balance)
        safefund.deposit(from:<-self.temporaryVault)
        log("successfully deposited")
        

    }
}
