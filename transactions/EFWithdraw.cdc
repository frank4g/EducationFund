import FungibleToken from 0x1
import FlowToken from 0x02
import EducationFund from 0x03

// Transation that withdraws from the FundVault of SafeFund
// Only registered recipient(here, child-0x05) in SafeFund can successfully execute it.
transaction {

    prepare(acct: AuthAccount){
        // set withdrawal amount
        let withdrawlamount = 10.0
        //
        let efund = getAccount(0x03)
        let safeFundPath = EducationFund.getSafeFundPublicPath(guardian:Address(0x04),recipient:Address(0x05))
                        ?? panic("safeFund not registered")
        let safefund = efund.getCapability(safeFundPath)
                             .borrow<&EducationFund.SafeFund>()
                             ?? panic("Could not borrow a reference to the fund safevault")
        let idtokegen:@EducationFund.IDTokenGenerator <- EducationFund.createIDTokenGenerator()
        if idtokegen == nil {
            panic("idtokengen generation failed")
        }
        if acct.borrow<&EducationFund.IDTokenGenerator>(from: /storage/efIDTokenGen)==nil{
            acct.save<@EducationFund.IDTokenGenerator>(<- idtokegen, to: /storage/efIDTokenGen)
        }
        let idtokegennRef = acct.borrow<&EducationFund.IDTokenGenerator>(from: /storage/efIDTokenGen)
                ?? panic("Could not borrow owner's IDTokenGenerator reference")
        let idtoken:@EducationFund.IDToken <-idtokegennRef.generateIDToken(amount:withdrawlamount)
        if idtoken == nil {
            panic("idtoken generation failed")
        }
        log(idtoken.address)
        log(idtoken.amount)
        safefund.withdraw(idtoken:<-idtoken)
        log("successfully withdrawn!")
    }
}
