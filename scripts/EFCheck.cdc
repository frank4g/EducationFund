import EducationFund from 0x03

pub fun main() {
    let efund = getAccount(0x03)
    let safeFundPath = EducationFund.getSafeFundPublicPath(guardian:Address(0x04),recipient:Address(0x05))
                    ?? panic("safeFund not registered")
    log(safeFundPath)
    let safefund = efund.getCapability(safeFundPath)
                            .borrow<&EducationFund.SafeFund>()
                            ?? panic("Could not borrow a reference to the fund safevault")
    log(safefund.withdrawlLimit)
    log(safefund.balance)
    log(safefund.spent)
    log(safefund.recipient)
    log(safefund.guardian)
}

