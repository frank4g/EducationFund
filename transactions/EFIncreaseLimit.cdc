import FungibleToken from 0x1
import FlowToken from 0x02
import EducationFund from 0x03

// Transation that sets withdraw limit of SafeFund
// Only registered guardian/parenet(here, 0x04) in SafeFund can successfully execute it.
// use 0x04 for guardian
transaction {
    
    prepare(acct: AuthAccount){
        // set withdrawlLimit
        var withdrawlLimit:UFix64 = 10.0
        //
        let efund = getAccount(0x03)
        let safeFundPath = EducationFund.getSafeFundPublicPath(guardian:Address(0x04),recipient:Address(0x05))
                ?? panic("safeFund not registered")
        let safefund = efund.getCapability(safeFundPath)
                             .borrow<&EducationFund.SafeFund>()
                             ?? panic("Could not borrow a reference to the fund safefund")
        let idtokegen:@EducationFund.IDTokenGenerator <- EducationFund.createIDTokenGenerator()
        if idtokegen == nil {
            panic("idtokengen generation failed")
        }
        if acct.borrow<&EducationFund.IDTokenGenerator>(from: /storage/efIDTokenGen)==nil {
            acct.save<@EducationFund.IDTokenGenerator>(<- idtokegen, to: /storage/efIDTokenGen)
        }
        let idtokegennRef = acct.borrow<&EducationFund.IDTokenGenerator>(from: /storage/efIDTokenGen)
                ?? panic("Could not borrow owner's IDTokenGenerator reference")
        let idtoken4increase:@EducationFund.IDToken <-idtokegennRef.generateIDToken(amount:withdrawlLimit)
        if idtoken4increase == nil {
            panic("idtoken generation failed")
        }
        log(idtoken4increase.address)
        log(idtoken4increase.amount)
        //
        if withdrawlLimit <= safefund.withdrawlLimit {
            log("You are not allowed to decrease it.")
        }
        //
        safefund.updateWithdrawalLimit(idtoken:<-idtoken4increase)
        log("successfully increased!")
    }
}
