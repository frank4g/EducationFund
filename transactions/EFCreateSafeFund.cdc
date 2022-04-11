import FungibleToken from 0x1
import FlowToken from 0x02
import EducationFund from 0x03

// Transation that creates FundVault, SafeFund, Public/Private/Storage Paths for them.
// Here, FundVault source is saved to EducationFund contract owner. So the account is in control
// If you don't like it, you can create it from your account or random account, then throw it into the blockhole(simply forget it.)
// Then, the FundVault will be secured from any account.
transaction {
    prepare (fundadmin: AuthAccount){
        if fundadmin.address != Address(0x03) {
            panic("You should choose EducationFund Admin(here,0x03) as AuthAccount for this transaction.")
        }
        let guardian:Address = 0x04
        let recipient:Address = 0x05
        // fundvault storagepath, privatepath
        let fundVaultStoragePath4XY:StoragePath = /storage/flowtokenVault4XYZ
        let fundVaultPrivatePath4XY:PrivatePath = /private/flowtokenVault4XYZ
        // safefund storagepath, publicpath
        let safeFundStoragePath4XY:StoragePath = /storage/efSafeFund4XYZ
        let safeFundPublicPath4XY:PublicPath = /public/efSafeFund4XYZ
        // recipient Flow Token Receiver Public Path
        let recipientFTReceiverPath=/public/flowTokenReceiver

        // fetch admin reference
        let adminRef = fundadmin.borrow<&EducationFund.Administrator>(from: EducationFund.AdministratorStoragePath)
                        ?? panic("Could not borrow owner's admin reference")

        // register safefundpath to EducationFun
        adminRef.registerSafeFund(guardian:guardian,recipient:recipient,safeFundPath:safeFundPublicPath4XY)

        // create FundVault
        fundadmin.save<@FungibleToken.Vault>(<- FlowToken.createEmptyVault(), to: fundVaultStoragePath4XY)
        //borrow a reference to the fundvault in storage
        let fundVaultCapability = fundadmin.link<&FlowToken.Vault>(fundVaultPrivatePath4XY,target:fundVaultStoragePath4XY)
                                    ?? panic("Unable to create private link to Fund Vault")
               
        // create SafeFund for guardianX, recipientY
        let safeFund4XY <- adminRef.createSafeFund(guardian:guardian,recipient:recipient,recipientRecvPath:recipientFTReceiverPath,fundvault:fundVaultCapability)
        fundadmin.save<@EducationFund.SafeFund>(<-safeFund4XY,to:safeFundStoragePath4XY)
        fundadmin.link<&EducationFund.SafeFund>(safeFundPublicPath4XY, target:safeFundStoragePath4XY)
                                               ?? panic("Unable to create private link to Safe Fund")
        
        // This is only for test
        fundadmin.link<&FlowToken.Vault{FungibleToken.Balance}>(/public/flowTokenBalanceXYZ, target: fundVaultStoragePath4XY)
    }
}
